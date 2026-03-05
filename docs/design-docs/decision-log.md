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

- Date: 2026-03-05
- Decision: Replace POC/CLI-first framing with stage-based delivery framing.
- Context: Product direction requires staged outcomes (skill-based -> web -> iOS) without treating later outcomes as non-goals.
- Options considered: retain POC-first docs, stage-based docs with legacy deprecations.
- Chosen option: stage-based docs with legacy files marked deprecated.
- Consequences: clearer long-term planning and less interface lock-in.
- Related docs: `docs/product-specs/delivery-stages.md`, `docs/product-specs/stage-gates.md`, `docs/product-specs/product-charter.md`

- Date: 2026-03-05
- Decision: Separate semantic extraction from evidence anchoring in primary flow.
- Context: Full-content extraction quality should not depend on pre-cut segment nodes.
- Options considered: segment-first extraction, extraction-first with post-hoc evidence anchoring.
- Chosen option: extraction-first, then evidence anchoring.
- Consequences: clearer stage boundaries and better support for segment modeling alternatives.
- Related docs: `docs/design-docs/system-design-overview.md`, `docs/specs/ingestion-pipeline.md`, `docs/design-docs/segment-evidence-model-options.md`
