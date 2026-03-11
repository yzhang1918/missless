# Reviewer Spawn Helper

## Metadata

- Plan name: Reviewer Spawn Helper
- Owner: Human+Codex
- Date opened: 2026-03-11
- Date completed: 2026-03-11
- Intake source: issue `#10`
- Work type: harness/process
- GitHub repository: `yzhang1918/missless`
- Related issue(s): `#10`

## Objective

Add a repository-local helper that turns a selected review dimension list into a runtime-agnostic reviewer launch manifest so `loop-review-loop` orchestration is less manual without hardcoding a reviewer taxonomy or changing review gate semantics.

## Scope

- In scope:
  - Add a helper script under `loop-review-loop` that emits a JSON manifest for selected reviewer dimensions.
  - Standardize manifest entries so each reviewer includes a stable output path and launch-ready `loop-reviewer` prompt text.
  - Update `loop-review-loop` and `loop-reviewer` docs for the new helper path.
  - Add targeted validation coverage for the helper path alongside the existing review-loop regression checks.
- Out of scope:
  - Fail-closed reviewer fallback or retry semantics from issue `#11`.
  - Review severity, blocker-vs-strategic, or taxonomy changes from issue `#22`.
  - Accepted deferred risk tracking changes from issue `#20`.
  - Final-gate or publish enforcement changes from issues `#9`, `#12`, and `#19`.
  - Product runtime or live E2E AI review work.

## Acceptance Criteria

- [x] `loop-review-loop` includes a helper that accepts `round-id`, `scope`, and selected dimensions, then emits a JSON reviewer manifest.
- [x] The helper keeps dimension selection configurable by treating dimensions as free-form values rather than a fixed registry.
- [x] Each manifest entry includes the selected dimension, a normalized output artifact path, a standard reviewer prompt, and an optional `focus` field when provided.
- [x] `loop-review-loop` and `loop-reviewer` documentation describe the helper path and keep reviewer schema/gate semantics unchanged.
- [x] Validation covers the helper path with at least one targeted dry-run or regression-style script check in addition to `git diff --check` and `.agents/skills/loop-review-loop/scripts/review_regression.sh`.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define and implement the reviewer-manifest helper contract so the launch surface is deterministic, runtime-agnostic, and compatible with the existing reviewer artifact schema.
- Expected files:
  - `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-reviewer/SKILL.md`
  - Helper-path docs or references directly needed by the new script
- Validation commands:
  - Targeted helper dry run with representative dimensions and optional focus input
  - `git diff --check`
- Documentation impact:
  - Document the helper as the preferred way to prepare reviewer launches while preserving dynamic dimension selection.
- Exit criteria:
  - A contributor can run one command and receive a JSON manifest with launch-ready reviewer entries for the chosen dimensions.
- Validation evidence:
  - Added `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh` plus `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md`.
  - Updated `.agents/skills/loop-review-loop/SKILL.md`, `.agents/skills/loop-reviewer/SKILL.md`, and the related `agents/openai.yaml` prompts to describe the helper-generated launch path.
  - Ran a targeted helper dry run for round `20260311-101500` with `security`, `docs/spec consistency`, and `correctness`; the manifest emitted three reviewer entries with stable output paths and optional focus only on `security`.
  - Ran `git diff --check`.

### Step 2

- Status: completed
- Objective: Add regression coverage for the helper path so manifest shape, prompt content, and input validation remain stable as the review loop evolves.
- Expected files:
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - Any helper-specific script fixtures kept local to `loop-review-loop`
- Validation commands:
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - Any helper-specific dry-run check added in this step
- Documentation impact:
  - Record the helper-path validation command where reviewers of the harness would expect it.
- Exit criteria:
  - Regression checks fail on malformed helper inputs and pass on a valid manifest-generation path.
- Validation evidence:
  - Expanded `.agents/skills/loop-review-loop/scripts/review_regression.sh` to cover invalid helper inputs, manifest content, prompt generation, and cleanup of launch manifests.
  - Updated `.agents/skills/loop-review-loop/scripts/review_cleanup.sh` so helper-generated launch manifests are treated as ephemeral loop artifacts.
  - Ran `.agents/skills/loop-review-loop/scripts/review_regression.sh` and it passed.

### Step 3

- Status: completed
- Objective: Run the required validations, summarize the review outcome, sync issue state, and archive the completed harness plan.
- Expected files:
  - `docs/harness/active/2026-03-11-reviewer-spawn-helper.md`
  - `docs/harness/completed/2026-03-11-reviewer-spawn-helper.md`
  - `docs/harness/completed/README.md`
