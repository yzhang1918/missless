# Segment Evidence Model Options

Status: Draft

## Purpose

Evaluate whether segments should be modeled as first-class nodes, embedded evidence attributes, or a hybrid approach.

## Problem Framing

A claim/artifact can be supported by multiple evidence snippets, and a single snippet can support multiple claims/artifacts. The model must preserve auditability without forcing unnecessary storage complexity.

## Option A: Segment as First-Class Node

Definition:
- `Segment` is an explicit entity with locator metadata and reusable references.

Pros:
- Natural many-to-many reuse (`segment -> atom`, `segment -> artifact`).
- Strong provenance and citation navigation.
- Easier cross-source evidence analysis.

Cons:
- More objects/edges to manage.
- Higher complexity for simple deployments.

## Option B: Segment as Embedded Evidence Attribute

Definition:
- Segment-like evidence is stored directly inside edge/item payloads.

Pros:
- Simpler persistence model.
- Fewer joins for small-scale flows.

Cons:
- Harder evidence reuse across multiple outputs.
- Risk of duplicated locator/snippet payloads.
- Weaker graph-level evidence analytics.

## Option C: Hybrid (Recommended Baseline)

Definition:
- Logical model keeps reusable segment identity.
- Physical storage may inline or normalize based on backend/profile.
- Contract uses stable evidence anchor fields regardless of storage shape.

Why this baseline:
- Preserves semantic flexibility while enabling lightweight implementations.
- Supports both early-stage speed and later graph-level capabilities.

## Decision Triggers

Promote to explicit node-first implementation when:
- evidence reuse rate is high
- multi-claim/traceability queries become frequent
- UI requires deep evidence graph navigation

Keep embedded-only profile when:
- deployment is minimal and query surface is small
- evidence reuse and graph navigation are low priority
