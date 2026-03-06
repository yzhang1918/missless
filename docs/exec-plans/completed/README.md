# Completed Execution Plans

Status: Active

## Purpose

Store completed plans as durable execution history.

## Rules

Each completed plan should include:
- delivered scope
- validation summary
- open follow-up/debt IDs (if any)
- mapping to tracker IDs in `../tracker.md`
- when the catalog changes, a validation check that every completed plan file in this folder is listed below

Recommended catalog sync check:

```sh
find docs/exec-plans/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \; \
  | while read -r file; do
      rg -q "$file" docs/exec-plans/completed/README.md || echo "missing:$file"
    done
```

## Catalog

| Plan | Date | Summary |
| --- | --- | --- |
| [`2026-03-06-evidence-contract-first-slice.md`](./2026-03-06-evidence-contract-first-slice.md) | 2026-03-06 | Locked the text-source `Segment` evidence contract and defined the first delivery slice plus acceptance bar. |

Harness/process plan history is stored separately under `docs/harness/completed/`.
