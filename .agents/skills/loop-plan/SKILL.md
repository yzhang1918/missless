---
name: loop-plan
description: Convert an approved discovery outcome into an execution-ready plan with step boundaries, acceptance criteria, validation strategy, and documentation obligations.
---

# Loop Plan

## Overview

Create or refine a plan that is executable by an agent without hidden context.

## Inputs

- Approved discovery outcome.
- Repository constraints and standards.

## Execution Contract

1. Use `docs/exec-plans/active/YYYY-MM-DD-<topic>.md` as the plan file.
2. Break work into small, reviewable steps.
3. For each step, define:
   - objective
   - expected files
   - validation commands
   - documentation impact
4. Define review cadence:
   - delta review after each step
   - full-pr review before final gate
5. Define final gate conditions explicitly.

## Output

A plan with:
- clear scope boundaries
- step-level acceptance criteria
- validation strategy
- risk and mitigation notes

## Guardrails

- Keep steps outcome-driven, not tool-driven.
- Do not duplicate source-of-truth across multiple plans.
