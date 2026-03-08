import { readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import {
  getRunArtifactPaths
} from "@missless/contracts";
import type { ExtractionDraft } from "@missless/contracts";

import type {
  AnchoredAtom,
  EvidenceAnchoringResult
} from "../evidence/anchor-evidence.js";

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

export async function buildReviewBundleInRunDir(
  runDir: string,
  now = new Date()
): Promise<ReviewBundle> {
  const resolvedRunDir = resolve(runDir);
  const artifactPaths = getRunArtifactPaths(resolvedRunDir);
  const [canonicalText, draftText, evidenceText] = await Promise.all([
    readFile(artifactPaths.canonicalText, "utf8"),
    readFile(artifactPaths.extractionDraft, "utf8"),
    readFile(artifactPaths.evidenceResult, "utf8")
  ]);
  const draft = JSON.parse(draftText) as ExtractionDraft;
  const evidenceResult = JSON.parse(evidenceText) as EvidenceAnchoringResult;

  if (!evidenceResult.ok) {
    throw new Error(
      "Cannot render review until anchor-evidence succeeds for the run."
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
