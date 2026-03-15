# CLI Dev Contract Cleanup

## Metadata

- Plan name: CLI Dev Contract Cleanup
- Owner: Human+Codex
- Date opened: 2026-03-15
- Date completed: 2026-03-15
- Intake source: direct request
- Work type: Harness
- Related issue(s):
  - `#42` Investigate broken tarball packaging for `@missless/cli`

## Objective

Make the repository's current `missless` contract unambiguous for the
high-iteration development phase. The only supported way to run the local CLI
should be `source scripts/dev-activate-missless.sh` followed by `missless ...`.
Remove repository signals that imply tarball or npm-style distribution is a
current supported path.

## Scope

- In scope:
  - Remove package metadata and test coverage that currently claim or validate
    tarball-based installation as a supported contract.
  - Replace packaged-install regression coverage with developer-entrypoint
    coverage centered on `source scripts/dev-activate-missless.sh`.
  - Keep README and skill wording aligned with one supported local-development
    entrypoint.
  - Record the accepted deferment for future distribution work explicitly in
    repository history.
- Out of scope:
  - Repairing tarball packaging or npm release behavior.
  - Defining the future public distribution model for `@missless/cli`.
  - Renaming runtime subcommands or changing first-slice product behavior.

## Acceptance Criteria

- [x] `README.md` and `skills/missless/SKILL.md` describe only the sourced
      activation workflow as the current supported entrypoint.
- [x] `apps/cli/package.json` no longer contains packaging-era contract signals
      that imply current tarball distribution support.
- [x] Repository tests no longer validate or imply tarball installation as a
      current supported path.
- [x] Replacement validation proves `source scripts/dev-activate-missless.sh`
      yields a working `missless` command in the current shell session.
- [x] The accepted deferment for future release packaging is recorded with a
      clear link to issue `#42`.

## Accepted Deferred Risks

- Future npm or tarball distribution is intentionally deferred.
  - Follow-up: `#42` tracks the release-path packaging decision and any future
    artifact validation work.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Remove current-code signals that imply packaged distribution is
  part of the supported development contract.
- Expected files:
  - `apps/cli/package.json`
  - `apps/cli/scripts/build.mjs` only if contract comments need cleanup
- Validation commands:
  - `pnpm --filter @missless/cli build`
  - `pnpm --filter @missless/cli typecheck`
- Documentation impact:
  - Packaging is no longer framed as part of the current supported entrypoint.
- Notes:
  - Removed `bin`, `files`, `prepack`, and `bundleDependencies` from
    `apps/cli/package.json` so the private workspace package no longer signals
    a supported tarball-distribution contract.
  - Reworded the `apps/cli/scripts/build.mjs` contract comment so it describes
    repo-local runtime resolution instead of bundled packaged dependencies.
  - `pnpm --filter @missless/cli build` passed.
  - `pnpm --filter @missless/cli typecheck` still fails in the current
    workspace with unresolved existing package-resolution errors; this slice
    did not touch the failing TypeScript sources.

### Step 2

- Status: completed
- Objective: Replace tarball-install regression coverage with developer
  activation coverage that matches the current supported workflow.
- Expected files:
  - `tests/integration/cli/activation-cli.test.ts`
  - additional helper files only if the new workflow coverage needs them
- Validation commands:
  - `pnpm exec tsx --test tests/integration/cli/activation-cli.test.ts`
- Documentation impact:
  - None if the test names and assertions stay implementation-focused.
- Notes:
  - Removed `tests/integration/cli/installable-cli.test.ts`.
  - Added `tests/integration/cli/activation-cli.test.ts` to validate the
    sourced activation contract directly:
    - repo-local wrapper resolution in both `bash` and `zsh`
    - caller working-directory preservation
    - alias fail-closed behavior in `zsh`
    - runtime help plus `print-draft-contract` in both `bash` and `zsh`
  - `pnpm exec tsx --test tests/integration/cli/activation-cli.test.ts`
    passed.

### Step 3

- Status: completed
- Objective: Align long-lived docs with the one supported local-development
  contract and record the accepted tarball deferment cleanly.
- Expected files:
  - `README.md`
  - `skills/missless/SKILL.md`
  - `docs/harness/completed/2026-03-15-cli-dev-contract-cleanup.md`
- Validation commands:
  - `rg -n "npm pack|npm install -g|tarball|packaged-install" README.md skills/missless/SKILL.md`
  - `rg -n "source scripts/dev-activate-missless.sh" README.md skills/missless/SKILL.md`
- Documentation impact:
  - The user-facing and skill-facing entrypoint story should collapse to one
    supported activation path.
- Notes:
  - Updated `README.md` so the only supported local-development entrypoint is
    `source scripts/dev-activate-missless.sh`.
  - Updated `skills/missless/SKILL.md` so repository agents activate the local
    runtime instead of assuming a preinstalled packaged CLI.
  - A keyword search over current README, skill, package metadata, and CLI
    integration tests found no remaining supported-contract references to
    tarball install, packaged install, `bundleDependencies`, or `prepack`.

### Step 4

- Status: completed
- Objective: Run full branch validation, update plan status, and leave a clear
  repository record of what was intentionally deferred.
