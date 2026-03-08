# Product Foundation

Status: Draft

## Purpose

Capture the current product intent in one place until detailed scope decisions are made.

## Positioning

- From FOMO to Focus.
- missless is an AI judgment engine for links and ideas.
- Read less. Know more. Miss less.
- Drop a link. Get a decision.

## Problem

- Information overload and derivative content reduce signal.
- Link collection alone does not create durable understanding.
- Users want concise judgment with evidence they can inspect.

## Product Intent

`missless` converts sources into reusable knowledge and clear reading decisions.

## Core Principles

- Decision over collection.
- Citation is not destination.
- Human control at persistence boundaries.
- Evidence traceability for important conclusions.
- Interface-agnostic core semantics.

## Baseline Workflow (Discussion Draft)

1. User submits a source.
2. System reads full content and extracts candidate knowledge.
3. System validates and materializes supporting evidence anchors.
4. System aligns candidates against existing knowledge.
5. System proposes what to accept, reject, edit, or defer.
6. Human decides what persists.

## First Delivery Slice

- Start with a pnpm-workspace monorepo so the first CLI can later grow into
  web, Docker, mobile, or extension surfaces without flattening product code
  into one package.
- Use a single-source, URL-only, text-first workflow for the first slice.
- Create a `run_dir` for each non-dry run and treat its canonical normalized
  markdown snapshot as immutable within that run.
- Use a provider abstraction for fetch/normalize. The first implementation uses
  Jina Reader, with `MISSLESS_JINA_BASE_URL` reserved for local and mocked
  runs and optional `JINA_API_KEY` support for authenticated environments.
- Use Codex as the current extraction engine through a product-facing skill in
  `skills/`; a custom embedded runtime agent remains deferred.
- Produce a `TLDR`, a knowledge-base-agnostic reading decision
  (`deep_read|skim|skip`), ordered claim-first atom candidates, quote-oriented
  evidence selectors, and optional compact self-check notes.
- Validate evidence selectors against canonical text and materialize a
  read-only internal review package with highlighted evidence.
- Stop at the review package boundary in the first slice; persistence, commit,
  and cross-source alignment remain deferred.

## Acceptance Bar

- A submitted URL can be fetched, normalized, and stored in a stable `run_dir`
  with source metadata and canonical text.
- The system can produce a structured extraction draft that includes a TLDR,
  explicit `deep_read|skim|skip` decision, decision reasons, claim-first atom
  candidates, and candidate evidence selectors.
- Runtime can validate the draft contract and fail closed with clear
  diagnostics when schema or draft-contract invariants are violated.
- Runtime can validate candidate evidence selectors and render a read-only HTML
  review package that highlights supporting canonical text.
- `validate-draft` provides concise summary output by default and structured
  JSON diagnostics when `--json` is requested.
- Human review happens before any persistence boundary; the first slice does
  not commit accepted atoms.

## Deferred From the First Slice

- Knowledge-aware personalized decisions based on the user's existing
  knowledge base. This is a core product differentiator, but it remains
  outside the first slice.
- When refresh/re-ingest and source versioning should be introduced.
- When non-text sources (`podcast`, `audio`, `pdf`) become first-class
  evidence inputs.
- Which quality bars are required before expanding interfaces, alignment
  depth, or persistence scope.
