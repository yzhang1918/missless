export interface ProviderFetchResult {
  readonly canonicalText: string;
  readonly fetchedAt: string;
  readonly providerUrl: string;
  readonly responseStatus: number;
  readonly responseHeaders: Readonly<Record<string, string>>;
}

export interface SourceProvider {
  readonly name: string;
  fetch(sourceUrl: string): Promise<ProviderFetchResult>;
}
