# missless

From FOMO to Focus.

missless helps you decide what matters from links and ideas.

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

The runtime CLI exists to support deterministic fetch, validation, evidence
anchoring, and review rendering. It is an implementation detail in this slice,
not the main user story.

## Current Boundary

- This slice is `single-run URL -> review package`.
- Decisions are knowledge-base-agnostic in this slice.
- Persistence, personal knowledge alignment, and web/app surfaces remain
  deferred.
