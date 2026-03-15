# Reviewer Dispatch Record

`review_prepare_reviewers.sh` emits a per-round reviewer dispatch scaffold at
`.local/loop/review-dispatch-<round-id>.json`.

The caller/runtime that actually launches reviewer subagents is responsible for
updating this file as each reviewer slot changes state.

## Purpose

Use this record to make reviewer launch attempts and fallback eligibility
repo-observable without binding the repository to a specific subagent runtime.

- Every expected reviewer slot starts as `pending`.
- The caller/runtime records reviewer launch and outcome events with
  `review_record_dispatch.sh`.
- `review_finalize.sh` uses the dispatch record to decide whether a
  `manual-fallback` artifact is legitimate.

## Dispatch Status Vocabulary

- `pending`
- `launch-started`
- `artifact-written`
- `launch-failed`
- `timeout`
- `invalid-artifact`
- `runtime-blocked`

Fallback-eligible statuses:

- `launch-failed`
- `timeout`
- `invalid-artifact`

Non-fallback statuses:

- `pending`
- `launch-started`
- `artifact-written`
- `runtime-blocked`

`runtime-blocked` means the current environment could not launch the reviewer
subagent at all. That is a review blocker, not a valid trigger for
`manual-fallback`.

## Shape

```json
{
  "round_id": "20260315-010203",
  "manifest_path": ".local/loop/review-launch-20260315-010203.json",
  "generated_at": "2026-03-15T01:02:03Z",
  "reviewers": [
    {
      "dimension": "security",
      "dimension_slug": "security",
      "output_path": ".local/loop/review-20260315-010203-security.json",
      "last_status": "timeout",
      "last_reason": "reviewer subagent timed out without writing its artifact",
      "attempts": [
        {
          "status": "launch-started",
          "recorded_at": "2026-03-15T01:02:05Z"
        },
        {
          "status": "timeout",
          "reason": "reviewer subagent timed out without writing its artifact",
          "recorded_at": "2026-03-15T01:12:05Z"
        }
      ]
    }
  ]
}
```

## Notes

- `review_record_dispatch.sh` appends to `attempts[]` and updates
  `last_status`/`last_reason`.
- A clean subagent reviewer path should normally end with `artifact-written`.
- `launch-failed`, `artifact-written`, `timeout`, and `invalid-artifact` are
  only valid immediately after the same reviewer slot recorded
  `launch-started`.
- `runtime-blocked` is the only terminal dispatch status that may appear
  without a prior `launch-started`, because it represents an environment-level
  inability to launch the reviewer at all.
- Once `runtime-blocked` is recorded for a slot, that slot is terminal for the
  round. Start a new round in a capable runtime instead of appending later
  dispatch events.
- A `manual-fallback` reviewer artifact is only valid when the matching
  reviewer slot's `last_status` is `launch-failed`, `timeout`, or
  `invalid-artifact`.
