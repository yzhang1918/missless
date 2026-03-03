# Repository Architecture

This file is the top-level map of how knowledge is organized in this repository.

## Design Principle

Repository knowledge is the system of record. If it is not in this repository, it does not exist for agents.

## Top-Level Layout

- `AGENTS.md`: operating contract for human + Codex collaboration
- `docs/`: all long-lived product and engineering knowledge

## `docs/` Structure

- `docs/index.md`: global navigation
- `docs/design-docs/`: product and system design intent, architecture tradeoffs, decision logs
- `docs/product-specs/`: product goals, scope, workflow, acceptance criteria, roadmap
- `docs/specs/`: formal contracts (data model, pipeline, scoring, CLI, run artifacts)
- `docs/exec-plans/`: active/completed execution plans and technical debt tracking
- `docs/standards/`: documentation, governance, and merge workflow standards
- `docs/references/`: external practice notes and glossary

## Change Policy

Any substantial product or engineering change must update at least one file in `docs/` in the same branch.
