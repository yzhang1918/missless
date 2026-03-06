# System Design

Status: Draft

## Purpose

Capture the current system design rationale at a level suitable for early implementation discussions.

## Baseline Flow

1. Acquire and normalize source content.
2. Extract candidate atoms/artifacts from full-content understanding.
3. Attach evidence anchors to extracted candidates through validation and materialization.
4. Align candidates with existing knowledge.
5. Produce a human-reviewable proposal.
6. Persist only after explicit human decision.

## Knowledge Shape

- Core objects: `Source`, `Atom`, `Artifact`, `Segment`.
- For text sources, evidence is represented by first-class `Segment` objects rather than embedded-only anchors.
- Relations between atoms (for example contradiction or extension) are supported but remain draft-level contracts.

## Evidence Modeling Choice

Current baseline for the first delivery slice is:
- Keep a stable evidence-anchor contract around independent `Segment` objects.
- Do not pre-cut source text into segments at ingest time.
- Let the extraction agent propose evidence candidates, then let runtime validate and materialize reusable `Segment` records on demand.
- Treat the internal canonical source view as the primary evidence-reading surface; opening the original source remains an enhancement.

## Evidence Anchoring Contract (Text Baseline)

- `Segment` is a reusable evidence-location object, not an editable semantic object.
- `Atom` carries semantic judgment and references one or more supporting `Segment` objects.
- Runtime owns evidence identity. LLM output is only a candidate selector until validation succeeds.
- The baseline loop is `candidate -> validate -> refine -> materialize`.
- Validation failure does not silently drop evidence requirements. Candidates that still fail after bounded refinement are surfaced as `needs_review`.
- A validated text locator contains `exact quote + prefix/suffix + char_range`.
- `char_range` is derived by runtime for fast highlighting; `exact/prefix/suffix` preserve a more robust text-anchor identity.

## First Delivery Slice

- Source kind: normalized text snapshots only.
- Source snapshot policy: canonical text is stored and treated as immutable after ingest for the first slice.
- Candidate/persistence scope: the first slice closes the `Atom` evidence-review loop only; `Artifact` extraction and persistence stay out of scope.
- Alignment scope: cross-source alignment remains outside the first slice and may exist only as a no-op placeholder.
- User experience: review candidate atoms with highlighted evidence in the internal source view.
- Deferred from the first slice: non-text locator contracts, refresh/versioning flows, evidence-role taxonomies, and external-page deep-link guarantees.

## Design Priorities

- Traceability: every important conclusion can point to evidence.
- Auditability: alignment and persistence decisions are replayable.
- Evolvability: avoid over-committing schema before first implementation slice.

## Open Questions

- What is the minimum relation set for first delivery?
- Which quality checks are required before expanding interfaces?
