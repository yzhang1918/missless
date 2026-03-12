import { createDirectOriginProvider } from "./direct-origin.js";
import { createJinaReaderProvider } from "./jina.js";
import {
  createFallbackSourceProvider,
  type SourceProvider
} from "./provider.js";

export function createDefaultSourceProvider(): SourceProvider {
  return createFallbackSourceProvider([
    createJinaReaderProvider(),
    createDirectOriginProvider()
  ]);
}
