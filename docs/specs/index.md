# Specs Index

Status: Active

## Purpose

Define technical contracts in a draft-first mode until implementation decisions are locked.

## Status Legend

- `Active`: approved and stable contract
- `Draft`: under active design
- `Superseded`: replaced by newer contract

## Document Catalog

| Document | Status | Summary | When to read |
| --- | --- | --- | --- |
| [CLI Contracts](./cli-contracts.md) | Draft | Stable first-slice command names, arguments, stdout JSON envelopes, and error semantics. | Before changing CLI I/O or agent-facing workflow commands. |
| [Core Data Model](./core-data-model.md) | Draft | Minimum object and relation contracts for source, atom, artifact, and evidence. | Before schema and storage decisions. |
| [Pipeline Contracts](./pipeline-contracts.md) | Draft | End-to-end ingestion/review/commit contract and adapter requirements. | Before orchestration and interface decisions. |
