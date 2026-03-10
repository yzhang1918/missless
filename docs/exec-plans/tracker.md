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

## Queue

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |

## Follow-ups

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| FUP-0003 | Package missless as an installable skill plus stable runtime entrypoint | P2 | todo | Human+Codex | `README.md`, `skills/missless/SKILL.md`, `apps/cli/package.json`, `docs/exec-plans/completed/2026-03-09-first-review-package-product-facing-v0.md` | The current slice is repository-coupled. Future work should let users install `missless` into an agent environment and invoke a stable runtime command without depending on this repo layout. |
| FUP-0004 | Add provider fallback strategy beyond the default Jina reader | P2 | todo | Human+Codex | `packages/core/src/providers/`, `packages/core/src/source/fetch-normalize.ts`, `docs/design-docs/system-design.md`, `docs/specs/pipeline-contracts.md` | Keep localhost/private rejection as runtime policy, but define which provider failures should stay fail-closed and which should trigger fallback to a second fetch provider. |
| FUP-0005 | Finish provider-boundary SSRF policy beyond initial resolved-host checks | P1 | todo | Human+Codex | `packages/core/src/source/fetch-normalize.ts`, `packages/core/src/providers/`, `docs/design-docs/system-design.md`, `docs/specs/pipeline-contracts.md` | Initial resolved-host rejection now runs before provider fetch, but the repo still needs a provider contract for redirect hops and final fetch destinations so remote readers can fail closed on private, loopback, or link-local redirects instead of only checking the original URL hostname. |

## Technical Debt

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| DEBT-0001 | Re-evaluate document split policy after first delivery slice | P3 | todo | Human+Codex | `docs/product-specs/index.md` | Avoid premature fragmentation. |

## Completed

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| FUP-0006 | Harden render-review cleanup trust model | P2 | done | Human+Codex | `packages/core/src/runtime/run-registry.ts`, `packages/core/src/runtime/cleanup-token.ts`, `packages/core/src/review/build-review-bundle.ts`, `packages/core/src/source/fetch-normalize.ts`, `tests/integration/cli/review-package.test.ts`, `tests/unit/core/fetch-normalize.test.ts`, `docs/design-docs/system-design.md`, `docs/specs/pipeline-contracts.md` | Completed: stale rendered-output cleanup now relies on runtime-owned cleanup state under missless runtime state, including a runs-root registry plus per-run attestation, and may also fall back to a valid signed run-local cleanup token; registry corruption now degrades to those trusted fallbacks instead of bubbling raw parse errors, and regression tests cover trusted cleanup, untrusted refusal, and isolated trust-source branches. |
| TASK-0003 | Deliver the first review-package slice as product-facing `missless v0` | P1 | done | Human+Codex | `docs/exec-plans/completed/2026-03-09-first-review-package-product-facing-v0.md`, PR `#8`, `.local/e2e/20260309T150137Z/runs/run-20260309T150138Z-a5c6ed21/ai_review.json`, `.local/loop/review-20260309-150816.json`, `.local/loop/final-gate-20260309-151010.json` | Completed: the branch delivered the first real slice, unified the product entrypoint under `missless`, added repository-native AI-reviewed E2E, absorbed late review-driven hardening into the same task, and archived it as one completed plan. |
| TASK-0002 | Define the first implementation slice and acceptance bar | P1 | done | Human+Codex | `docs/product-specs/product-foundation.md`, `docs/specs/pipeline-contracts.md`, `docs/design-docs/system-design.md`, `docs/exec-plans/completed/2026-03-06-evidence-contract-first-slice.md` | Completed: first delivery slice is defined as text-first, review-first, and `Atom`-only for persistence, with deferred artifact and alignment expansion. |
| TASK-0001 | Decide evidence anchor representation profile | P1 | done | Human+Codex | `docs/design-docs/system-design.md`, `docs/specs/core-data-model.md`, `docs/specs/pipeline-contracts.md`, `docs/exec-plans/completed/2026-03-06-evidence-contract-first-slice.md` | Completed: the current first slice uses runtime-validated anchored evidence records in run artifacts, while reusable `Segment` identities remain a deferred persistence-layer design choice. |
