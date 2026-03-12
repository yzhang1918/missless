# Reviewer Contract Hardening

## Metadata

- Plan name: Reviewer Contract Hardening
- Owner: Human+Codex
- Date opened: 2026-03-13
- Intake source: GitHub issues `#11` and `#24`
- Work type: Harness/process
- Related issues:
  - `#11` Make review-loop reviewer fallback fail closed and explicit
  - `#24` Harden reviewer subagent ownership and side-effect isolation
- Scope note: This is one coherent harness task because both issues tighten the same reviewer-loop contract: expected reviewer outputs, allowed local write surface, and fail-closed behavior when that contract is violated.

## Objective

Harden the reviewer loop so each review round has one authoritative contract for which reviewer artifacts must exist and which local writes are allowed, then fail closed when reviewer output is missing or repo-observable side effects exceed that contract.

## Scope

- In scope:
  - Treat the reviewer launch manifest, or closely related round metadata, as the authoritative source for the expected reviewer set and allowed reviewer output paths for one round.
  - Make review aggregation/finalization fail closed when expected reviewer artifacts are missing, malformed, duplicated, or left incomplete.
  - Support one explicit recovery path for missing reviewer output so the reason for retry or fallback is recorded instead of being silently absorbed.
  - Detect repo-observable reviewer contract violations such as unexpected tracked worktree changes, unexpected `HEAD` movement, or undeclared reviewer outputs.
  - Update workflow docs, references, and regression coverage so the shipped contract is legible in-repo.
- Out of scope:
  - Runtime-level sandboxing, containerization, separate worktrees per reviewer, or other heavyweight isolation mechanisms.
  - Full automatic detection of remote side effects such as PR edits, issue updates, or other off-repo mutations.
  - Reviewer taxonomy, severity-model, deferred-risk-tracking, publish, or final-gate follow-ups that are not required to close `#11` and `#24`.

## Acceptance Criteria

- [x] The review round keeps one machine-readable authoritative record of the expected reviewer set and each reviewer's allowed artifact output path.
- [x] `review_aggregate.sh` and `review_finalize.sh` fail closed when any expected reviewer artifact is missing, malformed, duplicated, or incomplete, and the resulting round record makes the contract failure explicit.
- [x] The review loop exposes one explicit recovery path for missing reviewer output, and the tracked plan or PR summary records why that retry or fallback path was needed.
- [x] Reviewer execution is documented as write-scoped to its designated artifact output, and the review loop rejects repo-observable contract violations including unexpected tracked worktree changes, unexpected `HEAD` movement, or undeclared reviewer outputs.
- [x] The shipped ownership enforcement is explicitly documented as repo-observable contract checking, not as full runtime isolation or comprehensive remote side-effect detection.
- [x] `loop-review-loop`, `loop-reviewer`, manifest/output references, and regression checks stay aligned with the missing-output and side-effect-violation paths introduced by this plan.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define the authoritative reviewer-round contract so one machine-readable source names expected reviewers, allowed artifact outputs, and the repo-observable ownership boundary the review loop will enforce.
- Expected files:
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-reviewer/SKILL.md`
  - `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md`
  - `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`
  - `.agents/skills/loop-review-loop/scripts/review_init.sh`
- Validation commands:
  - `bash -n .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`
  - `bash -n .agents/skills/loop-review-loop/scripts/review_init.sh`
  - `rg -n "authoritative|allowed output|repo-observable|fallback" .agents/skills/loop-review-loop/SKILL.md .agents/skills/loop-reviewer/SKILL.md .agents/skills/loop-review-loop/references/reviewer-launch-manifest.md`
- Documentation impact:
  - Make the manifest-backed reviewer contract explicit before aggregate/finalize logic depends on it.
- Evidence:
  - Updated `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh` so each launch manifest now captures `baseline_repo_state`, `allowed_output_paths`, and reviewer prompts that explicitly forbid writes outside the designated artifact path.
  - Updated `.agents/skills/loop-review-loop/SKILL.md`, `.agents/skills/loop-reviewer/SKILL.md`, and `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md` so the manifest is documented as the authoritative round contract and reviewer ownership is expressed as declared reviewer output paths plus repo-observable drift checks rather than a full isolation guarantee.
  - Ran `bash -n .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`, `rg -n "authoritative|allowed output|repo-observable|fallback" .agents/skills/loop-review-loop/SKILL.md .agents/skills/loop-reviewer/SKILL.md .agents/skills/loop-review-loop/references/reviewer-launch-manifest.md`, and `.agents/skills/loop-review-loop/scripts/review_regression.sh`; all passed.

### Step 2

- Status: completed
- Objective: Implement the fail-closed completeness contract for issue `#11` so finalization can compare expected reviewers against produced artifacts and make retry or fallback reasons explicit.
- Expected files:
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-review-loop/references/reviewer-output-schema.md`
  - `.agents/skills/loop-review-loop/scripts/review_aggregate.sh`
  - `.agents/skills/loop-review-loop/scripts/review_finalize.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
