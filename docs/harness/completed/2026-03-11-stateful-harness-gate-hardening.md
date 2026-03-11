# Stateful Harness Gate Hardening

## Metadata

- Plan name: Stateful Harness Gate Hardening
- Owner: Human+Codex
- Date opened: 2026-03-11
- Intake source: GitHub issues `#9`, `#12`, and `#19`
- Work type: Harness/process
- Related issue(s): `#9`, `#12`, `#19`

## Objective

Harden the harness so stateful review/publish/final-gate/land decisions fail closed when repository state is stale, plan state is incomplete, or machine-readable gate inputs do not match the current branch state.

## Scope

- In scope:
  - Add a shared repo-sync preflight contract for stateful harness decisions in the owned publish/final-gate/land surface.
  - Enforce plan completion and archival expectations before publish and final gate.
  - Tighten the machine-readable final-gate input contract while keeping the CI artifact small and directly consumable by `final_gate.sh`.
  - Update loop workflow and relevant harness standards/docs so the documented process matches the scripted behavior.
- Out of scope:
  - Review-loop helper spawning or fallback behavior (`#10`, `#11`, `#20`, `#22`).
  - Product runtime/provider code.
  - Installable skill packaging.

## Acceptance Criteria

- [x] `loop-publish`, `loop-final-gate`, and `loop-land` require a repo-sync preflight before stateful decisions and document that requirement consistently.
- [x] Publish and final-gate reject incomplete plan state, including unfinished acceptance criteria/step status and completed plans that still live only in `docs/harness/active/` or `docs/exec-plans/active/`.
- [x] `final_gate.sh` consumes a small machine-readable CI/status artifact that is validated against the current branch/commit state and fails closed when required inputs are missing or stale.
- [x] Workflow docs/templates/standards describe the stable plan fields and gate expectations needed by the new enforcement.
- [x] Validation covers `git diff --check`, `.agents/skills/loop-review-loop/scripts/review_regression.sh`, and targeted checks for each changed harness script.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define the shared repo-sync and plan-state contract that all stateful gate actions will rely on.
- Expected files:
  - `.agents/skills/AGENT_LOOP_WORKFLOW.md`
  - `docs/standards/repository-standards.md`
  - `docs/exec-plans/templates/execution-plan-template.md`
  - `docs/harness/active/README.md`
  - `docs/exec-plans/active/README.md`
  - `docs/harness/completed/README.md`
  - `docs/exec-plans/completed/README.md`
- Validation commands:
  - `rg -n "repo-sync|active/|completed/|Acceptance Criteria|Status:" .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md docs/exec-plans/templates/execution-plan-template.md docs/harness/active/README.md docs/exec-plans/active/README.md docs/harness/completed/README.md docs/exec-plans/completed/README.md`
- Documentation impact:
  - Establish the stable markdown plan fields and workflow wording that scripted enforcement can depend on.
- Evidence:
  - Updated workflow/standards docs so repo-sync preflight, archived-plan-only gating, and stable plan fields are stated consistently in `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `docs/standards/repository-standards.md`, `docs/harness/active/README.md`, `docs/exec-plans/active/README.md`, `docs/harness/completed/README.md`, `docs/exec-plans/completed/README.md`, and `docs/exec-plans/templates/execution-plan-template.md`.
  - Added the same repo-sync preflight wording to `.agents/skills/loop-review-loop/SKILL.md` after the first review round exposed doc drift.
  - Validated with `rg -n "repo-sync|active/|completed/|Acceptance Criteria|Status:" .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md docs/exec-plans/templates/execution-plan-template.md docs/harness/active/README.md docs/exec-plans/active/README.md docs/harness/completed/README.md docs/exec-plans/completed/README.md`.

### Step 2

- Status: completed
- Objective: Implement shared harness checks and wire them into publish/final-gate/land so stale repo state, stale plan state, and stale gate inputs are rejected.
- Expected files:
  - `.agents/skills/loop-publish/SKILL.md`
  - `.agents/skills/loop-publish/scripts/publish_pr.sh`
  - `.agents/skills/loop-final-gate/SKILL.md`
  - `.agents/skills/loop-final-gate/scripts/export_ci_status.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh`
  - `.agents/skills/loop-final-gate/scripts/final_gate.sh`
  - `.agents/skills/loop-land/SKILL.md`
  - `.agents/skills/loop-land/scripts/land_preflight.sh`
  - `.agents/skills/loop-review-loop/scripts/review_init.sh`
- Validation commands:
  - `bash -n .agents/skills/loop-publish/scripts/publish_pr.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/export_ci_status.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`
  - `bash -n .agents/skills/loop-land/scripts/land_preflight.sh`
  - `bash -n .agents/skills/loop-review-loop/scripts/review_init.sh`
- Documentation impact:
  - Keep each affected skill contract aligned with the actual script behavior and new required inputs.
- Evidence:
  - Added `.agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh` so publish/final-gate/land share repo-sync and archived-plan validation logic, including stale active-twin rejection.
  - Added `.agents/skills/loop-final-gate/scripts/export_ci_status.sh` to emit a small CI/status JSON keyed to `head_sha`, `base_ref`, `base_sha`, required checks, and docs/spec update status.
  - Tightened `.agents/skills/loop-publish/scripts/publish_pr.sh`, `.agents/skills/loop-final-gate/scripts/final_gate.sh`, and `.agents/skills/loop-land/scripts/land_preflight.sh` so they fail closed on stale repo state, stale plan state, or stale gate artifacts.
  - Implemented the review-loop side of the repo-sync contract in `.agents/skills/loop-review-loop/scripts/review_init.sh` so stateful review rounds also fetch fresh remote refs before starting.
  - Updated the publish/final-gate/land skill docs and prompts to match the new script contracts.
  - Validated shell syntax with `bash -n .agents/skills/loop-publish/scripts/publish_pr.sh`, `bash -n .agents/skills/loop-final-gate/scripts/export_ci_status.sh`, `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh`, `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`, `bash -n .agents/skills/loop-land/scripts/land_preflight.sh`, and `bash -n .agents/skills/loop-review-loop/scripts/review_init.sh`.

### Step 3

- Status: completed
- Objective: Add or update regression coverage and finalize the plan/archive/documentation record for the harness change set.
- Expected files:
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`
  - `docs/harness/completed/README.md`
  - This archived plan
