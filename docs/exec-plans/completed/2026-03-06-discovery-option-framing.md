# Discovery Option Framing Calibration

## Metadata

- Plan name: Discovery Option Framing Calibration
- Owner: Human+Codex
- Date: 2026-03-06
- Related issue/task: TASK-0005
- Tracker IDs: TASK-0005

## Objective

Refine `loop-discovery` so Socratic discovery remains concise while offering better decision framing: 2-4 realistic options when useful, each with a short upside/downside note.

## Scope

- In scope:
  - Update `loop-discovery` skill instructions for context-shaped option counts.
  - Require brief pros/cons for discovery options without turning responses verbose.
  - Sync `loop-discovery/agents/openai.yaml` so UI entry text matches the revised behavior.
  - Capture isolated subagent test evidence for the revised option framing.
- Out of scope:
  - Changing discovery from one-question-per-turn behavior.
  - Changing planning, execution, or merge mechanics outside the discovery skill.

## Acceptance Criteria

- [x] `.agents/skills/loop-discovery/SKILL.md` allows 2-4 realistic options based on decision shape.
- [x] `.agents/skills/loop-discovery/SKILL.md` requires a very short upside/downside note per option and explicitly guards against verbose compare tables.
- [x] `.agents/skills/loop-discovery/agents/openai.yaml` reflects the revised concise-tradeoff behavior.
- [x] Isolated subagent tests show both a 3-option case and a true 2-option fork without padding weak alternatives.

## Work Breakdown

1. Inspect the current skill contract and metadata to identify why discovery responses were converging on sparse option framing.
2. Update the skill contract and UI metadata to prefer 2-4 realistic options with brief tradeoffs.
3. Validate the skill with structural checks and isolated subagent simulations.
4. Run repository review/final-gate workflow and record evidence.

## Validation Plan

- `python3 /Users/yaozhang/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/loop-discovery`
- Isolated subagent simulations for:
  - a 3-option architectural fork
  - a 3-option implementation-slice choice
  - a true 2-option scope fork
- `find docs/exec-plans/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \; | while read -r file; do rg -q "$file" docs/exec-plans/completed/README.md || echo "missing:$file"; done`
- `loop-review-loop` in `full-pr` mode
- `loop-final-gate` against the latest review artifact and local CI-equivalent metadata

## Validation Summary

- Executed `python3 /Users/yaozhang/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/loop-discovery`; the skill passed validation.
- Executed three isolated subagent simulations with `fork_context=false` and archived the observed response shapes here:
  - Prompt: design the first `Segment` entity for evidence anchoring. Observed result: 3 options, each with one short upside and one short downside, followed by a concise recommendation.
  - Prompt: choose the first implementation slice after evidence anchoring. Observed result: 3 options, each with one short upside and one short downside, with no long compare table.
  - Prompt: decide whether v1 `Segment` must support podcast/audio locators now. Observed result: 2 options only, each with one short upside and one short downside, confirming true binary forks do not get padded with weak extras.
- Executed `find docs/exec-plans/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \; | while read -r file; do rg -q "$file" docs/exec-plans/completed/README.md || echo "missing:$file"; done`; the command produced no missing entries, so the completed-plan catalog stayed in sync.
- Executed `loop-review-loop` full-PR round `20260306-015645`; review gate passed with `BLOCKER=0`, `IMPORTANT=0`.
- Executed `loop-review-loop` delta round `20260306-020428`; review gate blocked with `BLOCKER=0`, `IMPORTANT=1`, which drove the archive-evidence updates in this plan and the catalog-sync rule added to `docs/exec-plans/completed/README.md`.
- Executed `loop-review-loop` delta round `20260306-020831`; review gate passed with `BLOCKER=0`, `IMPORTANT=0` after the archive-evidence updates.
- Executed `loop-final-gate` against `.local/loop/review-20260306-020831.json` and `.local/loop/ci-20260306-discovery-option-framing.json`; the gate passed with `review_ok=true`, `ci_ok=true`, `branch_ok=true`, and `docs_ok=true`.

## Risks and Mitigations

- Risk: The model still defaults to 3 options even for clear binary decisions.
  - Mitigation: Add explicit wording that 2 options are preferred for a true fork and verify with an isolated 2-option test.
- Risk: Adding pros/cons makes discovery verbose.
  - Mitigation: Require one very short upside and one very short downside per option, and forbid long compare tables or essays.

## Completion Summary

- Delivered:
  - Reframed discovery option guidance from `2-3 approaches` to `2-4 realistic options` based on decision shape.
  - Required concise upside/downside notes per option.
  - Synced the discovery skill UI prompt with the new framing rules.
  - Captured isolated subagent evidence showing both 3-option and 2-option behavior.
- Not delivered:
  - No changes to the surrounding discovery/plan workflow beyond option framing.
- Tracker updates:
  - Marked `TASK-0005` as `done` and linked it to this archived plan.
