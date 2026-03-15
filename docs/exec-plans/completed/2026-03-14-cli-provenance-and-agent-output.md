# CLI Provenance And Agent Output

## Metadata

- Plan name: CLI Provenance And Agent Output
- Owner: Human+Codex
- Date opened: 2026-03-14
- Date completed: 2026-03-14
- Intake source: GitHub issue `#29` plus approved synchronous discovery scope
  refinement in chat
- Work type: Product
- Related issues:
  - `#29` Record decision-basis snapshot provenance in ingest artifacts
- Scope note: This is one coherent product task because issue `#29`'s durable
  provenance contract, explicit fetch-method selection, and the approved
  agent-first CLI simplification all land on the same shipped deterministic
  ingest/review entrypoint.

## Objective

Reshape the first-slice CLI and ingest artifact contract so `missless`
exposes an agent-first command surface, records only durable
decision-basis provenance in `source.json`, and lets callers choose the
requested fetch method explicitly without leaking provider-attempt details
into long-lived artifacts.

## Scope

- In scope:
  - Rename the primary workflow commands to `fetch`, `validate`, `anchor`,
    and `review`.
  - Add `--fetch-method <auto|jina|direct>` to `missless fetch`.
  - Persist canonical fetch-method values in `source.json` as
    `auto|jina_reader|direct_origin`.
  - Replace the current `source.json` shape with a provenance-first contract
    that keeps only durable `requested` and `decision_basis` fields plus
    shared run-level metadata.
  - Make the default stdout contract for `fetch`, `validate`, `anchor`, and
    `review` a single JSON object with a shared envelope and concise summary.
  - Add a dedicated CLI I/O spec and update related draft contracts, design
    docs, and workflow guidance so reviewers can inspect the intended surface
    before reading implementation details.
  - Update skill and integration-test consumers that currently parse
    human-formatted stdout so they use the new structured command contract.
- Out of scope:
  - Provider-attempt sequences, execution-trace storage, or long-lived debug
    metadata.
  - New persistence-layer or database schema work beyond defining the durable
    artifact contract that future storage may consume.
  - New multi-source, multi-format, or background-job command surfaces.
  - Release automation or public distribution changes beyond keeping the
    existing packaged CLI contract truthful after the rename.

## Acceptance Criteria

- [x] `missless` exposes `fetch`, `validate`, `anchor`, and `review` as the
      primary first-slice workflow commands, and the documented command set is
      consistent across help text, skill guidance, and specs.
- [x] `missless fetch` accepts `--fetch-method auto|jina|direct`, preserves
      the current default `auto` behavior, and fails closed for unsupported
      method values.
- [x] `source.json` becomes a durable provenance artifact with shallow
      `requested` and `decision_basis` groups, records the final content URL
      used for the decision basis, and no longer stores provider endpoint or
      transport-response details.
- [x] The default stdout for `fetch`, `validate`, `anchor`, and `review` is a
      single machine-readable JSON object that includes at least `ok`,
      `command`, `summary`, `run_dir`, and `artifacts`, plus command-specific
      state needed for the next workflow step.
- [x] The JSON output remains human-scannable by including concise summaries,
      while skill and test consumers stop depending on regex parsing of
      English-formatted stdout lines.
- [x] A dedicated CLI contract spec documents command names, arguments,
      success/failure JSON envelopes, stderr/exit-code expectations, and the
      role of the auxiliary `print-draft-contract` command.
- [x] `pnpm -r build`, `pnpm -r typecheck`, `pnpm -r test`, and targeted CLI
      contract regressions pass on the branch head.
- [x] The branch leaves issue `#29` in a closable state on merge; if execution
      uncovers out-of-scope trace/debug requirements, record them as follow-up
      backlog work before closing this plan.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Lock the reviewed contract for the renamed CLI workflow, the new
  JSON-first output envelope, and the provenance-first `source.json` schema in
  repository docs before implementation details spread.
