# Repository Standards

Status: Active

## Purpose

Define the repository-specific standards that still belong in `missless`
after adopting `easyharness`: documentation placement, status semantics, and
documentation sync expectations for product work.

## Authority

- `AGENTS.md` is the primary collaboration contract.
- The `easyharness`-managed workflow block in `AGENTS.md` owns generic harness
  process behavior.
- This file provides the `missless`-specific conventions that the generic
  harness contract should not duplicate.

## Documentation Standards

- Write all docs in English.
- Keep docs concrete and concise.
- Keep each folder `index.md` updated when docs change.
- Avoid duplicating the same policy text across many files.

## Placement Standards

- Product intent/workflow -> `docs/product-specs/`
- Design rationale/tradeoffs -> `docs/design-docs/`
- Technical contracts -> `docs/specs/`
- Tracked plans and archived execution history -> `docs/plans/`
- External distillations and terms -> `docs/references/`
- Repository structure map -> `ARCHITECTURE.md`

## Status Standards

Use these statuses for docs:
- `Draft`: under discussion, not yet stable
- `Active`: current approved source of truth
- `Superseded`: replaced by a newer document

Clarification:
- Do not use `Completed` as a product/spec status.
- Completion is tracked in `docs/plans/` under the active or archived layout
  that `easyharness` manages for this repository.

## Documentation Sync Standards

- If a change alters product goals, user workflow, or feature positioning,
  update the affected file under `docs/product-specs/` in the same branch.
- If a change alters technical behavior, stable interfaces, data contracts, or
  CLI semantics, update the affected file under `docs/specs/` in the same
  branch.
- If a change adds, removes, or reverses an important tradeoff, update
  `docs/design-docs/` in the same branch.
- If a change alters repository layout or document ownership boundaries, update
  `ARCHITECTURE.md` in the same branch.
- If a folder's entrypoint changes, update the relevant `index.md` or archive
  catalog in the same branch.

## Skills Alignment Standards

- Skills under `.agents/skills/` are operational playbooks.
- The `easyharness`-managed `harness-*` skills own the generic workflow
  contract for planning and execution.
- Repository docs remain the source of truth for `missless`-specific product
  context even when skills describe a generic workflow.
- Do not reintroduce a parallel local copy of the generic harness workflow
  rules that `easyharness` already manages.
