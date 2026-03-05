# System Design

Status: Draft

## Purpose

Capture the current system design rationale at a level suitable for early implementation discussions.

## Baseline Flow

1. Acquire and normalize source content.
2. Extract candidate atoms/artifacts from full-content understanding.
3. Attach evidence anchors to extracted candidates.
4. Align candidates with existing knowledge.
5. Produce a human-reviewable proposal.
6. Persist only after explicit human decision.

## Knowledge Shape

- Core objects: `Source`, `Atom`, `Artifact`.
- Evidence is represented by anchor references; materialized `Segment` nodes are optional.
- Relations between atoms (for example contradiction or extension) are supported but remain draft-level contracts.

## Evidence Modeling Choice (Open)

Current baseline is hybrid:
- Keep a stable evidence-anchor contract.
- Allow either embedded anchors or materialized segment nodes by implementation profile.

## Design Priorities

- Traceability: every important conclusion can point to evidence.
- Auditability: alignment and persistence decisions are replayable.
- Evolvability: avoid over-committing schema before first implementation slice.

## Open Questions

- When should segment nodes become mandatory (if ever)?
- What is the minimum relation set for first delivery?
- Which quality checks are required before expanding interfaces?
