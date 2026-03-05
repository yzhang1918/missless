# Product Design Principles

Status: Active

## Purpose

Define non-negotiable product design principles for `missless`.

## Core Principles

1. Decision over collection.
   - The product optimizes for judgment quality, not link hoarding.
2. Citation is not destination.
   - Sources are evidence anchors, not mandatory reading queues.
3. Atom-first knowledge.
   - Core unit is a short verifiable claim, not a long summary paragraph.
4. Extract first, anchor evidence second.
   - Semantic extraction should use full-content understanding before evidence localization.
5. Evidence must be traceable.
   - Every important atom/artifact must map to evidence anchors.
6. Human control at persistence boundaries.
   - The system proposes; users accept, reject, edit, or override.
7. Knowledge compounding over time.
   - New runs align against existing knowledge to reduce duplication and improve precision.

## Quality Attributes

- Clarity: outputs are scan-friendly and auditable.
- Compactness: avoid verbose, repetitive, low-signal output.
- Traceability: every important conclusion links to concrete evidence.
- Evolvability: new artifact subtypes can be added without destabilizing core contracts.
- Operator trust: high-impact decisions are visible and reversible.

## Stage-Agnostic Interface Principle

Core product semantics must not depend on one interface assumption (CLI/web/mobile/skill). Interface adapters may differ; contracts must not.
