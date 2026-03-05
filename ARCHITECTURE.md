# Repository Architecture

This file is the top-level map of how knowledge is organized in this repository.

## Design Principle

Repository knowledge is the system of record. If it is not in this repository, it does not exist for agents.

## Top-Level Layout

- `AGENTS.md`: operating contract for human + Codex collaboration
- `.agents/skills/`: repository-local skills
- `docs/`: long-lived product and engineering knowledge

## `docs/` Structure

- `docs/index.md`: global navigation
- `docs/product-specs/`: product foundation and workflow intent
- `docs/design-docs/`: design rationale and decision log
- `docs/specs/`: technical contracts (currently draft-first)
- `docs/exec-plans/`: tactical planning, tracker, and plan archives
- `docs/standards/`: working rules for documentation/review alignment
- `docs/references/`: external distillations and glossary

## Change Policy

Any substantial product or engineering change must update at least one file in `docs/` in the same branch.