- Validation commands:
  - `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`
  - `bash -n .agents/skills/loop-review-loop/scripts/review_finalize.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
- Documentation impact:
  - Document the fail-closed missing-output and explicit recovery semantics in the review-loop workflow and artifact contract.
- Evidence:
  - Updated `.agents/skills/loop-review-loop/scripts/review_aggregate.sh` to read the launch manifest as the authoritative expected-reviewer contract, aggregate even when zero reviewer artifacts are present, and preserve explicit contract failures plus manual-fallback recovery reasons in the aggregated review artifact.
  - Updated `.agents/skills/loop-review-loop/scripts/review_finalize.sh` and `.agents/skills/loop-review-loop/scripts/review_gate.sh` so missing reviewer artifacts now fail closed as a blocked review round instead of surfacing as a malformed review artifact.
  - Updated `.agents/skills/loop-review-loop/SKILL.md` and `.agents/skills/loop-review-loop/references/reviewer-output-schema.md` so the explicit recovery path is a designated-path manual fallback artifact with recorded `producer.reason`.
  - Ran `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_finalize.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_gate.sh`, and `.agents/skills/loop-review-loop/scripts/review_regression.sh`; all passed.

### Step 3

- Status: completed
- Objective: Implement the lightweight ownership enforcement for issue `#24` by detecting repo-observable reviewer side effects before or after reviewer execution and failing rounds that exceed the allowed local write surface.
- Expected files:
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-reviewer/SKILL.md`
  - `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md`
  - `.agents/skills/loop-review-loop/scripts/review_init.sh`
  - `.agents/skills/loop-review-loop/scripts/review_finalize.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - Any new helper kept local to `.agents/skills/loop-review-loop/scripts/`
