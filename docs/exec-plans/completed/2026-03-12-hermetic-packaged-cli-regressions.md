# Hermetic Packaged CLI Regressions

## Metadata

- Plan name: Hermetic Packaged CLI Regressions
- Owner: Human+Codex
- Date opened: 2026-03-12
- Date completed: 2026-03-12
- Intake source: GitHub issues `#30` and `#35`
- Work type: Product
- Related issues:
  - `#30` Add CLI integration coverage for the default provider fallback boundary
  - `#35` Make installable CLI tarball regression hermetic
- Scope note: This is one coherent product task because both issues land on the
  same shipped-artifact regression surface: the packed `missless` tarball must
  install deterministically and the installed `missless` bin must directly
  prove the default provider boundary at the user-facing entrypoint.

## Objective

Make the packed `@missless/cli` tarball the authoritative regression surface
for shipped CLI behavior. The packaged artifact should install without npm
registry or npm cache coupling, and the installed `missless` command should
directly prove the shipped `Jina Reader -> direct origin fetch` fallback
boundary plus redirect-preflight fail-closed behavior.

## Scope

- In scope:
  - Remove npm registry and local npm cache coupling from the packaged CLI
    install regression by making the tarball installable from a fresh cache in
    offline mode.
  - Keep `missless` as the stable packaged command surface without changing the
    first-slice subcommand set.
  - Preserve the existing external Node runtime assumption; do not bundle the
    Node.js engine into the package.
  - Add installed-bin regression coverage for one recoverable
    `Jina Reader -> direct_origin` fallback case and one redirect-preflight
    rejection case.
  - Keep the packaged-install regression dependent only on repository-owned
    fixtures, local mock servers, and temporary directories.
  - Update the execution record and any owned docs/spec wording needed to keep
    the shipped CLI contract truthful.
- Out of scope:
  - Making repository bootstrap (`pnpm install`) network-free.
  - npm registry publishing, release automation, or public `npx missless`
    flows tracked in `#27`.
  - New provider metadata or ingest-artifact enrichment tracked in `#29`.
  - Harness/process backlog items such as `#31`, `#32`, `#33`, or `#34`.
  - Broad provider refactors beyond what is required to prove the shipped
    fallback and redirect boundary through the packaged CLI surface.

## Acceptance Criteria

- [x] Packing `./apps/cli` still produces an installable `@missless/cli`
      tarball for the current first-slice command surface.
- [x] Local and prefix-global installation from the packed tarball succeed in
      offline mode with fresh npm cache directories, so the regression no
      longer depends on live registry access or prewarmed cache state.
- [x] The installed `missless` bin still passes `--help`,
      `print-draft-contract`, and the existing happy-path `fetch-normalize`
      smoke against repository-owned fixtures.
- [x] The installed `missless fetch-normalize` regression directly covers one
      recoverable default-provider fallback case and records the expected
      `direct_origin` result in run artifacts.
- [x] The installed `missless fetch-normalize` regression directly covers one
      redirect-preflight rejection case and proves blocked redirect targets do
      not fall back.
- [x] `pnpm -r build`, `pnpm -r typecheck`, `pnpm -r test`, and targeted
      packaged-install validation pass on the branch head.
- [x] The branch closes `#30` and `#35` without creating new follow-up issues;
      if execution uncovers extra work that cannot be resolved in-scope, stop
      and realign instead of widening the backlog.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Make the packaged CLI artifact self-contained enough that
  installing the tarball no longer requires npm registry access or prior npm
  cache state.
- Expected files:
  - `apps/cli/scripts/build.mjs`
  - `apps/cli/package.json`
- Validation commands:
  - `pnpm --filter @missless/cli build`
  - `npm pack ./apps/cli --json --pack-destination .local/tmp/hermetic-tarballs`
  - `npm install --offline --cache <fresh-cache-local> --prefix <fresh-prefix-local> <packed-tarball>`
  - `npm install --offline --cache <fresh-cache-global> --prefix <fresh-prefix-global> -g <packed-tarball>`
- Documentation impact:
  - Record the packaging choice in the plan because the shipped install
    contract stays ESM-first and does not imply npm publishing.

### Step 2

- Status: completed
- Objective: Extend the packaged-install regression so the installed bin proves
  both the shipped fallback success path and the redirect-preflight fail-closed
  path using only repository-owned fixtures and local mocks.
- Expected files:
  - `tests/integration/cli/installable-cli.test.ts`
  - `tests/integration/cli/fetch-normalize.test.ts`
  - `tests/integration/cli/e2e-driver.test.ts`
  - `tests/helpers/fetch-mock.mjs`
- Validation commands:
  - `pnpm exec tsx --test tests/integration/cli/installable-cli.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/fetch-normalize.test.ts`
  - `pnpm exec tsx --test tests/integration/cli/e2e-driver.test.ts`
- Documentation impact:
  - No long-lived docs/spec change required if the installed-bin regression
    becomes the proof point without changing the user-facing CLI contract.

### Step 3

