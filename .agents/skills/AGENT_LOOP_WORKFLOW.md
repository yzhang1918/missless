# Agent Loop Workflow

Status: Active

## Purpose

Define the repository-local workflow for Codex-led implementation in `missless`.

## Task Clarification Gate

Before entering the primary loop:
- If the human request does not specify an explicit task, ask one concise clarifying question.
- Confirm task objective and success criteria before running discovery.
- Do not start discovery/plan/execution on implicit assumptions.

## Primary Loop

For medium/large tasks, discovery + plan are required (do not skip steps 1-2).

0. Task clarification gate
1. `loop-discovery` (conversation-only; no repository file writes)
2. `loop-plan` (first step that writes plan artifacts)
3. `loop-execute` (per step)
4. `loop-review-loop` (delta mode, per step)
5. Repeat 3-4 until all steps are complete
6. `loop-review-loop` (full-pr mode)
7. `loop-final-gate`
8. `commit` (when creating local commits before merge)
9. `loop-land`

## Janitor Loop

Run `loop-janitor` independently on a recurring cadence for entropy control and behavior-preserving refactors.

## Artifact Policy

- Repository source-of-truth artifacts live in git-tracked docs and code.
- Discovery outputs remain in conversation until human approval.
- `.local/loop/*.json` files are ephemeral process artifacts.
- Review findings may remain in `.local` while active.
- Final decisions and outcomes must be summarized in tracked plan/PR records.
- Helper scripts are skill-local under `.agents/skills/*/scripts/`.
- Run review artifact cleanup after active review loops:
  - `.agents/skills/loop-review-loop/scripts/review_cleanup.sh --keep-rounds 1`
- If loop/gate scripts changed, run:
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`

## Review Policy

- Use dynamic reviewer dimensions based on change risk and scope.
- Candidate dimensions: correctness, architecture, tests, docs/spec consistency, security, performance/reliability.
- Do not hardcode a fixed reviewer set for every change.

## TDD Policy

- Execution defaults to Red/Green/Refactor.
- For behavior changes, write a failing test before implementation unless impossible.
- Full CI is required before landing; step-level development uses quick validation.

## Worktree Policy

- Skills never create worktrees automatically.
- Worktree usage is allowed only when explicitly initiated by the human.