- Expected files:
  - `docs/specs/cli-contracts.md`
  - `docs/specs/pipeline-contracts.md`
  - `docs/specs/index.md`
  - `docs/design-docs/system-design.md`
  - `apps/cli/src/index.ts`
  - `apps/cli/src/commands/print-draft-contract.ts`
  - `tests/integration/cli/help-contract.test.ts`
  - `tests/integration/cli/validate-draft.test.ts`
- Validation commands:
  - `pnpm --filter @missless/cli build`
  - `pnpm exec tsx --test tests/integration/cli/help-contract.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/validate-draft.test.ts`
- Documentation impact:
  - Add the dedicated CLI contract spec and align the existing pipeline/design
  docs with the renamed command surface and provenance contract.
- Validation evidence:
  - `pnpm --filter @missless/cli build` passed.
  - `pnpm exec tsx --test tests/integration/cli/help-contract.test.ts`
    passed.
  - `pnpm exec tsx --test tests/integration/cli/validate-draft.test.ts`
    passed.

### Step 2

- Status: completed
- Objective: Implement explicit fetch-method selection and the durable
  provenance artifact shape in core ingest logic, then ship the renamed
  `missless fetch` command with structured stdout.
- Expected files:
  - `packages/core/src/source/fetch-normalize.ts`
  - `packages/core/src/providers/default.ts`
  - `packages/core/src/providers/provider.ts`
  - `packages/core/src/source/url-safety.ts`
  - `packages/core/src/index.ts`
  - `apps/cli/src/index.ts`
  - `apps/cli/src/commands/fetch-normalize.ts`
  - `tests/unit/core/fetch-normalize.test.ts`
  - `tests/integration/cli/fetch-normalize.test.ts`
  - `tests/integration/cli/installable-cli.test.ts`
- Validation commands:
  - `pnpm -r build`
  - `pnpm exec tsx --test tests/unit/core/fetch-normalize.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/fetch-normalize.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/installable-cli.test.ts`
- Documentation impact:
  - Keep the new CLI spec truthful about `fetch` arguments and success/failure
    output once the ingest surface is shipped.
- Validation evidence:
  - `pnpm -r build` passed.
  - `pnpm exec tsx --test tests/unit/core/fetch-normalize.test.ts` passed.
  - `pnpm exec tsx --test tests/integration/cli/fetch-normalize.test.ts`
    passed.
  - `pnpm exec tsx --test tests/integration/cli/installable-cli.test.ts`
    passed.

### Step 3

- Status: completed
- Objective: Unify `validate`, `anchor`, and `review` around the shared JSON
  envelope, update the auxiliary draft contract and skill guidance, and remove
  regex-based workflow assumptions from tests and docs.
- Expected files:
  - `apps/cli/src/commands/validate-draft.ts`
  - `apps/cli/src/commands/anchor-evidence.ts`
  - `apps/cli/src/commands/render-review.ts`
  - `apps/cli/src/index.ts`
  - `skills/missless/SKILL.md`
  - `skills/missless/references/review-guidance.md`
  - `scripts/e2e/run_missless_review.sh`
  - `tests/integration/cli/validate-draft.test.ts`
  - `tests/integration/cli/review-package.test.ts`
  - `tests/integration/cli/e2e-driver.test.ts`
- Validation commands:
  - `pnpm exec tsx --test tests/integration/cli/validate-draft.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/review-package.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/e2e-driver.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/help-contract.test.ts`
- Documentation impact:
  - Refresh the runtime-owned draft contract and missless skill workflow so
    agent consumers read structured command results instead of English
    sentence fragments.
- Validation evidence:
  - `pnpm -r build` passed after the wrapper and skill updates.
  - `pnpm exec tsx --test tests/integration/cli/validate-draft.test.ts`
    passed.
  - `pnpm exec tsx --test tests/integration/cli/review-package.test.ts`
    passed.
  - `pnpm exec tsx --test tests/integration/cli/e2e-driver.test.ts` passed.
  - `pnpm exec tsx --test tests/integration/cli/help-contract.test.ts`
    passed.

### Step 4

