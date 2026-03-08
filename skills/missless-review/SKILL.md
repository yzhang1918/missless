---
name: missless-review
description: Use when you need to turn one URL into a missless review package with the local runtime. This skill fetches canonical text, writes or repairs extraction_draft.json, runs validate-draft and anchor-evidence, and renders a read-only local HTML review page.
---

# Missless Review

## Overview

Use this skill when the task is "turn this URL into a missless review package"
through the repository runtime.

The skill closes the current first-slice loop:
- fetch and normalize the source into a `run_dir`
- produce a complete `extraction_draft.json`
- validate and repair the draft when needed
- anchor evidence deterministically
- render a read-only HTML review page

## Workflow

1. Build the runtime if needed.

```bash
pnpm -r build
```

2. Fetch and normalize the URL into a run directory.

```bash
node apps/cli/dist/index.js fetch-normalize <url> --runs-dir .local/runs
```

Capture the `Created run directory:` path from stdout and treat it as the
single handle for the rest of the workflow.

3. Read `<run_dir>/canonical_text.md`.

4. Produce a complete `<run_dir>/extraction_draft.json`.

Read [references/extraction-contract.md](references/extraction-contract.md)
before writing the draft.

5. Validate the draft.

```bash
node apps/cli/dist/index.js validate-draft --run-dir <run_dir>
```

If validation fails, rerun with `--json`, repair the whole
`extraction_draft.json`, and validate again.

6. Anchor evidence.

```bash
node apps/cli/dist/index.js anchor-evidence --run-dir <run_dir>
```

If anchoring fails, rerun with `--json`, repair the draft, then rerun
`validate-draft` and `anchor-evidence`.

7. Render the review package.

```bash
node apps/cli/dist/index.js render-review --run-dir <run_dir>
```

8. Report the outcome with:
- the decision
- the run directory
- the HTML review path
- any remaining uncertainty worth human attention

## Guardrails

- This first slice is knowledge-base-agnostic. Do not inject personal
  knowledge-base comparisons into the decision.
- Stop at the review package. Do not persist atoms or invent commit behavior.
- Only the extraction agent writes `extraction_draft.json`.
- Do not hand-edit derived artifacts:
  `run.json`, `source.json`, `canonical_text.md`, `evidence_result.json`,
  `review_bundle.json`, or `review.html`.
- Keep `self_check` short or omit it.
- When diagnostics are available, prefer repairing the draft over weakening the
  evidence requirement.
