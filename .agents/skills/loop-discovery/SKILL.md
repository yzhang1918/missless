---
name: loop-discovery
description: Lead pre-implementation discovery for non-trivial work by asking high-leverage clarifying questions, proposing alternatives, and converging on a design before planning or coding. Use when tasks are medium/large, ambiguous, or require tradeoff decisions before execution.
---

# Loop Discovery

## Overview

Run discovery before implementation for medium/large or ambiguous tasks.
For medium/large tasks, discovery is mandatory before planning/execution.

## Inputs

- Task objective from the human.
- Relevant docs/specs/design context in the repository.

## Execution Contract

1. Load context from repository docs first, then code.
2. Ask one high-leverage clarifying question at a time.
3. Propose 2-3 approaches with trade-offs and a recommendation.
4. Converge on one approach with explicit acceptance criteria.
5. Record discovery outcomes in an execution plan under `docs/exec-plans/active/`.

## Output

Update or create `docs/exec-plans/active/YYYY-MM-DD-<topic>.md` with:
- Problem statement
- Constraints
- Accepted approach
- Rejected alternatives with short rationale
- Draft acceptance criteria

## Guardrails

- Do not implement code in this skill.
- Do not create a worktree automatically.
- Do not proceed to execution until the approach is approved.
