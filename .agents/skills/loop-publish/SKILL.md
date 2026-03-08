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

## Execution Contract

1. Confirm current branch matches `codex/*`, has intended commits, and has no uncommitted changes.
2. Push branch to `origin` (set upstream when needed).
3. Create PR if none exists for the branch, or update existing PR title/body.
4. Record PR URL and head SHA in the active plan or PR notes.
5. Return publish outcome (`created` or `updated`).

Use script:

```sh
.agents/skills/loop-publish/scripts/publish_pr.sh <base-branch> <title> <body-file> [--draft]
```

## Output

- Published PR URL.
- PR state (`created` or `updated`).

## Guardrails

- Do not merge in this skill.
- Do not force-push unless explicitly requested by the human.
- Publish only from `codex/*` working branches.
