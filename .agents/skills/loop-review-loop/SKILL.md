---
name: loop-review-loop
description: Run iterative self-review with dynamically selected subagent reviewers, aggregate findings into local review artifacts, and drive fix/re-review cycles until blocking findings are cleared. Use when validating step-level or full-change quality before final gate.
---

# Loop Review Loop

## Overview

Run structured review cycles in `delta` mode (per step) or `full-pr` mode (end-to-end).

## Inputs

- Review scope: `delta` or `full-pr`.
- Plan context and current branch state.

## Execution Contract

1. Start a new review round:

```sh
.agents/skills/loop-review-loop/scripts/review_init.sh <round-id> <scope>
```

2. Select reviewer dimensions dynamically based on risk and scope.
   Recommended pool:
   - correctness
   - architecture
   - tests/regression
   - docs/spec consistency
   - security
   - performance/reliability

3. Spawn subagent reviewers for selected dimensions.
4. Each subagent gathers its own context via local git commands (`git diff`, `git show`, `git log`) instead of requiring raw diff injection.
5. Save reviewer outputs to `.local/loop/review-<round-id>-<dimension>.json`.
   Use the schema in `references/reviewer-output-schema.md`.
6. Aggregate findings:

```sh
.agents/skills/loop-review-loop/scripts/review_aggregate.sh <round-id> .local/loop/review-<round-id>-*.json
```

7. Evaluate blocking state:

```sh
.agents/skills/loop-review-loop/scripts/review_gate.sh .local/loop/review-<round-id>.json
```

8. If blocked, fix findings and run another review round.
9. Summarize accepted review outcome in the tracked plan or PR description.

## Output

- Ephemeral process artifacts in `.local/loop/`.
- Human-readable summary in tracked repository records.

## Guardrails

- Treat `.local` artifacts as temporary process state.
- Keep final decisions in git-tracked docs or PR records.
- Do not require a fixed reviewer set for all tasks.