- Validation commands:
  - `bash -n .agents/skills/loop-review-loop/scripts/review_init.sh`
  - `bash -n .agents/skills/loop-review-loop/scripts/review_finalize.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `git diff --check`
- Documentation impact:
  - Clarify that reviewer isolation is contract-based and repo-observable rather than a promise of full sandboxing.
- Evidence:
  - Extended `.agents/skills/loop-review-loop/scripts/review_aggregate.sh` so review finalization now detects undeclared reviewer outputs, tracked worktree drift after manifest preparation, and `HEAD` movement after manifest preparation, all as explicit contract violations in the aggregate artifact.
  - Extended `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh` and `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md` with an explicit machine-readable `ownership_boundary` that states the shipped enforcement is `repo-observable`, covers declared reviewer output paths plus tracked-worktree and `HEAD` drift, and does not promise arbitrary untracked-file or remote-side-effect detection.
  - Updated `.agents/skills/loop-review-loop/SKILL.md` so the workflow docs now describe reviewer ownership enforcement as repo-observable contract checking rather than full runtime sandboxing.
  - Ran `bash -n .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_finalize.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_gate.sh`, `.agents/skills/loop-review-loop/scripts/review_regression.sh`, and `git diff --check`; all passed.

## Validation Plan

- Checks to run:
  - `bash -n` for every changed `loop-review-loop` shell entry point
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `git diff --check`
- Evidence to capture:
  - Delta review after each implementation step
  - One final full-pr review round before final gate
  - Regression coverage for missing reviewer artifacts, explicit recovery/fallback recording, unauthorized output paths, unexpected worktree mutations, and unexpected `HEAD` movement
  - Tracked plan summary that explains the chosen repo-observable boundary and does not overclaim runtime-isolation guarantees

## Review Cadence

- Delta review after Step 1 because the reviewer contract and manifest wording are cross-cutting.
- Delta review after Step 2 because fail-closed completeness changes review-round gate semantics.
- Delta review after Step 3 because ownership enforcement changes stateful review behavior.
- Full-pr review before final gate after all three steps are complete.

## Final Gate Conditions

- The reviewer launch contract is documented and enforced consistently across manifest generation, reviewer instructions, aggregation, and finalization.
- Review rounds cannot pass when expected reviewer output is missing or incomplete unless the explicit recovery path ran and its reason is recorded.
- Repo-observable reviewer side effects fail the review loop instead of silently mutating the task branch.
- Regression coverage passes for both missing-output and side-effect-violation paths as well as the clean-round happy path.
- The tracked plan and PR summary describe the final contract without claiming heavyweight sandbox guarantees that were not actually implemented.

## Validation Summary

- Ran `bash -n .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_finalize.sh`, and `bash -n .agents/skills/loop-review-loop/scripts/review_gate.sh`; all changed shell entry points parsed cleanly.
- Ran `.agents/skills/loop-review-loop/scripts/review_regression.sh`; it passed after adding manifest contract coverage, missing-reviewer fail-closed coverage, manual-fallback recovery coverage, undeclared reviewer output detection, tracked worktree drift detection, and `HEAD` movement detection.
- Ran `git diff --check`; no whitespace or patch-format issues were reported.
- Ran the completed-plan catalog sync check from `docs/harness/completed/README.md`; no missing completed-plan entries remained after restoring the previously omitted `2026-03-12-harness-closeout-reliability.md` entry and adding this plan.

## Review Summary

- Delta review round `20260312-164026` passed with `BLOCKER=0` and `IMPORTANT=0`.
- Full-pr review round `20260312-164223` passed with `BLOCKER=0` and `IMPORTANT=0`.
- Reviewer explorer threads were unreliable in this session, so both clean review rounds used explicit manual-fallback reviewer artifacts with recorded `producer.reason` values. The tracked record keeps the clean outcomes here while the `.local/loop` review artifacts remain ephemeral process state.
- One earlier docs/spec consistency review surfaced an `IMPORTANT` gap: the docs overstated ownership enforcement by implying arbitrary untracked-file isolation. The implementation and docs were tightened so the shipped boundary is now explicitly limited to declared reviewer output paths plus repo-observable tracked-worktree and `HEAD` drift.

## Risks and Mitigations

- Risk: Ownership enforcement grows into an oversized isolation project.
- Mitigation: Keep the first implementation limited to repo-observable state checks and explicit reviewer output contracts.
- Risk: Fail-closed completeness rules make noisy reviewer availability too cumbersome to recover from.
- Mitigation: Provide one explicit retry or fallback path that still leaves authoritative evidence and a recorded reason.
- Risk: Manifest, skill docs, and regression fixtures drift apart as the reviewer contract changes.
- Mitigation: Update references, workflow docs, and regression checks in the same step as each contract change.

## Completion Summary

- Delivered:
  - Launch manifests now act as the authoritative machine-readable reviewer-round contract, including baseline repo state, declared reviewer output paths, and an explicit repo-observable ownership boundary.
  - Review aggregation/finalization now fail closed when expected reviewer artifacts are missing and preserve explicit manual-fallback recovery reasons in the aggregate artifact.
  - Review ownership enforcement now detects undeclared reviewer output paths, tracked worktree drift after manifest preparation, and `HEAD` movement after manifest preparation.
  - Review docs, manifest/output references, and regression coverage now match the shipped reviewer-contract behavior.
- Not delivered:
  - No runtime-level sandboxing or comprehensive remote-side-effect detection was added in this plan.
- Linked issue updates:
  - Not yet synced back to GitHub issues `#11` and `#24`; update them during publish and closeout.
- Spawned follow-up issues:
  - None yet.
