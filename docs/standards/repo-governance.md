# Repository Governance

Status: Active

## Source-of-Truth Policy

- Product, architecture, and workflow decisions must live in this repo.
- External references are supplemental, not authoritative.

## Documentation Freshness

- Any behavior or contract change requires corresponding doc updates in the same branch.
- Stale docs must be corrected before or with implementation changes.

## Stage Governance

- Delivery stages are authoritative in `docs/product-specs/delivery-stages.md`.
- Stage gates are authoritative in `docs/product-specs/stage-gates.md`.
- Backlog prioritization is authoritative in `docs/exec-plans/backlog.md` and `docs/exec-plans/kanban.md`.

## Document Placement Governance

- New documents must follow the placement rules in `AGENTS.md`.
- For ambiguous cases, use `docs/standards/document-placement-matrix.md`.
- Document placement decisions should prefer the most restrictive interpretation:
  - machine-facing contract -> `docs/specs/`
  - governance/process policy -> `docs/standards/`
  - design rationale/tradeoff -> `docs/design-docs/`

## Ownership Model

- Human sets priorities and resolves ambiguity.
- Codex executes, validates, and maintains repository coherence.
