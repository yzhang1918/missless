---
name: issue-triage
description: Triage GitHub backlog issues for `missless` by reading issue context, assigning `scope:*`, `kind:*`, and optional `state:*` labels, and recording disposition. Use when an agent or human needs to process `needs-triage` issues, run recurring backlog sweeps, or prepare issues for later discovery without starting implementation.
---

# Issue Triage

## Overview

Keep the GitHub backlog legible and ready for future discovery. Read the issue, confirm provenance, apply the minimum required labels, and leave a clear disposition without turning triage into planning.

## Inputs

- Issue number(s) or a search query that selects the issues to triage.
- Any human guidance on scope, priority, or whether the issue should stay open.

## Label Taxonomy

- Intake:
  - `needs-triage`
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
- End triage with exactly one `scope:*` label and exactly one `kind:*` label.
- Remove `needs-triage` once triage is complete.
- Leave at most one `state:*` label.
- Only `state:accepted` issues are ready to enter discovery from backlog.

## Execution Contract

1. Read the issue body, recent comments, and directly linked plan/PR/issue context needed to understand the request and its origin.
2. Ensure the issue body records origin/provenance. If the origin is clear from the linked context but missing from the body, edit the body to add it.
3. Apply labels using the taxonomy above.
4. Apply at most one `state:*` label:
   - `state:accepted` for backlog items worth doing later
   - `state:parked` for valid items that should remain open but unscheduled
   - `state:blocked` only when a concrete blocker is already known
   - no `state:*` label when closing as duplicate, obsolete, or declined
5. Leave a short triage comment when the disposition is not obvious from the labels alone.
6. If closing the issue, record the reason and link any replacement issue, source issue, or merged PR.

## Recurring Sweep Procedure

1. Select stale open issues first:
   - `needs-triage` older than 3 days
   - `state:blocked` older than 14 days
   - `state:parked` older than 14 days
   - `state:accepted` older than 30 days whose context or source links may have drifted
2. Re-read the issue body plus any linked plan/PR/issue that changed since the last triage pass.
3. Refresh labels, provenance, blocker notes, or parking rationale if the underlying context changed.
4. Leave a short comment when the outcome stays the same but the sweep confirmed the issue is still valid.
5. Keep already-triaged issues open when nothing changed; do not churn labels just to record that a sweep happened.
6. Default sweep query: `gh issue list --repo yzhang1918/missless --state open --search "updated:<YYYY-MM-DD>"`.

## Output

- Updated issue body, labels, and optional triage comment.
- Short summary of the triage outcome.

## Guardrails

- Do not start implementation or create a repository plan during triage.
- Do not leave more than one `scope:*`, `kind:*`, or `state:*` label on the issue.
- Do not close an issue just because it is unscheduled; use `state:parked` when the work remains valid.
