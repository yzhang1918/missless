# Decision Log

Status: Active

Use this file to record high-impact product/system design decisions.

## Entry Template

- Date:
- Decision:
- Context:
- Options considered:
- Chosen option:
- Consequences:
- Related docs:

## Initial Decisions

- Date: 2026-03-03
- Decision: Repository documentation is established before implementation code.
- Context: The project starts as an empty repository and must support long-term agent-first delivery.
- Options considered: code-first bootstrap, docs-first bootstrap.
- Chosen option: docs-first bootstrap.
- Consequences: slower first commit, better long-term legibility and execution consistency.
- Related docs: `AGENTS.md`, `ARCHITECTURE.md`, `docs/index.md`

- Date: 2026-03-03
- Decision: `design-docs` is scoped to product/system design intent, not generic collaboration guidance.
- Context: Early version mixed product design with agent-operation content.
- Options considered: mixed content, strict scope separation.
- Chosen option: strict scope separation.
- Consequences: cleaner retrieval path for future design work and fewer context collisions.
- Related docs: `docs/design-docs/index.md`, `docs/standards/index.md`, `AGENTS.md`

- Date: 2026-03-03
- Decision: Use heterogeneous graph semantics as the logical knowledge model.
- Context: Product value depends on evidence traceability, deduplication, and relation-aware alignment.
- Options considered: flat summary store, document-only knowledge store, graph-first logical model.
- Chosen option: graph-first logical model (storage backend remains implementation-defined).
- Consequences: higher modeling complexity, significantly better explainability and contradiction handling.
- Related docs: `docs/specs/core-data-model.md`, `docs/design-docs/knowledge-graph-design-rationale.md`
