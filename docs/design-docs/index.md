# Design Docs Index

Status: Active

## Purpose

Capture the design intent of `missless`: why the product works this way, what system shape we are optimizing for, and which tradeoffs remain open.

## Status Legend

- `Active`: current source of truth
- `Draft`: under active design discussion
- `Deprecated`: kept for history, replaced by another document

## Document Catalog

| Document | Status | Summary | When to read |
| --- | --- | --- | --- |
| [Product Design Principles](./product-design-principles.md) | Active | Product-level principles and quality attributes. | Before changing user/system behavior assumptions. |
| [System Design Overview](./system-design-overview.md) | Active | End-to-end system shape and stage responsibilities. | Before architecture and orchestration changes. |
| [Segment Evidence Model Options](./segment-evidence-model-options.md) | Draft | Tradeoff analysis for segment node vs attribute vs hybrid modeling. | Before locking segment/evidence representation. |
| [Knowledge Graph Design Rationale](./knowledge-graph-design-rationale.md) | Active | Why heterogeneous graph semantics are used and how to evolve safely. | Before changing node/edge contracts. |
| [Decision Log](./decision-log.md) | Active | High-impact design and architecture decisions. | When proposing or reviewing major tradeoffs. |
