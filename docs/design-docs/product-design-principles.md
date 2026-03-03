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
4. Evidence must be traceable.
   - Every atom/artifact must map back to source segments.
5. Explainable prioritization.
   - `skip|skim|read|deep_read` must include reasoned breakdowns.
6. Human control at commit boundaries.
   - The system proposes; users accept, reject, edit, or override.
7. Knowledge compounding over time.
   - New runs align against existing knowledge to reduce duplication and improve precision.

## Quality Attributes

- Clarity: outputs are scan-friendly and auditable.
- Compactness: avoid verbose, repetitive, low-signal output.
- Traceability: every important conclusion links to concrete evidence.
- Evolvability: new artifact subtypes can be added without destabilizing core data model.
- Operator trust: high-impact decisions are visible and reversible.

## POC Design Boundaries

- CLI-first workflow is intentional.
- Structured extraction and alignment are prioritized over polished UI.
- Contradiction support is required, full debate graphing is deferred.
