# Delivery Stages

Status: Active

## Purpose

Define stage-by-stage product delivery without locking implementation to a single interface assumption.

## Stage Map

### Stage 1: Skill-Based Delivery

Primary outcome:
- Ship a usable skill-driven workflow for source-to-knowledge conversion and review loops.

Focus:
- extraction and alignment correctness
- auditable evidence anchoring
- replayable run artifacts
- operator-grade review controls

### Stage 2: Unified Web Application

Primary outcome:
- Ship an integrated web app for ingestion, review, graph navigation, and evidence inspection.

Focus:
- unified user flow
- rich evidence visualization
- faster human-in-the-loop decisions
- stable backend contracts from stage 1

### Stage 3: iOS Application

Primary outcome:
- Ship mobile-native capture and review experience.

Focus:
- fast source capture
- mobile triage and decision actions
- continuity with web and repository contracts

## Cross-Stage Invariants

- Data and run artifact contracts remain auditable.
- Stage promotion requires passing stage gates.
- Backlog prioritization lives in `docs/exec-plans/` and links to plans.
