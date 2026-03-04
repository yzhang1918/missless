# CLI Contract (POC)

Status: Active

## Commands

### `missless ingest <locator> [--ext <extension>] [--dry-run]`

Should print:
- `run_id` (required when `--dry-run` is not set)
- source summary
- TL;DR (`L0`, `L1`)
- rating + breakdown
- proposed atoms/artifacts with evidence pointers
- proposed merges/edges

Should create an `ingest_run` record.
Should not execute commit/persistence automatically.

`--dry-run` semantics:
- executes fetch/parse/extract/align/propose only
- does not create an `ingest_run` record
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

Prints atom text and top evidence segments with locators.

### `missless show artifact <artifact_id>`

Prints artifact fields and linked atoms.

### `missless open segment <segment_id>`

Prints locator, snippet, and navigation context to original source.
