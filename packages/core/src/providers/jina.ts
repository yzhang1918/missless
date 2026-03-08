import type { SourceProvider } from "./provider.js";

const DEFAULT_JINA_READER_BASE_URL = "https://r.jina.ai/";

export type FetchLike = typeof fetch;

function trimBlankLines(lines: readonly string[]): readonly string[] {
  let start = 0;
  let end = lines.length;

  while (start < end && lines[start]?.trim() === "") {
    start += 1;
  }

  while (end > start && lines[end - 1]?.trim() === "") {
    end -= 1;
  }

  return lines.slice(start, end);
}

export function normalizeReaderOutput(rawText: string): string {
  const withoutBom = rawText.replace(/^\uFEFF/u, "");
  const normalizedNewlines = withoutBom.replace(/\r\n?/gu, "\n");
  const withoutTrailingSpaces = normalizedNewlines
    .split("\n")
    .map((line) => line.replace(/[ \t]+$/u, ""))
    .join("\n");
  const trimmed = trimBlankLines(withoutTrailingSpaces.split("\n")).join("\n");

  return trimmed === "" ? "" : `${trimmed}\n`;
}

export function buildJinaReaderUrl(
  targetUrl: string,
  baseUrl = DEFAULT_JINA_READER_BASE_URL
): string {
  const normalizedBaseUrl = baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`;

  return `${normalizedBaseUrl}${targetUrl}`;
}

export interface CreateJinaReaderProviderOptions {
  readonly baseUrl?: string;
  readonly apiKey?: string;
  readonly fetchImpl?: FetchLike;
}

export function createJinaReaderProvider(
  options: CreateJinaReaderProviderOptions = {}
): SourceProvider {
  const baseUrl =
    options.baseUrl ??
    process.env.MISSLESS_JINA_BASE_URL ??
    DEFAULT_JINA_READER_BASE_URL;
  const apiKey = options.apiKey ?? process.env.JINA_API_KEY;
  const fetchImpl = options.fetchImpl ?? globalThis.fetch;

  return {
    name: "jina_reader",
    async fetch(sourceUrl: string) {
      const providerUrl = buildJinaReaderUrl(sourceUrl, baseUrl);
      const headers = new Headers({
        Accept: "text/plain"
      });

      if (apiKey !== undefined && apiKey !== "") {
        headers.set("Authorization", `Bearer ${apiKey}`);
      }

      const response = await fetchImpl(providerUrl, { headers });

      if (!response.ok) {
        throw new Error(
          `Jina Reader request failed with status ${response.status}`
        );
      }

      const canonicalText = normalizeReaderOutput(await response.text());

      if (canonicalText === "") {
        throw new Error("Jina Reader returned empty canonical text");
      }

      return {
        canonicalText,
        fetchedAt: new Date().toISOString(),
        providerUrl,
        responseStatus: response.status,
        responseHeaders: Object.fromEntries(response.headers.entries())
      };
    }
  };
}
