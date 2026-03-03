# CLI Contract (POC)

Status: Active

## Commands

### `missless ingest <locator> [--ext <extension>] [--dry-run]`

Should print:
- source summary
- TL;DR (`L0`, `L1`)
- rating + breakdown
- proposed atoms/artifacts with evidence pointers
- proposed merges/edges

Should create an `ingest_run` record.

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
