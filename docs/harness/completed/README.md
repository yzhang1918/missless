# Completed Harness Plans

Status: Active

## Purpose

Store completed harness/workflow plans as durable execution history.

## Rules

Each completed plan should include:
- delivered scope
- validation summary
- open follow-up/debt IDs (if any)
- mapping to tracker IDs in `../tracker.md`
- when the catalog changes, a validation check that every completed plan file in this folder is listed below

Recommended catalog sync check:

```sh
find docs/harness/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \; \
  | while read -r file; do
      rg -q "$file" docs/harness/completed/README.md || echo "missing:$file"
    done
```

## Catalog

| Plan | Date | Summary |
| --- | --- | --- |
| [`2026-03-05-skill-flow-calibration.md`](./2026-03-05-skill-flow-calibration.md) | 2026-03-05 | Calibrated task intake, discovery behavior, and plan handoff rules. |
| [`2026-03-06-discovery-option-framing.md`](./2026-03-06-discovery-option-framing.md) | 2026-03-06 | Refined discovery option framing to support concise 2-4 options with brief tradeoffs. |
| [`2026-03-09-post-first-slice-loop-remediation.md`](./2026-03-09-post-first-slice-loop-remediation.md) | 2026-03-09 | Captured the harness/process gaps exposed by the first product slice and separated delivered workflow clarifications from deferred harness follow-ups. |
