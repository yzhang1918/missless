# Harness Tracker

Status: Active

## Purpose

Single tactical tracker for agent-harness workflow/process priorities, follow-ups, and debt.

## How to Use

- Start harness/process sessions from this file.
- Keep this file harness-focused. Product delivery work is tracked in `docs/exec-plans/tracker.md`.
- Keep each item in exactly one section.
- For non-trivial work, link to a plan in `active/` or `completed/`.
- Keep non-done work near the top and `done` work in the tail `Completed` section for quick `head`/`tail` reads.
- Migration note: process items were split out from `docs/exec-plans/tracker.md` on 2026-03-06.

## Schema

- `ID`: `TASK-xxxx`, `FUP-xxxx`, `DEBT-xxxx`
- `Priority`: `P0|P1|P2|P3`
- `Status`: `todo|ready|in_progress|blocked|done`
- `Owner`: `Human`, `Codex`, or `Human+Codex`
- `Links`: related docs/plans/commits

## Current Focus

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |

## Queue

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |

## Follow-ups

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| FUP-0001 | Add optional CI status exporter for final-gate input | P2 | todo | Codex | `.agents/skills/loop-final-gate/scripts/final_gate.sh` | Emit machine-readable status file. |
| FUP-0002 | Add helper to spawn reviewer subagents by selected dimensions | P2 | todo | Codex | `.agents/skills/loop-review-loop/SKILL.md` | Keep dimensions configurable. |
| FUP-0004 | Make review-loop reviewer fallback fail closed and explicit | P1 | todo | Codex | `docs/harness/completed/2026-03-09-post-first-slice-loop-remediation.md`, `.agents/skills/loop-review-loop/SKILL.md` | If reviewer agents do not return, the loop should retry or fallback with recorded evidence instead of silently completing without reviewer output. |
| FUP-0005 | Enforce plan completion and archival before publish and final gate | P1 | todo | Codex | `docs/harness/completed/2026-03-09-post-first-slice-loop-remediation.md`, `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `.agents/skills/loop-publish/SKILL.md`, `.agents/skills/loop-final-gate/SKILL.md` | Publish/final-gate should refuse to outrun stale plan checkboxes, statuses, tracker state, or completed plans that still live only in `active/`. |
| FUP-0006 | Add rubric-based AI review for real E2E runs | P2 | todo | Codex | `docs/harness/completed/2026-03-09-post-first-slice-loop-remediation.md` | Future live-E2E validation should close the loop with an explicit AI-review rubric and artifact-scoped reviewer context rather than ad-hoc review prompting. |

## Technical Debt

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |

## Completed

| ID | Title | Priority | Status | Owner | Links | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TASK-0003 | Validate agent loop ergonomics after first real feature cycle | P2 | done | Human+Codex | `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `docs/harness/completed/2026-03-09-post-first-slice-loop-remediation.md` | Completed: the ergonomics review was captured in a documentation-first remediation plan for PR `#8`; implementation work was decomposed into follow-ups `FUP-0004` through `FUP-0006`. |
| TASK-0005 | Refine discovery option framing ergonomics | P2 | done | Human+Codex | `.agents/skills/loop-discovery/SKILL.md`, `.agents/skills/loop-discovery/agents/openai.yaml`, `docs/harness/completed/2026-03-06-discovery-option-framing.md` | Completed: discovery now uses context-shaped 2-4 options with concise tradeoff notes, validated with isolated subagent tests. |
| TASK-0004 | Calibrate task-intake and discovery flow in AGENTS/skills | P0 | done | Human+Codex | `AGENTS.md`, `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `.agents/skills/loop-discovery/SKILL.md`, `.agents/skills/loop-plan/SKILL.md`, `docs/harness/completed/2026-03-05-skill-flow-calibration.md` | Completed: task confirmation gate + conversation-only Socratic discovery are now codified. |
| FUP-0003 | Harden review-loop and final-gate artifact contracts | P1 | done | Codex | `.agents/skills/loop-review-loop/scripts/`, `.agents/skills/loop-final-gate/scripts/final_gate.sh`, commit `cbd4636` | Added fail-closed validation, safe cleanup behavior, and regression harness. |
