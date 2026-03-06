---
name: loop-discovery
description: Run interactive, Socratic pre-implementation discovery for medium/large or ambiguous tasks by clarifying scope through multi-round questioning before planning. Discovery is conversation-only and must not write repository files.
---

# Loop Discovery

## Overview

Run discovery before implementation for medium/large or ambiguous tasks.
For medium/large tasks, discovery is mandatory before planning/execution.
Discovery is a collaborative brainstorming phase and stays in conversation until approved.

## Inputs

- Explicit task objective from the human (if missing, clarify first).
- Relevant docs/specs/design context in the repository.
- Status of relevant contracts/docs (`Draft` vs `Active`).

## Execution Contract

1. Verify task clarity first.
   - If task is not explicit, ask one concise clarification question before discovery.
2. Load context from repository docs first, then code.
3. Run Socratic clarification over multiple rounds.
   - Ask exactly one high-leverage question per turn.
   - Prioritize purpose, constraints, non-goals, success criteria, and tradeoffs.
   - When related docs/contracts are `Draft`, keep probing assumptions until uncertainty is reduced.
4. When a decision benefits from explicit framing, present 2-4 realistic options.
   - Choose the count based on the real decision shape: 2 for a true fork, 3-4 when there are meaningful alternatives.
   - Give each option a very short trade-off note with one clear upside and one clear downside.
   - Keep options concise and non-redundant; do not pad weak options just to reach four.
5. Recommend a direction with short rationale when the trade-offs are asymmetric.
6. Converge on one approach with explicit acceptance criteria and human approval.
7. Produce a concise discovery summary in conversation for plan handoff.

## Output

Conversation-only discovery summary with:
- Problem statement
- Constraints
- Accepted approach
- Rejected alternatives with short rationale
- Draft acceptance criteria
- Open questions (if any)

## Guardrails

- Do not implement code in this skill.
- Do not write or modify repository files during discovery.
- Do not create a worktree automatically.
- Do not proceed to `loop-plan` until the discovery summary is approved by the human.
- Do not ask bundled multi-question prompts; keep one question per turn.
- Do not turn option framing into long compare tables or verbose essays.
