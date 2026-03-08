export const FIRST_SLICE_RUNTIME_BOUNDARY = {
  extractor: "codex",
  deterministicStages: [
    "fetch",
    "normalize",
    "validate_draft",
    "anchor_evidence",
    "render_review"
  ]
} as const;

export {
  buildJinaReaderUrl,
  createJinaReaderProvider,
  normalizeReaderOutput
} from "./providers/jina.js";
export type {
  CreateJinaReaderProviderOptions,
  FetchLike
} from "./providers/jina.js";
export type { ProviderFetchResult, SourceProvider } from "./providers/provider.js";
export {
  createRunId,
  fetchNormalizeSource
} from "./source/fetch-normalize.js";
export type {
  FetchNormalizeInput,
  FetchNormalizeResult,
  RunManifest,
  SourceArtifact
} from "./source/fetch-normalize.js";
export { anchorEvidenceInRunDir } from "./evidence/anchor-evidence.js";
export { buildReviewBundleInRunDir } from "./review/build-review-bundle.js";
export { validateDraftInRunDir } from "./diagnostics/validate-draft.js";
export type {
  DraftValidationResult,
  ValidationDiagnostic
} from "./diagnostics/validate-draft.js";
