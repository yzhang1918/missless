# Review Outcome Taxonomy And Deferred Risks

## Metadata

- Plan name: Review Outcome Taxonomy And Deferred Risks
- Owner: Human+Codex
- Date opened: 2026-03-14
- Date reopened: 2026-03-15
- Intake source: GitHub issues `#20` and `#22`
- Work type: Harness/process
- Related issue(s): `#20`, `#22`
- Scope note: This is one coherent harness task because both issues tighten the same review contract: how reviewers classify current-slice blockers versus accepted deferred risks and strategic observations, how reviewer subagents are required to run, and when fallback is legitimately allowed.

## Objective

Make review artifacts and gate decisions explicitly distinguish current-slice blockers from accepted deferred risks and broader strategic observations, while also enforcing that reviewer subagents are attempted for every reviewer slot and that manual fallback is only valid after a documented reviewer-subagent failure.

## Scope

- In scope:
  - Define an explicit review outcome taxonomy that separates current-slice findings, accepted deferred risks, and strategic observations.
  - Update reviewer output guidance, reviewer launch prompts, aggregation, and review/final-gate script contracts to consume the new structure.
  - Add a stable plan section for accepted deferred risks and update workflow/standards docs to explain how those records should be used.
  - Extend regression coverage so the new taxonomy and gate semantics fail closed when the artifact shape is wrong and pass when only non-blocking layers are populated.
  - Tighten review-loop workflow rules so reviewer subagents are the required first path for each manifest entry and manual fallback is allowed only after a recorded reviewer-subagent failure.
  - Add a machine-readable reviewer-dispatch or equivalent round record so fallback eligibility is repo-observable instead of relying on narrative text alone.
- Out of scope:
  - Replacing the runtime-owned reviewer launcher with a repository-specific agent runtime.
  - Introducing automatic GitHub issue creation from reviewer artifacts.
  - Product-runtime changes outside the harness/review workflow surface.

## Acceptance Criteria

- [x] Reviewer output schema and reviewer instructions define separate sections for `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations`.
- [x] Review aggregation preserves those layers distinctly, computes gate-driving counts from current-slice findings only, and fails closed on malformed layered artifacts.
- [x] `review_gate.sh` and `final_gate.sh` only block on current-slice `BLOCKER` or `IMPORTANT` findings, while accepted deferred risks and strategic observations remain visible but non-blocking.
- [x] Harness workflow/standards/template guidance defines a stable `## Accepted Deferred Risks` plan section and explains how accepted issues or defer reasons should be recorded there.
- [x] Regression coverage exercises layered reviewer output, malformed artifact rejection, and the non-blocking behavior of accepted deferred risks plus strategic observations.
- [x] `loop-review-loop` and related standards make reviewer subagent launch mandatory for every manifest reviewer slot and treat runtime-level inability to launch reviewers as a review blocker rather than implicit fallback.
- [x] Manual fallback reviewer artifacts are accepted only when the same reviewer slot has a machine-readable recorded subagent failure or timeout; fallback without a recorded failed reviewer attempt fails closed.
- [x] Regression coverage proves both the happy path with recorded reviewer dispatch and the blocked path where fallback is attempted without an eligible failed reviewer-subagent record.

## Accepted Deferred Risks

- None at plan open.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define the layered review output contract in docs, reviewer guidance, reviewer prompts, and plan standards before script logic depends on it.
- Expected files:
  - `.agents/skills/loop-reviewer/SKILL.md`
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-review-loop/references/reviewer-output-schema.md`
  - `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`
  - `.agents/skills/AGENT_LOOP_WORKFLOW.md`
  - `docs/standards/repository-standards.md`
  - `docs/exec-plans/templates/execution-plan-template.md`
  - `.agents/skills/loop-plan/SKILL.md`
  - `docs/harness/active/README.md`
  - `docs/exec-plans/active/README.md`
- Validation commands:
  - `rg -n "current_slice_findings|accepted_deferred_risks|strategic_observations|Accepted Deferred Risks" .agents/skills/loop-reviewer/SKILL.md .agents/skills/loop-review-loop/SKILL.md .agents/skills/loop-review-loop/references/reviewer-output-schema.md .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md docs/exec-plans/templates/execution-plan-template.md .agents/skills/loop-plan/SKILL.md docs/harness/active/README.md docs/exec-plans/active/README.md`
- Documentation impact:
  - Make the layered review/deferment contract explicit before aggregate and gate logic rely on it.
- Evidence:
  - Updated reviewer and review-loop skills, the reviewer output schema reference, and reviewer launch prompts so reviewer output now distinguishes `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations`.
  - Updated workflow/standards/plan guidance in `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `.agents/skills/loop-plan/SKILL.md`, `docs/standards/repository-standards.md`, `docs/harness/active/README.md`, `docs/exec-plans/active/README.md`, and `docs/exec-plans/templates/execution-plan-template.md` so accepted deferment has a stable `## Accepted Deferred Risks` home.
  - Ran the taxonomy wording validation `rg -n "current_slice_findings|accepted_deferred_risks|strategic_observations|Accepted Deferred Risks" ...`; all targeted files contained the expected contract language.