- Expected files:
  - `docs/harness/completed/2026-03-15-cli-dev-contract-cleanup.md`
  - `docs/harness/completed/README.md`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `zsh -lc 'source scripts/dev-activate-missless.sh >/dev/null && missless --help >/dev/null'`
  - `git diff --check`
- Documentation impact:
  - The completed plan should record the supported contract and the accepted
    packaging deferment.
- Notes:
  - `pnpm -r build` passed.
  - `pnpm -r test` passed.
  - `zsh -lc 'source scripts/dev-activate-missless.sh >/dev/null && missless --help >/dev/null'`
    passed.
  - `git diff --check` passed.
  - `pnpm -r typecheck` still fails in existing workspace TypeScript paths
    under `packages/core` and `apps/cli`; those failures were observed but not
    changed by this contract-cleanup slice.

## Validation Strategy

- Treat `source scripts/dev-activate-missless.sh` plus `missless ...` as the
  authoritative regression surface for current development workflow behavior.
- Prefer deterministic shell-based validation that explicitly runs in a fresh
  shell session and confirms `missless` resolves after activation.
- Keep existing workspace build, typecheck, and test coverage passing so the
  contract cleanup does not silently regress runtime behavior.

## Review Cadence

- Run delta review after each implementation step.
- Run at least one full-pr review before final gate.

## Review Summary

- Performed a targeted self-review of the changed files after implementation.
- Ran one full-pr review round (`20260315-143707`) for the shipped branch
  state after the cleanup landed.
- Reviewer-subagent runtime attempts in the current environment did not return
  usable artifacts, so the round completed with explicit `manual-fallback`
  reviewer artifacts after recorded `launch-failed` dispatch states.
- Manual fallback review identified two current-slice gaps before the final
  branch state:
  activation regression coverage only exercised `zsh`, and the activated
  wrapper path only smoke-tested `--help` plus `print-draft-contract` instead
  of a behaviorful subcommand.
- Added `bash` coverage and an activated-wrapper `fetch` regression to
  `tests/integration/cli/activation-cli.test.ts`, reran the relevant tests,
  and finalized the aggregated review result with `BLOCKER=0` and
  `IMPORTANT=0`.
- Aligned `skills/README.md` with the narrowed contract so repository
  skill-authoring guidance now points at stable runtime command names plus the
  required activation step when the supported entrypoint is repo-local.
- The final review outcome remained clean, and the deferred packaging
  follow-up stayed isolated under issue `#42`.

## Risks and Mitigations

- Risk: Some repository docs or tests still imply packaged distribution after
  the cleanup.
  - Mitigation: Search for packaging keywords directly and rewrite or remove
    any remaining supported-contract claims.
- Risk: Removing packaging-era metadata accidentally breaks local build or CLI
  invocation.
  - Mitigation: Keep build/typecheck plus sourced-activation smoke in the core
    validation set.
- Risk: Future release work becomes harder to restart because current intent is
  not explicit enough.
  - Mitigation: Record the deferment clearly and keep issue `#42` linked from
    the plan.

## Final Gate Conditions

- All acceptance criteria are checked.
- No long-lived doc or automated test still presents tarball install as a
  current supported path.
- The sourced activation workflow passes local validation on the branch head.
- Review has no unresolved blocker or important findings.

## Delivered Scope

- Removed the remaining packaging-era support signals from the private CLI
  workspace package.
- Replaced tarball-install regression coverage with activation-entrypoint
  regression coverage.
- Collapsed the current documented entrypoint to one supported local workflow:
  `source scripts/dev-activate-missless.sh` then `missless ...`.
- Aligned repository skill-authoring guidance with the activation-based
  developer contract.
- Preserved issue `#42` as the explicit future-release packaging follow-up
  instead of carrying tarball claims in current docs or tests.

## Validation Summary

- `pnpm exec tsx --test tests/integration/cli/activation-cli.test.ts` passed.
- `pnpm -r build` passed.
- `pnpm -r test` passed.
- `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260315-143707 .local/loop/review-20260315-143707-*.json`
  passed with `BLOCKER=0` and `IMPORTANT=0`.
- `zsh -lc 'source scripts/dev-activate-missless.sh >/dev/null && missless --help >/dev/null'`
  passed.
- `git diff --check` passed.
- `rg -n "npm pack|npm install -g|tarball|packaged-install|installable-cli\\.test|bundleDependencies|prepack" README.md skills/missless/SKILL.md apps/cli/package.json tests/integration/cli -S`
  returned no matches.
- `rg -n "stable installable runtime command|installable runtime" skills/README.md`
  returned no matches.
- `pnpm --filter @missless/cli typecheck` and `pnpm -r typecheck` still fail in
  the current workspace with pre-existing TypeScript issues outside the scope
  of this contract-cleanup slice.

## Issue Update Note

- Follow-up issue `#42` remains the repository-backed place to decide and
  implement future release or distribution packaging.

## Publish Record

- Publish outcome: created pull request [#44](https://github.com/yzhang1918/missless/pull/44)
- Publish metadata: direct request (no issue); related follow-up remains `#42`
- Synced the current contract cleanup back to issue `#42` in
  `https://github.com/yzhang1918/missless/issues/42#issuecomment-4063112093`.
