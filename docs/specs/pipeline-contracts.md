# Pipeline Contracts

Status: Draft

## Purpose

Define the baseline processing contract from source ingestion to commit-ready proposal.

## Baseline Stages

1. `fetch`: acquire source and metadata.
2. `normalize`: produce the canonical normalized content snapshot.
3. `extract`: produce candidate atoms/artifacts from full content.
4. `anchor_evidence`: validate and materialize evidence anchors for candidates.
5. `align`: compare with existing knowledge and propose relations.
6. `propose`: assemble human-review package.
7. `review`: human accepts/rejects/edits/defers/overrides.
8. `commit`: optional persistence step.

## Evidence Anchoring Contract (Text Baseline)

- `extract` may propose candidate atoms before stable evidence identifiers exist.
- `anchor_evidence` runs as `candidate -> validate -> refine -> materialize`.
- Candidate evidence is proposed by the extraction agent as quote-oriented selectors rather than direct offsets.
- Runtime validates candidates against the canonical normalized source text.
- When validation succeeds, runtime `lookup-or-create`s a reusable `Segment`.
- When validation fails, runtime returns a concrete reason and requests refinement.
- When bounded refinement still fails, the candidate item must be marked `needs_review` instead of persisting as an evidence-free accepted item.
- Validated text locators are stored as `exact quote + prefix/suffix + char_range`.

## First Delivery Slice Profile

- Required source kind: text sources with a canonical normalized text snapshot.
- Required stages in the first slice: `fetch`, `normalize`, `extract`, `anchor_evidence`, `propose`, `review`, `commit`.
- Required candidate output in the first slice: `Atom` candidates only.
- Required persisted output in the first slice: accepted `Atom` decisions with validated `Segment` references.
- Out of scope in the first slice: `Artifact` extraction and persistence.
- Deferred from the first slice: refresh/versioning, non-text locator variants, evidence-role semantics, and external-page deep-link guarantees.
- `align` remains part of the broader baseline architecture but may be a no-op in the first delivery slice.

## Review Contract

Review actions must support:
- accept selected items
- reject selected items
- edit candidate fields
- defer selected items
- override alignment decisions
- inspect evidence in the internal canonical source view
- identify items blocked in `needs_review`

## Interface Contract (Adapter-Agnostic)

Any interface (skill/CLI/web/mobile) must preserve:
- stable run identifier for non-dry runs
- review-before-commit semantics
- auditable evidence references
- replayable run artifacts
- an internal evidence-reading surface for canonical-source highlighting

## Run Artifact Contract (Baseline)

Each non-trivial run should emit machine-readable artifacts:
- `extraction_output.json`
- `evidence_result.json`
- `alignment_result.json` when `align` executes
- `commit_plan.json`

Exact schemas are draft and should evolve with implementation feedback.

## Scoring Contract (Baseline)

The system may output a read-priority label with reasons.

Contract requirements:
- label is explicit
- reasons are human-readable
- scoring inputs are auditable
