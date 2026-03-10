import assert from "node:assert/strict";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  validateAiReviewPayload
} from "../../../scripts/e2e/validate_ai_review.mjs";

async function createRunDir(name: string): Promise<string> {
  return mkdtemp(join(tmpdir(), `${name}-`));
}

async function writeRequiredArtifacts(runDir: string): Promise<void> {
  await Promise.all([
    writeFile(join(runDir, "review_bundle.json"), "{}\n", "utf8"),
    writeFile(join(runDir, "evidence_result.json"), "{}\n", "utf8"),
    writeFile(join(runDir, "canonical_text.md"), "# Canonical\n", "utf8"),
    writeFile(join(runDir, "review.html"), "<html></html>\n", "utf8")
  ]);
}

test("validateAiReviewPayload accepts negative reviewer verdicts when the artifact is schema-valid", async () => {
  const runDir = await createRunDir("missless-ai-review-negative");
  await writeRequiredArtifacts(runDir);

  assert.doesNotThrow(
    () =>
      validateAiReviewPayload(
        {
          ok: false,
          summary: "The run failed contract checks.",
          findings: ["missing evidence"],
          reviewer_backend: "codex",
          reviewed_artifacts: [
            "review_bundle.json",
            "evidence_result.json",
            "canonical_text.md",
            "review.html"
          ]
        },
        runDir
      )
  );
});

test("validateAiReviewPayload requires concrete required run artifacts", async () => {
  const runDir = await createRunDir("missless-ai-review-artifacts");
  await writeFile(join(runDir, "review_bundle.json"), "{}\n", "utf8");

  assert.throws(
    () =>
      validateAiReviewPayload(
        {
          ok: true,
          summary: "Looks fine.",
          findings: [],
          reviewer_backend: "codex",
          reviewed_artifacts: [
            "review_bundle.json",
            "evidence_result.json",
            "canonical_text.md",
            "review.html"
          ]
        },
        runDir
      ),
    /missing/
  );
});

test("validateAiReviewPayload accepts successful reviews with required artifacts", async () => {
  const runDir = await createRunDir("missless-ai-review-success");
  await writeRequiredArtifacts(runDir);

  assert.doesNotThrow(() =>
    validateAiReviewPayload(
      {
        ok: true,
        summary: "The review package satisfies the first-slice contract.",
        findings: [],
        reviewer_backend: "codex",
          reviewed_artifacts: [
            "review_bundle.json",
            "evidence_result.json",
            "canonical_text.md",
            "review.html"
          ]
        },
      runDir
    )
  );
});