- Validation commands:
  - `git diff --check`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - Completed-plan catalog sync check from `docs/harness/completed/README.md`
- Documentation impact:
  - Preserve the delivered scope, validation evidence, and linked issue update in the completed harness history.
- Exit criteria:
  - The harness plan is archived under `completed/`, cataloged, and the linked GitHub issue records the plan/execution result.
- Validation evidence:
  - Archived the plan to `docs/harness/completed/2026-03-11-reviewer-spawn-helper.md` and added the catalog entry in `docs/harness/completed/README.md`.
  - Ran `git diff --check`.
  - Ran `.agents/skills/loop-review-loop/scripts/review_regression.sh` after archival and it passed.
  - Ran the completed-plan catalog sync check from `docs/harness/completed/README.md`; it produced no missing entries.
  - Added an execution update comment to issue `#10`: `https://github.com/yzhang1918/missless/issues/10#issuecomment-4035597587`.

## Review Cadence

- Run delta review after the helper contract and validation coverage are in place.
- Run full-PR review once the plan, docs, and helper changes are complete.

## Validation Plan

- Required checks:
  - `git diff --check`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - One targeted helper dry run that exercises multi-dimension manifest output and at least one optional `focus` value
- Evidence to capture:
  - Manifest-generation output path and key fields from the helper dry run
  - Regression-script pass result
  - Review round IDs and disposition once review-loop runs complete

## Risks and Mitigations

- Risk: The helper accidentally encodes a fixed reviewer taxonomy and makes dynamic selection harder.
  - Mitigation: Treat dimensions as free-form manifest inputs and keep prompt generation template-based.
- Risk: Prompt generation broadens the reviewer contract beyond the current schema or gate expectations.
  - Mitigation: Reuse the existing `loop-reviewer` contract and scope the helper to launch preparation only.
- Risk: Runtime-specific launch assumptions leak into the helper and make it less portable for non-Codex contributors.
  - Mitigation: Emit JSON manifest data and prompt text only; leave actual agent spawning to the caller/runtime.

## Final Gate Conditions

- All acceptance criteria above are checked.
- Helper validation and `review_regression.sh` both pass.
- No blocking review findings remain open.
- Completed harness history and issue links reflect the delivered scope without widening into the deferred review-contract issues.

## Validation Summary

- Ran a targeted helper dry run for round `20260311-101500`; the generated manifest path was `.local/loop/review-launch-20260311-101500.json`, with reviewer entries for `security`, `docs/spec consistency`, and `correctness`, and optional focus only on `security`.
- Ran `.agents/skills/loop-review-loop/scripts/review_regression.sh`; it passed.
- Ran `git diff --check`; no whitespace or patch-format issues were reported.
- Ran the completed-plan catalog sync check from `docs/harness/completed/README.md`; it reported no missing catalog entries.

## Review Summary

- Delta review round `20260311-014043` passed with `BLOCKER=0`, `IMPORTANT=0`.
- Full-PR review round `20260311-014303` passed with `BLOCKER=0`, `IMPORTANT=0`.
- After the completed-plan record changed, reran full-PR review round `20260311-014409`; it passed with `BLOCKER=0`, `IMPORTANT=0`.
- Reviewer subagent spawning was unstable in this session, so the review rounds used explicit manual fallback reviewer artifacts after `spawn_agent` attempts aborted; the fallback reviews found and fixed one docs-path inconsistency (`<dimension>` vs `<dimension-slug>`) before the final full-PR rerun.
- Retained review artifact: `.local/loop/review-20260311-014409.json`.

## Completion Summary

- Delivered:
  - Added `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh` to emit runtime-agnostic reviewer launch manifests for selected dimensions.
  - Added `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md` to document the manifest contract and usage.
  - Updated `loop-review-loop`, `loop-reviewer`, and their `agents/openai.yaml` prompts so the new helper path is explicit while reviewer schema and gate semantics stay unchanged.
  - Expanded `review_regression.sh` and `review_cleanup.sh` to validate and clean up helper-generated launch manifests.
  - Archived the completed harness plan and synced the result back to issue `#10`.
- Not delivered:
  - No runtime-specific subagent launcher was added inside repository scripts; actual spawning remains caller/runtime-owned by design.
  - No changes were made to fail-closed reviewer fallback semantics, reviewer taxonomy, deferred-risk tracking, or publish/final-gate enforcement.
- Linked issue updates:
  - Commented on issue `#10` with the completed plan path, validation summary, and review disposition: `https://github.com/yzhang1918/missless/issues/10#issuecomment-4035597587`.
- Spawned follow-up issues:
  - None.
