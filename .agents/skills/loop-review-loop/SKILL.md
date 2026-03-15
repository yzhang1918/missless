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

1. Run repo-sync preflight before stateful review decisions so local refs and base-branch state are current.
2. Start a new review round:

```sh
.agents/skills/loop-review-loop/scripts/review_init.sh <round-id YYYYMMDD-HHMMSS> <scope>
```

`round-id` uses UTC timestamp format (`YYYYMMDD-HHMMSS`) so cleanup and retention logic can safely classify rounds.

3. Select reviewer dimensions dynamically based on risk and scope.
   Recommended pool:
   - correctness
   - architecture
   - tests/regression
   - docs/spec consistency
   - security
   - performance/reliability

4. Prepare a reviewer launch manifest for the selected dimensions:

```sh
.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh <round-id YYYYMMDD-HHMMSS> <scope delta|full-pr> [--focus "<dimension>=<focus>"]... <dimension> [<dimension> ...]
```

This writes `.local/loop/review-launch-<round-id>.json`.
Use the manifest shape in `references/reviewer-launch-manifest.md`.
The manifest is the authoritative machine-readable contract for that round's
expected reviewer outputs and repo-observable ownership boundary.

5. Spawn subagent reviewers from the manifest entries using `loop-reviewer`.
   The caller/runtime owns the actual spawn mechanism; the repository helper only emits launch data and prompt text.
6. Each subagent gathers its own context via local git commands (`git diff`, `git show`, `git log`) instead of requiring raw diff injection.
7. Each reviewer writes JSON directly to `.local/loop/review-<round-id>-<dimension-slug>.json`.
   Use the schema in `references/reviewer-output-schema.md`.
   Reviewers are instructed to use only that designated artifact path, and the
   harness fails closed on declared reviewer-output drift plus repo-observable
   tracked-worktree or `HEAD` changes.
8. Finalize the round (aggregate + gate) with one command:

```sh
.agents/skills/loop-review-loop/scripts/review_finalize.sh <round-id YYYYMMDD-HHMMSS> [ .local/loop/review-<round-id>-*.json ]
```

`review_finalize.sh` always prints the aggregated artifact path. If expected
reviewer artifacts are missing or the gate is otherwise blocked, it exits
non-zero (currently `2`) after printing the path.
The aggregate contract also fails closed when a reviewer artifact's declared
`scope` does not match the launch manifest scope, and records those mismatches
under `contract.scope_mismatches`.

9. If blocked, fix findings and run another review round.
   - If a reviewer did not return, either rerun the reviewer or write an
     explicit manual-fallback artifact to the designated output path with a
     recorded `producer.reason` before re-finalizing the round.
10. Summarize accepted review outcome in the tracked plan or PR description using summary-first evidence.
   - record the final clean result, key commands, and final conclusion
   - only record resolved findings when they materially changed the shipped outcome
   - do not rely on `.local/loop/*.json` paths as durable evidence references
11. Cleanup ephemeral artifacts after the loop:

```sh
.agents/skills/loop-review-loop/scripts/review_cleanup.sh --keep-rounds 1
```

Promoted bundles under `.local/final-evidence/` must remain untouched by this cleanup step.
12. When review-loop or final-gate scripts change, run regression checks:

```sh
.agents/skills/loop-review-loop/scripts/review_regression.sh
```

## Output

- Ephemeral process artifacts in `.local/loop/`, including reviewer launch manifests.
- Human-readable summary in tracked repository records.

## Guardrails

- Treat `.local` artifacts as temporary process state.
- Treat `.local/final-evidence/<plan-slug>/` as the one retained local evidence bundle for the latest passing gate state, not as a general archive of every review round.
- Keep final decisions in git-tracked docs or PR records.
- Do not require a fixed reviewer set for all tasks.
- Do not bind the helper to a specific subagent runtime inside repository scripts.
- Treat reviewer ownership enforcement as a repo-observable contract check over
  declared reviewer outputs, tracked-worktree drift, and `HEAD` movement, not
  as full runtime sandboxing or arbitrary untracked-file isolation.
- Do not hand-author reviewer JSON when reviewer subagent output is available.
- If fallback manual reviewer artifacts are required, record the reason in the plan/PR review summary.
