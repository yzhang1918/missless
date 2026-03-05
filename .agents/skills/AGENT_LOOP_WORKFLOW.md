# Agent Loop Workflow

Status: Active

## Purpose

Define the repository-local workflow for Codex-led implementation in `missless`.

## Primary Loop

1. `loop-discovery`
2. `loop-plan`
3. `loop-execute` (per step)
4. `loop-review-loop` (delta mode, per step)
5. Repeat 3-4 until all steps are complete
6. `loop-review-loop` (full-pr mode)
7. `loop-final-gate`
8. `loop-land`

## Janitor Loop

Run `loop-janitor` independently on a recurring cadence for entropy control and behavior-preserving refactors.

## Artifact Policy

- Repository source-of-truth artifacts live in git-tracked docs and code.
- `.local/loop/*.json` files are ephemeral process artifacts.
- Review findings may remain in `.local` while active.
- Final decisions and outcomes must be summarized in tracked plan/PR records.

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
