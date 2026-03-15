# Local CLI Dev Install Workflow

## Metadata

- Plan name: Local CLI Dev Install Workflow
- Owner: Human+Codex
- Date opened: 2026-03-15
- Date completed: 2026-03-15
- Intake source: Direct request in chat (no issue)
- Work type: Harness/process
- Related issues:
  - Follow-up packaging blocker: [#42](https://github.com/yzhang1918/missless/issues/42)

## Objective

Provide one repeatable session-local activation path for the `missless` CLI so a contributor can rerun the same command after code changes and end up with an updated `missless` command in the current shell, while recording the packaged-tarball blocker in tracked evidence instead of the README.

## Scope

- In scope:
  - Add one canonical developer activation entry point that is safe to rerun without manually reasoning about current shell state.
  - Make the developer path worktree-local and session-local rather than global, so different terminals can point at different checkouts.
  - Update repository docs so day-to-day local-development guidance is concise and user-facing.
  - Validate that the developer activation path yields a runnable `missless` command from the current checkout.
  - Record the separate tarball-packaging blocker in tracked execution evidence and a follow-up issue.
- Out of scope:
  - Real npm publishing, versioning, or registry automation.
  - Watch-mode rebuild automation.
  - Cross-platform shell abstraction beyond the repository's current local development assumptions.
  - Repairing the packaged tarball itself in this harness slice.

## Acceptance Criteria

- [x] The repository exposes one documented developer activation entry point that contributors can rerun after source changes without manually handling prior shell state or global `npm link` state.
- [x] Running the developer activation path makes `missless` resolve to the current repository checkout inside the current shell session.
- [x] The developer activation path does not rely on mutating a machine-global `missless` link, so different terminal sessions can activate different worktrees independently.
- [x] Re-sourcing the same checkout after another `missless` worktree can move this checkout's wrapper back to the front of `PATH` without mutating machine-global link state.
- [x] The activation helper preserves the caller's working directory and fails closed if package-local `node_modules` resolves outside the current worktree.
- [x] README documents the session-local developer activation workflow in concise user-facing terms and no longer advertises broken packaged-install commands.
- [x] Validation evidence shows the developer activation workflow succeeds and the separate tarball blocker is captured in tracked evidence.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define one canonical session-local developer activation contract and repository entry point for local CLI development without collapsing it into tarball packaging.
- Expected files:
  - `scripts/dev-activate-missless.sh`
  - `scripts/bin/missless`
- Validation commands:
  - `bash -n scripts/dev-activate-missless.sh`
  - `bash -n scripts/bin/missless`
  - `cd apps/cli && pnpm exec node scripts/build.mjs`
  - `zsh -lc 'repo=/Users/yaozhang/.codex/worktrees/50ee/missless && tmp_dir=$(mktemp -d) && tmp_dir_physical=$(cd "$tmp_dir" && pwd -P) && cd "$tmp_dir" && source "$repo/scripts/dev-activate-missless.sh" >/dev/null && [ "$(pwd -P)" = "$tmp_dir_physical" ]'`
  - `zsh -lc 'repo=/Users/yaozhang/.codex/worktrees/50ee/missless && export PATH="/tmp/fake:$repo/scripts/bin:$PATH" && source "$repo/scripts/dev-activate-missless.sh" >/dev/null && [ "$(command -v missless)" = "$repo/scripts/bin/missless" ] && case "$PATH" in "$repo/scripts/bin":*) ;; *) exit 1 ;; esac'`
  - `zsh -lc 'alias missless="echo nope"; if source /Users/yaozhang/.codex/worktrees/50ee/missless/scripts/dev-activate-missless.sh >/tmp/missless-alias.out 2>/tmp/missless-alias.err; then exit 1; fi; grep -q "defines it as alias" /tmp/missless-alias.err'`
- Documentation impact:
  - Establish the sourced activation entry point that README will reference as the default local-development workflow.
- Evidence:
  - The first implementation spike used global `npm link`, but the requirement changed after execution: terminal sessions must be able to point at different worktrees independently.
  - Delta review round `20260315-093010` surfaced two `IMPORTANT` findings against the global-link approach: it could report success while resolving a stale `missless`, and it could not satisfy per-session worktree isolation.
  - Replaced the global-link approach with `scripts/dev-activate-missless.sh`, a sourced activation script that bootstraps the current worktree when needed, rebuilds `@missless/cli`, prepends one repo-local bin directory to `PATH`, and validates that `missless` resolves to the current worktree's `scripts/bin/missless`.
  - Added `scripts/bin/missless`, a repo-local wrapper that executes `apps/cli/dist/index.js` from the current checkout and fails closed if the CLI has not been built yet.
  - Removed the earlier `pnpm dev:install:missless` / `npm link` path because child processes cannot persist shell environment changes and machine-global linking cannot satisfy per-session worktree isolation.
  - Skipped an isolated Red-phase test because the behavior under change is shell-session activation and PATH precedence rather than a repository-local pure function; used command-level validation instead.
  - Full-pr review round `20260315-101754` surfaced four `IMPORTANT` implementation gaps in the first session-local version: sourcing changed the caller's working directory, repeated activation could not move one checkout back ahead of another in `PATH`, activation always reran a mutable `pnpm install`, and package-local `node_modules` from another checkout could shadow the current worktree.
  - Updated `scripts/dev-activate-missless.sh` so install/build work runs in subshells, preserving the caller's working directory while still exporting session-local PATH changes.
  - Replaced the previous "prepend only if missing" PATH logic with a unique-prepend helper so `source A -> source B -> source A` moves A's wrapper back to the front of `PATH`.
  - Gated `pnpm install` behind missing or stale workspace state, missing build dependencies, or an explicit `MISSLESS_FORCE_INSTALL=1`, so repeated activation does not rewrite dependencies unless the current worktree actually needs bootstrap.
  - Added guards in both `scripts/dev-activate-missless.sh` and `scripts/bin/missless` so activation fails closed if `apps/cli/node_modules` resolves outside the current worktree. During review validation, deleting an untracked external symlink at `apps/cli/node_modules` immediately reproduced a missing-`esbuild` failure, confirming the earlier build success had been polluted by another checkout.
  - Delta review round `20260315-132449` found one remaining correctness bug: a shell alias or function named `missless` could still override the activated wrapper even when PATH validation succeeded.
  - Added `missless_require_no_shell_override` to `scripts/dev-activate-missless.sh`, so activation now fails closed if the current shell already defines `missless` as an alias or function instead of letting the session continue with a misleading success message.
  - Ran `bash -n scripts/dev-activate-missless.sh`, `bash -n scripts/bin/missless`, `cd apps/cli && pnpm exec node scripts/build.mjs`, `zsh -lc 'source scripts/dev-activate-missless.sh && command -v missless && missless --help'`, the caller-working-directory validation command above, the PATH-rebinding validation command above, the alias-override validation command above, and a negative guard test that sourced the activation script after replacing `apps/cli/node_modules` with an external symlink; all behaved as intended.

### Step 2

- Status: completed
- Objective: Update the user-facing install guidance so session-local development activation is concise, legible, and clearly distinct from the separate packaged-tarball follow-up.
- Expected files:
  - `README.md`
- Validation commands:
  - `rg -n "source|MISSLESS_FORCE_INSTALL|current working directory" README.md`
- Documentation impact:
  - Rewrite the install section so contributors can follow the local-development workflow without reading execution-log detail in the README.
- Evidence:
  - Updated `README.md` so local development now documents `source scripts/dev-activate-missless.sh` as the canonical day-to-day workflow instead of the removed global-link path.
  - Documented the session-local contract explicitly: activation affects the current shell, preserves the caller's working directory, different terminals can point at different worktrees, and re-sourcing another worktree in one shell moves that worktree's wrapper to the front of `PATH`.
  - Documented the activation bootstrap contract explicitly: rerunning the script rebuilds the CLI and reruns `pnpm install` only when workspace state is missing or stale, when required build dependencies such as `esbuild` are unavailable in the current worktree, or when `MISSLESS_FORCE_INSTALL=1` is set.
  - Removed the broken tarball-install commands from `README.md`; the packaged-tarball blocker is now tracked in this plan and follow-up issue `#42` instead of being explained inline in the user-facing entrypoint doc.
  - Ran `rg -n "source|MISSLESS_FORCE_INSTALL|current working directory" README.md`; the updated install section and the key local-development contract points were present as expected.

### Step 3

- Status: completed
- Objective: Validate the new developer activation entry point end to end and record the separate tarball blocker in tracked evidence.
- Expected files:
  - `docs/harness/completed/2026-03-15-local-cli-dev-install.md`
- Validation commands:
  - `zsh -lc 'source scripts/dev-activate-missless.sh && command -v missless && missless --help'`
  - `cd apps/cli && npm pack --json --pack-destination /tmp/missless-pack-good`
  - `tar -tzf /tmp/missless-pack-good/missless-cli-0.0.0.tgz | sed -n '1,40p'`
  - `cd apps/cli && pnpm pack --pack-destination /tmp/missless-pnpm-pack`
  - `npm install --prefix <fresh-temp-prefix> /tmp/missless-pack-good/missless-cli-0.0.0.tgz`
  - `npx --prefix <fresh-temp-prefix> missless --help`
- Documentation impact:
  - Record validation outcomes and the packaged-tarball blocker directly in tracked execution history instead of the README.
- Evidence:
  - The session-local activation workflow passed end to end with `zsh -lc 'source scripts/dev-activate-missless.sh && command -v missless && missless --help'`.
  - `cd apps/cli && npm pack --json --pack-destination /tmp/missless-pack-good` completes after restoring `apps/cli/package.json` to the `origin/main` `prepack` contract and restoring `apps/cli/scripts/build.mjs` to the shipped external-runtime contract.
  - The produced tarball is still invalid for local install in this worktree: `tar -tzf /tmp/missless-pack-good/missless-cli-0.0.0.tgz | sed -n '1,40p'` shows many `package/../../node_modules/...` entries, `npm install --prefix <fresh-temp-prefix> /tmp/missless-pack-good/missless-cli-0.0.0.tgz` emits repeated `TAR_ENTRY_ERROR path contains '..'` warnings, and `npx --prefix <fresh-temp-prefix> missless --help` fails with `Cannot find module 'tough-cookie'`.
  - `pnpm pack --pack-destination /tmp/missless-pnpm-pack` in `apps/cli` fails closed with `ERR_PNPM_BUNDLED_DEPENDENCIES_WITHOUT_HOISTED`, which is the current best tracked packaging error in this worktree.
  - Step 3's investigative objective is complete: the developer activation path is validated, and the packaged-tarball blocker is captured for follow-up instead of being widened into this harness slice.

## Validation Plan

- Checks to run:
  - `bash -n scripts/dev-activate-missless.sh`
  - `bash -n scripts/bin/missless`
  - `cd apps/cli && pnpm exec node scripts/build.mjs`
  - `zsh -lc 'source scripts/dev-activate-missless.sh && command -v missless && missless --help'`
  - `zsh -lc 'repo=/Users/yaozhang/.codex/worktrees/50ee/missless && tmp_dir=$(mktemp -d) && tmp_dir_physical=$(cd "$tmp_dir" && pwd -P) && cd "$tmp_dir" && source "$repo/scripts/dev-activate-missless.sh" >/dev/null && [ "$(pwd -P)" = "$tmp_dir_physical" ]'`
  - `zsh -lc 'repo=/Users/yaozhang/.codex/worktrees/50ee/missless && export PATH="/tmp/fake:$repo/scripts/bin:$PATH" && source "$repo/scripts/dev-activate-missless.sh" >/dev/null && [ "$(command -v missless)" = "$repo/scripts/bin/missless" ] && case "$PATH" in "$repo/scripts/bin":*) ;; *) exit 1 ;; esac'`
  - Negative guard validation by replacing `apps/cli/node_modules` with an external symlink before sourcing `scripts/dev-activate-missless.sh`
  - `cd apps/cli && npm pack --json --pack-destination /tmp/missless-pack-good`
  - `tar -tzf /tmp/missless-pack-good/missless-cli-0.0.0.tgz | sed -n '1,40p'`
  - `cd apps/cli && pnpm pack --pack-destination /tmp/missless-pnpm-pack`
  - `npm install --prefix <fresh-temp-prefix> /tmp/missless-pack-good/missless-cli-0.0.0.tgz`
  - `npx --prefix <fresh-temp-prefix> missless --help`
  - `git diff --check`
- Evidence to capture:
  - Plan step status updates as each step lands
  - Delta review after implementation of the session-local activation entry point
  - Final review before final gate
  - Plan validation summary with the observed command outcomes and any environment caveats

## Review Cadence

- Delta review after Step 1 because shell activation behavior and PATH precedence are the highest-risk contract changes.
- Delta review after Step 2 if the documentation materially changes command expectations or prerequisites.
- Full-pr review before final gate after Step 3 validation is complete.

## Final Gate Conditions

- One rerunnable session-local developer activation entry point exists and matches the documented command in `README.md`.
- The local-development workflow yields a working session-local `missless` command from the current checkout without requiring a global link mutation.
- The tracked record accurately states the packaged-tarball blocker and links the spawned follow-up instead of leaving the blocker only in chat context.
- Validation evidence and review records are captured in the archived plan before publish/final-gate work.

## Validation Summary

- Step 1 validation passed:
  - `bash -n scripts/dev-activate-missless.sh`
  - `bash -n scripts/bin/missless`
  - `cd apps/cli && pnpm exec node scripts/build.mjs`
  - `zsh -lc 'source scripts/dev-activate-missless.sh && command -v missless && missless --help'`
  - `zsh -lc 'repo=/Users/yaozhang/.codex/worktrees/50ee/missless && tmp_dir=$(mktemp -d) && tmp_dir_physical=$(cd "$tmp_dir" && pwd -P) && cd "$tmp_dir" && source "$repo/scripts/dev-activate-missless.sh" >/dev/null && [ "$(pwd -P)" = "$tmp_dir_physical" ]'`
  - `zsh -lc 'repo=/Users/yaozhang/.codex/worktrees/50ee/missless && export PATH="/tmp/fake:$repo/scripts/bin:$PATH" && source "$repo/scripts/dev-activate-missless.sh" >/dev/null && [ "$(command -v missless)" = "$repo/scripts/bin/missless" ] && case "$PATH" in "$repo/scripts/bin":*) ;; *) exit 1 ;; esac'`
  - `zsh -lc 'alias missless="echo nope"; if source /Users/yaozhang/.codex/worktrees/50ee/missless/scripts/dev-activate-missless.sh >/tmp/missless-alias.out 2>/tmp/missless-alias.err; then exit 1; fi; grep -q "defines it as alias" /tmp/missless-alias.err'`
  - Negative guard validation: replacing `apps/cli/node_modules` with an external symlink makes `source scripts/dev-activate-missless.sh` fail closed with the expected path-isolation error
- Step 2 validation passed:
  - `rg -n "source|MISSLESS_FORCE_INSTALL|current working directory" README.md`
- Step 3 investigative validation completed:
  - `cd apps/cli && npm pack --json --pack-destination /tmp/missless-pack-good`
  - `tar -tzf /tmp/missless-pack-good/missless-cli-0.0.0.tgz | sed -n '1,40p'`
  - `git diff --check`
- Step 3 blocker evidence recorded:
  - `cd apps/cli && pnpm pack --pack-destination /tmp/missless-pnpm-pack`
  - `npm install --prefix <fresh-temp-prefix> /tmp/missless-pack-good/missless-cli-0.0.0.tgz`
  - `npx --prefix <fresh-temp-prefix> missless --help`
  - `pnpm pack` fails closed with `ERR_PNPM_BUNDLED_DEPENDENCIES_WITHOUT_HOISTED`.
  - `npm pack` emits a tarball whose first entries already include `package/../../node_modules/...`, `npm install` emits repeated `TAR_ENTRY_ERROR path contains '..'` warnings, and the installed CLI still fails at runtime with `Cannot find module 'tough-cookie'`.

## Review Summary

- Full-pr review round `20260315-101754` found the initial session-local implementation gaps around caller working directory preservation, PATH rebinding, unconditional installs, and package-local dependency leakage.
- Full-pr review round `20260315-102823` confirmed the implementation fixes cleared performance/reliability concerns and narrowed the remaining work to documentation and recorded-validation alignment.
- Delta review round `20260315-103114` passed with `BLOCKER=0` and `IMPORTANT=0`, clearing the final correctness and docs/spec consistency findings after the README and plan evidence were updated.
- Delta review round `20260315-132449` found one remaining correctness issue around shell aliases or functions overriding `missless`; the activation script now fails closed on shell-level overrides instead of reporting a misleading success.
- Delta review round `20260315-132701` cleared the final docs/correctness findings after the shell-override guard and archive cleanup landed.

## Risks and Mitigations

- Risk: A non-sourced helper cannot persist environment changes back into the caller shell, so the documented entry point could appear to succeed while leaving `missless` unavailable.
- Mitigation: Use an explicitly sourced activation script and validate it through `zsh -lc 'source ... && command -v missless'`.
- Risk: PATH precedence could still leave an older `missless` ahead of the repo-local wrapper.
- Mitigation: Remove any existing copy of the repo-local wrapper from `PATH`, prepend it once, and validate the resolved `missless` path directly.
- Risk: The developer-install script and README drift apart.
- Mitigation: Make the README point to one canonical entry point and validate the exact documented commands during execution.
- Risk: The developer-install path starts behaving like a release workflow and becomes slow or stateful.
- Mitigation: Keep tarball validation as a separate investigative path and do not reuse it for the default local-development script.
- Risk: Broken packaged-install instructions could linger in README even after this harness slice deliberately defers the packaging fix.
- Mitigation: Remove the broken packaged-install commands from README and keep the blocker evidence in this archived plan plus issue `#42`.
- Risk: package-local `node_modules` from another checkout could shadow the current worktree and make activation appear healthy when it is not.
- Mitigation: Fail closed if `apps/cli/node_modules` resolves outside the current worktree, and bootstrap current-worktree dependencies before building.

## Completion Summary

- Delivered:
  - A sourced, session-local `missless` activation workflow in `scripts/dev-activate-missless.sh`
  - A repo-local `scripts/bin/missless` wrapper that runs the current checkout's built CLI
  - Updated `README.md` guidance for day-to-day development, focused on the local activation workflow
  - A tracked validation record showing the developer path works and the packaged-tarball blocker is captured for follow-up
- Not delivered:
  - A clean, installable tarball workflow from this worktree
- Linked issue updates:
  - Direct request (no issue).
- Spawned follow-up issues:
  - [#42](https://github.com/yzhang1918/missless/issues/42) tracks the tarball-packaging blocker discovered during Step 3 validation.
