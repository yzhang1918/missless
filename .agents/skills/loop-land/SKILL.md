---
name: loop-land
description: Land a change only after final gate pass, then record merge outcomes, commit identifiers, and follow-up risk notes. Use when final gate is passing and the change is ready to merge.
---

# Loop Land

## Overview

Complete integration after final gate success.

## Inputs

- Final gate outcome marked as pass.
- Target merge method and repository policy.

## Execution Contract

1. Verify final gate is pass and current evidence is fresh.
2. Verify PR is already published and merge strategy matches repository policy.
3. Perform merge/land action according to repository workflow.
   - prefer `rebase` or `squash` if merge commits are disabled
4. Record:
   - merge commit SHA
   - relevant PR link
   - key validation references
   - deferred follow-up items
5. Update completion summary in the execution plan.

## Output

Tracked landing summary in plan/PR records.

## Guardrails

- Do not land when final gate is fail or unknown.
- Do not rewrite shared history.
