# Repository Architecture

This file is the top-level map of how knowledge is organized in this repository.

## Design Principle

Repository knowledge is the system of record. If it is not in this repository, it does not exist for agents.

## Top-Level Layout

- `AGENTS.md`: operating contract for human + Codex collaboration
- `.agents/skills/`: repository-local execution skills and loop workflow assets
- `docs/`: long-lived product and engineering knowledge
- `scripts/loop/`: lightweight automation helpers for review/gate loops

## `docs/` Structure

- `docs/index.md`: global navigation
- `docs/design-docs/`: product/system design intent, tradeoffs, decision logs
- `docs/product-specs/`: product charter, stage strategy, workflow, stage gates
- `docs/specs/`: formal contracts (data model, pipeline, extension, scoring, interfaces, run artifacts)
- `docs/exec-plans/`: active/completed plans, backlog, kanban, follow-ups, debt tracking
- `docs/standards/`: governance and merge/review standards
- `docs/references/`: external practice notes and glossary

## Change Policy

Any substantial product or engineering change must update at least one file in `docs/` in the same branch.
