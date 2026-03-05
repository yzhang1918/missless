# Pipeline Contracts

Status: Draft

## Purpose

Define the baseline processing contract from source ingestion to commit-ready proposal.

## Baseline Stages

1. `fetch`: acquire source and metadata.
2. `normalize`: produce normalized content snapshot.
3. `extract`: produce candidate atoms/artifacts from full content.
4. `anchor_evidence`: attach evidence anchors to candidates.
5. `align`: compare with existing knowledge and propose relations.
6. `propose`: assemble human-review package.
7. `review`: human accepts/rejects/edits/defers/overrides.
8. `commit`: optional persistence step.

## Review Contract

Review actions must support:
- accept selected items
- reject selected items
- edit candidate fields
- defer selected items
- override alignment decisions

## Interface Contract (Adapter-Agnostic)

Any interface (skill/CLI/web/mobile) must preserve:
- stable run identifier for non-dry runs
- review-before-commit semantics
- auditable evidence references
- replayable run artifacts

## Run Artifact Contract (Baseline)

Each non-trivial run should emit machine-readable artifacts:
- `extraction_output.json`
- `alignment_result.json`
- `commit_plan.json`

Exact schemas are draft and should evolve with implementation feedback.

## Scoring Contract (Baseline)

The system may output a read-priority label with reasons.

Contract requirements:
- label is explicit
- reasons are human-readable
- scoring inputs are auditable
