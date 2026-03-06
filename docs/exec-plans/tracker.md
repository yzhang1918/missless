# Execution Tracker

Status: Active

## Purpose

Single tactical tracker for priorities, follow-ups, and debt.

## How to Use

- Start each session from this file.
- Keep each item in exactly one section.
- For non-trivial work, link to a plan in `active/` or `completed/`.
- Keep non-done work near the top and `done` work in the tail `Completed` section for quick `head`/`tail` reads.

## Schema

- `ID`: `TASK-xxxx`, `FUP-xxxx`, `DEBT-xxxx`
- `Priority`: `P0|P1|P2|P3`
- `Status`: `todo|ready|in_progress|blocked|done`
- `Owner`: `Human`, `Codex`, or `Human+Codex`
- `Links`: related docs/plans/commits

## Current Focus

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TASK-0001 | Decide evidence anchor representation profile | P1 | ready | Human+Codex | `docs/design-docs/system-design.md` | Deferred from current skill-flow PR; restart with interactive discovery when resumed. |
| TASK-0002 | Define the first implementation slice and acceptance bar | P1 | todo | Human+Codex | `docs/product-specs/product-foundation.md` | Scope should be discussed before coding. |

## Queue

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TASK-0003 | Validate agent loop ergonomics after first real feature cycle | P2 | todo | Human+Codex | `.agents/skills/AGENT_LOOP_WORKFLOW.md` | Re-tune loop only after real usage data. |

## Follow-ups

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| FUP-0001 | Add optional CI status exporter for final-gate input | P2 | todo | Codex | `.agents/skills/loop-final-gate/scripts/final_gate.sh` | Emit machine-readable status file. |
| FUP-0002 | Add helper to spawn reviewer subagents by selected dimensions | P2 | todo | Codex | `.agents/skills/loop-review-loop/SKILL.md` | Keep dimensions configurable. |

## Technical Debt

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| DEBT-0001 | Re-evaluate document split policy after first delivery slice | P3 | todo | Human+Codex | `docs/product-specs/index.md` | Avoid premature fragmentation. |

## Completed

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TASK-0005 | Refine discovery option framing ergonomics | P2 | done | Human+Codex | `.agents/skills/loop-discovery/SKILL.md`, `.agents/skills/loop-discovery/agents/openai.yaml`, `docs/exec-plans/completed/2026-03-06-discovery-option-framing.md` | Completed: discovery now uses context-shaped 2-4 options with concise tradeoff notes, validated with isolated subagent tests. |
| TASK-0004 | Calibrate task-intake and discovery flow in AGENTS/skills | P0 | done | Human+Codex | `AGENTS.md`, `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `.agents/skills/loop-discovery/SKILL.md`, `.agents/skills/loop-plan/SKILL.md`, `docs/exec-plans/completed/2026-03-05-skill-flow-calibration.md` | Completed: task confirmation gate + conversation-only Socratic discovery are now codified. |
| FUP-0003 | Harden review-loop and final-gate artifact contracts | P1 | done | Codex | `.agents/skills/loop-review-loop/scripts/`, `.agents/skills/loop-final-gate/scripts/final_gate.sh`, commit `cbd4636` | Added fail-closed validation, safe cleanup behavior, and regression harness. |
