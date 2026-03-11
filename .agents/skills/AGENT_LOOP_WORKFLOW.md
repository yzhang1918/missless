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
- Only triaged `state:accepted` issues are eligible to enter `loop-discovery`. `needs-triage`, `state:blocked`, and `state:parked` issues stay out of the execution queue until triage changes them.
- A direct human request in chat may enter `loop-discovery` without a pre-existing issue.
- Once a task has an active plan, the repository plan is the execution source of truth.

## Issue Operations

- Use `issue-triage` for `needs-triage` issues, recurring backlog sweeps, and cron-driven disposition work.
- Use `issue-create` to capture new backlog items or backfill issue origin/provenance while execution is still fresh.

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
   - If execution discovers future work, create or update the linked GitHub issues with explicit origin links before treating the task as closed.
   - `loop-publish`, `loop-final-gate`, and `loop-land` must not treat a task as closed while its completed plan still lives only in `active/`.
10. `loop-publish` (push branch and open/update PR)
   - Run repo-sync preflight before publish decisions so local refs and PR state are current.
   - Pass the archived completed plan path; publish must fail closed if the plan is still under `active/` or if the archived plan is not actually complete.
   - Call the publish script with explicit issue metadata: `--direct-request` when no intake issue exists, `--link-issue` for referenced-but-open issues, and `--close-issue` for issues that should close on merge.
   - PR bodies must list the linked issue(s), or explicitly say `direct request (no issue)` when no intake issue exists.
   - Use GitHub closing keywords such as `Closes #123` only for issues that should close on merge; otherwise use a plain reference.
11. `loop-final-gate`
   - Run repo-sync preflight before gate decisions.
   - Pass the archived completed plan path plus a machine-readable CI/status artifact tied to the current `HEAD` and base ref.
   - Repositories using this gate must expose at least one required GitHub status check for the PR; zero-check repos are not final-gate ready.
12. `loop-land`
   - Run repo-sync preflight before landing decisions.
   - Re-check that the archived completed plan and final-gate artifact still match current repository state before merge.
   - After merge, verify that each issue intended to close actually closed on GitHub. If auto-close did not happen, close it manually with the merge reference.
   - Do not close implementation issues before the landing outcome is known.

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

## Stateful Gate Contract

- Before stateful review, publish, final-gate, or land decisions, synchronize remote state first (`git fetch --prune origin` or stricter equivalent).
- Before `loop-publish`, `loop-final-gate`, or `loop-land`, the working tree must also be clean so gate evidence always matches the published `HEAD`.
- `loop-publish`, `loop-final-gate`, and `loop-land` must operate on an archived completed plan path under `docs/exec-plans/completed/` or `docs/harness/completed/`.
- A stateful gate must reject an archived plan if the same plan filename still exists under the matching `active/` folder.
- Plans used by those stateful gates must keep these stable machine-checked fields:
  - `## Acceptance Criteria` with markdown checkboxes (`- [ ]` / `- [x]`)
  - `## Work Breakdown` with `### Step N` subsections
  - exactly one `- Status: ...` line per step using `pending`, `in_progress`, `completed`, or `blocked`
- Final-gate CI/status artifacts must stay small and directly consumable by `final_gate.sh`. At minimum they must identify the current `HEAD`, target base ref/SHA, required-check results, and docs/spec update status.
- Repositories that rely on `loop-final-gate` must configure at least one required GitHub status check on the protected base branch so `export_ci_status.sh` can export a real required-check result set.

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
