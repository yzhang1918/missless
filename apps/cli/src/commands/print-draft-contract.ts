import { DECISION_LABELS, RUN_ARTIFACT_FILES } from "@missless/contracts";

const DRAFT_CONTRACT = {
  slice: "single-run URL -> review package",
  run_handle: "run_dir",
  draft_file: RUN_ARTIFACT_FILES.extractionDraft,
  canonical_text_file: RUN_ARTIFACT_FILES.canonicalText,
  schema_path: "extraction-draft.schema.json",
  required_fields: [
    "tldr",
    "decision",
    "decision_reasons",
    "atom_candidates"
  ],
  optional_fields: ["self_check"],
  required_atom_fields: ["claim", "significance", "evidence_selectors"],
  evidence_selector_fields: ["exact", "prefix", "suffix"],
  decision_labels: DECISION_LABELS,
  derived_artifacts: [
    RUN_ARTIFACT_FILES.evidenceResult,
    RUN_ARTIFACT_FILES.reviewBundle,
    RUN_ARTIFACT_FILES.reviewHtml
  ],
  repair_loop: [
    "Write extraction_draft.json",
    "Run validate-draft --run-dir <dir> [--json]",
    "Repair extraction_draft.json when diagnostics fail",
    "Run anchor-evidence --run-dir <dir> [--json]",
    "Run render-review --run-dir <dir>"
  ]
} as const;

export async function runPrintDraftContractCommand(
  args: readonly string[]
): Promise<number> {
  if (args.length > 0) {
    throw new Error("print-draft-contract does not accept arguments");
  }

  console.log(JSON.stringify(DRAFT_CONTRACT, null, 2));

  return 0;
}
