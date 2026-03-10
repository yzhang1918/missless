# Agent Loop Workflow

Status: Active

## Purpose

Define the repository-local workflow for Codex-led implementation and harness evolution in `missless`.

## Task Clarification Gate

Before entering the primary loop:
- If the human request does not specify an explicit task, ask one concise clarifying question.
- Confirm task objective and success criteria before running discovery.
- Do not start discovery/plan/execution on implicit assumptions.

## Intake Policy

- Open backlog and asynchronous intake live in GitHub Issues for `yzhang1918/missless`.
- A direct human request in chat may enter `loop-discovery` without a pre-existing issue.
- Once a task has an active plan, the repository plan is the execution source of truth.

## Primary Loop

For medium/large tasks, discovery + plan are required (do not skip steps 1-2).

0. Task clarification gate
1. `loop-discovery` (conversation-only; no repository file writes)
2. `loop-plan` (first step that writes plan artifacts)
   - Product work -> `docs/exec-plans/active/`
   - Harness/process work -> `docs/harness/active/`
3. `loop-execute` (per step)
4. `commit` (zero-to-many; create reviewable increments during execution)
5. `loop-review-loop` (delta mode, per step)
6. Repeat 3-5 until all steps are complete
7. `loop-review-loop` (full-pr mode)
8. `commit` (optional final fix commit; if new changes are introduced here, rerun step 7)
9. Archive completed plans and sync issue state
   - Move finished product plans from `docs/exec-plans/active/` to `docs/exec-plans/completed/`.
   - Move finished harness/process plans from `docs/harness/active/` to `docs/harness/completed/`.
   - Update completed-plan catalogs and issue links in the same change.
   - If execution discovers future work, create or update the linked GitHub issues before treating the task as closed.
   - `loop-publish`, `loop-final-gate`, and `loop-land` must not treat a task as closed while its completed plan still lives only in `active/`.
10. `loop-publish` (push branch and open/update PR)
11. `loop-final-gate`
12. `loop-land`

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
