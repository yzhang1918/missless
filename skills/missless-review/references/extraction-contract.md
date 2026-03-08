# Extraction Contract

The extraction agent owns exactly one file: `extraction_draft.json`.

## Output Rules

- Output one JSON object only.
- The JSON must satisfy
  `packages/contracts/extraction-draft.schema.json`.
- Do not wrap the JSON in Markdown fences.
- Rewrite the whole draft on repair; do not edit runtime-derived artifacts.

## Required Fields

- `tldr`
  - 1-2 sentences
  - explain what the source is about and why it matters
- `decision`
  - one of `deep_read`, `skim`, `skip`
  - this is a knowledge-base-agnostic reading-investment decision
- `decision_reasons`
  - concise human-readable reasons
- `atom_candidates`
  - ordered by importance
  - each item must be a claim-first sentence, not a section heading
  - avoid near-duplicate atoms
- `evidence_selectors`
  - use `exact` plus at least one of `prefix` or `suffix`
  - copy selector text from the canonical text rather than paraphrasing it
- `self_check`
  - optional
  - keep it short
  - use only `corrected[]` and/or `uncertain[]`

## Repair Loop

When `validate-draft` fails:
- rerun with `--json`
- inspect the diagnostics
- rewrite `extraction_draft.json`
- rerun `validate-draft`

When `anchor-evidence` fails:
- rerun with `--json`
- repair the selector text in `extraction_draft.json`
- rerun `validate-draft`
- rerun `anchor-evidence`

## Extraction Heuristics

- Prefer fewer, stronger atoms over exhaustive fragmentation.
- Use as many atoms as the source needs, but do not split one idea into several
  weakly different claims.
- Prefer selectors that are specific enough to survive repeated phrases.
- If the source is borderline between `skim` and `deep_read`, explain that in
  `decision_reasons` or `self_check` rather than inventing a new label.
