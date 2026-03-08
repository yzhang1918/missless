import { join } from "node:path";

export const RUN_ARTIFACT_FILES = {
  runManifest: "run.json",
  source: "source.json",
  canonicalText: "canonical_text.md",
  extractionDraft: "extraction_draft.json",
  evidenceResult: "evidence_result.json",
  reviewBundle: "review_bundle.json",
  reviewHtml: "review.html"
} as const;

export interface RunArtifactPaths {
  readonly runDir: string;
  readonly runManifest: string;
  readonly source: string;
  readonly canonicalText: string;
  readonly extractionDraft: string;
  readonly evidenceResult: string;
  readonly reviewBundle: string;
  readonly reviewHtml: string;
}

export function getRunArtifactPaths(runDir: string): RunArtifactPaths {
  return {
    runDir,
    runManifest: join(runDir, RUN_ARTIFACT_FILES.runManifest),
    source: join(runDir, RUN_ARTIFACT_FILES.source),
    canonicalText: join(runDir, RUN_ARTIFACT_FILES.canonicalText),
    extractionDraft: join(runDir, RUN_ARTIFACT_FILES.extractionDraft),
    evidenceResult: join(runDir, RUN_ARTIFACT_FILES.evidenceResult),
    reviewBundle: join(runDir, RUN_ARTIFACT_FILES.reviewBundle),
    reviewHtml: join(runDir, RUN_ARTIFACT_FILES.reviewHtml)
  };
}
