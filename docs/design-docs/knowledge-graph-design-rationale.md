# Knowledge Graph Design Rationale

Status: Active

## Purpose

Explain why `missless` uses a heterogeneous graph model and how that choice supports product outcomes.

## Why Graph, Not Plain Summaries

- Summaries collapse nuance and hide evidence chains.
- Graph structure preserves relationships between sources, segments, claims, and structured artifacts.
- Alignment edges make novelty, overlap, and contradiction explicit and computable.

## Why Heterogeneous Nodes

- Source captures provenance and quality signals.
- Segment captures localization for auditability.
- Atom captures compact decision-relevant claims.
- Artifact captures structured domain outputs (method/result/etc.).

This separation avoids overloading one entity with conflicting semantics.

## Why Explicit Relation Types

`equivalent_to`, `duplicate_of`, `qualifies`, `entails`, `contradicts`, and `extends` encode different operator actions:
- merge or suppress redundancy
- preserve nuance and scope constraints
- surface conflict for review
- support incremental knowledge growth

## Tradeoffs

- Benefit: richer reasoning and explainability.
- Cost: more complex alignment logic and QA burden.
- Mitigation: human review gates plus auditable alignment rationale.

## Storage Strategy

Physical storage may be relational, document, or graph DB.
Logical model remains graph-first to protect semantics and future evolution.

## Evolution Guardrails

- Do not add new edge types without explicit decision-log entry.
- Do not widen atom length constraints to compensate for weak extraction.
- Add structured scope facets only when repeated query needs justify complexity.
