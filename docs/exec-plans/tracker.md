# Execution Tracker

Status: Active

## Purpose

Single tactical tracker for priorities, follow-ups, and debt.

## How to Use

- Start each session from this file.
- Keep each item in exactly one section.
- For non-trivial work, link to a plan in `active/` or `completed/`.

## Schema

- `ID`: `TASK-xxxx`, `FUP-xxxx`, `DEBT-xxxx`
- `Priority`: `P0|P1|P2|P3`
- `Status`: `todo|ready|in_progress|blocked|done`
- `Owner`: `Human`, `Codex`, or `Human+Codex`
- `Links`: related docs/plans/commits

## Current Focus

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TASK-0001 | Decide evidence anchor representation profile | P1 | ready | Human+Codex | `docs/design-docs/system-design.md` | Keep contract stable; storage shape can vary. |
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
