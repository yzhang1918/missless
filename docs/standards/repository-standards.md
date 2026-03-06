# Repository Standards

Status: Active

## Purpose

Define detailed operational standards for documentation, status semantics, review flow, and skill alignment.

## Authority

- `AGENTS.md` is the primary collaboration contract.
- This file provides detailed enforcement-level conventions.
- If a skill conflicts with `AGENTS.md` or this file, update the skill.

## Documentation Standards

- Write all docs in English.
- Keep docs concrete and concise.
- Keep each folder `index.md` updated when docs change.
- Avoid duplicating the same policy text across many files.

## Placement Standards

- Product intent/workflow -> `docs/product-specs/`
- Design rationale/tradeoffs -> `docs/design-docs/`
- Technical contracts -> `docs/specs/`
- Product tactical execution/progress tracking -> `docs/exec-plans/`
- Harness/process workflow tracking -> `docs/harness/`
- External distillations and terms -> `docs/references/`

## Status Standards

Use these statuses for docs:
- `Draft`: under discussion, not yet stable
- `Active`: current approved source of truth
- `Superseded`: replaced by a newer document

Clarification:
- Do not use `Completed` as a product/spec status.
- Completion is tracked in execution trackers and plan archives (`docs/exec-plans/*` for product, `docs/harness/*` for harness/process).

## Review and Merge Standards

For non-trivial work:
- run step-level delta review during execution
- run full review before final merge
- resolve blocking/important findings before final gate
- track unresolved follow-ups or debt in the appropriate tracker:
  - product scope -> `docs/exec-plans/tracker.md`
  - harness/process scope -> `docs/harness/tracker.md`

## Skills Alignment Standards

- Skills under `.agents/skills/` are operational playbooks.
- Standards remain normative.
- Skills should be self-contained when practical: scripts used by a skill should live under that skill folder.
- When standards change, update affected skills in the same branch.
