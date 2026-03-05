---
name: loop-final-gate
description: Evaluate whether a change is ready to land by combining review status, required CI checks, branch readiness, and documentation completeness into a go/no-go decision. Use when all planned changes are complete and merge readiness must be decided.
---

# Loop Final Gate

## Overview

Perform the final readiness decision before landing. This skill decides; it does not merge.

## Inputs

- Latest aggregated review artifact.
- CI check status from GitHub or local equivalent.
- Plan and docs/spec update status.

## Execution Contract

1. Confirm no unresolved blocking review findings.
2. Confirm required CI checks are green.
3. Confirm docs/spec updates are complete for behavior changes.
4. Confirm branch is in a merge-ready state.
5. Run final gate evaluation:

```sh
.agents/skills/loop-final-gate/scripts/final_gate.sh <review-json> <ci-json>
```

6. Record gate result in the active plan with links/evidence.

## Output

- Go/no-go gate decision.
- Evidence summary in tracked plan.

## Guardrails

- Never merge in this skill.
- Fail closed when evidence is missing.
