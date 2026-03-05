# AGENTS.md

This document defines how humans and Codex collaborate in `missless`.

## Mission

Build `missless` as an agent-first, repository-legible system that turns information overload into decision clarity.

## Non-Negotiable Rules

1. Repository is the single source of truth.
2. All docs and code must be written in English, even if discussion happens in another language.
3. Every meaningful change must be documented in-repo in the same branch.
4. Evidence over opinion: decisions must link to specs, plans, or run artifacts.
5. Codex must close the loop: plan, execute, validate, and report outcomes.

## Human and Codex Roles

- Human responsibilities:
  - Set priorities, constraints, and acceptance criteria.
  - Make judgment calls when tradeoffs are ambiguous.
  - Approve or redirect strategic decisions.
- Codex responsibilities:
  - Drive implementation end-to-end.
  - Keep docs, plans, and code consistent.
  - Self-verify and surface risks clearly.

## Working Modes

### Mode A: Discovery

Use for ambiguous tasks.
- Identify relevant docs/specs.
- Clarify assumptions.
- Converge on a concrete approach before major edits.

### Mode B: Execution

Use for scoped tasks.
- Update or create an execution plan for non-trivial work.
- Implement in small, reviewable increments.
- Run validation and capture evidence.

### Mode C: Stabilization

Use after delivery.
- Update docs where behavior changed.
- Track unresolved follow-ups in `docs/exec-plans/follow-ups.md`.
- Map unresolved follow-ups to backlog IDs.

## Standard Workflow

1. Intake
   - Restate goal, constraints, and done criteria.
2. Context Load
   - Read relevant docs first, then code.
3. Prioritize
   - Start from `docs/exec-plans/kanban.md` and `docs/exec-plans/backlog.md`.
4. Plan
   - For medium/large work, create/update plan under `docs/exec-plans/active/`.
5. Execute
   - Make atomic changes tied to plan steps.
6. Validate
   - Run checks relevant to the change.
7. Document
   - Update specs/docs in the same branch.
8. Report
   - Summarize changes, validation, open risks, and follow-ups.

## Local Skills

Repository-local skills live under `.agents/skills/`.

- Workflow overview: `.agents/skills/AGENT_LOOP_WORKFLOW.md`
- Available loop skills:
  - `loop-discovery`
  - `loop-plan`
  - `loop-execute`
  - `loop-review-loop`
  - `loop-final-gate`
  - `loop-land`
  - `loop-janitor`

Standards/skill overlap policy:
- Standards are normative.
- Skills are operational playbooks.
- If they conflict, standards win.
- See `docs/standards/skills-alignment.md`.

## Git Workflow

- Main branch: `main`
- Working branch prefix: `codex/`
- Branch naming format: `codex/<area>-<short-goal>`
- Commit style: small and atomic; imperative subject line
- Merge preference: short-lived branches and fast feedback loops
- Never rewrite shared history without explicit approval

## Pull Request Expectations

Every PR should include:
- Problem statement
- Scope of change
- Validation evidence
- Updated docs/specs links
- Known limitations or follow-up tasks with IDs

## Documentation Lifecycle

- `Draft`: proposal under active discussion
- `Active`: current source of truth
- `Deprecated`: retained for history, replaced by another file

When deprecating a document:
- Keep the file
- Add replacement link
- Mark status and date at the top

## Knowledge Placement Rules

- Product intent and staged outcomes: `docs/product-specs/`
- Technical contracts: `docs/specs/`
- Collaboration and quality rules: `docs/standards/`
- Product/system design intent and decisions: `docs/design-docs/`
- Tactical plans, backlog, follow-ups, and debt: `docs/exec-plans/`
- External learnings and glossary: `docs/references/`

## Placement Decision Heuristics

Use these checks when deciding where a new document should live:
- If it defines what the product should do, use `docs/product-specs/`.
- If it defines machine-facing contracts consumed by implementation, use `docs/specs/`.
- If it explains product/system rationale and tradeoffs, use `docs/design-docs/`.
- If it defines process, governance, quality policy, or review rules, use `docs/standards/`.
- If it tracks tactical delivery work, use `docs/exec-plans/`.

For ambiguous cases, use `docs/standards/document-placement-matrix.md`.

## Definition of Done

A task is done only when:
- Acceptance criteria are met.
- Validation was performed (or explicitly declared unavailable).
- Relevant docs/specs are updated.
- Open follow-ups are tracked with IDs and mapped to backlog or active plan.
