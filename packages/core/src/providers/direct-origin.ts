import { Readability } from "@mozilla/readability";
import { JSDOM } from "jsdom";
import { NodeHtmlMarkdown } from "node-html-markdown";

import {
  ProviderFetchError,
  type ProviderRuntimeContext,
  type SourceProvider
} from "./provider.js";
import { normalizeProviderText } from "./normalize.js";

const DEFAULT_ACCEPT_HEADER =
  "text/html,application/xhtml+xml,text/plain;q=0.9,text/markdown;q=0.8,*/*;q=0.1";
const DEFAULT_REDIRECT_LIMIT = 10;

function isRedirectStatus(status: number): boolean {
  return status === 301 || status === 302 || status === 303 || status === 307 || status === 308;
}

function isHtmlContentType(contentType: string | null): boolean {
  return contentType !== null && /^(text\/html|application\/xhtml\+xml)\b/iu.test(contentType);
}

function looksLikeHtml(body: string): boolean {
  return /^\s*</u.test(body);
}

function htmlToMarkdown(html: string, url: string): string {
  const dom = new JSDOM(html, {
    url
  });

  try {
    const document = dom.window.document;
    const readable = new Readability(document).parse();
    const title = readable?.title?.trim() ?? document.title.trim();
    const htmlContent =
      readable?.content ??
      document.body?.innerHTML ??
      document.documentElement.innerHTML;
    const markdown = normalizeProviderText(NodeHtmlMarkdown.translate(htmlContent));

    if (title === "") {
      return markdown;
    }

    if (markdown === "") {
      return normalizeProviderText(`# ${title}`);
    }

    return normalizeProviderText(`# ${title}\n\n${markdown}`);
  } finally {
    dom.window.close();
  }
}

async function cancelResponseBody(response: Response): Promise<void> {
  try {
    await response.body?.cancel();
  } catch {
    // Ignore body cancellation failures; redirect handling already completed.
  }
}

export interface CreateDirectOriginProviderOptions {
  readonly fetchImpl?: typeof fetch;
  readonly maxRedirects?: number;
}

export function createDirectOriginProvider(
  options: CreateDirectOriginProviderOptions = {}
): SourceProvider {
  return {
    name: "direct_origin",
    async fetch(sourceUrl: string, context: ProviderRuntimeContext) {
      const fetchImpl = options.fetchImpl ?? context.fetchImpl;
      const maxRedirects = options.maxRedirects ?? DEFAULT_REDIRECT_LIMIT;
      const headers = new Headers({
        Accept: DEFAULT_ACCEPT_HEADER
      });
      let currentUrl = sourceUrl;

      for (let redirectCount = 0; ; redirectCount += 1) {
        await context.assertSafeUrl(currentUrl);

        let response: Response;

        try {
          response = await fetchImpl(currentUrl, {
            headers,
            redirect: "manual"
          });
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);

          throw new ProviderFetchError({
            providerName: "direct_origin",
            message: `Direct origin fetch failed for ${currentUrl}: ${message}`,
            disposition: "fail_closed",
            cause: error
          });
        }

        if (isRedirectStatus(response.status)) {
          await cancelResponseBody(response);

          const location = response.headers.get("location");

          if (location === null || location.trim() === "") {
            throw new ProviderFetchError({
              providerName: "direct_origin",
              message: `Direct origin returned a redirect without a Location header for ${currentUrl}`,
              disposition: "fail_closed"
            });
          }

          if (redirectCount >= maxRedirects) {
            throw new ProviderFetchError({
              providerName: "direct_origin",
              message: `Direct origin exceeded the redirect limit for ${sourceUrl}`,
              disposition: "fail_closed"
            });
          }

          let nextUrl: string;

          try {
            nextUrl = new URL(location, currentUrl).toString();
          } catch (error) {
            throw new ProviderFetchError({
              providerName: "direct_origin",
              message: `Direct origin returned an invalid redirect target for ${currentUrl}`,
              disposition: "fail_closed",
              cause: error
            });
          }

          currentUrl = nextUrl;
          continue;
        }

        if (!response.ok) {
          throw new ProviderFetchError({
            providerName: "direct_origin",
            message: `Direct origin request failed with status ${response.status}`,
            disposition: "fail_closed"
          });
        }

        const body = await response.text();
        const contentType = response.headers.get("content-type");
        const canonicalText = isHtmlContentType(contentType) || looksLikeHtml(body)
          ? htmlToMarkdown(body, currentUrl)
          : normalizeProviderText(body);

        if (canonicalText === "") {
          throw new ProviderFetchError({
            providerName: "direct_origin",
            message: "Direct origin returned empty canonical text",
            disposition: "fail_closed"
          });
        }

        return {
          providerName: "direct_origin",
          durableFetchMethod: "direct_origin",
          canonicalText,
          fetchedAt: new Date().toISOString(),
          providerUrl: currentUrl,
          resolvedSourceUrl: currentUrl,
          responseStatus: response.status,
          responseHeaders: Object.fromEntries(response.headers.entries())
        };
      }
    }
  };
}
