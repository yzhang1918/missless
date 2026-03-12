import { lookup } from "node:dns/promises";
import { isIP } from "node:net";

import type { FetchLike } from "../providers/provider.js";

const DEFAULT_REDIRECT_LIMIT = 10;

export type HostResolver = (
  hostname: string
) => Promise<readonly { address: string; family: 4 | 6 }[]>;

function parseIpv4MappedIpv6(hostname: string): string | null {
  const normalized = stripIpv6Brackets(hostname).toLowerCase();

  if (!normalized.startsWith("::ffff:")) {
    return null;
  }

  const suffix = normalized.slice("::ffff:".length);

  if (isIP(suffix) === 4) {
    return suffix;
  }

  if (/^[0-9a-f]{1,8}$/u.test(suffix)) {
    const value = Number.parseInt(suffix, 16);

    return [
      (value >>> 24) & 0xff,
      (value >>> 16) & 0xff,
      (value >>> 8) & 0xff,
      value & 0xff
    ].join(".");
  }

  const parts = suffix.split(":");

  if (parts.length !== 2 || parts.some((part) => !/^[0-9a-f]{1,4}$/u.test(part))) {
    return null;
  }

  const [first, second] = parts.map((part) => Number.parseInt(part, 16));

  return [
    (first >>> 8) & 0xff,
    first & 0xff,
    (second >>> 8) & 0xff,
    second & 0xff
  ].join(".");
}

function isBlockedIpv4Host(hostname: string): boolean {
  const octets = hostname.split(".").map((part) => Number(part));

  if (octets.length !== 4 || octets.some((part) => Number.isNaN(part))) {
    return false;
  }

  const [first, second] = octets;

  return (
    first === 0 ||
    first === 10 ||
    first === 127 ||
    (first === 169 && second === 254) ||
    (first === 172 && second >= 16 && second <= 31) ||
    (first === 192 && second === 168) ||
    (first === 100 && second >= 64 && second <= 127) ||
    (first === 198 && (second === 18 || second === 19))
  );
}

function isBlockedIpv6Host(hostname: string): boolean {
  const normalized = stripIpv6Brackets(hostname).toLowerCase();
  const mappedIpv4 = parseIpv4MappedIpv6(normalized);

  if (
    normalized === "::" ||
    normalized === "::1" ||
    normalized.startsWith("fe8") ||
    normalized.startsWith("fe9") ||
    normalized.startsWith("fea") ||
    normalized.startsWith("feb") ||
    normalized.startsWith("fc") ||
    normalized.startsWith("fd")
  ) {
    return true;
  }

  if (mappedIpv4 !== null) {
    return isBlockedIpv4Host(mappedIpv4);
  }

  return false;
}

function isBlockedHostname(hostname: string): boolean {
  const normalized = stripTrailingDnsDots(
    stripIpv6Brackets(hostname).toLowerCase()
  );
  const ipVersion = isIP(normalized);

  if (ipVersion === 4) {
    return isBlockedIpv4Host(normalized);
  }

  if (ipVersion === 6) {
    return isBlockedIpv6Host(normalized);
  }

  return (
    normalized === "localhost" ||
    normalized.endsWith(".localhost") ||
    normalized.endsWith(".local") ||
    !normalized.includes(".")
  );
}

function stripIpv6Brackets(hostname: string): string {
  return hostname.startsWith("[") && hostname.endsWith("]")
    ? hostname.slice(1, -1)
    : hostname;
}

function stripTrailingDnsDots(hostname: string): string {
  return hostname.replace(/\.+$/u, "");
}

export async function defaultHostResolver(
  hostname: string
): Promise<readonly { address: string; family: 4 | 6 }[]> {
  const results = await lookup(hostname, {
    all: true,
    verbatim: true
  });

  return results.filter(
    (result): result is { address: string; family: 4 | 6 } =>
      result.family === 4 || result.family === 6
  );
}

export async function assertSafeHttpUrl(
  sourceUrl: string,
  hostResolver: HostResolver
): Promise<void> {
  const parsed = new URL(sourceUrl);

  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new Error("fetch-normalize only supports http and https URLs");
  }

  if (parsed.username !== "" || parsed.password !== "") {
    throw new Error("fetch-normalize rejects source URLs with embedded credentials");
  }

  if (isBlockedHostname(parsed.hostname)) {
    throw new Error(
      "fetch-normalize rejects localhost, private, link-local, and single-label hosts"
    );
  }

  const resolvedAddresses = await hostResolver(
    stripTrailingDnsDots(stripIpv6Brackets(parsed.hostname).toLowerCase())
  );

  if (resolvedAddresses.some((result) => isBlockedHostname(result.address))) {
    throw new Error(
      "fetch-normalize rejects hostnames that resolve to localhost, private, or link-local addresses"
    );
  }
}

async function cancelResponseBody(response: Response): Promise<void> {
  try {
    await response.body?.cancel();
  } catch {
    // Ignore body cancellation failures; the safety decision already happened.
  }
}

function isRedirectStatus(status: number): boolean {
  return status === 301 || status === 302 || status === 303 || status === 307 || status === 308;
}

export interface RedirectResolution {
  readonly originalUrl: string;
  readonly finalUrl: string;
  readonly redirects: readonly string[];
}

export interface ResolveSafeRedirectChainOptions {
  readonly fetchImpl?: FetchLike;
  readonly hostResolver?: HostResolver;
  readonly maxRedirects?: number;
}

export async function resolveSafeRedirectChain(
  sourceUrl: string,
  options: ResolveSafeRedirectChainOptions = {}
): Promise<RedirectResolution> {
  const fetchImpl = options.fetchImpl ?? globalThis.fetch;
  const hostResolver = options.hostResolver ?? defaultHostResolver;
  const maxRedirects = options.maxRedirects ?? DEFAULT_REDIRECT_LIMIT;
  const redirects: string[] = [];
  let currentUrl = sourceUrl;

  for (let redirectCount = 0; ; redirectCount += 1) {
    try {
      await assertSafeHttpUrl(currentUrl, hostResolver);
    } catch (error) {
      if (redirects.length > 0) {
        throw new Error(
          "fetch-normalize rejects redirect hops and final destinations that are localhost, private, or link-local",
          {
            cause: error
          }
        );
      }

      throw error;
    }

    let response: Response;

    try {
      response = await fetchImpl(currentUrl, {
        method: "GET",
        redirect: "manual"
      });
    } catch (error) {
      throw new Error(
        `fetch-normalize could not verify redirect safety for ${currentUrl}`,
        {
          cause: error
        }
      );
    }

    if (!isRedirectStatus(response.status)) {
      await cancelResponseBody(response);

      return {
        originalUrl: sourceUrl,
        finalUrl: currentUrl,
        redirects
      };
    }

    await cancelResponseBody(response);

    const location = response.headers.get("location");

    if (location === null || location.trim() === "") {
      throw new Error(
        `fetch-normalize encountered a redirect without a Location header for ${currentUrl}`
      );
    }

    if (redirectCount >= maxRedirects) {
      throw new Error(
        `fetch-normalize exceeded the redirect limit while resolving ${sourceUrl}`
      );
    }

    let nextUrl: string;

    try {
      nextUrl = new URL(location, currentUrl).toString();
    } catch (error) {
      throw new Error(
        `fetch-normalize encountered an invalid redirect target for ${currentUrl}`,
        {
          cause: error
        }
      );
    }

    redirects.push(nextUrl);
    currentUrl = nextUrl;
  }
}