- Status: completed
- Objective: Run full validation, tighten any remaining docs/spec drift, and
  leave the branch ready for review-loop, issue sync, and later archival.
- Expected files:
  - `docs/exec-plans/active/2026-03-14-cli-provenance-and-agent-output.md`
  - `docs/specs/cli-contracts.md`
  - `docs/specs/pipeline-contracts.md`
  - `docs/design-docs/system-design.md`
  - `docs/specs/index.md`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `git diff --check`
- Documentation impact:
  - Record the final validation evidence and any required follow-up issue links
    in the plan before the active file moves to `completed/`.
- Validation evidence:
  - `pnpm -r typecheck` passed.
  - `pnpm -r test` passed.
  - `git diff --check` passed.

## Validation Strategy

- Use unit coverage to prove fetch-method selection, fallback boundaries, and
  the new `source.json` contract independently of the CLI surface.
- Use CLI integration tests to prove command renames, JSON-envelope defaults,
  help text, and skill-consumable output for the full first-slice workflow.
- Keep packaged/installable CLI regressions passing so the renamed command
  surface remains truthful outside the repo-native runtime.
- Treat docs/spec updates as part of the validation surface: the shipped CLI
  behavior, skill instructions, and technical contract docs must agree.

## Review Cadence

- Run delta review after each implementation step.
- Run at least one full-PR review before final gate.
- Re-check issue scope before archiving so the plan either closes `#29` cleanly
  or records explicitly linked follow-up backlog work for anything durable that
  remains out of scope.

## Final Gate Conditions

- All acceptance criteria are checked.
- Full workspace build, typecheck, and test commands pass on synchronized
  branch state.
- The CLI contract spec, pipeline/design docs, and skill guidance all match
  the shipped command surface and artifact shape.
- Review has no unresolved blocker or important findings.
- Issue/PR linkage is ready so `#29` can close on merge, with any newly
  discovered out-of-scope work linked before archival.

## Risks And Mitigations

- Risk: Renaming commands breaks local skills, installable-bin regressions, or
  any workflow that still parses legacy stdout strings.
  - Mitigation: Update the skill guidance and CLI integration tests in the same
    slice, and treat help-contract plus packaged-install tests as blocking
    regressions.
- Risk: The new JSON output becomes verbose but still underspecified for agent
  consumers.
  - Mitigation: Define one common envelope in the CLI spec, keep field names
    stable, and include only the command-specific state needed for the next
    workflow step.
- Risk: Provenance work accidentally reintroduces provider-attempt or
  transport-level metadata into the durable artifact.
  - Mitigation: Keep `source.json` scoped to `requested` and `decision_basis`
    fields only, and push any execution-trace discussion into follow-up work if
    it becomes necessary.
- Risk: The broader CLI contract cleanup widens beyond issue `#29` and hides
  unfinished design questions.
  - Mitigation: Keep auxiliary command changes limited to making the current
    first-slice workflow coherent, and stop for realignment instead of silently
    expanding into unrelated CLI redesign.

## Execution Notes

- Added a new `docs/specs/cli-contracts.md` document so command naming, output
  envelopes, and fetch provenance can be reviewed directly without inferring
  the contract from tests.
- Reshaped `source.json` into a durable provenance-first artifact with
  `requested` and `decision_basis` groups, plus explicit requested/chosen
  fetch-method recording.
- Renamed the workflow commands to `fetch`, `validate`, `anchor`, and
  `review`, while keeping `print-draft-contract` as the auxiliary
  introspection surface.
- Switched the workflow commands to default JSON stdout envelopes with concise
  summaries, and updated the missless skill plus e2e driver to consume the
  structured results instead of regex-matching English sentences.
- Tightened the injected-provider provenance contract in
  `fetchNormalizeSource`: custom providers must identify a durable chosen fetch
  method through either a built-in `providerName` or explicit
  `durableFetchMethod`; otherwise provenance recording fails closed.
