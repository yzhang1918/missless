# Installable Skill and Stable CLI Entrypoint

## Metadata

- Plan name: Installable Skill and Stable CLI Entrypoint
- Owner: Human+Codex
- Date opened: 2026-03-11
- Date completed: 2026-03-11
- Intake source: GitHub issue #14
- Work type: Product
- Related issue(s): #14

## Objective

Package the first-slice `missless` runtime behind a stable `missless` command so
the product skill no longer depends on the current repository layout. Keep the
product contract as `single-run URL -> review package` while making local or
global tarball installation the supported way to invoke the runtime.

## Scope

- In scope:
  - Make the runtime surface legible as `missless <subcommand>`.
  - Ensure the CLI package can be packed and then installed locally or globally
    to expose the `missless` command without using
    `node apps/cli/dist/index.js`.
  - Rewrite the product skill and user-facing docs to depend on the stable
    command rather than repository-relative runtime paths.
  - Add the minimum targeted validation needed to prove tarball-installed
    `missless` works in addition to existing workspace build/typecheck/test
    coverage.
  - Update the plan record in this branch and archive it on completion.
- Out of scope:
  - Publishing to npm or any other package registry.
  - Provider fallback or SSRF hardening follow-up work tracked in #15 and #16.
  - Harness/process code changes for publish, final-gate, or review-loop work.
  - Broad documentation split or cleanup work tracked in #17.
  - Broad provider-internal refactors unrelated to the CLI entrypoint contract.

## Acceptance Criteria

- [x] `skills/missless/SKILL.md` uses `missless ...` as the runtime command
      surface and no longer instructs users to run
      `node apps/cli/dist/index.js ...`.
- [x] `apps/cli` exposes a stable `missless` bin that works after local or
      global tarball installation without depending on the repository layout at
      invocation time.
- [x] `README.md` and `skills/README.md` describe the current supported install
      and invocation story in a way that matches the first-slice product
      contract.
- [x] The first-slice runtime subcommands and behavior remain legible and
      unchanged in intent: `fetch-normalize`, `print-draft-contract`,
      `validate-draft`, `anchor-evidence`, `render-review`.
- [x] `scripts/e2e/run_missless_review.sh` is updated only if the stable
      entrypoint contract requires it.
- [x] `pnpm -r build`, `pnpm -r typecheck`, `pnpm -r test`, and targeted
      stable-entrypoint checks for local and prefix-global tarball installs pass
      locally.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Lock the stable CLI contract and make the package installation
  path explicit without expanding the first-slice product scope.
- Expected files:
  - `apps/cli/package.json`
  - `apps/cli/src/index.ts`
  - `apps/cli/src/commands/print-draft-contract.ts`
- Validation commands:
  - `pnpm --filter @missless/cli build`
  - `npm pack ./apps/cli --pack-destination .local/tmp/tarballs3`
- Documentation impact:
  - Runtime help output and package metadata should reflect the stable command
    users and skills will call.

### Step 2

- Status: completed
- Objective: Rewrite the product skill and user-facing docs so the supported
  install/invocation flow is stable-command-first instead of repository-path-
  first.
- Expected files:
  - `skills/missless/SKILL.md`
  - `README.md`
  - `skills/README.md`
  - `scripts/e2e/run_missless_review.sh` only if needed
- Validation commands:
  - `rg -n "node apps/cli/dist/index\\.js" README.md skills/README.md skills/missless/SKILL.md`
  - `./.local/tmp/tar-install-local/node_modules/.bin/missless print-draft-contract`
- Documentation impact:
  - Product-facing instructions and runtime usage examples should align on one
    stable `missless` command surface.

### Step 3

- Status: completed
- Objective: Validate the full branch, record issue linkage, and archive the
  plan if the scoped work is complete.
- Expected files:
  - `docs/exec-plans/completed/2026-03-11-installable-skill-stable-cli.md`
  - `docs/exec-plans/completed/README.md`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `./.local/tmp/tar-install-local/node_modules/.bin/missless --help`
  - `./.local/tmp/tar-install-local/node_modules/.bin/missless print-draft-contract`
  - `./.local/tmp/tar-install-global/bin/missless --help`
  - `./.local/tmp/tar-install-global/bin/missless print-draft-contract`
- Documentation impact:
  - The execution record should show the issue intake source, delivered scope,
    and local validation evidence.

## Validation Strategy

- Prefer the existing deterministic unit and integration suite for runtime
  behavior regression coverage.
- Add targeted command-surface checks through the package-installed `missless`
  bin rather than repository-relative node execution.
- Keep validation scoped to the owned surface unless a regression forces a
  broader fix.

## Review Cadence

- Run delta review after each implementation step.
- Run at least one full-pr review before final gate.

## Review Summary

- `20260311-141640` full-pr review: blocked with 2 `IMPORTANT` findings
  covering missing automated tarball-install regression coverage and premature
  completion records before review/final-gate evidence existed.
