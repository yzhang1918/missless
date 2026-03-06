# Evidence Contract and First Delivery Slice

## Metadata

- Plan name: Evidence Contract and First Delivery Slice
- Owner: Human+Codex
- Date: 2026-03-06
- Related tasks: TASK-0001, TASK-0002
- Tracker IDs: TASK-0001, TASK-0002

## Objective

Convert the approved evidence-anchor discovery into repository source-of-truth docs, then define the first implementation slice and acceptance bar without committing runtime code yet.

## Scope

- In scope:
  - Lock the baseline evidence contract around first-class `Segment` objects for text sources.
  - Align design and spec docs on `candidate -> validate -> refine -> materialize`.
  - Define the first delivery slice, quality bar, and explicit out-of-scope items.
  - Record the design decision and sync tracker state.
- Out of scope:
  - Runtime ingestion, extraction, review, or persistence code.
  - Non-text source locator contracts (`audio`, `video`, `pdf` page/time variants).
  - Refresh/re-ingest/versioned source updates.
  - External-page deep-linking as a correctness requirement.
  - Evidence-role taxonomies beyond unordered `Segment` references.

## Acceptance Criteria

- [x] `docs/design-docs/system-design.md` states that text-source evidence uses independent `Segment` objects rather than optional embedded-only anchors.
- [x] `docs/specs/core-data-model.md` defines `Segment` identity via a validated locator and models `Atom` evidence as a list of `Segment` references.
- [x] `docs/specs/pipeline-contracts.md` defines the evidence loop as `candidate -> validate -> refine -> materialize`, including the `needs_review` fallback when validation cannot be resolved.
- [x] `docs/product-specs/product-foundation.md` defines the first delivery slice and acceptance bar around canonical text, extraction, anchored evidence, and human review.
- [x] `docs/design-docs/decision-log.md` records the evidence-contract decision and its main consequences.
- [x] `docs/exec-plans/tracker.md` links this plan and reflects the current status of TASK-0001 and TASK-0002.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Align design/spec docs on the chosen evidence-anchor representation profile.
- Expected files:
  - `docs/design-docs/system-design.md`
  - `docs/specs/core-data-model.md`
  - `docs/specs/pipeline-contracts.md`
  - `docs/design-docs/decision-log.md`
- Validation commands:
  - `rg -n "Segment|candidate -> validate -> refine -> materialize|needs_review|validated locator|prefix|suffix|char_range" docs/design-docs/system-design.md docs/specs/core-data-model.md docs/specs/pipeline-contracts.md docs/design-docs/decision-log.md`
- Documentation impact:
  - Convert the open evidence-model choice into an explicit draft contract.
  - Record the decision in the active design log.
- Evidence:
  - Updated `system-design.md`, `core-data-model.md`, `pipeline-contracts.md`, and `decision-log.md` to make `Segment` first-class for text sources and to codify `candidate -> validate -> refine -> materialize`.
  - Validated with `rg -n "Segment|candidate -> validate -> refine -> materialize|needs_review|validated locator|prefix|suffix|char_range" docs/design-docs/system-design.md docs/specs/core-data-model.md docs/specs/pipeline-contracts.md docs/design-docs/decision-log.md`.

### Step 2

- Status: completed
- Objective: Define the first delivery slice and acceptance bar using the approved evidence contract as a constraint.
- Expected files:
  - `docs/product-specs/product-foundation.md`
  - `docs/specs/pipeline-contracts.md`
  - `docs/design-docs/system-design.md`
- Validation commands:
  - `rg -n "First Delivery Slice|Acceptance Bar|text-first|canonical normalized text snapshot|internal evidence view|opening the original source|Deferred From the First Slice" docs/product-specs/product-foundation.md docs/specs/pipeline-contracts.md docs/design-docs/system-design.md`
- Documentation impact:
  - Replace the current implementation-slice open question with an explicit first-slice boundary.
  - Capture backlog items that remain intentionally deferred.
- Evidence:
  - Updated `product-foundation.md`, `pipeline-contracts.md`, and `system-design.md` to make the first slice text-first, review-first, `Atom`-only for persistence, with deferred alignment/artifact expansion.
  - Validated with `rg -n "First Delivery Slice|Acceptance Bar|text-first|canonical normalized text snapshot|internal evidence view|opening the original source|Deferred From the First Slice" docs/product-specs/product-foundation.md docs/specs/pipeline-contracts.md docs/design-docs/system-design.md`.

### Step 3

- Status: completed
- Objective: Sync tactical records and prepare the change for execution review.
- Expected files:
  - `docs/exec-plans/completed/2026-03-06-evidence-contract-first-slice.md`
  - `docs/exec-plans/tracker.md`
- Validation commands:
  - `rg -n "TASK-0001|TASK-0002|2026-03-06-evidence-contract-first-slice" docs/exec-plans/tracker.md docs/exec-plans/completed/2026-03-06-evidence-contract-first-slice.md`
  - `git diff --check`
- Documentation impact:
  - Keep tracker and active-plan links aligned.
  - Preserve deferred work in tracker/backlog instead of burying it in prose.
