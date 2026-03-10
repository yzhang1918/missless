#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const REQUIRED_REVIEW_ARTIFACTS = [
  "review_bundle.json",
  "evidence_result.json",
  "canonical_text.md",
  "review.html"
];

export function validateAiReviewPayload(payload, runDir) {
  if (typeof payload !== "object" || payload === null) {
    throw new Error("AI review must be a JSON object");
  }

  if (typeof payload.ok !== "boolean") {
    throw new Error("AI review must include boolean ok");
  }

  if (typeof payload.summary !== "string" || payload.summary.length === 0) {
    throw new Error("AI review must include non-empty summary");
  }

  if (!Array.isArray(payload.findings)) {
    throw new Error("AI review must include findings[]");
  }

  if (
    typeof payload.reviewer_backend !== "string" ||
    payload.reviewer_backend.length === 0
  ) {
    throw new Error("AI review must include non-empty reviewer_backend");
  }

  if (!Array.isArray(payload.reviewed_artifacts)) {
    throw new Error("AI review must include reviewed_artifacts[]");
  }

  if (
    payload.reviewed_artifacts.some(
      (artifact) => typeof artifact !== "string" || artifact.length === 0
    )
  ) {
    throw new Error("AI review reviewed_artifacts entries must be non-empty strings");
  }

  const reviewedArtifacts = new Set(payload.reviewed_artifacts);

  for (const artifactName of REQUIRED_REVIEW_ARTIFACTS) {
    if (!reviewedArtifacts.has(artifactName)) {
      throw new Error(
        `AI review must explicitly review required artifact: ${artifactName}`
      );
    }

    if (!fs.existsSync(path.join(runDir, artifactName))) {
      throw new Error(
        `Required run artifact is missing for AI review validation: ${artifactName}`
      );
    }
  }
}

export function validateAiReviewFile(filePath, runDir) {
  const payload = JSON.parse(fs.readFileSync(filePath, "utf8"));
  validateAiReviewPayload(payload, runDir);
  return payload;
}

export function readAiReviewVerdict(filePath) {
  const payload = JSON.parse(fs.readFileSync(filePath, "utf8"));

  if (typeof payload !== "object" || payload === null || typeof payload.ok !== "boolean") {
    throw new Error("AI review verdict requires a boolean ok field");
  }

  return payload.ok;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [filePath, runDir] = process.argv.slice(2);

  if (filePath === undefined || runDir === undefined) {
    console.error("Usage: validate_ai_review.mjs <ai-review-file> <run-dir>");
    process.exit(64);
  }

  try {
    validateAiReviewFile(filePath, runDir);
  } catch (error) {
    console.error(
      error instanceof Error ? error.message : "AI review validation failed"
    );
    process.exit(1);
  }
}
