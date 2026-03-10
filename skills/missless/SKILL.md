---
name: missless
description: Missless turns one public URL into a reading decision with inspectable evidence. Use when users want to turn an article URL into a missless review package.
---

# missless

## Overview

Use this skill when the task is "turn this URL into a missless review
package".

This skill owns one product action: `single-run URL -> review package`.

## Workflow

1. Build the runtime if needed.

```bash
pnpm -r build
```

2. Read the runtime-owned contract surface.

```bash
node apps/cli/dist/index.js --help
node apps/cli/dist/index.js print-draft-contract
```

3. If a caller already prepared a run directory for the target URL, resume from
that `run_dir` and skip directly to reading `canonical_text.md`.

Otherwise, fetch and normalize the URL into a run directory.

```bash
node apps/cli/dist/index.js fetch-normalize <url> --runs-dir .local/runs
```

Capture the `Created run directory:` path from stdout and treat it as the
single handle for the rest of the workflow.

4. Read `<run_dir>/canonical_text.md`.

5. Read [references/review-guidance.md](references/review-guidance.md).

6. Write a complete `<run_dir>/extraction_draft.json`.

The agent owns exactly one authored artifact in this slice:
`extraction_draft.json`.

7. Validate the draft.

```bash
node apps/cli/dist/index.js validate-draft --run-dir <run_dir>
```

If validation fails, rerun with `--json`, repair `extraction_draft.json`, and
validate again.

8. Anchor evidence.

```bash
node apps/cli/dist/index.js anchor-evidence --run-dir <run_dir>
```

If anchoring fails, rerun with `--json`, repair `extraction_draft.json`, then
rerun `validate-draft` and `anchor-evidence`.

9. Render the review package.

```bash
node apps/cli/dist/index.js render-review --run-dir <run_dir>
```

10. Report the result in chat with:
- the TLDR
- the decision
- the most important reasons
- the run directory
- the HTML review path
- any remaining uncertainty worth human attention

## Guardrails

- This first slice is knowledge-base-agnostic. Do not inject personal
  knowledge-base comparisons into the decision.
- Stop at the review package. Do not persist atoms or invent commit behavior.
- Before the first `validate-draft` attempt, limit context gathering to:
  - this skill
  - `references/review-guidance.md`
  - `missless --help`
  - `missless print-draft-contract`
  - the current run's `canonical_text.md`
- Do not inspect older runs, runtime source code, or tests before the first
  validation attempt unless the current run fails and the runtime diagnostics
  are insufficient.
- Do not hand-edit derived artifacts:
  `run.json`, `source.json`, `canonical_text.md`, `evidence_result.json`,
  `review_bundle.json`, or `review.html`.
- Keep `self_check` short or omit it.
- Prefer runtime diagnostics over weakening the evidence requirement.
