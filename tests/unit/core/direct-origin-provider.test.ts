import assert from "node:assert/strict";
import test from "node:test";

import { createDirectOriginProvider } from "../../../packages/core/src/index.ts";

test("direct origin provider follows safe redirects and converts html to markdown-friendly text", async () => {
  const requestedUrls: string[] = [];
  const provider = createDirectOriginProvider({
    fetchImpl: async (input) => {
      const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
      requestedUrls.push(url);

      if (url === "https://example.com/article") {
        return new Response(null, {
          status: 302,
          headers: {
            location: "https://www.example.com/final-article"
          }
        });
      }

      if (url === "https://www.example.com/final-article") {
        return new Response(
          [
            "<!doctype html>",
            "<html>",
            "<head><title>Example Article</title></head>",
            "<body>",
            "<article>",
            "<h1>Example Article</h1>",
            "<p>This is the canonical body.</p>",
            "</article>",
            "</body>",
            "</html>"
          ].join(""),
          {
            status: 200,
            headers: {
              "content-type": "text/html; charset=utf-8"
            }
          }
        );
      }

      throw new Error(`Unexpected URL: ${url}`);
    }
  });

  const result = await provider.fetch("https://example.com/article", {
    assertSafeUrl: async () => undefined,
    fetchImpl: globalThis.fetch
  });

  assert.deepEqual(requestedUrls, [
    "https://example.com/article",
    "https://www.example.com/final-article"
  ]);
  assert.equal(result.providerName, "direct_origin");
  assert.equal(result.providerUrl, "https://www.example.com/final-article");
  assert.equal(result.resolvedSourceUrl, "https://www.example.com/final-article");
  assert.match(result.canonicalText, /Example Article/);
  assert.match(result.canonicalText, /This is the canonical body/);
});

test("direct origin provider fails closed on blocked redirect destinations", async () => {
  const checkedUrls: string[] = [];
  const provider = createDirectOriginProvider({
    fetchImpl: async () =>
      new Response(null, {
        status: 302,
        headers: {
          location: "http://127.0.0.1/private"
        }
      })
  });

  await assert.rejects(
    () =>
      provider.fetch("https://example.com/article", {
        async assertSafeUrl(url) {
          checkedUrls.push(url);

          if (url.includes("127.0.0.1")) {
            throw new Error("blocked destination");
          }
        },
        fetchImpl: globalThis.fetch
      }),
    /blocked destination/
  );
  assert.deepEqual(checkedUrls, [
    "https://example.com/article",
    "http://127.0.0.1/private"
  ]);
});
