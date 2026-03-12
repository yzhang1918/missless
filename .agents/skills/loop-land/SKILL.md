---
name: loop-land
description: Land a change only after final gate pass, then record merge outcomes, commit identifiers, and follow-up risk notes. Use when final gate is passing and the change is ready to merge.
---

# Loop Land

## Overview

Complete integration after final gate success.

## Inputs

- Final gate outcome marked as pass.
- Final-gate artifact path.
- Archived completed plan path.
- Base branch name.
- Target merge method and repository policy.
- Linked issue numbers and which ones should close on merge.

## Execution Contract

1. Verify final gate is pass and current evidence is fresh by running:

```sh
.agents/skills/loop-land/scripts/land_preflight.sh <final-gate-json> <plan-path> <base-branch> [--pr <number>]
```

2. Perform merge/land action according to repository workflow:

```sh
.agents/skills/loop-land/scripts/land_merge.sh <final-gate-json> <plan-path> <base-branch> [--pr <number>] [--method <auto|merge|squash|rebase>] [--delete-branch <auto|true|false>] [--output <path>]
```

   - prefer `rebase` or `squash` if merge commits are disabled
   - Treat remote merge success as authoritative even when local branch switching or branch cleanup cannot complete because of worktree constraints.
   - Keep tracked plan/PR records summary-first: record merge result, merge commit, and any cleanup warnings in git-tracked summaries instead of depending on the local JSON path as durable evidence.
3. Record:
   - merge commit SHA
   - relevant PR link
   - linked issue closure outcome
   - key validation references
   - local cleanup warnings, if any
   - deferred follow-up items
4. Update completion summary in the execution plan.
5. Verify each issue intended to close is actually closed after merge; if auto-close did not happen, close it manually with the merge reference.

## Output

- A landing summary from `land_merge.sh` that separates the remote merge result from any local cleanup warnings.
- Tracked landing summary in plan/PR records.

## Guardrails

- Do not land when final gate is fail or unknown.
- Do not land when the final-gate artifact, repo state, or plan state is stale.
- Do not rewrite shared history.
- Do not close implementation issues before the merge result is known.
- Do not report landing failure when the remote merge succeeded and only optional local cleanup failed.