### Step 2

- Status: completed
- Objective: Implement layered aggregation and gate semantics so only current-slice blockers can hold review or final gate while accepted deferred risks and strategic observations remain visible in artifacts.
- Expected files:
  - `.agents/skills/loop-review-loop/scripts/review_aggregate.sh`
  - `.agents/skills/loop-review-loop/scripts/review_gate.sh`
  - `.agents/skills/loop-final-gate/scripts/final_gate.sh`
  - `.agents/skills/loop-final-gate/SKILL.md`
  - Any directly related skill docs or references needed to keep the script contract legible
- Validation commands:
  - `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`
  - `bash -n .agents/skills/loop-review-loop/scripts/review_gate.sh`
  - `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`
- Documentation impact:
  - Keep review/final-gate wording aligned with the new current-slice-only blocking rule.
- Evidence:
- Updated `review_aggregate.sh` so it requires the layered reviewer payload, preserves separate `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations` in the aggregated review artifact, and computes blocking counts from current-slice findings only.
  - Updated `review_gate.sh` and `final_gate.sh` so they validate the layered review artifact contract and block only on current-slice `BLOCKER` or `IMPORTANT` findings.
  - Updated `.agents/skills/loop-final-gate/SKILL.md` so the final-gate contract explicitly states that accepted deferred risks and strategic observations remain visible but non-blocking.
  - Ran `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_gate.sh`, and `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`; all parsed cleanly.

### Step 3

- Status: completed
- Objective: Extend regression coverage, run required validations, record review results, and prepare the task for archival/publish sync.
- Expected files:
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `docs/harness/active/2026-03-14-review-outcome-taxonomy-and-deferred-risks.md`
  - Any completed-plan catalog or archive files needed once the task is finished
- Validation commands:
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `git diff --check`
- Documentation impact:
  - Preserve the validation evidence, review outcome, and linked issue state in the tracked plan record.
- Evidence:
  - Extended `review_regression.sh` so regression coverage now checks the layered reviewer prompt wording, malformed accepted deferred risk rejection, aggregate counts for the new non-blocking layers, and the clean pass path when only accepted deferred risks plus strategic observations remain.
  - Updated `stateful_gate_regression.sh` so final-gate regression coverage consumes a layered clean review artifact rather than a legacy `findings[]`-only shape.
  - Ran `.agents/skills/loop-review-loop/scripts/review_regression.sh`, `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`, and `git diff --check`; all passed.

### Step 4

- Status: completed
- Objective: Enforce reviewer-subagent-first review execution so fallback artifacts are allowed only after a machine-readable recorded reviewer-subagent failure for the same reviewer slot.
- Expected files:
  - `.agents/skills/loop-review-loop/SKILL.md`
  - `.agents/skills/loop-reviewer/SKILL.md`
  - `.agents/skills/AGENT_LOOP_WORKFLOW.md`
  - `docs/standards/repository-standards.md`
  - `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md`
  - `.agents/skills/loop-review-loop/references/reviewer-output-schema.md`
  - `.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`
  - `.agents/skills/loop-review-loop/scripts/review_aggregate.sh`
  - `.agents/skills/loop-review-loop/scripts/review_finalize.sh`
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - Any new helper kept local to `.agents/skills/loop-review-loop/scripts/`
- Validation commands:
  - `bash -n` for every changed `loop-review-loop` shell entry point
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `git diff --check`
- Documentation impact:
  - Make reviewer-subagent-first review and fallback eligibility explicit in both human guidance and machine-readable review-round records.
