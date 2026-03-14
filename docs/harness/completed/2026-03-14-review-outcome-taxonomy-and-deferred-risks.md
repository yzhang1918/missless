# Review Outcome Taxonomy And Deferred Risks

## Metadata

- Plan name: Review Outcome Taxonomy And Deferred Risks
- Owner: Human+Codex
- Date opened: 2026-03-14
- Intake source: GitHub issues `#20` and `#22`
- Work type: Harness/process
- Related issue(s): `#20`, `#22`
- Scope note: This is one coherent harness task because both issues tighten the same review contract: how reviewers classify current-slice blockers versus accepted deferred risks and strategic observations, and how review/final gate consume that distinction.

## Objective

Make review artifacts and gate decisions explicitly distinguish current-slice blockers from accepted deferred risks and broader strategic observations so known deferrals stay visible without repeatedly blocking later review loops.

## Scope

- In scope:
  - Define an explicit review outcome taxonomy that separates current-slice findings, accepted deferred risks, and strategic observations.
  - Update reviewer output guidance, reviewer launch prompts, aggregation, and review/final-gate script contracts to consume the new structure.
  - Add a stable plan section for accepted deferred risks and update workflow/standards docs to explain how those records should be used.
  - Extend regression coverage so the new taxonomy and gate semantics fail closed when the artifact shape is wrong and pass when only non-blocking layers are populated.
- Out of scope:
  - Changing reviewer spawn/runtime mechanics or reviewer ownership enforcement beyond the already shipped manifest contract.
  - Introducing automatic GitHub issue creation from reviewer artifacts.
  - Product-runtime changes outside the harness/review workflow surface.

## Acceptance Criteria

- [x] Reviewer output schema and reviewer instructions define separate sections for `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations`.
- [x] Review aggregation preserves those layers distinctly, computes gate-driving counts from current-slice findings only, and fails closed on malformed layered artifacts.
- [x] `review_gate.sh` and `final_gate.sh` only block on current-slice `BLOCKER` or `IMPORTANT` findings, while accepted deferred risks and strategic observations remain visible but non-blocking.
- [x] Harness workflow/standards/template guidance defines a stable `## Accepted Deferred Risks` plan section and explains how accepted issues or defer reasons should be recorded there.
- [x] Regression coverage exercises layered reviewer output, malformed artifact rejection, and the non-blocking behavior of accepted deferred risks plus strategic observations.

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
  - Updated `review_aggregate.sh` so it accepts the new layered reviewer payload, preserves separate `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations` in the aggregated review artifact, and computes blocking counts from current-slice findings only while still tolerating legacy `findings[]` payloads during transition.
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

## Validation Plan

- Checks to run:
  - `bash -n` for every changed shell entry point
  - `.agents/skills/loop-review-loop/scripts/review_regression.sh`
  - `git diff --check`
- Evidence to capture:
  - One delta review after the layered contract and gate logic land
  - One final full-pr review before final gate/publish work
  - Validation results showing accepted deferred risks and strategic observations do not block when current-slice blockers are absent

## Review Cadence

- Delta review after Step 2 because the taxonomy affects cross-cutting review/gate semantics.
- Full-pr review before final gate after all steps are complete.

## Final Gate Conditions

- Layered reviewer outputs, aggregate artifacts, and gate scripts agree on the same machine-readable taxonomy.
- Accepted deferred risks remain visible with explicit issue links or defer reasons but do not block review/final gate by themselves.
- Strategic observations remain visible but never count toward current-slice blocker totals.
- Regression coverage passes for malformed layered artifacts, current-slice blocker failures, and non-blocking deferment/strategy-only cases.

## Validation Summary

