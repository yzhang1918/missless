import type { SourceProvider } from "./provider.js";

const DEFAULT_JINA_READER_BASE_URL = "https://r.jina.ai/";
const FORWARD_OVERRIDE_AUTH_ENV = "MISSLESS_JINA_FORWARD_API_KEY_TO_OVERRIDE";

export type FetchLike = typeof fetch;

function parseBooleanEnv(value: string | undefined): boolean {
  if (value === undefined) {
    return false;
  }

  return value === "1" || value.toLowerCase() === "true";
}

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
  const fetchImpl = options.fetchImpl ?? globalThis.fetch;
  const allowOverrideApiKeyForwarding =
    options.allowOverrideApiKeyForwarding ??
    parseBooleanEnv(process.env[FORWARD_OVERRIDE_AUTH_ENV]);

  return {
    name: "jina_reader",
    async fetch(sourceUrl: string) {
      const providerUrl = buildJinaReaderUrl(sourceUrl, baseUrl);
      const headers = new Headers({
        Accept: "text/plain"
      });

      if (
        apiKey !== undefined &&
        apiKey !== "" &&
        shouldForwardJinaApiKey(baseUrl, allowOverrideApiKeyForwarding)
      ) {
        headers.set("Authorization", `Bearer ${apiKey}`);
      }

      let response: Response;

      try {
        response = await fetchImpl(providerUrl, { headers });
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);

        throw new Error(`Jina Reader fetch failed for ${providerUrl}: ${message}`);
      }

      if (!response.ok) {
        throw new Error(
          `Jina Reader request failed with status ${response.status}`
        );
      }

      const canonicalText = normalizeReaderOutput(await response.text());

      if (canonicalText === "") {
        throw new Error("Jina Reader returned empty canonical text");
      }

      const warning = detectReaderWarning(canonicalText);

      if (warning !== null) {
        throw new Error(warning);
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
