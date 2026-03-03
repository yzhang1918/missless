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

- Decision target requirement:
  - If `decision == new`, target id is omitted.
  - If `decision != new`, a target id is required.
    - atoms: require `target_atom_id`
    - artifacts: require `target_artifact_id`

- `source_id`
- `atoms[]`
  - `temp_id`, `decision`, `target_atom_id` (required when `decision != new`), optional `relation_type`, `confidence`, optional `rationale`
- `artifacts[]`
  - `temp_id`, `decision`, `target_artifact_id` (required when `decision != new`), `confidence`, optional `rationale`
- `new_edges.atom_atom_edges[]`
  - references to atom ids/temp ids, `relation_type`, `strength`, optional `rationale`
- optional `new_edges.source_atom_edges[]`
- optional `new_edges.source_source_edges[]`

## `commit_plan.json` Expectation

At minimum, include:
- node upserts
- edge upserts
- resolved references from temp ids to persisted ids
- summary counts and validation checks
