# Run Artifacts JSON Contracts

Status: Active

## Required Run Files

Each ingest run must support machine-readable outputs:
- `extraction_output.json`
- `alignment_result.json`
- `commit_plan.json`

Artifacts must be self-contained per run for replay/debugging.

## `extraction_output.json` Skeleton

- `source_id`
- `extension_id`
- `tldr_l0`
- `tldr_l1`
- `atoms[]`
  - `temp_id`, `text`, `type`, optional `scope_text`, optional `confidence`
- `artifacts[]`
  - `temp_id`, `subtype`, `name`, `l0_abstract`, optional `l1_overview`, `payload`, `schema_version`
- `edges.segment_states[]`
  - `segment_id`, `atom_temp_id`, `polarity`, `strength`
- `edges.source_artifacts[]`
  - `source_id`, `artifact_temp_id`, `relation_type`, `key_segments[]`
- `edges.artifact_atoms[]`
  - `artifact_temp_id`, `atom_temp_id`, `relation_type`, `strength`, `segments[]`
- optional `edges.intra_atoms[]`

## `alignment_result.json` Skeleton

- Decision vocabulary:
  - `atoms[].decision`: `new|duplicate_of|equivalent_to|qualifies|entails|contradicts|extends`
  - `artifacts[].decision`: `new|duplicate_of|equivalent_to|variant_of|improves|uses|compares_to`

- Decision target requirement:
  - If `decision == new`, target id is omitted.
  - If `decision != new`, a target id is required.
    - atoms: require `target_atom_id`
    - artifacts: require `target_artifact_id`

- Candidate score audit requirement:
  - Candidate scores are required for all decisions.
  - `candidate_scores[]` may be empty only when retrieval returned no candidates.

- Relation edge requirement:
  - If `atoms[].decision` is `qualifies|entails|contradicts|extends`, include:
    - `relation_type` (must equal decision)
    - `relation_strength` (`0..1`)
  - If `artifacts[].decision` is `variant_of|improves|uses|compares_to`, include:
    - `relation_type` (must equal decision)
    - `relation_strength` (`0..1`)

- `source_id`
- `atoms[]`
  - `temp_id`, `decision`, `target_atom_id` (required when `decision != new`), optional `relation_type`, optional `relation_strength`, `confidence`, `rationale`
  - `candidate_scores[]` (required)
    - `candidate_atom_id`, `score_final`, optional `score_lexical`, optional `score_embedding`, optional `score_nli`
- `artifacts[]`
  - `temp_id`, `decision`, `target_artifact_id` (required when `decision != new`), optional `relation_type`, optional `relation_strength`, `confidence`, `rationale`
  - `candidate_scores[]` (required)
    - `candidate_artifact_id`, `score_final`, optional `score_lexical`, optional `score_embedding`, optional `score_nli`
- `new_edges.atom_atom_edges[]`
  - references to atom ids/temp ids, `relation_type`, `strength`, optional `rationale`
- optional `new_edges.source_atom_edges[]`
  - `source_id`, `atom_id_or_temp`, `strength_agg`, optional `top_segments[]`
- optional `new_edges.source_source_edges[]`
  - `from_source_id`, `to_source_id`, `relation_type` (`duplicates|rewrites|quotes`), `strength`, optional `rationale`

## `commit_plan.json` Expectation

At minimum, include:
- node upserts
- edge upserts
- resolved references from temp ids to persisted ids
- summary counts and validation checks
