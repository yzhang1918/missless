export type FetchLike = typeof fetch;

export type ProviderFailureDisposition = "retryable" | "fail_closed";

export interface ProviderFetchResult {
  readonly providerName: string;
  readonly canonicalText: string;
  readonly fetchedAt: string;
  readonly providerUrl: string;
  readonly resolvedSourceUrl: string;
  readonly responseStatus: number;
  readonly responseHeaders: Readonly<Record<string, string>>;
}

export interface ProviderRuntimeContext {
  readonly fetchImpl: FetchLike;
  readonly assertSafeUrl: (url: string) => Promise<void>;
}

export interface SourceProvider {
  readonly name: string;
  fetch(
    sourceUrl: string,
    context: ProviderRuntimeContext
  ): Promise<ProviderFetchResult>;
}

export interface ProviderFetchErrorOptions {
  readonly providerName: string;
  readonly message: string;
  readonly disposition: ProviderFailureDisposition;
  readonly cause?: unknown;
}

export class ProviderFetchError extends Error {
  readonly providerName: string;
  readonly disposition: ProviderFailureDisposition;

  constructor(options: ProviderFetchErrorOptions) {
    super(options.message, {
      cause: options.cause
    });
    this.name = "ProviderFetchError";
    this.providerName = options.providerName;
    this.disposition = options.disposition;
  }
}

export function isProviderFetchError(
  error: unknown
): error is ProviderFetchError {
  return error instanceof ProviderFetchError;
}

export function createFallbackSourceProvider(
  providers: readonly SourceProvider[]
): SourceProvider {
  if (providers.length === 0) {
    throw new Error("Fallback provider chain requires at least one provider");
  }

  return {
    name: providers.map((provider) => provider.name).join("->"),
    async fetch(sourceUrl, context) {
      let lastError: unknown;

      for (const [index, provider] of providers.entries()) {
        try {
          return await provider.fetch(sourceUrl, context);
        } catch (error) {
          lastError = error;

          if (
            !isProviderFetchError(error) ||
            error.disposition !== "retryable" ||
            index === providers.length - 1
          ) {
            throw error;
          }
        }
      }

      throw lastError ?? new Error("Fallback provider chain exhausted");
    }
  };
}
