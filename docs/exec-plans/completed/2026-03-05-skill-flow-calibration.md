# Skill Flow Calibration (Task Intake + Discovery Behavior)

Status: Active

## Metadata

- Plan name: Skill Flow Calibration (Task Intake + Discovery Behavior)
- Owner: Human+Codex
- Date: 2026-03-05
- Related issue/task: TASK-0004
- Tracker IDs: TASK-0004

## Objective

Align repository collaboration flow so Codex confirms task intent before discovery and keeps discovery as Socratic, conversation-only collaboration (no repository file writes).

## Scope

- In scope:
  - Update `AGENTS.md` task-intake expectations.
  - Update loop workflow contract to include task clarification gate and discovery artifact behavior.
  - Update `loop-discovery` and `loop-plan` skill contracts.
  - Sync related skill `agents/openai.yaml` interface text.
  - Update tracker with this calibration task and deferred context for `TASK-0001`.
- Out of scope:
  - Changing execution/review/final-gate mechanics beyond discovery/plan handoff.
  - Implementing runtime code behavior unrelated to skill docs.

## Acceptance Criteria

- [x] `AGENTS.md` states explicit task-confirmation requirement before discovery.
- [x] `.agents/skills/AGENT_LOOP_WORKFLOW.md` includes task clarification gate and discovery conversation-only behavior.
- [x] `.agents/skills/loop-discovery/SKILL.md` requires one-question-per-turn, multi-round Socratic discovery, and no file writes.
- [x] `.agents/skills/loop-plan/SKILL.md` requires approved discovery summary before writing plan artifacts.
- [x] Tracker includes `TASK-0004` and records deferred context for `TASK-0001`.

## Work Breakdown

1. Add task-intake and workflow gates in top-level docs.
2. Refine discovery/plan skill contracts and interface metadata.
3. Sync tracker state and run term-level validation checks.

## Validation Plan

- `rg -n "Task Intake Gate|interactive brainstorming; no repository file writes|task clarification gate" AGENTS.md .agents/skills/AGENT_LOOP_WORKFLOW.md`
- `rg -n "Socratic|one high-leverage question|Do not write or modify repository files during discovery|Do not proceed to .*loop-plan" .agents/skills/loop-discovery/SKILL.md`
- `rg -n "approved discovery summary|If not approved, return to .*loop-discovery" .agents/skills/loop-plan/SKILL.md`
- `rg -n "TASK-0004|TASK-0001" docs/exec-plans/tracker.md docs/exec-plans/completed/2026-03-05-skill-flow-calibration.md`

## Risks and Mitigations

- Risk: Over-constraining discovery reduces efficiency on small tasks.
  - Mitigation: Keep small-task collapse policy in `AGENTS.md`; enforce strict discovery only for medium/large or ambiguous work.
- Risk: Skill metadata drifts from skill body.
  - Mitigation: Update associated `agents/openai.yaml` descriptions in the same change set.

## Completion Summary

- Delivered:
  - Added task-intake gate and discovery write restrictions in `AGENTS.md`.
  - Added task clarification gate and discovery artifact policy in workflow doc.
  - Reworked `loop-discovery` to Socratic, multi-round, conversation-only behavior.
  - Reworked `loop-plan` to require explicit discovery approval before file-writing.
  - Synced `agents/openai.yaml` text for `loop-discovery` and `loop-plan`.
  - Added tracker task `TASK-0004`, then restored `TASK-0001` to `ready` after this PR scope was narrowed to skill-flow only.
- Not delivered:
  - No additional execution-loop behavior changes outside discovery/plan handoff.
- Tracker updates:
  - `TASK-0004` marked `done` and linked to this completed plan.
  - `TASK-0001` kept out of this PR scope and set to `ready`.