- Evidence:
  - Added `.agents/skills/loop-review-loop/references/reviewer-dispatch-record.md` plus `.agents/skills/loop-review-loop/scripts/review_record_dispatch.sh`, and updated `review_prepare_reviewers.sh` so every review round now emits a matching machine-readable dispatch ledger alongside the reviewer launch manifest.
  - Tightened `.agents/skills/loop-review-loop/SKILL.md`, `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `docs/standards/repository-standards.md`, `.agents/skills/loop-review-loop/references/reviewer-launch-manifest.md`, and `.agents/skills/loop-review-loop/references/reviewer-output-schema.md` so reviewer-subagent launch is the required first path and manual fallback is only valid after the same slot records `launch-failed`, `timeout`, or `invalid-artifact`.
  - Updated `review_record_dispatch.sh` and `review_aggregate.sh` so reviewer slots reject or fail closed on missing subagent attempts, `runtime-blocked` fallback, terminal reviewer states that skip `launch-started`, and crafted dispatch histories that append later events after `runtime-blocked`, while preserving dispatch/fallback evidence in the contract summary.
  - Extended `review_regression.sh` so regression now covers dispatch scaffolding, helper-level rejection of direct terminal states, valid recorded timeout fallback, invalid fallback without an eligible failed status, `runtime-blocked` rejection, the `missing-launch-start` failure mode, and the new `runtime-blocked` terminal invariant.
  - Ran `bash -n .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh .agents/skills/loop-review-loop/scripts/review_record_dispatch.sh .agents/skills/loop-review-loop/scripts/review_aggregate.sh .agents/skills/loop-review-loop/scripts/review_cleanup.sh .agents/skills/loop-review-loop/scripts/review_regression.sh`, `.agents/skills/loop-review-loop/scripts/review_regression.sh`, and `git diff --check`; all passed on 2026-03-15.

## Validation Plan

- Checks to run:
  - `bash -n` for every changed shell entry point
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `git diff --check`
- Evidence to capture:
  - One delta review after the layered contract and gate logic land
  - One delta review after reviewer-subagent enforcement lands
  - One final full-pr review before final gate/publish work on the reopened branch head
  - Validation results showing accepted deferred risks and strategic observations do not block when current-slice blockers are absent
  - Validation results showing fallback without a recorded reviewer-subagent failure fails closed

## Review Cadence

- Delta review after Step 2 because the taxonomy affects cross-cutting review/gate semantics.
- Delta review after Step 4 because reviewer-subagent enforcement changes review-loop execution semantics.
- Full-pr review before final gate after all steps are complete on the reopened branch head.

## Final Gate Conditions

- Layered reviewer outputs, aggregate artifacts, and gate scripts agree on the same machine-readable taxonomy.
- Accepted deferred risks remain visible with explicit issue links or defer reasons but do not block review/final gate by themselves.
- Strategic observations remain visible but never count toward current-slice blocker totals.
- Reviewer fallback is impossible unless the same reviewer slot has a recorded subagent launch failure or timeout that makes fallback eligible.
- Regression coverage passes for malformed layered artifacts, current-slice blocker failures, non-blocking deferment/strategy-only cases, and invalid fallback-without-failure attempts.

## Validation Summary

- Reopened on 2026-03-15 to add reviewer-subagent enforcement and fallback-eligibility tightening to PR `#40`.
- Earlier validation, review, publish, and final-gate records below remain useful baseline evidence for Steps 1-3 but are now stale with respect to the reopened branch head; rerun closeout evidence after Step 4 completes.
- On 2026-03-15, `bash -n` passed for every changed `loop-review-loop` shell entry point involved in the reopened scope.
- On 2026-03-15, `.agents/skills/loop-review-loop/scripts/review_regression.sh` passed after adding dispatch-ledger enforcement, runtime-blocked rejection, runtime-blocked terminal enforcement, and launch-start ordering validation.
- On 2026-03-15, `git diff --check` passed after the reopened Step 4 edits.
- On 2026-03-15, both `gh auth status` and `git fetch --prune origin` succeeded in this worktree, so stateful publish/final-gate refresh is no longer blocked by the earlier environment issues.
- On 2026-03-15, commit `e141eb2` tightened `review_gate.sh` and `final_gate.sh` so missing `accepted_deferred_risks` or `strategic_observations` arrays fail closed, and both `review_regression.sh` plus `stateful_gate_regression.sh` passed on that head.
- On 2026-03-15, commit `410ad27` tightened `review_aggregate.sh` so reviewer artifacts must match the manifest `scope`, and `review_regression.sh` passed with new missing-scope and mismatched-scope coverage on that head.
- The earlier 2026-03-15 clean full-pr review and passing final-gate records apply only through commit `7acdbf5`; they were superseded by commits `e141eb2` and `410ad27`, and the refreshed follow-up review/final-gate records are captured below.
- On 2026-03-15, delta review round `20260315-093341` passed with no current-slice blockers after the archived-plan refresh.
- On 2026-03-15, `export_ci_status.sh main --docs-updated true --pr 40 --output .local/loop/ci-status-20260315-093341.json` and `final_gate.sh .local/loop/review-20260315-093341.json .local/loop/ci-status-20260315-093341.json docs/harness/completed/2026-03-14-review-outcome-taxonomy-and-deferred-risks.md main .local/loop/final-gate-20260315-093341.json` both passed for commit `126a599`.

## Review Summary

