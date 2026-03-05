# Specs Index

Status: Active

## Purpose

Define implementation contracts that must remain stable or explicitly versioned.

## Status Legend

- `Active`: current contract
- `Draft`: proposal under development
- `Deprecated`: superseded contract

## Document Catalog

| Document | Status | Summary | When to read |
| --- | --- | --- | --- |
| [Core Data Model](./core-data-model.md) | Active | Node/edge schemas and claim/evidence constraints. | Before any schema or graph relation changes. |
| [Ingestion Pipeline](./ingestion-pipeline.md) | Active | Stage-by-stage run lifecycle and extraction/anchoring flow. | Before orchestration or ingestion flow changes. |
| [Extension System](./extension-system.md) | Active | Extract/align/merge contracts and review/event expectations. | Before adding or changing extension behavior. |
| [Scoring Model](./scoring-model.md) | Active | Rating components and explainability requirements. | Before ranking or weighting changes. |
| [Interface Contracts](./interface-contracts.md) | Active | Interface adapter contracts (CLI now, others by stage). | Before changing interaction semantics. |
| [Run Artifacts JSON Contracts](./run-artifacts-json.md) | Active | Per-run machine-readable artifact schemas. | Before changing debug/replay outputs. |
| [Legacy CLI Contract](./cli-contract.md) | Deprecated | Historical CLI-only framing. | Only when auditing prior assumptions. |
