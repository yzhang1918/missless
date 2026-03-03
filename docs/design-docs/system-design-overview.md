# System Design Overview

Status: Active

## Purpose

Describe the intended system shape for `missless` and why the pipeline is structured as staged transformations.

## End-to-End System Shape

Input source locator -> content acquisition -> normalized segments -> knowledge extraction -> alignment against KB -> proposal generation -> human review -> commit and event logging.

## Design Goals

- Keep each stage auditable and replayable.
- Separate concerns between acquisition, extraction, alignment, and commit.
- Preserve deterministic artifacts per run for debugging.
- Allow extension-based extraction logic by source type.

## Stage Responsibilities

1. Connector
   - Fetch source content and metadata.
   - Produce normalized text snapshot and segment locators.
2. Extractor Extension
   - Produce atoms/artifacts and evidence edges.
   - Optionally produce TL;DR summaries.
3. Aligner
   - Compare outputs with existing KB candidates.
   - Decide `new|duplicate_of|equivalent_to|qualifies|contradicts|entails|extends`.
4. Proposer
   - Build human-reviewable package and rating breakdown.
5. Human Review
   - Accept/reject/edit/override before persistence.
6. Committer
   - Persist resolved plan and emit complete event trail.

## Boundary Contracts

- Data contracts live in `docs/specs/`.
- Design rationale and tradeoffs live in `docs/design-docs/`.
- Operational collaboration rules live in `AGENTS.md` and `docs/standards/`.

## Evolution Strategy

- Add new connectors/extensions without changing core ingestion orchestration.
- Add artifact subtypes via payload schema versioning.
- Keep run artifact formats backward-compatible where possible.
