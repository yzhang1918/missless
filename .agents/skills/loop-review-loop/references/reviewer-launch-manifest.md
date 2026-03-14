# Reviewer Launch Manifest

`review_prepare_reviewers.sh` emits a runtime-agnostic JSON manifest for one
review round at `.local/loop/review-launch-<round-id>.json`.

## Usage

```sh
.agents/skills/loop-review-loop/scripts/review_prepare_reviewers.sh \
  <round-id YYYYMMDD-HHMMSS> \
  <scope delta|full-pr> \
  [--focus "<dimension>=<focus>"]... \
  <dimension> [<dimension> ...]
```

## Purpose

Use this helper when you already know the review dimensions for a round and want
stable reviewer launch records without binding the repository to a specific
subagent runtime.

- The caller still owns actual subagent spawning.
- The caller/runtime must also keep the matching reviewer dispatch record up to
  date.
- `dimension` remains free-form.
- Each reviewer entry carries a standard `loop-reviewer` prompt plus the target
  output artifact path.
- The manifest is the authoritative machine-readable contract for the round's
  expected reviewer outputs and repo-observable ownership baseline.

## Manifest Shape

```json
{
  "round_id": "20260311-101500",
  "scope": "full-pr",
  "generated_at": "2026-03-11T10:15:00Z",
  "dispatch_record_path": ".local/loop/review-dispatch-20260311-101500.json",
  "baseline_repo_state": {
    "head_sha": "abc123def456",
    "tracked_worktree": []
  },
  "ownership_boundary": {
    "mode": "repo-observable",
    "declared_reviewer_output_paths_only": true,
    "observable_side_effect_checks": [
      "unexpected reviewer output paths",
      "tracked worktree changes",
      "HEAD movement"
    ],
    "detects_arbitrary_untracked_files": false,
    "detects_remote_side_effects": false
  },
  "allowed_output_paths": [
    ".local/loop/review-20260311-101500-security.json"
  ],
  "reviewers": [
    {
      "skill": "loop-reviewer",
      "scope": "full-pr",
      "dimension": "security",
      "dimension_slug": "security",
      "output_path": ".local/loop/review-20260311-101500-security.json",
      "prompt": "Use $loop-reviewer to run the `security` review dimension...",
      "focus": "Check secret handling and auth boundaries"
    }
  ]
}
```

## Notes

- `dimension_slug` is derived from the free-form dimension text and is only used
  for stable artifact naming.
- `baseline_repo_state` captures the repo-observable baseline immediately before
  reviewer launch so finalize can detect later `HEAD` movement or tracked
  worktree drift.
- `dispatch_record_path` points to the matching per-round reviewer dispatch
  ledger documented in `references/reviewer-dispatch-record.md`.
- `ownership_boundary` makes the shipped enforcement boundary explicit: the
  harness checks declared reviewer output paths plus repo-observable tracked
  worktree and `HEAD` drift, but it does not claim arbitrary untracked-file,
  full runtime, or remote-side-effect isolation.
- `allowed_output_paths` lists the only local reviewer artifact paths allowed
  for that round.
- The helper rejects two dimensions that normalize to the same slug.
- `focus` is optional and is omitted when not provided.
- Launch manifests are ephemeral `.local/loop` artifacts and should be cleaned
  up by `review_cleanup.sh`.
