# AGENTS.md

This document defines how humans and Codex collaborate in `missless`.

## Mission

Build `missless` as an agent-first, repository-legible system that turns information overload into decision clarity.

## Non-Negotiable Rules

1. Repository is the single source of truth for approved plans, specs, validation evidence, and completed execution history.
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

## Intake Sources

- Asynchronous backlog, future work, and community input live in GitHub Issues for `yzhang1918/missless`.
- A direct human request in chat may enter discovery without a pre-existing issue.
- Once work enters planning/execution, the repository plan becomes the authoritative execution record.

## Required Workflow

For medium or large work, these steps are mandatory:
1. Discovery (interactive brainstorming; no repository file writes)
2. Plan
   - Product work: write to `docs/exec-plans/active/` only after discovery approval
   - Harness/process work: write to `docs/harness/active/` only after discovery approval
3. Execution (small reviewable increments)
4. Validation (checks + evidence)
5. Documentation updates
6. Issue updates
   - If work came from a GitHub issue, sync plan/PR links and disposition back to that issue.
   - If execution reveals future work, create or update GitHub issues before closing the current plan.
7. Plan archival
   - When a task is complete, move its plan from `active/` to `completed/` before publish/final gate.
   - Keep `active/` reserved for unfinished work only.

For small work, discovery+plan can be collapsed, but rationale must still be explicit.

## Start Points

- Open backlog and async next steps: GitHub Issues in `yzhang1918/missless`
- Direct synchronous requests: start from the human's explicit chat request, then enter discovery
- Product context: `docs/product-specs/index.md`
- Design rationale: `docs/design-docs/index.md`
- Technical contracts: `docs/specs/index.md`
- Detailed standards: `docs/standards/repository-standards.md`

## Local Skills

Repository-local skills live under `.agents/skills/`.
If standards and skills conflict, standards win.

Primary skills:
- `loop-discovery`, `loop-plan`, `loop-execute`
- `loop-review-loop`, `loop-final-gate`, `loop-publish`, `loop-land`, `loop-janitor`
- `loop-reviewer` (subagent reviewer output contract)
- `commit`

## Git Rules

- Main branch: `main`
- Working branch prefix: `codex/`
- Commits: small and atomic
- Commit cadence: commits can happen multiple times during execution; publish/merge timing is controlled by loop workflow, not by the `commit` skill itself.
- Never rewrite shared history without explicit approval