- Validation commands:
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`
  - `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260311-151838 .local/loop/review-20260311-151838-*.json`
  - `find docs/harness/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \\; | while read -r file; do rg -q "$file" docs/harness/completed/README.md || echo "missing:$file"; done`
  - `git diff --check`
- Documentation impact:
  - Record validation evidence, keep indexes current, and leave the plan ready for archive-before-publish workflow.
- Evidence:
  - Extended `.agents/skills/loop-review-loop/scripts/review_regression.sh` for the new final-gate contract.
  - Added `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh` to cover publish/export/final-gate/land behavior with a temporary git remote and fake `gh` surface, including:
    - publish `gh pr create` and `gh pr edit` repo-sync against remote-only base refs
    - repo-sync prune of stale remote-tracking refs
    - dirty working trees
    - active, incomplete, and stale-twin plan rejection in publish/final-gate/land
    - pending required checks
    - stale CI metadata
    - stale `origin/main` advancement after artifact creation
  - Ran one full-pr review round (`20260311-013800`), addressed the resulting correctness/docs/tests findings, reran full-pr review round `20260311-014054`, and later reran full-pr review round `20260311-151838`; both clean rounds passed with `BLOCKER=0` and `IMPORTANT=0`.
  - Archived this plan into `docs/harness/completed/` and synced the completed-plan catalog.

## Review Cadence

- Run delta review after Step 1 because it changes cross-cutting workflow and standards contracts.
- Run delta review after Step 2 because it changes stateful harness enforcement.
- Run full-pr review after Step 3 before final gate.

## Final Gate Conditions

- Shared repo-sync preflight is documented and enforced for the owned stateful gate surfaces.
- Publish/final-gate/land fail closed when plan/archive prerequisites are not satisfied.
- Final-gate machine-readable input is small, validated, and tied to the current branch/commit state.
- Required validations and review-loop regression checks pass and are recorded in the plan before archival.

## Validation Summary

- Executed `rg -n "repo-sync|active/|completed/|Acceptance Criteria|Status:" .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md docs/exec-plans/templates/execution-plan-template.md docs/harness/active/README.md docs/exec-plans/active/README.md docs/harness/completed/README.md docs/exec-plans/completed/README.md`; the documented plan/gate contract terms are present across the updated workflow and standards surfaces.
- Executed `bash -n .agents/skills/loop-publish/scripts/publish_pr.sh`, `bash -n .agents/skills/loop-final-gate/scripts/export_ci_status.sh`, `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh`, `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`, `bash -n .agents/skills/loop-land/scripts/land_preflight.sh`, and `bash -n .agents/skills/loop-review-loop/scripts/review_init.sh`; all changed shell entry points parsed cleanly.
- Executed `.agents/skills/loop-review-loop/scripts/review_regression.sh`; the review-loop and final-gate regression suite passed under the new archived-plan and CI-artifact contract, including repo-sync fetch/prune coverage for `review_init.sh`.
- Executed `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`; the targeted stateful-gate regression suite passed, covering publish repo-sync on both create/edit paths, stale remote-tracking ref pruning, active-plan rejection, incomplete archived plans, stale active twins, dirty working trees, pending required checks, stale CI metadata, stale `origin/main` advancement, and land preflight freshness.
- Executed `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260311-151838 .local/loop/review-20260311-151838-*.json`; the latest full-pr review round passed with `BLOCKER=0` and `IMPORTANT=0`.
- Executed `find docs/harness/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \\; | while read -r file; do rg -q "$file" docs/harness/completed/README.md || echo "missing:$file"; done`; the completed-plan catalog stayed in sync after archival.
- Executed `git diff --check`; no whitespace or patch-format issues were reported.
- After `origin/main` advanced to `b63054a` on 2026-03-11, moved the detached worktree state onto `codex/issue-9-12-19-stateful-gate-hardening`, rebased/recommitted the branch as `d704d4b`, then reran `git diff --check`, `.agents/skills/loop-review-loop/scripts/review_regression.sh`, and `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh` against the new base.
- After addressing the final repo-sync prune-coverage gap on 2026-03-11, reran `git diff --check`, `bash -n .agents/skills/loop-review-loop/scripts/review_regression.sh`, `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`, `.agents/skills/loop-review-loop/scripts/review_regression.sh`, `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`, and `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260311-151838 .local/loop/review-20260311-151838-*.json`; all passed on the rebased branch.

## Review Summary

- Full-pr review round `20260311-013800` initially surfaced two `IMPORTANT` findings and one `MINOR` finding:
  - `loop-review-loop/SKILL.md` had not yet been updated to mention the new repo-sync preflight required before stateful review decisions.
  - The archived-plan validator still allowed an archived completed plan when a stale same-name twin remained under the matching `active/` folder.
  - The targeted exporter regression did not yet cover the `gh pr checks` pending/exit-8 path.
- Addressed those findings by updating `loop-review-loop/SKILL.md`, tightening `stateful_gate_validate_archived_plan()` to reject stale active twins, and extending `stateful_gate_regression.sh` to cover pending required checks.
- Full-pr review round `20260311-014054` then passed with `BLOCKER=0`, `IMPORTANT=0`, `MINOR=0`, and `NIT=0`.
- After rebasing onto newer `origin/main`, full-pr review round `20260311-144141` surfaced two follow-up `IMPORTANT` findings:
  - `final_gate.sh` still allowed a dirty working tree, which meant local unpublished edits could contaminate gate/export/land evidence.
  - This archived plan still reflected the pre-rebase validation and review state rather than the refreshed branch state on top of `b63054a`.
- Addressed those follow-up findings by requiring a clean working tree in `export_ci_status.sh`, `final_gate.sh`, and `land_preflight.sh`, extending targeted regression coverage for that rule, and refreshing this archived plan with the post-rebase validation/review history.
- Later review refreshes identified and resolved three more contract/evidence gaps:
  - `review_init.sh` had not yet implemented the repo-sync preflight that workflow/standards/`loop-review-loop` had already documented.
  - `stateful_gate_regression.sh` did not yet lock publish repo-sync on the existing-PR `gh pr edit` path.
  - `stateful_gate_regression.sh` did not yet lock archived-plan rejection in `final_gate` and `land_preflight`, or stale-`origin/main` rejection after gate artifacts were minted.
- Addressed those follow-up gaps by implementing repo-sync in `review_init.sh`, extending `review_regression.sh` to prove remote refs are fetched before a review round starts, and expanding `stateful_gate_regression.sh` to cover publish create/edit repo-sync plus archived-plan/stale-main negative paths across publish/final-gate/land.
- A later regression review also pointed out that repo-sync coverage only proved new refs were fetched, not that stale remote-tracking refs were pruned.
- Addressed that final coverage gap by extending both `review_regression.sh` and `stateful_gate_regression.sh` to assert that repo-sync preflights remove stale `origin/*` refs after the upstream branches are deleted.
- Full-pr review round `20260311-151838` then passed with `BLOCKER=0`, `IMPORTANT=0`, `MINOR=0`, and `NIT=0`.

## Risks and Mitigations

- Risk: Plan-state parsing becomes too brittle for real plan variations.
- Mitigation: Standardize a minimal stable plan contract in docs/template updates and validate only those explicit fields.
- Risk: Shared gate helpers sprawl across too many scripts.
- Mitigation: Keep the new contract small and focused on repo sync, plan state, and CI/status freshness only.

## Completion Summary

- Delivered:
  - Shared repo-sync and archived-plan validation helpers for stateful publish/final-gate/land decisions.
  - A small GitHub-backed CI/status exporter directly consumable by `final_gate.sh`.
  - Fail-closed enforcement for dirty working trees, incomplete archived plans, stale active twins, stale CI metadata, pending required checks, and stale PR head/base state.
  - Repo-sync enforcement at the review-loop entry point via `review_init.sh`.
  - Workflow/standards/template updates that make the gateable plan contract explicit.
  - Regression coverage for both the review-loop/final-gate contract and the new stateful publish/export/land surface.
- Not delivered:
  - No merge/land action was executed on this branch in this loop.
- Linked issue updates:
  - Published as PR `#26` (`https://github.com/yzhang1918/missless/pull/26`) from head SHA `cf7aab6bf924d76905d2648b3e0475408108cdec`.
  - The PR body uses merge-time closing keywords for `#9`, `#12`, and `#19`.
  - Keep those issues open until land verifies the merge outcome and auto-close behavior.
- Spawned follow-up issues: None.
