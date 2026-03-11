---
name: loop-publish
description: Push the working branch and create or update the PR so review and landing can proceed without manual publishing steps.
---

# Loop Publish

## Overview

Publish current branch changes into an open PR before landing.

## Inputs

- Base branch name (usually `main`).
- PR title/body content.
- Current branch state and local commit history.
- Archived completed plan path under `docs/exec-plans/completed/` or `docs/harness/completed/`.
- Linked issue numbers and whether each one should close on merge.
- Whether the work came from a direct request with no intake issue.

## Execution Contract

1. Run repo-sync preflight before publish decisions so local refs and PR state are current.
2. Confirm current branch matches `codex/*`, has intended commits, has no uncommitted changes, and the supplied plan is an archived completed plan.
3. Push branch to `origin` (set upstream when needed).
4. Create PR if none exists for the branch, or update existing PR title/body.
   - PR body must list the linked issue(s).
   - Use GitHub closing keywords only for issues that should close when the PR merges.
   - If the work came from a direct request with no issue, say so explicitly in the PR body.
   - Treat declared issue metadata and the direct-request no-issue flag as mutually exclusive sources of truth.
   - Fail publish if the caller did not provide any declared issue metadata and also omitted the direct-request no-issue flag.
   - Fail publish if a declared linked issue is missing from the PR body.
   - Fail publish if a declared closing issue is missing the required closing keyword, or if a linked-only issue uses one by mistake.
   - Additional issue references are allowed for spawned or related backlog items; only the declared linked/closing issue set is publish-gated.
   - Fail publish if the PR body does not match the declared direct-request metadata.
5. Record PR URL and head SHA in the archived plan or PR notes.
6. Return publish outcome (`created` or `updated`).

Use script:

```sh
.agents/skills/loop-publish/scripts/publish_pr.sh <base-branch> <title> <body-file> --plan <archived-plan-path> [--draft] [--direct-request] [--link-issue <issue-ref>]... [--close-issue <issue-ref>]...
```

## Output

- Published PR URL.
- PR state (`created` or `updated`).

## Guardrails

- Do not merge in this skill.
- Do not force-push unless explicitly requested by the human.
- Publish only from `codex/*` working branches.
- Fail closed if the plan is still under `active/` or if the archived plan is not actually complete.
