# Harness Engineering Notes

Status: Active

## Source

- Title: Harness engineering: leveraging Codex in an agent-first world
- Publisher: OpenAI Engineering
- Date: 2026-02-11
- URL: https://openai.com/index/harness-engineering/

## Purpose

This note is a retrieval-oriented distillation of agent-harness practices from the source article. It is written for future implementation decisions in `missless`.

## Quick Lookup

| If you need to decide about... | Read section |
| --- | --- |
| Where to put knowledge so agents can use it reliably | Repository as the system of record |
| How to avoid overloaded instruction files | AGENTS as map, docs as depth |
| How to keep architecture coherent under high throughput | Enforce invariants mechanically |
| How to handle rapid PR flow without quality collapse | Throughput-aware merge philosophy |
| How to reduce pattern drift over time | Entropy management and garbage collection |
| What humans should still do in agent-first workflows | Human role shift |
| How to stage autonomy safely | Levels of autonomy model |
| What remains uncertain long-term | Open questions |

## Distilled Themes

### 1) Human Role Shift

- Human contribution moves from writing code to shaping environment, constraints, and feedback loops.
- Humans should focus on intent quality, acceptance criteria, and correctness standards.
- When agents fail repeatedly, treat it as a missing capability or missing structure problem.

### 2) Repository as the System of Record

- Agents can only reason over what is discoverable in repository context.
- Knowledge outside the repo (chat, docs tools, implicit memory) is operationally invisible.
- Durable decisions must be encoded in repo-local, versioned artifacts.

### 3) AGENTS as Map, Docs as Depth

- A giant instruction file degrades guidance quality.
- Better pattern:
  - concise `AGENTS.md` for orientation and operating contract
  - modular `docs/` for domain-specific depth
- Progressive disclosure improves context efficiency and reduces instruction collisions.

### 4) Agent Legibility as a First-Class Goal

- Code and documentation should optimize for agent navigability.
- Prefer stable abstractions and explicit boundaries over cleverness.
- Make domain intent discoverable in text artifacts near code/spec boundaries.

### 5) Enforce Invariants Mechanically

- Do not rely on style reminders alone.
- Encode architecture boundaries and quality rules in checks/lints/tests.
- Keep constraints focused on invariants, not implementation micromanagement.

### 6) Throughput-Aware Merge Philosophy

- High agent throughput changes cost structure: waiting is expensive, correction is cheaper.
- Favor short-lived branches and rapid integration.
- Use follow-up fixes for minor defects instead of long blocking queues.

### 7) Entropy Management and Garbage Collection

- Agents replicate observed patterns, including weak ones.
- Continuous cleanup beats periodic large refactors.
- Convert repeated review comments into enforceable rules or templates.

### 8) Increasing Autonomy is System-Dependent

- End-to-end autonomy is possible only when validation loops and context surfaces are robust.
- Local environment legibility (UI state, logs, metrics, traces) improves autonomous debugging.
- Autonomy should expand as checks and observability become reliable.

### 9) What Agent-Generated Means Operationally

- Agent-generated scope can include product code, tests, CI config, docs, tools, and review responses.
- Human oversight remains essential at acceptance and strategy boundaries.

### 10) Open Questions

- Long-horizon architectural coherence in fully agent-generated systems remains uncertain.
- Balance between strict constraints and local solution flexibility is still evolving.
- Best practices will continue to change as model capability changes.

## Failure Modes to Avoid

- Monolithic instruction manuals with weak retrieval structure.
- Critical decisions made only in chat without repo updates.
- Architecture guidance that is descriptive but not enforceable.
- Long-lived branches and large PRs that slow correction loops.
- Deferred cleanup that allows bad patterns to compound.

## Direct Application to `missless`

### Current Adoption (already reflected in repo)

- docs-first repository bootstrap
- modular docs hierarchy with clear functional boundaries
- explicit `AGENTS.md` collaboration contract
- specs separated from design rationale
- tracker-driven execution and follow-up handling

### Operationalization Note

- Use this reference as external distillation, not as a tactical backlog.
- When adopting any recommendation here, track it in `docs/exec-plans/tracker.md`.

## Implementation Prompts (Reusable)

### Prompt Pattern: Capability Gap Investigation

"The run failed on [task]. Identify the missing capability, missing context, or missing guardrail. Propose the smallest repository change that prevents recurrence."

### Prompt Pattern: Invariant Encoding

"Convert this repeated review comment into an enforceable repository rule. Define where it lives (spec, standard, linter, test) and how compliance is validated."

### Prompt Pattern: Knowledge Externalization

"Summarize the decision made in discussion and write it into the correct repository document with rationale, alternatives, and consequences."

## Related Repository Documents

- `AGENTS.md`
- `docs/design-docs/index.md`
- `docs/standards/repository-standards.md`
- `docs/exec-plans/index.md`
