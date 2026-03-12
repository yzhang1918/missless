import assert from "node:assert/strict";
import test from "node:test";

import {
  createFallbackSourceProvider,
  ProviderFetchError
} from "../../../packages/core/src/index.ts";

test("fallback provider retries the next provider after a recoverable failure", async () => {
  const attempts: string[] = [];
  const provider = createFallbackSourceProvider([
    {
      name: "primary",
      async fetch() {
        attempts.push("primary");
        throw new ProviderFetchError({
          providerName: "primary",
          message: "primary transient failure",
          disposition: "retryable"
        });
      }
    },
    {
      name: "secondary",
      async fetch() {
        attempts.push("secondary");

        return {
          providerName: "secondary",
          canonicalText: "Fallback canonical text\n",
          fetchedAt: "2026-03-11T00:00:00.000Z",
          providerUrl: "https://origin.example/article",
          resolvedSourceUrl: "https://example.com/article",
          responseStatus: 200,
          responseHeaders: {
            "content-type": "text/markdown"
          }
        };
      }
    }
  ]);

  const result = await provider.fetch("https://example.com/article", {
    assertSafeUrl: async () => undefined,
    fetchImpl: globalThis.fetch
  });

  assert.deepEqual(attempts, ["primary", "secondary"]);
  assert.equal(result.providerName, "secondary");
});

test("fallback provider does not continue after a terminal policy failure", async () => {
  const attempts: string[] = [];
  const provider = createFallbackSourceProvider([
    {
      name: "primary",
      async fetch() {
        attempts.push("primary");
        throw new ProviderFetchError({
          providerName: "primary",
          message: "blocked destination",
          disposition: "fail_closed"
        });
      }
    },
    {
      name: "secondary",
      async fetch() {
        attempts.push("secondary");
        throw new Error("secondary should not be reached");
      }
    }
  ]);

  await assert.rejects(
    () =>
      provider.fetch("https://example.com/article", {
        assertSafeUrl: async () => undefined,
        fetchImpl: globalThis.fetch
      }),
    /blocked destination/
  );
  assert.deepEqual(attempts, ["primary"]);
});
