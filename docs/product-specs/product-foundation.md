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

- Single-source, text-first workflow.
- Store a canonical normalized text snapshot for each source and treat it as immutable for the first slice.
- Extract candidate `Atom` records from the full source.
- Attach evidence through reusable `Segment` objects that are validated and materialized on demand.
- Persist accepted `Atom` decisions only; `Artifact` extraction and persistence stay out of scope for the first slice.
- Treat cross-source alignment as deferred or no-op in the first slice.
- Review candidates in an internal evidence view that can highlight the supporting source text.
- Allow opening the original source URL as a convenience, but do not make external-page highlighting a correctness requirement.

## Acceptance Bar

- A submitted text source can be fetched, normalized, and stored as canonical text.
- The system can produce candidate `Atom` records plus candidate evidence selectors.
- Runtime can validate evidence selectors and materialize reusable `Segment` records.
- Persisted accepted atoms always reference at least one validated `Segment`.
- Evidence validation failures surface as `needs_review` rather than slipping into accepted state.
- A reviewer can inspect highlighted evidence inside the system before deciding what persists.

## Deferred From the First Slice

- Which interface should be used first for real usage?
- When refresh/re-ingest and source versioning should be introduced.
- When non-text sources (`podcast`, `audio`, `pdf`) become first-class evidence inputs.
- Which quality bars are required before expanding interfaces or alignment depth.
