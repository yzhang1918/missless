# Design Docs Index

Status: Active

## Purpose

Capture the design intent of `missless` itself: why the product works this way, what system shape we are optimizing for, and what tradeoffs are intentional.

## Status Legend

- `Active`: current source of truth
- `Draft`: under active design discussion
- `Deprecated`: kept for history, replaced by another document

## Document Catalog

| Document | Status | Summary | When to read |
| --- | --- | --- | --- |
| [Product Design Principles](./product-design-principles.md) | Active | Defines product-level design principles and quality attributes. | Before changing user-facing behavior or scope. |
| [System Design Overview](./system-design-overview.md) | Active | Explains the end-to-end system shape, boundaries, and stage responsibilities. | Before designing architecture or splitting implementation work. |
| [Knowledge Graph Design Rationale](./knowledge-graph-design-rationale.md) | Active | Explains why the heterogeneous graph model is chosen and how to evolve it safely. | Before changing nodes/edges/schema behavior. |
| [Decision Log](./decision-log.md) | Active | Records high-impact design and architecture decisions. | When proposing or reviewing major tradeoffs. |
