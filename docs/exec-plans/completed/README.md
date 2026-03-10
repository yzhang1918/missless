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
| [`2026-03-06-evidence-contract-first-slice.md`](./2026-03-06-evidence-contract-first-slice.md) | 2026-03-06 | Locked a pre-implementation `Segment`-oriented evidence plan and the first delivery slice acceptance bar; later implementation history superseded the shipped first-slice contract with anchored evidence run artifacts. |
| [`2026-03-09-first-review-package-product-facing-v0.md`](./2026-03-09-first-review-package-product-facing-v0.md) | 2026-03-09 | Delivered the first URL-to-review-package slice and archived the whole branch as one unified TASK-0003 record. |

Harness/process plan history is stored separately under `docs/harness/completed/`.
