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

- Core objects for the current slice: `Source`, `Atom`, `Artifact`, plus
  run-artifact-local anchored evidence records.
- Reusable `Segment` objects remain a possible future persistence-layer
  abstraction, not the current first-slice runtime contract.
- Relations between atoms remain draft-level contracts in the first slice.

## Evidence Modeling Choice

Current baseline for the first delivery slice is:
- Do not pre-cut source text into segments at ingest time.
- Let the extraction agent propose evidence candidates, then let runtime
  validate selectors and write deterministic anchored evidence records on
  demand.
- Treat the internal canonical source view as the primary evidence-reading
  surface; opening the original source remains an enhancement.
- Defer reusable evidence identities until persistence and cross-run reuse
  justify them.

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

- `fetch` is the first deterministic CLI seam. It creates a stable `run_dir`
  and writes `run.json`, `source.json`, and `canonical_text.md`.
- `fetch` also registers the run in runtime-owned cleanup state
  under missless runtime state, outside caller-supplied runs roots, so later
  repair flows can distinguish real missless run directories from arbitrary
  caller-supplied folders when cleaning stale derived artifacts.
- Current cleanup state uses both a runs-root registry and a per-run
  attestation so stale-output cleanup can stay fail-closed even when one
  runtime-state file is missing or corrupt.
- The runtime also writes a signed run-local cleanup token so restored local
  runs can still prove cleanup ownership without trusting a caller-editable
  plaintext marker.
- Fetch/normalize uses a provider abstraction with explicit recoverable versus
  terminal failure outcomes.
- The user-facing CLI names the combined seam `fetch`; the internal stage split
  between fetch and normalize remains part of the pipeline model.
- The default provider sequence is `Jina Reader -> direct origin fetch`.
- Runtime resolves the source redirect chain under the same SSRF policy before
  provider access so redirect hops and final destinations cannot bypass the
  initial source-url safety gate.
- Local and mocked runs may override the reader endpoint with
  `MISSLESS_JINA_BASE_URL`; authenticated environments may also provide
  `JINA_API_KEY`.
- `fetch` rejects embedded credentials plus localhost/private
  targets by default so repository runs do not silently exfiltrate internal or
  credentialed URLs through the third-party reader.
- `fetch` now also rejects hostnames whose resolved addresses point
  at loopback, private, or link-local targets before provider fetch begins.
- The same fail-closed policy also applies across redirect hops and final
  fetch destinations; blocked redirect targets never trigger fallback.
- `JINA_API_KEY` is only forwarded to the official `r.jina.ai` origin unless
  `MISSLESS_JINA_FORWARD_API_KEY_TO_OVERRIDE` explicitly opts into credential
  forwarding for a custom override host.
- Direct-origin fallback only runs after recoverable Jina failures and performs
  local HTML-to-markdown normalization after a safe public fetch.
- `source.json` is a durable provenance artifact that keeps the requested URL,
  requested fetch method, final content URL, chosen fetch method, snapshot
  hash, and fetch time, while leaving provider-attempt and transport metadata
  out of the long-lived contract.
- `validate` reads the run artifacts and fails closed on schema or
  contract issues before any later evidence/materialization steps run.
- Run-level preconditions are enforced there as well, so `anchor` and `review`
  both depend on the same validated `run.json` boundary.
- The first non-schema draft invariant is duplicate claim detection so the
  runtime can reject obviously unstable atom sets even before evidence
  anchoring begins.

## Evidence Materialization Boundary

- `anchor` is deterministic runtime work, not prompt work.
- The first implementation resolves quote-oriented selectors into
  `char_range + context_excerpt` evidence records inside `evidence_result.json`.
- The anchored evidence artifact also records the draft and canonical-text
  snapshot identities used to produce those evidence ranges.
- Selector matching is strict on the exact quote and tolerant on surrounding
  whitespace in `prefix` and `suffix`, which keeps markdown line wrapping from
  breaking otherwise-valid anchors.
- Anchor failures are fail-closed and produce explicit diagnostics instead of
  silently dropping evidence.
- `review` assembles a `review_bundle.json` artifact and a local
  read-only `review.html` page from anchored evidence plus canonical text.
- `review` must reject stale evidence artifacts that were generated from
  an older draft revision or older canonical-text snapshot.
- `review` only deletes stale rendered outputs when the enclosing run
  directory remains trusted by runtime-owned cleanup state or by a valid
  signed run-local cleanup token.
- The repair loop is the same regardless of backend: generate a full draft,
  run deterministic validation, repair the draft from diagnostics, then rerun
  `anchor` and `review`.

## Evidence Anchoring Contract (Text Baseline)

- `Atom` carries semantic judgment and references one or more supporting
  anchored-evidence records inside `evidence_result.json`.
- Runtime owns evidence validation. LLM output is only a candidate selector
  until anchoring succeeds.
- The baseline loop is `candidate -> validate -> anchor`.
- Validation failure does not silently drop evidence requirements; the run
  fails closed and returns diagnostics for repair.
- A validated text locator contains `exact quote + prefix/suffix + char_range`.
- `char_range` is derived by runtime for fast highlighting; `exact/prefix`
  and `suffix` preserve a more robust text-anchor identity.
- Reusable `Segment` records remain deferred until the product actually
  persists graph-shaped evidence across runs.

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
