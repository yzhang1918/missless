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

## Execution Contract

1. Confirm no unresolved blocking review findings.
2. Run repo-sync preflight before gate decisions.
3. Confirm the working tree is clean and the supplied plan is an archived completed plan.
4. Confirm docs/spec updates are complete for behavior changes.
5. Confirm the CI/status artifact is machine-readable, small, and tied to the current `HEAD` and base SHA.
6. Confirm required CI checks are green.
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

## Output

- Go/no-go gate decision.
- Evidence summary in tracked plan.
- Final-gate artifact path.

## Guardrails

- Never merge in this skill.
- Fail closed when evidence is missing.
- Fail closed when the plan, CI artifact, or base/head state is stale.
