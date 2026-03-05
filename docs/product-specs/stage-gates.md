# Stage Gates

Status: Active

## Purpose

Define readiness checks for moving from one delivery stage to the next.

## Gate Structure

Each stage gate evaluates:
- capability completeness
- contract stability
- evidence/audit quality
- operator workflow reliability

## Stage 1 Exit Gate

- Core extraction/alignment pipeline is replayable end-to-end.
- Evidence anchoring is available for accepted outputs.
- Human review can deterministically control persistence.
- Backlog and follow-up tracking loops are operational.

## Stage 2 Exit Gate

- Web app covers primary ingestion/review/navigation journeys.
- Backend and run artifact contracts remain backward-compatible.
- Observability and quality checks catch regressions quickly.

## Stage 3 Exit Gate

- iOS workflows preserve parity for core decision actions.
- Cross-surface data consistency is verified.
- Mobile constraints do not degrade auditability guarantees.
