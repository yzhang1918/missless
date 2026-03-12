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

Until npm publishing exists, install the runtime from a built repository
checkout:

```bash
pnpm install
pnpm -r build
npm pack ./apps/cli
npm install -g ./missless-cli-0.0.0.tgz
missless --help
```

For a project-local install instead of a global one:

```bash
mkdir -p /tmp/missless-local
npm install --prefix /tmp/missless-local ./missless-cli-0.0.0.tgz
npx --prefix /tmp/missless-local missless --help
```

## Current Boundary

- This slice is `single-run URL -> review package`.
- Decisions are knowledge-base-agnostic in this slice.
- Persistence, personal knowledge alignment, and web/app surfaces remain
  deferred.
