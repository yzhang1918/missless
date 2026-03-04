# Ingestion Pipeline

Status: Active

## Pipeline Overview

One `ingest_run` is a full execution unit from source input to commit-ready proposal.
By default, `missless ingest` does not persist KB writes; commit is a separate explicit step.
In non-dry-run mode, `missless ingest` creates a persistent `ingest_run` record with `run_id`.
In `--dry-run` mode, no `ingest_run` record is created.

Stages:
1. `connector.fetch`
2. `connector.parse_to_segments`
3. `extension.extract`
4. `align`
5. `propose`
6. `human_review`
7. `commit` (optional follow-up stage, executed by `missless commit <run_id>`)

## Connector Responsibilities

Inputs:
- source locator (`URL`, `arXiv id`, etc.)

Outputs (minimum):
- Source metadata object
- normalized content snapshot reference
- segmented content with stable locators

Connector must set when detectable:
- access flags
- content hash and near-dup fingerprints

## POC Connector Scope

- `web_article` (HTML)
- `arXiv` paper (prefer HTML text, fallback to PDF text extraction)

## Proposal Generation Requirements

Proposal must include:
- source summary
- TL;DR (`L0`, `L1`)
- rating label and breakdown
- proposed atoms and artifacts with evidence links
- alignment/merge/edge suggestions
