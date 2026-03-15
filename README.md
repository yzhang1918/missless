# missless

From FOMO to Focus.

missless turns a URL into a reading decision you can inspect.

Drop a link. Get a decision.

## First Slice

- Input: one public URL
- Output:
  - a 1-2 sentence TLDR
  - a `deep_read`, `skim`, or `skip` recommendation
  - ordered claim-first atoms
  - a local review package with evidence you can inspect

## Product Entry

The current product entrypoint is the repository skill at `skills/missless/`.

That skill now depends on one stable installable runtime command: `missless`.

The runtime CLI exists to support deterministic fetch, validation, evidence
anchoring, and review rendering. It is an implementation detail in this slice,
not the main user story.

For day-to-day local development, activate the canonical session-local
developer entry point in the shell you want to use:

```bash
source scripts/dev-activate-missless.sh
missless --help
```

That activation command is safe to rerun after source changes. It refreshes
the CLI, prepends this checkout's repo-local `missless` wrapper to the current
shell `PATH`, and reruns `pnpm install` only when the workspace dependency
state is missing, older than `pnpm-lock.yaml`, or missing required build
dependencies such as `esbuild`. To force a fresh dependency install, set
`MISSLESS_FORCE_INSTALL=1` when sourcing the activation script.

Because the activation is shell-local, different terminal sessions can point at
different `missless` checkouts at the same time. If you want a different
worktree in one shell, source that worktree's activation script in the same
session to move its `missless` wrapper to the front of `PATH`.
The activation helper does not change your current working directory.

## Current Boundary

- This slice is `single-run URL -> review package`.
- Decisions are knowledge-base-agnostic in this slice.
- Persistence, personal knowledge alignment, and web/app surfaces remain
  deferred.
