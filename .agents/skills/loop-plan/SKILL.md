---
name: loop-plan
description: Convert an approved discovery summary into an execution-ready plan with step boundaries, acceptance criteria, validation strategy, and documentation obligations.
---

# Loop Plan

## Overview

Create or refine a plan that is executable by an agent without hidden context.

For medium/large tasks, this skill is required after discovery and before execution.

## Inputs

- Approved discovery summary from conversation.
- Repository constraints and standards.

## Execution Contract

1. Confirm discovery is explicitly approved by the human.
   - If not approved, return to `loop-discovery`.
2. Choose plan location by work type:
   - Product work -> `docs/exec-plans/active/YYYY-MM-DD-<topic>.md`
   - Harness/process work -> `docs/harness/active/YYYY-MM-DD-<topic>.md`
3. Break work into small, reviewable steps.
4. For each step, define:
   - objective
   - expected files
   - validation commands
   - documentation impact
5. Define review cadence:
   - delta review after each step
   - full-pr review before final gate
6. Define final gate conditions explicitly.

## Output

A plan with:
- clear scope boundaries
- step-level acceptance criteria
- validation strategy
- risk and mitigation notes

## Guardrails

- Keep steps outcome-driven, not tool-driven.
- Do not duplicate source-of-truth across multiple plans.