- Earlier 2026-03-14 review rounds remain part of the branch history for Steps 1-3.
- Reopened scope requires new review evidence after Step 4 lands because the previous clean rounds relied on manual fallback reviewer artifacts, which this reopened work is intended to tighten.
- During 2026-03-15 delta review iteration, a `correctness` reviewer subagent identified one additional current-slice gap: terminal dispatch statuses could bypass `launch-started`; that finding was fixed in the reopened Step 4 implementation and covered by regression.
- The earlier clean full-pr round for reopened Step 4 evidence was superseded by commits `e141eb2` and `410ad27`.
- Full-pr round `20260315-092401` then surfaced one current-slice `correctness` finding: `review_aggregate.sh` accepted reviewer artifacts with missing or incorrect `scope`; that finding was fixed in commit `410ad27` and covered by regression.
- Full-pr round `20260315-092915` then surfaced one current-slice `docs/spec consistency` finding: this archived plan still described pre-`e141eb2`/`410ad27` review and final-gate evidence as if it covered the latest reopened branch head.
- Delta round `20260315-093341` then re-reviewed the archived-plan refresh and passed with no current-slice blockers.

## Final Gate Summary

- Earlier final-gate records from 2026-03-14 are now stale for the reopened branch head and must be refreshed after Step 4 completes.
- On 2026-03-15, `export_ci_status.sh main --docs-updated true --pr 40 --output .local/loop/ci-status-20260315-005921.json` exported a GitHub-backed CI artifact for the latest published PR head.
- On 2026-03-15, `final_gate.sh` passed against `.local/loop/review-20260315-005808.json`, the exported CI artifact, and this archived plan.
- That passing final-gate record applies to the pre-`e141eb2` reopened head and is now superseded by later commits on PR `#40`.
- On 2026-03-15, `export_ci_status.sh main --docs-updated true --pr 40 --output .local/loop/ci-status-20260315-093341.json` exported a GitHub-backed CI artifact for commit `126a599`.
- On 2026-03-15, `final_gate.sh` passed against `.local/loop/review-20260315-093341.json`, the refreshed CI artifact, and this archived plan.
- The retained local evidence bundle `.local/final-evidence/2026-03-14-review-outcome-taxonomy-and-deferred-risks/` now contains the refreshed closeout evidence produced in the 20260315-093341 review/final-gate cycle.

## Risks and Mitigations

- Risk: The new taxonomy becomes too abstract and reviewers apply categories inconsistently.
- Mitigation: Make the schema and prompt language explicit about the intent of each layer and keep gate consumption limited to current-slice findings.
- Risk: Gate scripts and regression fixtures drift from the documented layered schema.
- Mitigation: Update docs, scripts, and regression coverage in the same branch and validate all touched shell entry points.
- Risk: Reviewer-subagent enforcement becomes unenforceable because the runtime-owned launch step leaves no repo-observable trace.
- Mitigation: Add a small machine-readable reviewer-dispatch record to the review round and validate fallback eligibility against it.
- Risk: Runtime-level inability to launch reviewer subagents becomes silently treated as ordinary fallback.
- Mitigation: Make runtime launch blockers fail closed in the review loop contract rather than qualifying for manual fallback.

## Completion Summary

- Delivered:
- Reviewer output guidance, prompt text, and schema now separate `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations`.
- Review aggregation and both gate scripts now preserve those layers while counting only current-slice blocker/important findings toward review/final-gate failure.
- Workflow standards and plan guidance now define a stable `## Accepted Deferred Risks` section for intentional deferment records.
- Regression coverage now proves malformed layered artifacts fail closed and accepted deferred risks or strategic observations do not block by themselves.
- Earlier publish/final-gate records for PR `#40` are preserved as baseline history but are stale after the 2026-03-15 reopen.
- Reviewer-subagent-first execution is now repo-observable through per-round dispatch ledgers, explicit fallback-eligibility rules, and aggregate enforcement for missing subagent attempts or missing `launch-started` events.
- Reviewer dispatch now also treats `runtime-blocked` as a terminal per-slot state, with helper-level rejection plus aggregate fail-closed enforcement if later events are appended.
- The reopened branch now also requires complete layered review artifacts at both gate scripts and per-reviewer manifest-`scope` enforcement in review aggregation.
- Refreshed closeout evidence now includes delta review round `20260315-093341`, CI export `.local/loop/ci-status-20260315-093341.json`, and final gate artifact `.local/loop/final-gate-20260315-093341.json`.
- Not delivered:
- Merge/landing and issue auto-close remain pending until PR `#40` lands after the reopened scope is complete.
- Linked issue updates:
- PR `#40` remains the active publication path for this reopened work: `https://github.com/yzhang1918/missless/pull/40`.
- Issue `#20`, issue `#22`, and PR `#40` reflect the reopened Step 4 work plus the refreshed closeout evidence recorded after follow-up fixes in commits `e141eb2` and `410ad27`.
- Issue `#20`, issue `#22`, and PR `#40` can now be synced to the refreshed closeout evidence from round `20260315-093341` and final gate artifact `.local/loop/final-gate-20260315-093341.json`.
- Spawned follow-up issues:
- None.
