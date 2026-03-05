# Agent Loop Skills Bootstrap Plan

Status: Completed
Date: 2026-03-04
Owner: Codex

## Objective

Create repository-local skills and lightweight automation scripts that support an agent-first development loop for `missless`, including TDD execution, flexible subagent-based review, final gate evaluation, and landing handoff.

## Scope

In scope:
- Add skill definitions under `.agents/skills/`.
- Add minimal script wrappers under `scripts/loop/` for review artifact handling and gate checks.
- Encode agreed operating rules:
  - Red/Green/Refactor TDD during execution.
  - Review process artifacts stay in `.local/`.
  - Subagent reviewer dimensions are selected dynamically by the main agent.
  - No automatic worktree creation by skills.

Out of scope:
- Full CI pipeline implementation.
- GitHub workflow or branch protection reconfiguration.
- Automatic PR lifecycle bots.

## Acceptance Criteria

- [x] Seven skills exist under `.agents/skills/` with `SKILL.md` and `agents/openai.yaml`.
- [x] `loop-review-loop` explicitly supports dynamic subagent reviewer selection.
- [x] `loop-execute` mandates Red/Green/Refactor TDD.
- [x] `loop-final-gate` and `loop-land` are clearly separated by responsibility.
- [x] `scripts/loop/` contains executable helpers for review artifact lifecycle and gate checks.
- [x] Changes are validated with shell-level smoke checks.

## Work Breakdown

1. Scaffold directories and workflow entry doc.
2. Author the seven skill contracts.
3. Add `agents/openai.yaml` metadata files.
4. Implement script helpers for review and gate flow.
5. Run smoke checks and finalize this plan.

## Validation Plan

Checks to run:
- Ensure all required files exist.
- Lint/validate shell scripts with `bash -n`.
- Run a local script smoke test for review aggregation and gate evaluation.

Evidence to capture:
- Command outputs in terminal session.
- Final file tree and `git status`.

## Risks and Mitigations

- Risk: Skills become too rigid and block adaptation.
  - Mitigation: Keep reviewer dimensions as recommendations and require dynamic selection by the main agent.
- Risk: Duplicate source-of-truth between `.local` and docs.
  - Mitigation: Restrict `.local` to process artifacts and require final decisions in plan/PR records.

## Decision Log

- Decision: Keep review JSON in `.local` and treat it as ephemeral process state.
  - Reason: Findings are resolved iteratively and do not need long-term storage once summarized in repository records.
- Decision: Add only minimal scripts now.
  - Reason: Establish deterministic contracts first, then iterate based on usage.

## Completion Summary

Delivered:
- Added `.agents/skills/AGENT_LOOP_WORKFLOW.md` to define the end-to-end loop and artifact policy.
- Added seven skills under `.agents/skills/` with `SKILL.md` and `agents/openai.yaml`.
- Added `loop-review-loop` reviewer schema reference at `.agents/skills/loop-review-loop/references/reviewer-output-schema.md`.
- Added executable helpers:
  - `scripts/loop/review_init.sh`
  - `scripts/loop/review_aggregate.sh`
  - `scripts/loop/review_gate.sh`
  - `scripts/loop/final_gate.sh`
- Updated `docs/standards/review-and-merge-workflow.md` to define review cadence and final-gate vs land responsibilities.
- Updated `.gitignore` to ignore `.local/` process artifacts.

Not delivered:
- Automatic CI status export to `ci.json` from GitHub API (left for next iteration).

Follow-up:
- FUP-0001: Add optional script to fetch required CI check status from the current PR and emit a compatible `ci.json` (mapped to BL-0003).
- FUP-0002: Add lightweight template command for spawning reviewer subagents by selected dimensions (mapped to BL-0004).
