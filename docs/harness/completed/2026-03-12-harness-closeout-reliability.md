# Harness Closeout Reliability

## Metadata

- Plan name: Harness Closeout Reliability
- Owner: Human+Codex
- Date opened: 2026-03-12
- Intake source: GitHub issues `#31`, `#32`, and `#34`
- Work type: Harness/process
- Related issues:
  - `#31` Retain plan-referenced review and final-gate artifacts during cleanup
  - `#32` Add repository-readiness preflight before publish and final gate
  - `#34` Make landing workflow worktree-aware in multi-worktree repos
- Scope note: This is one coherent harness task because all three issues tighten the same closeout surface: summary-first evidence, gate-readiness checks, and landing semantics after final gate.

## Objective

Make the closeout path easier to trust and inspect by keeping git-tracked plan and PR records summary-first, retaining one obvious local final-evidence bundle per plan, failing publish/final-gate early when the repository is not ready, and treating remote merge success as authoritative even when local worktree cleanup is imperfect.

## Scope

- In scope:
  - Define a summary-first evidence contract for future tracked plan and PR records so they record gate results, key commands, final conclusions, and at most a small number of notable resolved findings instead of treating `.local/loop/*.json` paths as durable evidence.
  - Promote the final clean `review aggregate`, `ci-status`, and `final-gate` artifacts into `.local/final-evidence/<plan-slug>/`, with stable filenames and overwrite semantics so only the latest passing bundle is retained for a plan.
  - Add an explicit repository-readiness preflight entry point and reuse the same readiness checks inside `loop-publish` and `loop-final-gate`.
  - Fail publish and final-gate early when readiness checks report a non-gate-ready repository, including required-check and Actions-policy problems that would otherwise surface too late.
  - Make `loop-land` explicitly worktree-aware so remote merge success remains the landing result while local cleanup failures are downgraded to warnings.
  - Add regression coverage and workflow documentation that match the shipped contract.
- Out of scope:
  - Backfilling historical completed plans that already reference deleted `.local/loop` artifacts.
  - Keeping every review round or every intermediate gate artifact.
  - Introducing a git-tracked evidence store or a new top-level artifact directory.
  - Expanding this plan to unrelated harness follow-ups such as PR review-thread capture or broader janitor refactors.

## Acceptance Criteria

- [x] Workflow and skill docs define future tracked plan and PR records as summary-first evidence, with git-tracked summaries instead of durable `.local/loop/*.json` references and optional notable resolved findings only when they materially shaped the final outcome.
- [x] After a passing final gate, the latest `review aggregate`, `ci-status`, and `final-gate` JSON artifacts are promoted into `.local/final-evidence/<plan-slug>/`, where `<plan-slug>` is derived from the plan filename without `.md`.
- [x] The promoted final-evidence bundle uses stable filenames and overwrite semantics so each plan keeps only one latest passing bundle.
- [x] Cleanup scripts continue removing ephemeral `.local/loop` artifacts but never delete promoted `.local/final-evidence/` bundles.
- [x] A reusable repository-readiness preflight command exists, and `loop-publish` plus `loop-final-gate` both reuse the same readiness checks rather than maintaining divergent gate logic.
- [x] Readiness preflight fails closed for gate-critical problems, including detached or non-`codex/*` branch state, stale base sync, missing required checks, and incompatible GitHub Actions policy.
- [x] `loop-land` treats remote merge success as landing success in multi-worktree repositories and records any local cleanup or branch-switch limitations as warnings rather than merge failures.
- [x] Targeted regression coverage and review evidence exercise final-evidence promotion, readiness blocking, and worktree-aware landing semantics without intentionally spawning new follow-up issues.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define the closeout contract in docs and skill instructions so summary-first tracked evidence, local final-evidence retention, readiness preflight usage, and remote-merge-success landing semantics are explicit before script changes land.
- Expected files:
  - `.agents/skills/AGENT_LOOP_WORKFLOW.md`
  - `docs/standards/repository-standards.md`
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-publish/SKILL.md`
  - `.agents/skills/loop-final-gate/SKILL.md`
  - `.agents/skills/loop-land/SKILL.md`
- Validation commands:
  - `rg -n "summary-first|final-evidence|readiness preflight|remote merge|warning" .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md .agents/skills/loop-review-loop/SKILL.md .agents/skills/loop-publish/SKILL.md .agents/skills/loop-final-gate/SKILL.md .agents/skills/loop-land/SKILL.md`
- Documentation impact:
  - The repository workflow and skill surfaces state the new evidence, readiness, and landing contract consistently before execution logic depends on it.
- Evidence:
  - Updated `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `docs/standards/repository-standards.md`, `.agents/skills/loop-review-loop/SKILL.md`, `.agents/skills/loop-publish/SKILL.md`, `.agents/skills/loop-final-gate/SKILL.md`, and `.agents/skills/loop-land/SKILL.md` so summary-first tracked evidence, `.local/final-evidence/<plan-slug>/` retention, explicit readiness preflight, and remote-merge-success landing semantics are aligned.
  - Validated the wording contract with `rg -n "summary-first|final-evidence|readiness preflight|remote merge|warning" .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md .agents/skills/loop-review-loop/SKILL.md .agents/skills/loop-publish/SKILL.md .agents/skills/loop-final-gate/SKILL.md .agents/skills/loop-land/SKILL.md`.

