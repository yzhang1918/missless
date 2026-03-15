---
name: loop-final-gate
description: Evaluate whether a change is ready to land by combining review status, required CI checks, branch readiness, and documentation completeness into a go/no-go decision. Use when all planned changes are complete and merge readiness must be decided.
---

# Loop Final Gate

## Overview

Perform the final readiness decision before landing. This skill decides; it does not merge.
Run this after `loop-publish` so gate evidence reflects the published branch state.

## Inputs

- Latest aggregated review artifact.
- Archived completed plan path.
- CI/status artifact from GitHub or a local equivalent, tied to the current `HEAD` and base ref.
- Base branch name.

The review artifact must keep `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations` distinct so final gate can block only on current-slice blockers.

## Execution Contract

1. Confirm no unresolved current-slice blocking review findings.
   - Accepted deferred risks and strategic observations should remain visible in the review artifact but must not fail final gate by themselves.
2. Run explicit repository-readiness preflight before gate decisions.
   - Final gate must reuse the same readiness contract enforced by publish.
3. Confirm the working tree is clean and the supplied plan is an archived completed plan.
4. Confirm docs/spec updates are complete for behavior changes.
5. Confirm the CI/status artifact is machine-readable, small, and tied to the current `HEAD` and base SHA.
6. Confirm required CI checks are green.
   - If GitHub reports no required checks for the PR, stop and configure at least one required status check before retrying final gate.
7. Confirm branch is in a merge-ready state:
   - local branch includes the latest target base after repo sync
8. Run final gate evaluation:

```sh
.agents/skills/loop-final-gate/scripts/final_gate.sh <review-json> <ci-json> <plan-path> <base-branch>
```

Optional GitHub-backed CI/status exporter:

```sh
.agents/skills/loop-final-gate/scripts/export_ci_status.sh <base-branch> --docs-updated <true|false> [--pr <number>] [--output <path>]
```

9. Record gate result in the archived plan with links/evidence.
   - Keep tracked plan and PR records summary-first: gate result, key commands, final conclusion, and only notable resolved findings when they materially changed the shipped outcome.
   - After a passing gate, promote the final `review aggregate`, `ci-status`, and `final-gate` files into `.local/final-evidence/<plan-slug>/` with stable filenames so one latest local evidence bundle remains easy to inspect.

## Output

- Go/no-go gate decision.
- Evidence summary in tracked plan plus one latest local evidence bundle under `.local/final-evidence/<plan-slug>/` after a passing gate.
- Final-gate artifact path.

## Guardrails

- Never merge in this skill.
- Fail closed when evidence is missing.
- Fail closed when the plan, CI artifact, or base/head state is stale.
