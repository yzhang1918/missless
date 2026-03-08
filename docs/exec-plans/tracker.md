# Execution Tracker

Status: Active

## Purpose

Single product-delivery tracker for priorities, follow-ups, and debt.

## How to Use

- Start each session from this file.
- Keep this file product-focused. Harness/process work is tracked in `docs/harness/tracker.md`.
- Keep each item in exactly one section.
- For non-trivial work, link to a plan in `active/` or `completed/`.
- Keep non-done work near the top and `done` work in the tail `Completed` section for quick `head`/`tail` reads.

## Schema

- `ID`: `TASK-xxxx`, `FUP-xxxx`, `DEBT-xxxx`
- `Priority`: `P0|P1|P2|P3`
- `Status`: `todo|ready|in_progress|blocked|done`
- `Owner`: `Human`, `Codex`, or `Human+Codex`
- `Links`: related docs/plans/commits

## Current Focus

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TASK-0003 | Implement the first URL-to-review-package slice | P1 | ready | Human+Codex | `docs/exec-plans/active/2026-03-08-first-review-package-slice.md`, PR `#8` | All four implementation steps are complete locally, the review-driven security/test follow-up fixes are in, delta review round `20260308-170151` is clear, and final gate passed. Knowledge-aware personalized decisions remain the key differentiator but are deferred from this slice. |

## Queue

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |

## Follow-ups

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| FUP-0001 | Investigate `codex exec` hangs when structured-output runs read local files before final JSON emission | P2 | todo | Codex | `docs/exec-plans/active/2026-03-08-first-review-package-slice.md` | Manual E2E succeeded with the same canonical text inlined into the prompt plus `packages/contracts/extraction-draft.codex-output-schema.json`, but direct local-file-read prompts stalled after context gathering. |

## Technical Debt

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| DEBT-0001 | Re-evaluate document split policy after first delivery slice | P3 | todo | Human+Codex | `docs/product-specs/index.md` | Avoid premature fragmentation. |

## Completed

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TASK-0002 | Define the first implementation slice and acceptance bar | P1 | done | Human+Codex | `docs/product-specs/product-foundation.md`, `docs/specs/pipeline-contracts.md`, `docs/design-docs/system-design.md`, `docs/exec-plans/completed/2026-03-06-evidence-contract-first-slice.md` | Completed: first delivery slice is defined as text-first, review-first, and `Atom`-only for persistence, with deferred artifact and alignment expansion. |
| TASK-0001 | Decide evidence anchor representation profile | P1 | done | Human+Codex | `docs/design-docs/system-design.md`, `docs/specs/core-data-model.md`, `docs/specs/pipeline-contracts.md`, `docs/exec-plans/completed/2026-03-06-evidence-contract-first-slice.md` | Completed: text-source evidence now uses runtime-materialized `Segment` objects with validated locators and internal evidence review. |
