# Product Specs Index

Status: Active

## Purpose

Define what `missless` should do before technical scope is finalized.

## Status Legend

- `Active`: approved source of truth
- `Draft`: under discussion
- `Superseded`: replaced by newer doc

## Document Catalog

| Document | Status | Summary | When to read |
| --- | --- | --- | --- |
| [Product Foundation](./product-foundation.md) | Draft | Positioning, problem, principles, and baseline workflow in one file. | Before discussing scope, sequencing, or product direction. |

## Split Policy

Keep one foundation file until at least one of these is true:
- a section exceeds ~150 lines and is frequently edited independently
- two sections have different review cadence/owners
- implementation work repeatedly needs a stable standalone contract

When splitting:
- keep `product-foundation.md` as the entry document
- add new files incrementally and register them in this index
