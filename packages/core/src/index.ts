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
