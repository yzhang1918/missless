# Ingestion Pipeline

Status: Active

## Pipeline Overview

One ingestion execution unit transforms a source into a reviewable proposal, with optional commit as a separate follow-up action.

Stages:
1. `connector.fetch`
2. `connector.normalize_content`
3. `extension.extract_knowledge`
4. `evidence.anchor`
5. `align`
6. `propose`
7. `human_review`
8. `commit` (optional follow-up stage)

## Connector Responsibilities

Inputs:
- source locator (`URL`, `arXiv id`, file pointer, or future adapter input)

Outputs (minimum):
- source metadata object
- normalized full-content representation
- content fingerprints for dedupe/slop signals

## Extraction and Evidence Anchoring Contract

- Extraction reads normalized full content to produce atoms/artifacts first.
- Evidence anchoring attaches supporting/refuting references after extraction.
- Segment objects may be materialized as reusable nodes or embedded anchors depending on storage profile.

## Connector Coverage by Stage

Connector coverage is stage-dependent and tracked in product delivery plans/backlog, not hardcoded in this file.

## Proposal Requirements

Proposal must include:
- source summary
- TL;DR (`L0`, `L1`)
- rating label and breakdown
- proposed atoms/artifacts with evidence links
- alignment/merge/edge suggestions
