# AGENTS.md

This document defines how humans and Codex collaborate in `missless`.

## Mission

Build `missless` as an agent-first, repository-legible system that turns information overload into decision clarity.

## Non-Negotiable Rules

1. Repository is the single source of truth.
2. All docs and code must be written in English.
3. Every meaningful change must update docs/specs in the same branch.
4. Evidence over opinion: decisions link to specs, plans, or run artifacts.
5. Codex closes the loop: discovery -> plan -> execute -> validate -> report.

## Role Split

- Human: set priorities, constraints, acceptance criteria, and final tradeoff calls.
- Codex: execute end-to-end, keep docs/code aligned, surface risks clearly.

## Task Intake Gate

Before any discovery/plan/execution work:
- If the human has not explicitly provided a task, Codex must ask a concise clarification question first.
- Codex must confirm objective and success criteria before entering discovery.
- Codex must not start implementation-oriented work on assumed tasks.

## Required Workflow

For medium or large work, these steps are mandatory:
1. Discovery (interactive brainstorming; no repository file writes)
2. Plan (write to `docs/exec-plans/active/` only after discovery approval)
3. Execution (small reviewable increments)
4. Validation (checks + evidence)
5. Documentation updates
6. Tracker updates (`docs/exec-plans/tracker.md`)

For small work, discovery+plan can be collapsed, but rationale must still be explicit.

## Start Points

- What to do next: `docs/exec-plans/tracker.md`
- Product context: `docs/product-specs/index.md`
- Design rationale: `docs/design-docs/index.md`
- Technical contracts: `docs/specs/index.md`
- Detailed standards: `docs/standards/repository-standards.md`

## Local Skills

Repository-local skills live under `.agents/skills/`.
If standards and skills conflict, standards win.

Primary skills:
- `loop-discovery`, `loop-plan`, `loop-execute`
- `loop-review-loop`, `loop-final-gate`, `loop-land`, `loop-janitor`
- `commit`

## Git Rules

- Main branch: `main`
- Working branch prefix: `codex/`
- Commits: small and atomic
- Never rewrite shared history without explicit approval
