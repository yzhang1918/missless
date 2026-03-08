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
