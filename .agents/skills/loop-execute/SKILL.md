---
name: loop-execute
description: Implement a planned step using Red/Green/Refactor TDD, run quick validation, and update plan progress before entering review. Use when a plan step is approved and ready for implementation.
---

# Loop Execute

## Overview

Implement one step from the active plan with strict TDD discipline.

## Inputs

- Plan file path.
- Step identifier.
- Completed discovery + approved plan for medium/large tasks.

## Execution Contract

1. Confirm step objective and acceptance criteria.
2. Execute Red/Green/Refactor:
   - Red: write or update a test that fails for the intended behavior.
   - Green: implement minimal code to pass.
   - Refactor: improve structure without changing behavior.
3. Run quick validation for changed scope (lint/typecheck/targeted tests).
4. Update plan with step status and validation evidence.

## Output

- Code and test changes for one step.
- Updated plan step status and evidence.

## Guardrails

- Do not skip TDD for behavior changes unless technically impossible; if skipped, document reason.
- Do not rely on full CI for every step.
- Do not create worktrees automatically.
