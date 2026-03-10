---
name: issue-create
description: Create or update GitHub backlog issues for `missless` with explicit origin, context, labels, and cross-links. Use when an agent or human needs to capture future work discovered during execution, turn an asynchronous idea into backlog, or backfill issue provenance so later triage and discovery have enough context.
---

# Issue Create

## Overview

Capture open work in GitHub before the context goes stale. Create or update the issue body so later triage can classify it quickly and later discovery can recover the original intent.

## Inputs

- Summary of the work to capture.
- Origin/provenance for the issue.
- Known references such as plans, PRs, prior issues, runs, screenshots, or docs.
- Optional label intent when the human has already decided scope or kind.

## Label Taxonomy

- Intake:
  - `needs-triage` for new backlog items that still need classification
- Scope:
  - `scope:harness`
  - `scope:product`
- Kind:
  - `kind:feature`
  - `kind:bug`
  - `kind:debt`
- State:
  - `state:accepted`
  - `state:blocked`
  - `state:parked`

Use these rules:
- Default newly created issues to `needs-triage`.
- Only apply `scope:*`, `kind:*`, or `state:*` labels when they are already known and intentional.
- If creating a pre-triaged issue, remove `needs-triage`, assign exactly one `scope:*`, exactly one `kind:*`, and at most one `state:*`.

## Execution Contract

1. Check whether an open issue already captures the same work. Prefer updating and linking existing issues over creating duplicates.
2. Write or update the issue body with these sections:
   - `Summary`
   - `Origin`
   - `Context`
   - `Evidence Or References`
   - `Desired Outcome`
3. Record origin explicitly. State whether the issue came from a direct idea, a spawned follow-up, another issue, a plan, or a PR, and link the source when available.
4. Default new issues to `needs-triage` unless the human explicitly asks for a pre-triaged issue.
5. Apply labels using the taxonomy above.
6. If the issue is spawned during active execution, add the new issue link back to the current plan or PR before closing the current task.

## Output

- Created or updated GitHub issue number and URL.
- Short summary of the captured backlog item and any labels applied.

## Guardrails

- Do not leave open work only in a completed plan or PR comment; capture it in a GitHub issue.
- Do not omit the origin section, even for rough mobile-created ideas.
- Do not mark an issue resolved from this skill; closure belongs to the landing flow.
