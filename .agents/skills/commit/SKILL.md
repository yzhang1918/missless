---
name: commit
description: Create a well-formed git commit from current changes using session history for rationale and summary. Use when asked to commit, prepare a commit message, or finalize staged work.
---

# Commit

## Goals

- Produce a commit that reflects actual changes and session context.
- Follow common git conventions (type prefix, short subject, wrapped body).
- Include both summary and rationale in the body.
- Keep commits small and atomic so they can be published/merged incrementally.

## Inputs

- Session history for intent and rationale.
- `git status`, `git diff`, and `git diff --staged` for actual changes.
- Repository commit conventions (if documented).
- Current loop stage to determine commit timing (execution can have multiple commits).

## Commit Cadence

- This skill defines commit quality, not commit frequency.
- Commit frequency is controlled by the active harness execution workflow.
- Multiple commits in one task are expected when they improve reviewability.

## Steps

1. Read session context to identify scope and rationale.
2. Inspect working tree and staged changes.
3. Stage intended changes after confirming scope.
4. Sanity-check staged files for accidental artifacts.
5. Fix staging scope or ask for confirmation if unrelated files are included.
6. Choose conventional type and optional scope (`feat`, `fix`, `docs`, `refactor`, `chore`).
7. Write subject in imperative mood, <= 72 chars, no trailing period.
8. Write body with:
   - Summary (what changed)
   - Rationale (why)
   - Tests/validation run (or explicit not-run reason)
9. Append `Co-authored-by: Codex <codex@openai.com>` unless user requests otherwise.
10. Wrap body lines at 72 chars.
11. Use `git commit -F <file>` (not newline escapes in `-m`).
12. Commit only if message matches staged diff.

## Template

```text
<type>(<scope>): <short summary>

Summary:
- <what changed>
- <what changed>

Rationale:
- <why>
- <why>

Tests:
- <command or "not run (reason)">

Co-authored-by: Codex <codex@openai.com>
```
