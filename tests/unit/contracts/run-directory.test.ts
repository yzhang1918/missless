import assert from "node:assert/strict";
import test from "node:test";

import { getRunArtifactPaths } from "../../../packages/contracts/src/index.ts";

test("run directories use stable artifact filenames", () => {
  const paths = getRunArtifactPaths("/tmp/missless/run-20260308");

  assert.deepEqual(paths, {
    runDir: "/tmp/missless/run-20260308",
    runManifest: "/tmp/missless/run-20260308/run.json",
    source: "/tmp/missless/run-20260308/source.json",
    canonicalText: "/tmp/missless/run-20260308/canonical_text.md",
    extractionDraft: "/tmp/missless/run-20260308/extraction_draft.json",
    evidenceResult: "/tmp/missless/run-20260308/evidence_result.json",
    reviewBundle: "/tmp/missless/run-20260308/review_bundle.json",
    reviewHtml: "/tmp/missless/run-20260308/review.html"
  });
});
