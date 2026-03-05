# Backlog

Status: Active

## Purpose

Canonical queue of actionable work items across stages.

## Fields

- `ID`: stable backlog identifier (`BL-xxxx`)
- `Priority`: `P0|P1|P2|P3`
- `Status`: `todo|ready|in_progress|blocked|done`
- `Stage`: delivery stage alignment
- `Owner`: responsible human/agent
- `Source`: origin (plan follow-up, review finding, discovery outcome)

## Items

| ID | Title | Priority | Status | Stage | Owner | Source | Links |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BL-0001 | Decide segment evidence representation profile for stage 1 | P1 | ready | Stage 1 | Codex | design open question | `docs/design-docs/segment-evidence-model-options.md` |
| BL-0002 | Define stage-1 concrete scope and initial stage-gate checklist | P1 | ready | Stage 1 | Human+Codex | product planning | `docs/product-specs/delivery-stages.md`, `docs/product-specs/stage-gates.md` |
| BL-0003 | Add CI status exporter for final-gate input (`ci.json`) | P2 | todo | Stage 1 | Codex | follow-up | `docs/exec-plans/follow-ups.md#fup-0001` |
| BL-0004 | Add reviewer subagent spawn template command | P2 | todo | Stage 1 | Codex | follow-up | `docs/exec-plans/follow-ups.md#fup-0002` |
