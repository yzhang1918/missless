# Reviewer Output Schema

Each subagent reviewer writes one JSON file to `.local/loop/review-<round-id>-<dimension-slug>.json`.

## Minimum shape

```json
{
  "scope": "delta",
  "dimension": "security",
  "status": "complete",
  "summary": "No blocking risks found.",
  "findings": [
    {
      "id": "SEC-1",
      "severity": "IMPORTANT",
      "title": "Missing input validation",
      "area": "src/module/file.ts",
      "fix": "Validate boundary input with explicit schema checks"
    }
  ],
  "producer": {
    "type": "manual-fallback",
    "reason": "reviewer subagent did not return before finalize"
  }
}
```

## Severity vocabulary

- `BLOCKER`
- `IMPORTANT`
- `MINOR`
- `NIT`

## Notes

- Keep findings actionable.
- Avoid duplicate findings across reviewer dimensions when possible.
- The main agent owns de-duplication and final severity normalization.
- `producer` is optional for normal subagent output.
- When a manual fallback artifact is used to recover from missing reviewer output,
  keep the designated `output_path`, set `producer.type` to
  `manual-fallback`, and record a non-empty `producer.reason`.