- Evidence:
  - Updated `tracker.md` first to link the in-flight plan, then to archive TASK-0001/TASK-0002 as completed work tied to this completed plan.
  - Archived this plan into `docs/exec-plans/completed/` and synced the completed-plan catalog.

## Execution Notes

- This change set is documentation-only. TDD was not applicable because no runtime behavior or testable code path changed in this loop.

## Validation Summary

- Executed `rg -n "Segment|candidate -> validate -> refine -> materialize|needs_review|validated locator|prefix|suffix|char_range" docs/design-docs/system-design.md docs/specs/core-data-model.md docs/specs/pipeline-contracts.md docs/design-docs/decision-log.md`; expected contract terms were present across the updated design/spec docs.
- Executed `rg -n "First Delivery Slice|Acceptance Bar|text-first|canonical normalized text snapshot|internal evidence view|opening the original source|Deferred From the First Slice" docs/product-specs/product-foundation.md docs/specs/pipeline-contracts.md docs/design-docs/system-design.md`; the first-slice scope and acceptance-bar language matched the updated docs.
- Executed `rg -n "TASK-0001|TASK-0002|2026-03-06-evidence-contract-first-slice" docs/exec-plans/tracker.md docs/exec-plans/completed/2026-03-06-evidence-contract-first-slice.md`; tracker/plan links were aligned after archival.
- Executed `git diff --check`; no whitespace or patch-format issues were reported.
- Executed the completed-plan catalog sync check from `docs/exec-plans/completed/README.md`; no missing catalog entries were reported.

## Validation Strategy

- Run the step-specific `rg` checks after each documentation step.
- Run `git diff --check` before review to catch formatting issues.
- Confirm that the same contract terms appear consistently across product, design, and spec docs.

## Review Cadence

- Run a delta review after Step 1 because it changes cross-document technical contracts.
- Run a delta review after Step 2 if the first-slice boundary changes Step 1 wording.
- Run one full-PR review before final gate.

## Review Summary

- Delta review round `20260306-022805` initially blocked the change with `BLOCKER=0`, `IMPORTANT=3`, `MINOR=2`; findings covered artifact-scope ambiguity, stale tracker/plan state, and first-slice alignment wording.
- Addressed those findings by explicitly scoping the first slice to `Atom` persistence, marking alignment as deferred/no-op, and syncing tracker/plan terminology.
- Delta review round `20260306-023322` then passed with `BLOCKER=0`, `IMPORTANT=0`.
- Full-PR review round `20260306-023328` passed with `BLOCKER=0`, `IMPORTANT=0`.
- Post-archive delta review round `20260306-024106` passed with `BLOCKER=0`, `IMPORTANT=0` after moving the plan into `completed/`, syncing the catalog, marking tracker tasks as done, and refreshing the final evidence references.

## Final Gate Conditions

- All acceptance criteria are checked.
- No blocking review findings remain open.
- Product, design, and spec docs agree on the first-generation evidence contract.
- TASK-0001 and TASK-0002 statuses in `tracker.md` match the actual repository state.
- Deferred items remain explicitly documented as backlog, not hidden in ambiguous wording.

## Final Gate Summary

- Initial local-equivalent final-gate evidence was superseded after detecting that the working branch had drifted behind `origin/main`.
- Switched work onto `codex/evidence-contract-first-slice`, fast-forwarded to `origin/main`, and re-applied the change set before recording final gate evidence.
- Executed `.agents/skills/loop-final-gate/scripts/final_gate.sh .local/loop/review-20260306-024106.json .local/loop/ci-local-20260306-024106.json .local/loop/final-gate-20260306-024106.json`.
- Final gate passed with `review_ok=true`, `ci_ok=true`, `branch_ok=true`, and `docs_ok=true`.

## Risks and Mitigations

- Risk: The first slice accidentally bakes in alignment, refresh, or non-text assumptions.
  - Mitigation: State explicit out-of-scope boundaries in the product and pipeline docs.
- Risk: `Segment` identity drifts across docs (`quote`-only in one place, validated locator in another).
  - Mitigation: Edit all design/spec sources in the same change set and validate shared terms.
- Risk: Evidence UX expectations overfit to external webpages.
  - Mitigation: Make the internal canonical evidence view the primary experience and keep original-page opening as an enhancement.

## Completion Summary

- Delivered:
  - Promoted text-source evidence to first-class runtime-materialized `Segment` objects across design and spec docs.
  - Defined the first delivery slice as text-first, review-first, and `Atom`-only for persistence.
  - Recorded the design decision in the decision log and archived the execution plan with validation/review/final-gate evidence.
  - Synced tracker state so TASK-0001 and TASK-0002 are recorded as completed outcomes.
- Not delivered:
  - No runtime ingestion, extraction, review, or persistence code.
  - No refresh/versioning flow, non-text locator contract, or external-page deep-link guarantee.
- Open follow-up/debt IDs:
  - DEBT-0001
  - FUP-0001
  - FUP-0002