- Follow-up fixes added `apps/cli/scripts/build.mjs`, `prepack`, an automated
  packaged-CLI integration smoke test, and narrower README wording around the
  CLI-vs-skill install story.
- `20260311-141945` full-pr re-review: code findings cleared; one
  docs/process `IMPORTANT` remained because the plan had already been archived
  as completed and the linked issue update still implied the loop was closed.
- Follow-up workflow fix: restored the plan to `active/` and updated the linked
  issue comment so the task no longer claimed completion before final gate.
- `20260311-142211` docs/process delta review: passed with 0 blocker/important
  findings after the plan/issue workflow records were corrected.

## Final Gate Conditions

- All acceptance criteria are checked.
- The stable `missless` command is the only product-facing runtime invocation
  documented in the owned surface.
- Full local validation passes.
- Full-pr review has no unresolved blocker/important findings.
- Final-gate evidence is recorded before the plan returns to
  `docs/exec-plans/completed/`.

## Final Gate Summary

- Final gate artifact: `.local/loop/final-gate-20260311-142211.json`
- Review artifact used for the gate:
  `.local/loop/review-20260311-142211.json`
- Local CI-equivalent artifact used for the gate:
  `.local/loop/ci-20260311-142211.json`
- Result: pass
- Basis:
  - required local checks passed
  - docs/spec updates were present
  - local branch matched fetched `origin/main` at gate time

## Risks and Mitigations

- Risk: Documentation switches to `missless` while the package install path is
  still fragile.
  - Mitigation: Validate through the package bin, not only through direct node
    execution.
- Risk: Packaging changes accidentally alter runtime behavior or subcommand
  naming.
  - Mitigation: Keep the command set intact and rely on existing CLI tests plus
    targeted entrypoint checks.
- Risk: Real npm publishing concerns leak into this issue and expand scope.
  - Mitigation: Document local/global installation only and defer registry
    publication.

## Validation Summary

- `pnpm -r build` passed.
- `pnpm -r typecheck` passed.
- `pnpm -r test` passed.
- `git diff --check` passed.
- `npm pack ./apps/cli --pack-destination .local/tmp/tarballs3` produced
  `missless-cli-0.0.0.tgz`.
- Local tarball install via
  `npm install --prefix .local/tmp/tar-install-local ./.local/tmp/tarballs3/missless-cli-0.0.0.tgz`
  succeeded, and the installed bin passed:
  - `./.local/tmp/tar-install-local/node_modules/.bin/missless --help`
  - `./.local/tmp/tar-install-local/node_modules/.bin/missless print-draft-contract`
- Prefix-global tarball install via
  `npm install --prefix .local/tmp/tar-install-global -g ./.local/tmp/tarballs3/missless-cli-0.0.0.tgz`
  succeeded, and the installed bin passed:
  - `./.local/tmp/tar-install-global/bin/missless --help`
  - `./.local/tmp/tar-install-global/bin/missless print-draft-contract`
- Updated packaged-CLI regression evidence on the latest branch state:
  - `pnpm exec tsx --test tests/integration/cli/installable-cli.test.ts`
  - `npm pack ./apps/cli --pack-destination .local/tmp/review-tarballs`
  - `./.local/tmp/review-tar-install-local/node_modules/.bin/missless --help`
  - `./.local/tmp/review-tar-install-global/bin/missless print-draft-contract`
- Review-loop evidence on the latest branch state:
  - `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260311-141640 .local/loop/review-20260311-141640-*.json`
  - `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260311-141945 .local/loop/review-20260311-141945-*.json`
  - `.agents/skills/loop-review-loop/scripts/review_finalize.sh 20260311-142211 .local/loop/review-20260311-142211-docs-spec-consistency.json`
- Final-gate evidence on the latest branch state:
  - `.agents/skills/loop-final-gate/scripts/final_gate.sh .local/loop/review-20260311-142211.json .local/loop/ci-20260311-142211.json .local/loop/final-gate-20260311-142211.json`

## Completion Summary

- Delivered:
  - bundled `apps/cli` into a self-contained installable `missless` bin
  - moved the CLI build logic into `apps/cli/scripts/build.mjs`
  - added `prepack` so tarball packaging rebuilds the CLI and schema copy
  - copied the extraction-draft schema into the packed CLI surface and updated
    `print-draft-contract` to report the packaged schema path
  - rewrote `skills/missless/SKILL.md`, `README.md`, and `skills/README.md` to
    treat `missless` as the stable runtime command
  - updated `scripts/e2e/run_missless_review.sh` to expose a stable `missless`
    command during repository-native validation
  - added automated coverage for local and prefix-global tarball installs in
    `tests/integration/cli/installable-cli.test.ts`
- Not delivered:
  - npm registry publishing, release automation, or public `npx missless`
    support
- Linked issue updates:
  - source issue: #14
  - published PR: #28
  - issue comment updated after final gate with the latest review/gate status
  - issue comment updated again after publish with the PR link and follow-up
    issue #27
- Spawned follow-up issues:
  - #27 `Publish missless CLI to npm and support public install flows`
