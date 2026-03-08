import assert from "node:assert/strict";
import test from "node:test";

import {
  buildJinaReaderUrl,
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
