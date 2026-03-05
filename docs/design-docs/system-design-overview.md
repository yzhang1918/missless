# System Design Overview

Status: Active

## Purpose

Describe the intended system shape for `missless` and why extraction and evidence anchoring are separated into distinct stages.

## End-to-End System Shape

Input source locator -> content acquisition -> normalized full-content representation -> knowledge extraction (atoms/artifacts) -> evidence anchoring (segment links) -> alignment against KB -> proposal generation -> human review -> optional commit and event persistence.

## Design Goals

- Keep each stage auditable and replayable.
- Separate semantic extraction from evidence localization.
- Preserve deterministic run artifacts for debugging and review.
- Keep interface adapters (skill/CLI/web/mobile) independent from core pipeline semantics.

## Stage Responsibilities

1. Connector
   - Fetch source content and metadata.
   - Produce normalized full-content representation.
2. Extractor Extension
   - Read normalized content and produce atoms/artifacts first.
   - Avoid premature dependency on pre-cut segment nodes.
3. Evidence Anchoring
   - Attach supporting/refuting segment references to extracted outputs.
   - Materialize segment objects when needed for audit/navigation.
4. Aligner
   - Compare outputs with existing KB candidates.
   - Decide type-specific alignment relations.
5. Proposer
   - Build human-reviewable package with rationale and candidate scores.
6. Human Review
   - Accept/reject/edit/override before persistence.
7. Committer (optional follow-up)
   - Persist approved plan and emit durable event trail.

## Boundary Contracts

- Data and run artifact contracts live in `docs/specs/`.
- Design rationale and tradeoffs live in `docs/design-docs/`.
- Operational collaboration rules live in `AGENTS.md` and `docs/standards/`.

## Open Design Topics

- Segment modeling alternatives: `docs/design-docs/segment-evidence-model-options.md`