- Tightened harness review aggregation so reviewer artifacts with the wrong
  declared `scope` can no longer satisfy a launch-manifest slot, and added a
  regression check for that fail-closed behavior.

## Review Summary

- Full-pr review loop completed locally in two rounds using manual-fallback
  reviewer artifacts because subagent review was not used in this session.
- Round 1 correctly blocked and surfaced two follow-up fixes before rerun:
  rejecting prototype-chain `--fetch-method` values such as `toString`, and
  updating unit fixture runs that still seeded the legacy `source.json`
  schema.
- After the follow-up patch and validation rerun, Round 2 passed with no
  blocker or important findings, leaving publish as the remaining step before
  final gate.
- A later isolated subagent review surfaced two additional follow-up fixes
  before publish:
  - custom-provider provenance now requires either a built-in provider name or
    an explicit `durableFetchMethod`
  - `loop-review-loop` now rejects reviewer artifacts whose declared `scope`
    does not match the launch manifest
- After those follow-up fixes, a fresh isolated full-pr subagent round
  (`20260315-092955`) passed with `0` blocker and `0` important findings.
  The only remaining note was one non-blocking reliability `NIT` about making
  invalid reviewer-artifact stderr text mention scope validation explicitly.
- The harness-side reviewer-scope hardening is also archived separately in
  `docs/harness/completed/2026-03-15-reviewer-scope-contract-hardening.md`
  so the product and harness execution histories stay split correctly.
- No new follow-up issue was required during execution.

## Validation Summary

- `pnpm -r build` passed after the review-loop follow-up fixes.
- `pnpm -r typecheck` passed.
- `pnpm -r test` passed.
- `git diff --check` passed.
- `.agents/skills/loop-review-loop/scripts/review_regression.sh` passed after
  the reviewer-scope enforcement update.
- The final isolated subagent review gate passed locally via
  `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260315-092955
  .local/loop/review-20260315-092955-*.json`.

## Issue Update Note

- `#29` status sync comment:
  [issuecomment-4060762455](https://github.com/yzhang1918/missless/issues/29#issuecomment-4060762455)
- `#29` PR sync comment:
  [issuecomment-4062679479](https://github.com/yzhang1918/missless/issues/29#issuecomment-4062679479)
- No new follow-up issue was required during execution.

## Publish Summary

- Branch: `codex/29-cli-provenance-agent-output`
- PR: [#41](https://github.com/yzhang1918/missless/pull/41)
- Publish command:
  `.agents/skills/loop-publish/scripts/publish_pr.sh main "feat(cli): ship agent-first workflow contracts" ... --plan docs/exec-plans/completed/2026-03-14-cli-provenance-and-agent-output.md --close-issue 29`
- Published head SHA: `0e1fbe998231d3361968ebcddbe78cfb46302e35`

## Final Gate Summary

- Full-pr review is passing locally and on the published PR head.
- Latest isolated full-pr review round: `20260315-092955`
  (`BLOCKER=0`, `IMPORTANT=0`, one non-blocking `NIT`).
- Publish unblocked the GitHub CI exporter:
  `.agents/skills/loop-final-gate/scripts/export_ci_status.sh main --docs-updated true --pr 41`
  produced `.local/loop/ci-status-0e1fbe998231.json` for the current PR head.
- Final gate then passed via:
  `.agents/skills/loop-final-gate/scripts/final_gate.sh .local/loop/review-20260315-092955.json .local/loop/ci-status-0e1fbe998231.json docs/exec-plans/completed/2026-03-14-cli-provenance-and-agent-output.md main`
- Required GitHub check status at gate time:
  `harness-checks=pass` with `ci_failures=0`.
- Retained local evidence bundle:
  `.local/final-evidence/2026-03-14-cli-provenance-and-agent-output/`

## Assumptions

- `print-draft-contract` remains as the auxiliary introspection command, but
  its payload and referenced workflow steps must reflect the renamed primary
  commands.
- The default stdout contract becomes JSON-first for the four workflow
  commands; a separate event-stream protocol is deferred unless execution
  reveals a concrete blocker.
