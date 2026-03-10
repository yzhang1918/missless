# Post-First-Slice Harness Follow-up Capture

## Metadata

- Plan name: Post-First-Slice Harness Follow-up Capture
- Owner: Human+Codex
- Date: 2026-03-09
- Related tasks: TASK-0003
- Tracker IDs: TASK-0003, FUP-0004, FUP-0005, FUP-0006
- Triggering product slice: `docs/exec-plans/completed/2026-03-09-first-review-package-product-facing-v0.md`

## Objective

Close the documentation loop on the harness/process issues exposed by the first real product slice. This completed plan records exactly what this PR changed in harness-facing docs and workflow rules, and it separates that from the larger harness implementation work that remains deferred.

## Scope

- In scope:
  - Record the concrete loop failures and discipline gaps surfaced by the first product-slice branch.
  - Update workflow/standards docs where this PR actually changed harness-facing rules.
  - Add tracker entries so the remaining harness work survives beyond chat history.
- Out of scope:
  - Implementing reviewer retry/fallback behavior in harness code.
  - Implementing publish/final-gate hard enforcement in harness code.
  - Implementing artifact-retention enforcement in harness code.
  - Implementing rubric-based AI review in harness code.

## Acceptance Criteria

- [x] `AGENTS.md` and `.agents/skills/AGENT_LOOP_WORKFLOW.md` now state that completed plans must move from `active/` to `completed/` before publish/final gate.
- [x] `docs/harness/tracker.md` records the remaining harness follow-ups for reviewer fallback, plan-closure enforcement, and rubric-based AI review.
- [x] This completed plan distinguishes between what this PR changed and what remains deferred to a future harness implementation pass.

## What Changed in This PR

- Added explicit plan-archival requirements to `AGENTS.md`.
- Added explicit plan-archival requirements to `.agents/skills/AGENT_LOOP_WORKFLOW.md`.
- Added or refined harness tracker follow-ups so reviewer fallback, plan-closure enforcement, and rubric-based AI review stay visible after the product PR lands.
- Preserved the observed review-loop failure modes from the first product slice as durable evidence for future harness work.

## What Did Not Change in This PR

- `loop-review-loop` still does not implement fail-closed reviewer retry/fallback behavior.
- `loop-publish` and `loop-final-gate` still do not hard-enforce stale-plan rejection in code.
- Cleanup/retention behavior is still not enforced by harness code.
- Rubric-based AI review for live E2E remains backlog work.

## Observed Gaps from the First Product Slice

- Reviewer-subagent availability was noisy enough that review completion required main-agent fallback, but the harness did not treat that as a first-class contract.
- The first AI-review prompt left too much room for the reviewer to inspect repository docs and prior examples instead of staying artifact-scoped, which weakens the review contract unless the harness constrains context more tightly.
- Publish/final-gate state could drift ahead of plan completion because active-plan checkbox discipline was not enforced strongly enough.
- Completed plans could remain in `active/` even after the task was effectively done, which makes publish/final-gate state look cleaner than the repository record actually is.
- Cleanup/retention behavior was not aligned tightly enough with the files referenced by plan and final-gate artifacts.
- Real-E2E validation now needs AI review to close the loop, but the harness does not yet provide a formal rubric/reviewer stage for that path.

## Deferred Harness Follow-ups

- FUP-0004: make review-loop reviewer fallback fail closed and explicit.
- FUP-0005: enforce plan completion and archival before publish and final gate.
- FUP-0006: add rubric-based AI review for real E2E runs.

## Validation Evidence for This PR

- `AGENTS.md` now includes a `Plan archival` rule in the required workflow.
- `.agents/skills/AGENT_LOOP_WORKFLOW.md` now includes an `Archive completed plans and sync trackers` step before publish/final gate.
- `docs/harness/tracker.md` contains follow-ups `FUP-0004` through `FUP-0006`.

## Notes for the Current PR

- This completed plan is mostly documentation and workflow clarification, not harness feature implementation.
- The only harness-facing behavior change that landed here is the explicit plan-archival rule in workflow/standards docs.
- Reviewer fallback, cleanup retention, and rubric-based AI review remain deferred to a future follow-up pass.
