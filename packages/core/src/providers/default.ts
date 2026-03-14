import { createDirectOriginProvider } from "./direct-origin.js";
import { createJinaReaderProvider } from "./jina.js";
import {
  createFallbackSourceProvider,
  type SourceProvider
} from "./provider.js";

export type FetchMethod = "auto" | "jina_reader" | "direct_origin";
export type ConcreteFetchMethod = Exclude<FetchMethod, "auto">;

export function createSourceProviderForMethod(
  fetchMethod: FetchMethod
): SourceProvider {
  if (fetchMethod === "jina_reader") {
    return createJinaReaderProvider();
  }

  if (fetchMethod === "direct_origin") {
    return createDirectOriginProvider();
  }

  return createFallbackSourceProvider([
    createJinaReaderProvider(),
    createDirectOriginProvider()
  ]);
}

export function createDefaultSourceProvider(): SourceProvider {
  return createSourceProviderForMethod("auto");
}