### Step 2

- Status: completed
- Objective: Implement the reusable repository-readiness preflight and final-evidence promotion flow so publish and final-gate fail early on non-ready repositories while passing gate output is retained in one obvious local bundle per plan.
- Expected files:
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh`
  - `.agents/skills/loop-final-gate/scripts/export_ci_status.sh`
  - `.agents/skills/loop-final-gate/scripts/final_gate.sh`
  - `.agents/skills/loop-publish/scripts/publish_pr.sh`
  - `.agents/skills/loop-review-loop/scripts/review_cleanup.sh`
  - `.agents/skills/loop-final-gate/scripts/repository_readiness_preflight.sh`
  - `.agents/skills/loop-final-gate/scripts/promote_final_evidence.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`
- Validation commands:
  - `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/export_ci_status.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`
  - `bash -n .agents/skills/loop-publish/scripts/publish_pr.sh`
  - `bash -n .agents/skills/loop-review-loop/scripts/review_cleanup.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/repository_readiness_preflight.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/promote_final_evidence.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`
- Documentation impact:
  - Updated skill docs must stay aligned with the new shared readiness entry point and the final-evidence promotion behavior.
- Evidence:
  - Added one shared repository-readiness preflight entry point plus shared helper enforcement in publish, CI export, and final gate so detached/non-`codex/*` state, dirty worktrees, stale base sync, missing required checks, disabled Actions, unsupported `allowed_actions=selected`, and local-only policy mismatches all fail before late-stage gating.
  - Added final-evidence promotion into `.local/final-evidence/<plan-slug>/` with stable filenames for `review.json`, `ci-status.json`, and `final-gate.json`, and refreshed the retained final-gate copy after injecting `retained_evidence_dir` metadata.
  - Strengthened regression coverage with direct preflight negatives, caller-specific publish/export-ci/final-gate negatives, retained-bundle overwrite checks, and review-cleanup coverage that leaves promoted final evidence intact.
  - Resolved one notable correctness finding during delta review by making readiness fail closed when the repository Actions permissions payload reports `enabled=false`; reran syntax plus regression checks and closed the step with a clean delta review summary.
  - Used manual fallback reviewer artifacts for the final clean Step 2 delta review after subagent thread-capacity limits blocked additional reviewer slots; the tracked record keeps the clean outcome here while the local review round remains ephemeral process state under the new evidence contract.

### Step 3

- Status: completed
- Objective: Make the landing workflow worktree-aware, lock the merge-versus-cleanup success semantics in tests and docs, and keep the plan/issue record aligned with the new no-new-follow-up scope.
- Expected files:
  - `.agents/skills/loop-land/SKILL.md`
  - `.agents/skills/loop-land/scripts/land_preflight.sh`
  - `.agents/skills/loop-land/scripts/land_merge.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`
  - `docs/harness/active/README.md`
  - This plan
- Validation commands:
  - `bash -n .agents/skills/loop-land/scripts/land_preflight.sh`
  - `bash -n .agents/skills/loop-land/scripts/land_merge.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`
  - `git diff --check`
- Documentation impact:
  - The landing contract, active-plan guidance, and tracked execution record reflect remote-merge-success semantics plus the decision not to spawn new follow-up issues for this slice.
- Evidence:
  - Added `.agents/skills/loop-land/scripts/land_merge.sh` so landing now verifies fresh preconditions, chooses a repository-compatible merge method, records a local landing artifact, and treats verified remote merge success as the landing outcome even when local cleanup stays deferred.
  - Updated landing behavior so local cleanup is explicitly worktree-aware: non-zero `gh pr merge` exits after a matching remote merge become warnings, the current worktree may remain on the merged `codex/*` branch, and remote-tracking cleanup is checked separately instead of being conflated with merge success.
  - Extended `stateful_gate_regression.sh` to cover auto-selected merge methods, blocked repository-disallowed merge methods, remote merge success with deferred local cleanup, non-zero `gh pr merge` exits after remote success, and failure when a merge command never produces a real merged PR state.
  - Updated `.agents/skills/loop-land/SKILL.md` and `docs/harness/active/README.md` so the loop-land invocation shape, summary-first landing record, and remote-merge-success/warning semantics are documented consistently.
  - Closed the step with a clean delta review after aligning the helper contract and regression coverage; refreshed the final correctness/architecture reviewer artifacts in the main workspace because the new `land_merge.sh` file disappeared during reviewer subagent workspace sync while it was still untracked.

## Validation Plan

- Checks to run:
  - `bash -n` for every changed shell entry point
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`
  - `git diff --check`
- Evidence to capture:
  - Delta review after each implementation step
  - One final full-pr review round before final gate
  - A promoted final-evidence bundle at `.local/final-evidence/<plan-slug>/` containing the latest passing `review aggregate`, `ci-status`, and `final-gate` artifacts
  - Tracked plan summary that records gate result, key commands, final conclusion, and only notable resolved findings when they materially changed the shipped outcome

## Review Cadence

- Delta review after Step 1 because the contract changes touch multiple workflow and standards surfaces.
- Delta review after Step 2 because shared readiness and evidence-retention logic affects publish, final-gate, and cleanup behavior.
- Delta review after Step 3 if the landing helper or semantics change beyond the original plan shape.
- Full-pr review before final gate after all three steps are complete.

## Final Gate Conditions

- Future-facing workflow and skill docs consistently describe summary-first tracked evidence, `.local/final-evidence/<plan-slug>/` promotion, and worktree-aware landing semantics.
- Publish and final-gate both fail early on the agreed repository-readiness blockers through one shared readiness contract.
- Passing final-gate output promotes exactly one latest final-evidence bundle per plan and cleanup leaves that bundle intact.
- Landing separates remote merge outcome from optional local cleanup, with remote merge success treated as the landing result.
- Required validation and review-loop evidence pass without intentionally creating new follow-up issues for this scope.

## Validation Summary

- Ran `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_lib.sh`, `bash -n .agents/skills/loop-final-gate/scripts/repository_readiness_preflight.sh`, `bash -n .agents/skills/loop-final-gate/scripts/promote_final_evidence.sh`, `bash -n .agents/skills/loop-final-gate/scripts/export_ci_status.sh`, `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`, `bash -n .agents/skills/loop-publish/scripts/publish_pr.sh`, `bash -n .agents/skills/loop-land/scripts/land_preflight.sh`, `bash -n .agents/skills/loop-land/scripts/land_merge.sh`, `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`, and `bash -n .agents/skills/loop-review-loop/scripts/review_regression.sh`; all changed shell entry points parsed cleanly.
- Ran `.agents/skills/loop-review-loop/scripts/review_regression.sh` and `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`; both passed after the readiness, final-evidence, and worktree-aware landing changes were in place.
- Closed clean Step 2 and Step 3 delta reviews plus one clean full-pr review. Manual reviewer artifacts were used for the clean review rounds because subagent thread capacity stayed constrained during this loop.
- Did not run publish or final gate in this turn because the branch has not been pushed to a PR yet; final-evidence promotion therefore remains ready-but-not-executed for this branch until publish/final-gate time.

## Risks and Mitigations

- Risk: The new final-evidence retention path could become another confusing pile of local artifacts.
- Mitigation: Keep a single stable directory per plan under `.local/final-evidence/` and overwrite older passing bundles instead of timestamping them.
- Risk: Readiness checks could grow beyond gate-critical blockers and make publish/final-gate cumbersome.
- Mitigation: Limit the preflight to failures that invalidate publish or final-gate decisions, and keep remediation messages explicit in scripts and regression coverage.
- Risk: Worktree-aware landing may drift from actual `gh pr merge` behavior if the helper only documents semantics without enforcing them.
- Mitigation: Wrap the merge path in a dedicated helper and regression-test remote-merge success plus local-cleanup-warning scenarios.

## Completion Summary

- Delivered:
  - Summary-first evidence contract updates across workflow docs and skills.
  - Shared repository-readiness preflight plus fail-closed readiness reuse in publish, CI export, and final gate.
  - Final-evidence promotion into `.local/final-evidence/<plan-slug>/` with stable overwrite semantics.
  - Worktree-aware `land_merge.sh` that keeps verified remote merge success authoritative and records local cleanup as warnings.
  - Expanded regression coverage for readiness blockers, retained-bundle overwrite behavior, cleanup retention, and landing success-versus-cleanup semantics.
- Not delivered:
  - Publish, PR sync, final gate, and actual landing were not run in this turn.
- Linked issue updates:
  - Not yet synced back to GitHub issues `#31`, `#32`, and `#34` because this branch has not been published and linked from a PR yet.
- Spawned follow-up issues:
  - None.
