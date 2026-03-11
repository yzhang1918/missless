import {
  ProviderFetchError,
  type FetchLike,
  type ProviderRuntimeContext,
  type SourceProvider
} from "./provider.js";
import { normalizeProviderText } from "./normalize.js";

const DEFAULT_JINA_READER_BASE_URL = "https://r.jina.ai/";
const FORWARD_OVERRIDE_AUTH_ENV = "MISSLESS_JINA_FORWARD_API_KEY_TO_OVERRIDE";

function parseBooleanEnv(value: string | undefined): boolean {
  if (value === undefined) {
    return false;
  }

  return value === "1" || value.toLowerCase() === "true";
}

export function normalizeReaderOutput(rawText: string): string {
  return normalizeProviderText(rawText);
}

function normalizeBaseUrl(baseUrl: string): string {
  return baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`;
}

function detectReaderWarning(canonicalText: string): string | null {
  const upstreamWarning = canonicalText.match(
    /^Warning: Target URL returned error ([^\n]+)$/mu
  );

  if (upstreamWarning !== null) {
    return `Jina Reader returned an upstream warning page: ${upstreamWarning[1]}`;
  }

  if (
    canonicalText.startsWith("Title: Just a moment...") ||
    canonicalText.includes("Verification successful. Waiting for")
  ) {
    return "Jina Reader returned an interstitial page instead of canonical content";
  }

  return null;
}

function isOfficialJinaReaderOrigin(baseUrl: string): boolean {
  const parsed = new URL(normalizeBaseUrl(baseUrl));

  return (
    parsed.protocol === "https:" &&
    parsed.hostname.toLowerCase() === "r.jina.ai"
  );
}

export function shouldForwardJinaApiKey(
  baseUrl: string,
  allowOverrideApiKeyForwarding = false
): boolean {
  return (
    isOfficialJinaReaderOrigin(baseUrl) || allowOverrideApiKeyForwarding
  );
}

export function buildJinaReaderUrl(
  targetUrl: string,
  baseUrl = DEFAULT_JINA_READER_BASE_URL
): string {
  const normalizedBaseUrl = normalizeBaseUrl(baseUrl);

  return `${normalizedBaseUrl}${targetUrl}`;
}

export interface CreateJinaReaderProviderOptions {
  readonly baseUrl?: string;
  readonly apiKey?: string;
  readonly fetchImpl?: FetchLike;
  readonly allowOverrideApiKeyForwarding?: boolean;
}

export function createJinaReaderProvider(
  options: CreateJinaReaderProviderOptions = {}
): SourceProvider {
  const baseUrl =
    options.baseUrl ??
    process.env.MISSLESS_JINA_BASE_URL ??
    DEFAULT_JINA_READER_BASE_URL;
  const apiKey = options.apiKey ?? process.env.JINA_API_KEY;
  const allowOverrideApiKeyForwarding =
    options.allowOverrideApiKeyForwarding ??
    parseBooleanEnv(process.env[FORWARD_OVERRIDE_AUTH_ENV]);

  return {
    name: "jina_reader",
    async fetch(sourceUrl: string, context: ProviderRuntimeContext) {
      const providerUrl = buildJinaReaderUrl(sourceUrl, baseUrl);
      const headers = new Headers({
        Accept: "text/plain"
      });
      const effectiveFetchImpl = options.fetchImpl ?? context.fetchImpl;

      if (
        apiKey !== undefined &&
        apiKey !== "" &&
        shouldForwardJinaApiKey(baseUrl, allowOverrideApiKeyForwarding)
      ) {
        headers.set("Authorization", `Bearer ${apiKey}`);
      }

      let response: Response;

      try {
        response = await effectiveFetchImpl(providerUrl, { headers });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);

        throw new ProviderFetchError({
          providerName: "jina_reader",
          message: `Jina Reader fetch failed for ${providerUrl}: ${message}`,
          disposition: "retryable",
          cause: error
        });
      }

      if (!response.ok) {
        throw new ProviderFetchError({
          providerName: "jina_reader",
          message: `Jina Reader request failed with status ${response.status}`,
          disposition: "retryable"
        });
      }

      const canonicalText = normalizeReaderOutput(await response.text());

      if (canonicalText === "") {
        throw new ProviderFetchError({
          providerName: "jina_reader",
          message: "Jina Reader returned empty canonical text",
          disposition: "retryable"
        });
      }

      const warning = detectReaderWarning(canonicalText);

      if (warning !== null) {
        throw new ProviderFetchError({
          providerName: "jina_reader",
          message: warning,
          disposition: "retryable"
        });
      }

      return {
        providerName: "jina_reader",
        canonicalText,
        fetchedAt: new Date().toISOString(),
        providerUrl,
        resolvedSourceUrl: sourceUrl,
        responseStatus: response.status,
        responseHeaders: Object.fromEntries(response.headers.entries())
      };
    }
  };
}
