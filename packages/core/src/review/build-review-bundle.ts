import { createHash } from "node:crypto";
import { readFile, rm, stat, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import {
  getRunArtifactPaths
} from "@missless/contracts";
import type { ExtractionDraft } from "@missless/contracts";

import type {
  AnchoredAtom,
  EvidenceAnchoringResult
} from "../evidence/anchor-evidence.js";
import { hasValidCleanupToken } from "../runtime/cleanup-token.js";
import { isRegisteredRunDir } from "../runtime/run-registry.js";

export interface ReviewBundle {
  readonly generated_at: string;
  readonly run_dir: string;
  readonly tldr: string;
  readonly decision: ExtractionDraft["decision"];
  readonly decision_reasons: readonly string[];
  readonly atoms: readonly AnchoredAtom[];
  readonly canonical_text: string;
}

function writeJsonFile(path: string, value: unknown): Promise<void> {
  return writeFile(path, JSON.stringify(value, null, 2) + "\n", "utf8");
}

function sha256(input: string): string {
  return createHash("sha256").update(input, "utf8").digest("hex");
}

function isTrustedRunManifest(value: unknown): boolean {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const record = value as Record<string, unknown>;

  return (
    typeof record.run_id === "string" &&
    typeof record.stage === "string" &&
    record.stage === "normalized"
  );
}

async function cleanupReviewArtifacts(
  reviewBundlePath: string,
  reviewHtmlPath: string
): Promise<void> {
  await Promise.all([
    rm(reviewBundlePath, { force: true }),
    rm(reviewHtmlPath, { force: true })
  ]);
}

async function statOrError(
  path: string
): Promise<Awaited<ReturnType<typeof stat>> | Error> {
  try {
    return await stat(path);
  } catch (error) {
    return error instanceof Error ? error : new Error(String(error));
  }
}

async function canCleanupReviewArtifacts(
  artifactPaths: ReturnType<typeof getRunArtifactPaths>
): Promise<boolean> {
  try {
    const [
      runDirStat,
      reviewBundleStat,
      reviewHtmlStat,
      registeredRunDir,
      validCleanupToken
    ] =
      await Promise.all([
        stat(artifactPaths.runDir),
        statOrError(artifactPaths.reviewBundle),
        statOrError(artifactPaths.reviewHtml),
        isRegisteredRunDir(artifactPaths.runDir),
        hasValidCleanupToken(artifactPaths.runDir)
      ]);
    const isExistingFile = (
      value: Awaited<ReturnType<typeof stat>> | Error
    ): boolean => !(value instanceof Error) && value.isFile();

    const hasRenderedOutputs =
      isExistingFile(reviewBundleStat) || isExistingFile(reviewHtmlStat);

    if (
      !runDirStat.isDirectory() ||
      !hasRenderedOutputs ||
      (!registeredRunDir && !validCleanupToken)
    ) {
      return false;
    }

    return true;
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      (error.code === "ENOENT" || error.code === "ENOTDIR")
    ) {
      return false;
    }

    throw error;
  }
}

async function failClosedRenderReview(
  artifactPaths: ReturnType<typeof getRunArtifactPaths>,
  message: string
): Promise<never> {
  if (await canCleanupReviewArtifacts(artifactPaths)) {
    await cleanupReviewArtifacts(
      artifactPaths.reviewBundle,
      artifactPaths.reviewHtml
    );
  }

  throw new Error(message);
}

export async function buildReviewBundleInRunDir(
  runDir: string,
  now = new Date()
): Promise<ReviewBundle> {
  const resolvedRunDir = resolve(runDir);
  const artifactPaths = getRunArtifactPaths(resolvedRunDir);
  let runManifestText: string;

  try {
    runManifestText = await readFile(artifactPaths.runManifest, "utf8");
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      (error.code === "ENOENT" || error.code === "ENOTDIR")
    ) {
      return failClosedRenderReview(
        artifactPaths,
        "render-review requires a valid missless run.json before it can rebuild review artifacts."
      );
    }

    throw error;
  }

  let runManifest: unknown;

  try {
    runManifest = JSON.parse(runManifestText) as unknown;
  } catch {
    return failClosedRenderReview(
      artifactPaths,
      "render-review requires a valid missless run.json before it can rebuild review artifacts."
    );
  }

  if (!isTrustedRunManifest(runManifest)) {
    return failClosedRenderReview(
      artifactPaths,
      "render-review requires a valid missless run.json before it can rebuild review artifacts."
    );
  }

  let canonicalText: string;

  try {
    canonicalText = await readFile(artifactPaths.canonicalText, "utf8");
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      (error.code === "ENOENT" || error.code === "ENOTDIR")
    ) {
      return failClosedRenderReview(
        artifactPaths,
        "Cannot render review until canonical_text.md exists for the run."
      );
    }

    throw error;
  }

  let draftText: string;

  try {
    draftText = await readFile(artifactPaths.extractionDraft, "utf8");
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      (error.code === "ENOENT" || error.code === "ENOTDIR")
    ) {
      return failClosedRenderReview(
        artifactPaths,
        "Cannot render review until extraction_draft.json exists for the run."
      );
    }

    throw error;
  }

  let draft: ExtractionDraft;

  try {
    draft = JSON.parse(draftText) as ExtractionDraft;
  } catch {
    return failClosedRenderReview(
      artifactPaths,
      "Cannot render review until extraction_draft.json is valid for the run."
    );
  }

  let evidenceText: string;

  try {
    evidenceText = await readFile(artifactPaths.evidenceResult, "utf8");
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      (error.code === "ENOENT" || error.code === "ENOTDIR")
    ) {
      return failClosedRenderReview(
        artifactPaths,
        "Cannot render review until anchor-evidence succeeds for the run."
      );
    }

    throw error;
  }

  let evidenceResult: EvidenceAnchoringResult;

  try {
    evidenceResult = JSON.parse(evidenceText) as EvidenceAnchoringResult;
  } catch {
    return failClosedRenderReview(
      artifactPaths,
      "Cannot render review until a valid evidence_result.json exists for the run."
    );
  }

  if (!evidenceResult.ok) {
    return failClosedRenderReview(
      artifactPaths,
      "Cannot render review until anchor-evidence succeeds for the run."
    );
  }

  if (
    evidenceResult.draft_sha256 !== sha256(draftText) ||
    evidenceResult.canonical_text_sha256 !== sha256(canonicalText)
  ) {
    return failClosedRenderReview(
      artifactPaths,
      "Cannot render review until anchor-evidence is rerun for the current extraction draft and canonical text."
    );
  }

  const reviewBundle: ReviewBundle = {
    generated_at: now.toISOString(),
    run_dir: resolvedRunDir,
    tldr: draft.tldr,
    decision: draft.decision,
    decision_reasons: [...draft.decision_reasons],
    atoms: evidenceResult.atoms,
    canonical_text: canonicalText
  };

  await writeJsonFile(artifactPaths.reviewBundle, reviewBundle);

  return reviewBundle;
}
