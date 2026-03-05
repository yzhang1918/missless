# Decision Log

Status: Active

Use this file to record high-impact design decisions and reversals.

## Entry Template

- Date:
- Decision:
- Context:
- Options considered:
- Chosen option:
- Consequences:
- Related docs:

## Entries

- Date: 2026-03-03
- Decision: Repository documentation is established before implementation code.
- Context: The project starts from an empty repository and must support long-term agent-first delivery.
- Options considered: code-first bootstrap, docs-first bootstrap.
- Chosen option: docs-first bootstrap.
- Consequences: slower first commit, better long-term legibility and execution consistency.
- Related docs: `AGENTS.md`, `ARCHITECTURE.md`, `docs/index.md`

- Date: 2026-03-05
- Decision: Separate semantic extraction from evidence anchoring in the baseline flow.
- Context: Full-content understanding should not depend on pre-cut segments.
- Options considered: segment-first extraction, extraction-first then evidence anchoring.
- Chosen option: extraction-first then evidence anchoring.
- Consequences: clearer stage boundaries and better support for different evidence storage profiles.
- Related docs: `docs/design-docs/system-design.md`, `docs/specs/pipeline-contracts.md`

- Date: 2026-03-05
- Decision: Use a compact initial documentation layout and split later by explicit triggers.
- Context: Early repository had too many narrow files for the current discussion stage.
- Options considered: many specialized docs, compact foundation docs with split policy.
- Chosen option: compact foundation docs with split policy.
- Consequences: easier navigation now, controlled growth later.
- Related docs: `docs/product-specs/index.md`, `docs/exec-plans/tracker.md`, `docs/standards/repository-standards.md`
