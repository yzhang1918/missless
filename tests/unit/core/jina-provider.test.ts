import assert from "node:assert/strict";
import test from "node:test";

import {
  buildJinaReaderUrl,
  createJinaReaderProvider,
  normalizeReaderOutput
} from "../../../packages/core/src/index.ts";

test("normalizeReaderOutput preserves content while normalizing reader output", () => {
  const normalized = normalizeReaderOutput(
    "\uFEFF# Harness Engineering\r\n\r\nLine with trailing space   \r\n\r\n"
  );

  assert.equal(normalized, "# Harness Engineering\n\nLine with trailing space\n");
});

test("buildJinaReaderUrl prefixes the target URL with the reader base", () => {
  assert.equal(
    buildJinaReaderUrl(
      "https://example.com/agent-harness",
      "https://r.jina.ai/"
    ),
    "https://r.jina.ai/https://example.com/agent-harness"
  );
});

test("createJinaReaderProvider forwards auth to the official reader host", async () => {
  let seenAuthorization: string | null = null;
  const provider = createJinaReaderProvider({
    apiKey: "secret-token",
    fetchImpl: async (_input, init) => {
      const headers = new Headers(init?.headers);

      seenAuthorization = headers.get("Authorization");

      return new Response("# Harness Engineering\n");
    }
  });

  await provider.fetch("https://example.com/agent-harness");

  assert.equal(seenAuthorization, "Bearer secret-token");
});

test("createJinaReaderProvider does not forward auth to override hosts by default", async () => {
  let seenAuthorization: string | null = null;
  const provider = createJinaReaderProvider({
    baseUrl: "http://127.0.0.1:4321/",
    apiKey: "secret-token",
    fetchImpl: async (_input, init) => {
      const headers = new Headers(init?.headers);

      seenAuthorization = headers.get("Authorization");

      return new Response("# Harness Engineering\n");
    }
  });

  await provider.fetch("https://example.com/agent-harness");

  assert.equal(seenAuthorization, null);
});

test("createJinaReaderProvider wraps transport failures with provider context", async () => {
  const provider = createJinaReaderProvider({
    fetchImpl: async () => {
      throw new TypeError("fetch failed");
    }
  });

  await assert.rejects(
    () => provider.fetch("https://example.com/agent-harness"),
    /Jina Reader fetch failed for https:\/\/r\.jina\.ai\/https:\/\/example\.com\/agent-harness: fetch failed/
  );
});

test("createJinaReaderProvider rejects upstream warning pages", async () => {
  const provider = createJinaReaderProvider({
    fetchImpl: async () =>
      new Response(
        [
          "Title: Just a moment...",
          "",
          "URL Source: https://example.com/agent-harness",
          "",
          "Warning: Target URL returned error 403: Forbidden",
          "Warning: This page maybe not yet fully loaded, consider explicitly specify a timeout.",
          "",
          "Markdown Content:",
          "Just a moment...",
          "===============",
          "",
          "Verification successful. Waiting for example.com to respond"
        ].join("\n")
      )
  });

  await assert.rejects(
    () => provider.fetch("https://example.com/agent-harness"),
    /Jina Reader returned an upstream warning page: 403: Forbidden/
  );
});
