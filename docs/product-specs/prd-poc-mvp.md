# POC/MVP PRD

Status: Active

## Problem

- Information overload plus AI slop creates repeated low-signal content.
- Saved links rarely become reusable knowledge.
- Users want conclusions, methods, and insights, not citation accumulation.
- For research use cases, papers must be captured as structured knowledge, not generic summaries.

## Goals (POC/MVP)

Given one source (`URL` or `arXiv`), the system should output:
- TL;DR (`L0` and `L1`)
- Atoms (scan-friendly short claims)
- Artifacts (structured outputs; at minimum paper method/result)
- Alignment against existing knowledge (`new`, `duplicate_of`, `equivalent_to`, `qualifies`, `contradicts`, `entails`, `extends`)
- Explainable rating (`skip`, `skim`, `read`, `deep_read`)
- Human-in-the-loop review (accept/reject/edit before commit)

## Core Principle

Knowledge base logic is graph-centric, not summary-centric:
- Atom Graph: equivalence, qualification, entailment, contradiction, extension
- Source/Segment Graph: provenance, localization, evidence strength, slop/rewrites

## Product Stage Constraints

- POC is CLI-first.
- Self-host first.
- Productized UX channels are intentionally deferred.
