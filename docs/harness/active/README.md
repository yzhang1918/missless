# Active Harness Plans

Status: Active

## Purpose

Store harness/workflow plans currently in execution.

## Rules

- Naming convention: `YYYY-MM-DD-<short-topic>.md`
- Active plans must record their intake source, whether that is a GitHub issue or a direct request.
- Active plans are not valid inputs to `loop-publish`, `loop-final-gate`, or `loop-land`; archive the completed plan into `docs/harness/completed/` first.
- Plans that will later pass through stateful publish/final-gate/land checks must include:
  - `## Acceptance Criteria` with markdown checkboxes
  - `## Work Breakdown` with `### Step N` sections
  - one `- Status: pending|in_progress|completed|blocked` line per step
- When a landed plan records completion, treat remote merge success as the authoritative landing outcome and record any local cleanup limitations as warnings instead of silently converting the overall result back to failure.
- Any unresolved follow-up discovered during execution must become a GitHub issue before the current plan is closed.
