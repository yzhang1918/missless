import { createDirectOriginProvider } from "./direct-origin.js";
import { createJinaReaderProvider } from "./jina.js";
import {
  createFallbackSourceProvider,
  type DurableFetchMethod,
  type SourceProvider
} from "./provider.js";

export type ConcreteFetchMethod = DurableFetchMethod;
export type FetchMethod = "auto" | ConcreteFetchMethod;

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
