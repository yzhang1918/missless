# System Design

Status: Draft

## Purpose

Capture the current system design rationale at a level suitable for early
implementation discussions.

## Repository Layout for the First Slice

- Repository management starts as a pnpm-workspace monorepo.
- `apps/cli` holds the first local runtime surface.
- `packages/contracts` owns cross-surface schemas and stable run-artifact
  naming.
- `packages/core` owns deterministic pipeline logic.
- `packages/rendering` owns the read-only review surface primitives.
- `skills/` holds product-facing skills and prompt assets.

## Baseline Flow

1. Acquire and normalize source content.
2. Extract candidate atoms and review artifacts from full-content
   understanding.
3. Attach evidence anchors to extracted candidates through validation and
   materialization.
4. Align candidates with existing knowledge.
5. Produce a human-reviewable proposal.
6. Persist only after explicit human decision.

## Knowledge Shape

- Core objects: `Source`, `Atom`, `Artifact`, `Segment`.
- For text sources, evidence is represented by first-class `Segment` objects
  rather than embedded-only anchors.
- Relations between atoms remain draft-level contracts in the first slice.

## Evidence Modeling Choice

Current baseline for the first delivery slice is:
- Keep a stable evidence-anchor contract around independent `Segment` objects.
- Do not pre-cut source text into segments at ingest time.
- Let the extraction agent propose evidence candidates, then let runtime
  validate and materialize reusable `Segment` records on demand.
- Treat the internal canonical source view as the primary evidence-reading
  surface; opening the original source remains an enhancement.

## Current Extraction Boundary

- The deterministic runtime owns `fetch`, `normalize`, draft validation,
  evidence validation, artifact shaping, and review rendering.
- The agent backend owns proposal work: TLDR, decision, reasons, atom
  candidates, and evidence selectors.
- Product-facing orchestration belongs in `skills/`.
- The runtime contract is backend-neutral even when live validation happens
  through one currently available backend.
- The agent writes `extraction_draft.json` directly, and runtime remains the
  authoritative validator of that artifact.

## Ingestion and Validation Boundary

- `fetch-normalize` is the first deterministic CLI seam. It creates a stable
  `run_dir` and writes `run.json`, `source.json`, and `canonical_text.md`.
- Fetch/normalize uses a provider abstraction. Jina Reader is the default
  implementation for the first slice.
- Local and mocked runs may override the reader endpoint with
  `MISSLESS_JINA_BASE_URL`; authenticated environments may also provide
  `JINA_API_KEY`.
- `fetch-normalize` rejects embedded credentials plus localhost/private
  targets by default so repository runs do not silently exfiltrate internal or
  credentialed URLs through the third-party reader.
- `JINA_API_KEY` is only forwarded to the official `r.jina.ai` origin unless
  `MISSLESS_JINA_FORWARD_API_KEY_TO_OVERRIDE` explicitly opts into credential
  forwarding for a custom override host.
- `validate-draft` reads the run artifacts and fails closed on schema or
  contract issues before any later evidence/materialization steps run.
- The first non-schema draft invariant is duplicate claim detection so the
  runtime can reject obviously unstable atom sets even before evidence
  anchoring begins.

## Evidence Materialization Boundary

- `anchor-evidence` is deterministic runtime work, not prompt work.
- The first implementation resolves quote-oriented selectors into
  `char_range + context_excerpt` evidence records inside `evidence_result.json`.
- Selector matching is strict on the exact quote and tolerant on surrounding
  whitespace in `prefix` and `suffix`, which keeps markdown line wrapping from
  breaking otherwise-valid anchors.
- Anchor failures are fail-closed and produce explicit diagnostics instead of
  silently dropping evidence.
- `render-review` assembles a `review_bundle.json` artifact and a local
  read-only `review.html` page from anchored evidence plus canonical text.
- The repair loop is the same regardless of backend: generate a full draft,
  run deterministic validation, repair the draft from diagnostics, then rerun
  `anchor-evidence` and `render-review`.

## Evidence Anchoring Contract (Text Baseline)

- `Segment` is a reusable evidence-location object, not an editable semantic
  object.
- `Atom` carries semantic judgment and references one or more supporting
  `Segment` objects.
- Runtime owns evidence identity. LLM output is only a candidate selector
  until validation succeeds.
- The baseline loop is `candidate -> validate -> refine -> materialize`.
- Validation failure does not silently drop evidence requirements. Candidates
  that still fail after bounded refinement are surfaced as `needs_review`.
- A validated text locator contains `exact quote + prefix/suffix + char_range`.
- `char_range` is derived by runtime for fast highlighting; `exact/prefix`
  and `suffix` preserve a more robust text-anchor identity.

## First Delivery Slice

- Source kind: URL-ingested canonical markdown snapshots only.
- Source snapshot policy: canonical text is stored in a `run_dir` and treated
  as immutable after ingest within that run.
- Candidate scope: the first slice produces a TLDR, a knowledge-base-agnostic
  `deep_read|skim|skip` decision, and ordered claim-first atom candidates.
- Persistence scope: the first slice ends at a read-only review package;
  commit-ready persistence stays out of scope.
- Alignment scope: cross-source alignment remains outside the first slice and
  may exist only as a no-op placeholder.
- User experience: review candidate atoms with highlighted evidence in an
  internal HTML page generated from run artifacts.
- Deferred from the first slice: non-text locator contracts,
  refresh/versioning flows, knowledge-aware personalized decisions, and
  external-page deep-link guarantees.

## Design Priorities

- Traceability: every important conclusion can point to evidence.
- Auditability: alignment and persistence decisions are replayable.
- Evolvability: avoid over-committing schema before first implementation
  slice.

## Open Questions

- What is the minimum relation set for first delivery?
- Which quality checks are required before expanding interfaces?
