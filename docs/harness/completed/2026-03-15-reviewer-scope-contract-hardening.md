# Reviewer Scope Contract Hardening

## Metadata

- Plan name: Reviewer Scope Contract Hardening
- Owner: Human+Codex
- Date opened: 2026-03-15
- Date completed: 2026-03-15
- Intake source: direct follow-up discovered during subagent full-pr review on
  the branch for issue `#29`
- Work type: Harness/process
- Related issues:
  - direct request (no issue)
- Scope note: This is a small harness closeout that tightens one shipped
  reviewer-round contract after isolated reviewer feedback exposed a missing
  fail-closed check.

## Objective

Make `loop-review-loop` fail closed when a reviewer artifact's declared
`scope` does not match the launch manifest, and record that harness contract in
the correct repository history lane.

## Scope

- In scope:
  - Reject reviewer artifacts whose `payload.scope` differs from the manifest
    scope during aggregate/finalize.
  - Record `contract.scope_mismatches` in the aggregate review artifact.
  - Extend harness regression coverage for the new fail-closed path.
  - Update harness workflow docs so the contract is legible in-repo.
- Out of scope:
  - Reviewer taxonomy changes.
  - New reviewer isolation mechanisms beyond the existing repo-observable
    contract.
  - Product CLI or provenance contract changes unrelated to reviewer-scope
    enforcement.

## Acceptance Criteria

- [x] `review_aggregate.sh` treats reviewer artifact scope mismatches as
      contract violations.
- [x] `review_finalize.sh` fails closed when a reviewer artifact with the wrong
      scope tries to satisfy a manifest slot.
- [x] The aggregate review artifact records scope mismatches explicitly under
      `contract.scope_mismatches`.
- [x] Harness docs and completed-plan history record the new scope-mismatch
      contract in `docs/harness/`.
- [x] `.agents/skills/loop-review-loop/scripts/review_regression.sh` passes
      with a regression that covers the new fail-closed path.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Tighten the reviewer aggregate contract, add regression coverage,
  and archive the harness change in the proper documentation lane.
- Expected files:
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-review-loop/scripts/review_aggregate.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `docs/harness/completed/2026-03-15-reviewer-scope-contract-hardening.md`
  - `docs/harness/completed/README.md`
- Validation commands:
  - `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `git diff --check`
- Documentation impact:
  - Record the scope-mismatch contract in harness workflow docs and completed
    harness history rather than only in a product execution record.
- Evidence:
  - Updated `review_aggregate.sh` so reviewer artifacts whose declared
    `scope` differs from the launch manifest now surface as explicit contract
    violations and block finalization.
  - Updated `loop-review-loop/SKILL.md` to describe the new fail-closed scope
    mismatch behavior.
  - Extended `review_regression.sh` with a scope-mismatch case; the regression
    suite passed locally.

## Validation Summary

- `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh` passed.
- `.agents/skills/loop-review-loop/scripts/review_regression.sh` passed.
- `git diff --check` passed on the working tree after the harness update.

## Review Summary

- This harness follow-up was discovered by isolated subagent review while the
  branch was being prepared for PR publication.
- The shipped result keeps reviewer ownership enforcement repo-observable, but
  now also rejects reviewer artifacts whose declared scope does not match the
  launch manifest.

## Completion Summary

- Delivered:
  - Scope-mismatched reviewer artifacts now fail closed.
  - Aggregate review artifacts now expose `contract.scope_mismatches`.
  - Harness docs and completed-plan history now record the reviewer-scope
    contract in the correct repository lane.
- Not delivered:
  - No broader reviewer isolation or runtime sandboxing changes were added.