- Status: completed
- Objective: Run full validation, update owned docs/specs or plan evidence as
  needed, and leave the branch archive-ready with clear closure for both
  intake issues.
- Expected files:
  - `docs/exec-plans/completed/2026-03-12-hermetic-packaged-cli-regressions.md`
  - `docs/exec-plans/completed/README.md`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `git diff --check`
- Documentation impact:
  - Ensure the plan records why long-lived docs/specs stayed unchanged: the
    shipped install and fallback contract remained the same, but the regression
    proof surface became deterministic.

## Validation Strategy

- Treat the packed tarball plus installed `missless` bin as the primary
  regression surface for this slice.
- Use fresh temp prefixes plus fresh npm cache directories and offline install
  mode to prove hermetic packaged-install behavior.
- Keep network-sensitive behavior under repository-owned local mock servers,
  fixture content, and fake agent binaries only; no live Codex or live fetches
  should be required by the targeted regressions.
- Keep the existing workspace unit and integration suite passing so packaging
  changes do not silently regress repo-native behavior.

## Review Cadence

- Run delta review after each implementation step.
- Run at least one full-PR review before final gate.
- Re-check issue scope before archiving so this plan closes `#30` and `#35`
  without spawning new backlog work.

## Review Summary

- `20260312-141748` full-pr review passed with `BLOCKER=0` and
  `IMPORTANT=0` in `.local/loop/review-20260312-141748.json`.
- Review used subagent reviewer artifacts for correctness, tests-regression,
  docs-spec-consistency, and reliability, then aggregated them through the
  review-loop finalizer.
- Reviewed dimensions: correctness, tests-regression,
  docs-spec-consistency, and reliability for the packaging, install regression,
  and local-mock changes.
- Review conclusion: the ESM-first `bundleDependencies` packaging change and
  the installed-bin fallback regressions are ready for publish/final-gate once
  issue/PR linkage is refreshed on the current branch head.

## Final Gate Conditions

- All acceptance criteria are checked.
- Fresh-cache offline packaged-install validation passes for both local and
  prefix-global flows.
- Full workspace build, typecheck, and test commands pass on synchronized
  branch state.
- Owned docs/specs and the archived plan match the shipped code.
- Review has no unresolved blocker or important findings.
- PR and issue updates are ready to close `#30` and `#35` on merge, with no
  newly created follow-up issue.

## Risks And Mitigations

- Risk: Bundling runtime dependencies into the packaged artifact changes CLI
  behavior or masks a packaging-only regression.
  - Mitigation: Keep the installed-bin smoke plus existing workspace tests in
    the validation set.
- Risk: Offline npm install behavior differs between local-prefix and
  prefix-global flows.
  - Mitigation: Validate both flows with separate fresh cache directories.
- Risk: Packaged-install coverage grows too broad and slows the suite without
  adding much signal.
  - Mitigation: Limit packaged-bin additions to the shipped happy path,
    one recoverable fallback case, and one redirect-preflight rejection case.
- Risk: Execution reveals adjacent provider or publish debt that would
  normally become a follow-up issue.
  - Mitigation: Keep the slice tightly scoped and stop for realignment instead
    of opening new backlog items.

## Execution Notes

- Preserved the packaged CLI as ESM. The branch does not pivot to CJS and does
  not bundle the Node.js engine into the artifact.
- Solved the packaged-install hermeticity gap with npm
  `bundleDependencies`, not by changing module format. `esbuild` still bundles
  workspace code, while the runtime packages stay external in the build and are
  carried inside the tarball for offline install flows.
- Added one shared test-only fetch mock module so repo-native CLI tests,
  packaged-install tests, and the fake-agent review driver can all exercise the
  same network-sensitive paths without live fetch access.
- No new follow-up issue was required during execution because the ESM-first
  packaging approach covered both the install determinism goal from `#35` and
  the shipped fallback boundary proof from `#30`.

## Validation Summary

- `npm pack ./apps/cli --json --pack-destination .local/tmp` produced a tarball
  that records bundled runtime dependencies for offline install flows.
- `pnpm exec tsx --test tests/integration/cli/fetch-normalize.test.ts` passed.
- `pnpm exec tsx --test tests/integration/cli/installable-cli.test.ts` passed.
- `pnpm exec tsx --test tests/integration/cli/e2e-driver.test.ts` passed.
- `pnpm -r build` passed.
- `pnpm -r typecheck` passed.
- `pnpm -r test` passed.
- `git diff --check` passed.

## Issue Update Note

- `#30` status sync comment:
  [issuecomment-4047163842](https://github.com/yzhang1918/missless/issues/30#issuecomment-4047163842)
- `#35` status sync comment:
  [issuecomment-4047163845](https://github.com/yzhang1918/missless/issues/35#issuecomment-4047163845)
- Both issues remain open until the branch is published and merged; no new
  follow-up issue was created during execution.

## Final Gate Summary

- Not run in this session because the branch has not been published to a PR and
  no GitHub-backed CI status artifact exists yet for the current `HEAD`.
