---
name: loop-review-loop
description: Run iterative self-review with dynamically selected subagent reviewers, aggregate findings into local review artifacts, and drive fix/re-review cycles until blocking findings are cleared. Use when validating step-level or full-change quality before final gate.
---

# Loop Review Loop

## Overview

Run structured review cycles in `delta` mode (per step) or `full-pr` mode (end-to-end).

Scope selection rule:
- Use `full-pr` at least once before final gate.
- Use `delta` after targeted fixes when changed surface is narrow.
- Re-run `full-pr` if fixes touch cross-cutting contracts, orchestration flow, or many files.

## Inputs

- Review scope: `delta` or `full-pr`.
- Plan context and current branch state.

## Execution Contract

1. Start a new review round:

```sh
.agents/skills/loop-review-loop/scripts/review_init.sh <round-id YYYYMMDD-HHMMSS> <scope>
```

`round-id` uses UTC timestamp format (`YYYYMMDD-HHMMSS`) so cleanup and retention logic can safely classify rounds.

2. Select reviewer dimensions dynamically based on risk and scope.
   Recommended pool:
   - correctness
   - architecture
   - tests/regression
   - docs/spec consistency
   - security
   - performance/reliability

3. Spawn subagent reviewers for selected dimensions using `loop-reviewer`.
4. Each subagent gathers its own context via local git commands (`git diff`, `git show`, `git log`) instead of requiring raw diff injection.
5. Each reviewer writes JSON directly to `.local/loop/review-<round-id>-<dimension>.json`.
   Use the schema in `references/reviewer-output-schema.md`.
6. Finalize the round (aggregate + gate) with one command:

```sh
.agents/skills/loop-review-loop/scripts/review_finalize.sh <round-id YYYYMMDD-HHMMSS> .local/loop/review-<round-id>-*.json
```

`review_finalize.sh` always prints the aggregated artifact path. If the gate is blocked, it exits non-zero (currently `2`) after printing the path.

7. If blocked, fix findings and run another review round.
8. Summarize accepted review outcome in the tracked plan or PR description.
9. Cleanup ephemeral artifacts after the loop:

```sh
.agents/skills/loop-review-loop/scripts/review_cleanup.sh --keep-rounds 1
```
10. When review-loop or final-gate scripts change, run regression checks:

```sh
.agents/skills/loop-review-loop/scripts/review_regression.sh
```

## Output

- Ephemeral process artifacts in `.local/loop/`.
- Human-readable summary in tracked repository records.

## Guardrails

- Treat `.local` artifacts as temporary process state.
- Keep final decisions in git-tracked docs or PR records.
- Do not require a fixed reviewer set for all tasks.
- Do not hand-author reviewer JSON when reviewer subagent output is available.
- If fallback manual reviewer artifacts are required, record the reason in the plan/PR review summary.
