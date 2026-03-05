---
name: loop-land
description: Land a change only after final gate pass, then record merge outcomes, commit identifiers, and follow-up risk notes.
---

# Loop Land

## Overview

Complete integration after final gate success.

## Inputs

- Final gate outcome marked as pass.
- Target merge method and repository policy.

## Execution Contract

1. Verify final gate is pass and current evidence is fresh.
2. Perform merge/land action according to repository workflow.
3. Record:
   - merge commit SHA
   - relevant PR link
   - key validation references
   - deferred follow-up items
4. Update completion summary in the execution plan.

## Output

Tracked landing summary in plan/PR records.

## Guardrails

- Do not land when final gate is fail or unknown.
- Do not rewrite shared history.