- Ran `rg -n "current_slice_findings|accepted_deferred_risks|strategic_observations|Accepted Deferred Risks" .agents/skills/loop-reviewer/SKILL.md .agents/skills/loop-review-loop/SKILL.md .agents/skills/loop-review-loop/references/reviewer-output-schema.md .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md docs/exec-plans/templates/execution-plan-template.md .agents/skills/loop-plan/SKILL.md docs/harness/active/README.md docs/exec-plans/active/README.md`; the layered contract wording and plan-section guidance were present across the intended workflow surfaces.
- Ran `bash -n .agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_aggregate.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_gate.sh`, `bash -n .agents/skills/loop-review-loop/scripts/review_regression.sh`, `bash -n .agents/skills/loop-final-gate/scripts/final_gate.sh`, and `bash -n .agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`; all changed shell entry points parsed cleanly.
- Ran `.agents/skills/loop-review-loop/scripts/review_regression.sh`; it passed after adding layered schema coverage, malformed accepted-deferred-risk rejection, and the non-blocking deferment/strategy-only pass path.
- Ran `.agents/skills/loop-final-gate/scripts/stateful_gate_regression.sh`; it passed after switching the clean final-gate fixture to the layered review artifact shape.
- Ran `git diff --check`; no whitespace or patch-format issues were reported.
- Published PR `#40`: `https://github.com/yzhang1918/missless/pull/40`.
- Exported `.local/loop/ci-status-pr40.json` with `export_ci_status.sh` after required `harness-checks` passed for PR `#40`.
- Ran `.agents/skills/loop-final-gate/scripts/final_gate.sh .local/loop/review-20260314-152557.json .local/loop/ci-status-pr40.json docs/harness/completed/2026-03-14-review-outcome-taxonomy-and-deferred-risks.md main .local/loop/final-gate-pr40.json`; it passed and promoted the retained evidence bundle to `.local/final-evidence/2026-03-14-review-outcome-taxonomy-and-deferred-risks/`.

## Review Summary

- Delta review round `20260314-152556` passed with current-slice `BLOCKER=0` and `IMPORTANT=0`.
- Full-pr review round `20260314-152557` passed with current-slice `BLOCKER=0` and `IMPORTANT=0`.
- Manual fallback reviewer artifacts were used for both clean rounds because reviewer subagents were not launched in this session; each designated reviewer output records its `producer.reason`.
- The clean review rounds did not surface blocking findings after the layered schema, gate logic, and regression coverage landed together.

## Final Gate Summary

- Published branch `codex/issue-20-22-review-taxonomy` to PR `#40`: `https://github.com/yzhang1918/missless/pull/40`.
- Exported CI status from PR `#40` with required `harness-checks` green and `docs_updated=true`.
- Final gate passed with `review_ok=true`, `ci_ok=true`, `branch_ok=true`, and `docs_ok=true`.
- Retained final-evidence bundle: `.local/final-evidence/2026-03-14-review-outcome-taxonomy-and-deferred-risks/`.

## Risks and Mitigations

- Risk: The new taxonomy becomes too abstract and reviewers apply categories inconsistently.
- Mitigation: Make the schema and prompt language explicit about the intent of each layer and keep gate consumption limited to current-slice findings.
- Risk: Gate scripts and regression fixtures drift from the documented layered schema.
- Mitigation: Update docs, scripts, and regression coverage in the same branch and validate all touched shell entry points.

## Completion Summary

- Delivered:
- Reviewer output guidance, prompt text, and schema now separate `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations`.
- Review aggregation and both gate scripts now preserve those layers while counting only current-slice blocker/important findings toward review/final-gate failure.
- Workflow standards and plan guidance now define a stable `## Accepted Deferred Risks` section for intentional deferment records.
- Regression coverage now proves malformed layered artifacts fail closed and accepted deferred risks or strategic observations do not block by themselves.
- Published PR `#40` and recorded a passing final gate plus retained local final-evidence bundle for the current head.
- Not delivered:
- Merge/landing and issue auto-close remain pending until PR `#40` lands.
- Linked issue updates:
- Published as PR `#40` (`https://github.com/yzhang1918/missless/pull/40`); the current published head SHA is `53f0f32c320cce4b3444c467d6ccf68814d37563`.
- Issue `#20` was updated with the archived plan path, PR link, review status, and final-gate result via comment `https://github.com/yzhang1918/missless/issues/20#issuecomment-4060720960`.
- Issue `#22` was updated with the archived plan path, PR link, review status, and final-gate result via comment `https://github.com/yzhang1918/missless/issues/22#issuecomment-4060720961`.
- The PR body uses merge-time closing keywords for `#20` and `#22`, so both issues should remain open until the PR lands.
- Spawned follow-up issues:
- None.
