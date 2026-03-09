# Post-First-Slice Loop Remediation

## Metadata

- Plan name: Post-First-Slice Loop Remediation
- Owner: Human+Codex
- Date: 2026-03-09
- Related tasks: TASK-0003
- Tracker IDs: TASK-0003, FUP-0004, FUP-0005, FUP-0006
- Triggering product slice: `docs/exec-plans/active/2026-03-09-product-facing-v0-remediation.md`

## Objective

Capture the harness/process gaps exposed by the first real product slice so they are ready for a later harness pass. This document is intentionally documentation-first for the current PR: it defines what the next harness iteration must fix, but it does not authorize harness implementation work in this branch beyond tracker/doc updates.

## Scope

- In scope:
  - Record the concrete loop failures and discipline gaps surfaced by PR #8.
  - Define the future harness work needed to make review, publish, and final-gate behavior fail-closed.
  - Add tracker entries so the issues survive beyond chat history.
- Out of scope:
  - Editing harness skills or scripts in this PR.
  - Reworking subagent orchestration or automation in this PR.

## Acceptance Criteria

- [x] The harness tracker links to this plan from the post-first-slice ergonomics task.
- [x] Reviewer no-response handling is explicitly captured as a future fail-closed requirement.
- [x] Plan-completion discipline before publish/final gate is explicitly captured as a future harness requirement.
- [x] Artifact-retention rules are explicitly captured so cleanup does not remove files still referenced by plans or gates.
- [x] Rubric-based AI review is recorded as backlog, not forgotten in chat history.

## Observed Gaps from the First Product Slice

- Reviewer-subagent availability was noisy enough that review completion required main-agent fallback, but the harness did not treat that as a first-class contract.
- The first AI-review prompt left too much room for the reviewer to inspect repository docs and prior examples instead of staying artifact-scoped, which weakens the review contract unless the harness constrains context more tightly.
- Publish/final-gate state could drift ahead of plan completion because active-plan checkbox discipline was not enforced strongly enough.
- Cleanup/retention behavior was not aligned tightly enough with the files referenced by plan and final-gate artifacts.
- Real-E2E validation now needs AI review to close the loop, but the harness does not yet provide a formal rubric/reviewer stage for that path.

## Work Breakdown

### Step 1

- Status: ready
- Objective: Make review-loop fallback explicit and fail-closed.
- Key changes for the future harness pass:
  - Require retry or fallback when reviewer agents do not return.
  - Require recorded evidence explaining which fallback path was used.
  - Prevent silent success when reviewer JSON is missing.
- Expected files:
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-reviewer/`
- Exit criteria for the future harness pass:
  - Missing reviewer output becomes a handled event with evidence, not an implicit pass.

### Step 2

- Status: ready
- Objective: Tighten publish/final-gate discipline around active plans.
- Key changes for the future harness pass:
  - Require active plan statuses and acceptance checkboxes to be current before publish/final gate passes.
  - Refuse to treat a branch as gate-ready when the active plan still misstates completion.
  - Make tracker updates part of the same close-the-loop requirement.
- Expected files:
  - `.agents/skills/loop-publish/SKILL.md`
  - `.agents/skills/loop-final-gate/SKILL.md`
  - `.agents/skills/AGENT_LOOP_WORKFLOW.md`
- Exit criteria for the future harness pass:
  - Publish/final-gate cannot outrun the active plan and tracker state.

### Step 3

- Status: ready
- Objective: Protect evidence artifacts referenced by plans and gates.
- Key changes for the future harness pass:
  - Define retention rules for review and final-gate artifacts that are still referenced by active/completed plans.
  - Prevent cleanup from deleting current evidence that the branch narrative still depends on.
- Expected files:
  - `.agents/skills/loop-final-gate/`
  - `.agents/skills/loop-janitor/`
- Exit criteria for the future harness pass:
  - Cleanup behavior cannot remove artifacts still serving as branch evidence.

### Step 4

- Status: ready
- Objective: Add a formal rubric-based AI review stage for real-E2E runs.
- Key changes for the future harness pass:
  - Define a reusable rubric for judging review-package quality.
  - Allow live-E2E runs to attach AI review evidence without relying on human judgment.
  - Keep this rubric generic enough to survive future backend expansion.
  - Keep reviewer context artifact-scoped so reviewers do not read unrelated repo docs or prior runs to infer the review contract.
- Expected files:
  - `.agents/skills/loop-review-loop/`
  - `docs/harness/tracker.md`
- Exit criteria for the future harness pass:
  - Real-E2E review can close the loop with an explicit AI-review contract instead of ad-hoc prompting.

## Validation Strategy for the Future Harness Pass

- Reproduce the first-slice failure modes in a controlled way.
- Prove reviewer fallback paths with dedicated harness tests or controlled dry runs.
- Verify that publish/final-gate refuses stale plan state.
- Verify that cleanup retains artifacts referenced by the active branch evidence.

## Notes for the Current PR

- This harness plan is documentation-only in the current branch.
- Product remediation work remains the active implementation priority.
- Documentation capture for this plan is complete in PR `#8`; the implementation work remains deferred to a future harness pass.
