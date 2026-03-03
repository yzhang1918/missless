# Document Placement Matrix

Status: Active

## Purpose

Provide a deterministic way to place new documents in the right repository area.

## Decision Matrix

| Question | If yes, place in | Why |
| --- | --- | --- |
| Does it define product scope, goals, non-goals, or acceptance criteria? | `docs/product-specs/` | Product intent and scope belong to product specs. |
| Does it define machine-facing contracts used by implementation (schema, API, CLI contract, run artifact format)? | `docs/specs/` | Implementation contracts must be stable and explicit. |
| Does it explain why the system is designed this way, including tradeoffs and rationale? | `docs/design-docs/` | Design rationale should be separated from executable contracts. |
| Does it define governance, process, review policy, or quality rules? | `docs/standards/` | Standards govern how work is performed and reviewed. |
| Does it track active delivery work, milestones, or debt items? | `docs/exec-plans/` | Execution plans are tactical and time-bound. |
| Is it external practice distillation or shared terminology? | `docs/references/` | References support, but do not define, project contracts. |

## Borderline Cases

### Architecture Boundary Rules

- If rule is process/policy or lint governance, place in `docs/standards/`.
- If rule is part of implementation contract (for example a dependency-layer contract consumed by tooling), place in `docs/specs/` and reference standards for enforcement policy.

### Scoring Changes

- Scoring intent and product implications go in `docs/design-docs/` or `docs/product-specs/`.
- Scoring formula and output contract go in `docs/specs/scoring-model.md`.

## Required Cross-Links

When creating a new document:
- add it to the nearest `index.md` with `Status`, summary, and `when to read`
- update root `docs/index.md` only if a new area is introduced
- add a decision-log entry when changing major design direction
