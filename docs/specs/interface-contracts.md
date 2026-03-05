# Interface Contracts

Status: Active

## Purpose

Define interface-level contracts (CLI, skills, and future app surfaces) without making any one interface the product center.

## Common Interface Requirements

Any interface that triggers ingestion/review/commit must:
- return or expose stable identifiers needed for follow-up actions
- preserve review-before-commit semantics
- preserve run artifact replayability
- preserve auditability fields required by specs

## CLI Adapter Contract

### `missless ingest <locator> [--ext <extension>] [--dry-run]`

Should print:
- `run_id` (required when `--dry-run` is not set)
- source summary
- TL;DR (`L0`, `L1`)
- rating + breakdown
- proposed atoms/artifacts with evidence pointers
- proposed merges/edges

Should not execute commit/persistence automatically.

`--dry-run` semantics:
- executes fetch/normalize/extract/anchor/align/propose only
- does not create persistent run records
- does not persist events, nodes, or edges
- omits `run_id` and marks output as dry-run

### `missless review <run_id>`

Interactive review actions:
- accept/reject selected items
- edit fields
- override alignment decisions

### `missless commit <run_id>`

Executes `commit_plan`.

### `missless show atom <atom_id>`

Prints atom text and top evidence anchors.

### `missless show artifact <artifact_id>`

Prints artifact fields and linked atoms.

### `missless open evidence <evidence_ref>`

Prints locator/snippet/navigation context for original source.

### `missless open segment <segment_id>` (Optional Alias)

Supported when segment nodes are materialized and `segment_id` is a valid evidence reference.

## Skill/Web/Mobile Adapters

Detailed contracts are stage-dependent and should be introduced under this file as adapters mature.
