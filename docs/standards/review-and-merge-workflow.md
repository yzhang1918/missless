# Review and Merge Workflow

Status: Active

## Purpose

Define go/no-go checks for integrating changes while preserving throughput and quality.

## Scope

Applies to non-trivial implementation work handled through execution plans.

## Review Goals

- Validate correctness against explicit acceptance criteria.
- Validate consistency with architecture and specs.
- Validate documentation updates and traceability.

## Review Cadence

- Step-level delta review: run after each implementation step.
- PR-level full review: run after all planned steps are complete.
- Resolve all blocking and important findings before final gate.

## Minimum Review Checklist

- Problem and scope are clear.
- Changed behavior is covered by docs/spec updates.
- Validation evidence is present.
- Open risks and follow-ups are explicit and tracked.

## Final Gate vs Land

Final gate answers: "Is this change ready to merge?"
- Required review findings are resolved.
- Required CI checks are green.
- Branch is merge-ready.
- Required docs/spec updates are complete.

Land answers: "Merge now and record outcomes."
- Merge only after final gate pass.
- Record merge SHA, validation links, and deferred follow-ups.

## Follow-up Tracking Requirement

- Do not leave follow-ups only in plan prose or PR comments.
- Every follow-up must be recorded in `docs/exec-plans/follow-ups.md`.
- Unresolved follow-ups must map to backlog IDs in `docs/exec-plans/backlog.md`.

## Merge Preference

- Favor short-lived branches and frequent integration.
- Prefer fast, iterative correction over long blocked queues.
