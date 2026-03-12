---
name: loop-reviewer
description: Produce one schema-valid structured reviewer JSON artifact for a single review dimension.
---

# Loop Reviewer

## Overview

Run one focused review dimension and write a JSON artifact consumed by `loop-review-loop`.

## Inputs

- Review scope (`delta` or `full-pr`).
- Dimension name (for example `architecture`, `docs-spec-consistency`).
- Output file path (for example `.local/loop/review-<round-id>-<dimension-slug>.json`).
- Optional focus text if the caller generated the prompt from `review_prepare_reviewers.sh`.
- Current branch diff/context.

## Execution Contract

1. Inspect repository context directly using local git commands (`git diff`, `git show`, `git log`).
2. Produce concise findings using severities:
   - `BLOCKER`
   - `IMPORTANT`
   - `MINOR`
   - `NIT`
3. Write JSON directly to the provided output path using the schema in:
   - `.agents/skills/loop-review-loop/references/reviewer-output-schema.md`
4. Return a short confirmation with output path and finding counts.

## Output

- One JSON artifact at the requested output path:
  - `scope`
  - `dimension`
  - `status`
  - `summary`
  - `findings[]`

## Guardrails

- Do not emit markdown as the artifact file content.
- Do not leave placeholder fields.
- If the caller provides extra focus guidance, keep the review scoped to that lens without changing the artifact schema.
- If no issues are found, write `findings: []` with `status: "complete"`.
- Do not modify tracked repository files, move `HEAD`, or write reviewer output anywhere except the designated output path.
