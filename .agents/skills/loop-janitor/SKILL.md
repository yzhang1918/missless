---
name: loop-janitor
description: Continuously reduce repository entropy by detecting drift, capturing debt, and applying behavior-preserving cleanup and refactor changes on a recurring cadence. Use when running periodic hygiene and debt-control passes.
---

# Loop Janitor

## Overview

Run recurring hygiene passes to keep the codebase and docs legible for future agent runs.

## Inputs

- Scan scope (paths/domains).
- Current standards/spec references.

## Execution Contract

1. Scan for drift:
   - stale docs
   - repeated anti-patterns
   - missing cross-links
   - structural inconsistencies
2. Classify findings:
   - fix-now, queue, or ignore-with-rationale
3. For behavior-preserving refactors, implement small and reviewable patches.
4. Log unresolved items in `docs/exec-plans/tracker.md` under Technical Debt.

## Output

- Cleanup changes and/or debt tracker updates.
- Short janitor summary with risk notes.

## Guardrails

- Keep cleanup changes scoped and reversible.
- For behavior changes, route work back to the primary loop.
