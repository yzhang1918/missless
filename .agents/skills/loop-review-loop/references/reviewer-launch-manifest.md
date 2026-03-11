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
- `dimension` remains free-form.
- Each reviewer entry carries a standard `loop-reviewer` prompt plus the target
  output artifact path.

## Manifest Shape

```json
{
  "round_id": "20260311-101500",
  "scope": "full-pr",
  "generated_at": "2026-03-11T10:15:00Z",
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
- The helper rejects two dimensions that normalize to the same slug.
- `focus` is optional and is omitted when not provided.
- Launch manifests are ephemeral `.local/loop` artifacts and should be cleaned
  up by `review_cleanup.sh`.
