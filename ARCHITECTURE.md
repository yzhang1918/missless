# Repository Architecture

This file is the top-level map of how knowledge is organized in this repository.

## Design Principle

Repository knowledge is the system of record. If it is not in this repository, it does not exist for agents.

## Top-Level Layout

- `AGENTS.md`: operating contract for human + Codex collaboration
- `.agents/skills/`: developer-only operational playbooks used while building the product
- `apps/`: runnable product surfaces such as the first local CLI and later web entry points
- `packages/`: reusable runtime modules, contracts, and rendering primitives
- `skills/`: product-facing skills and prompt assets that ship with `missless`
- `docs/`: long-lived product and engineering knowledge

## `docs/` Structure

- `docs/index.md`: global navigation
- `docs/product-specs/`: product foundation and workflow intent
- `docs/design-docs/`: design rationale and decision log
- `docs/specs/`: technical contracts (currently draft-first)
- `docs/exec-plans/`: product tactical planning, tracker, and plan archives
- `docs/harness/`: harness/process tactical planning, tracker, and plan archives
- `docs/standards/`: working rules for documentation/review alignment
- `docs/references/`: external distillations and glossary

## Change Policy

Any substantial product or engineering change must update at least one file in `docs/` in the same branch.

## Product vs. Developer Skills

- `.agents/skills/` exists to help Codex follow repository workflow.
- `skills/` exists for product behavior that should ship as part of `missless`.
- Product-facing prompt assets must not be hidden inside developer-only helper folders.
