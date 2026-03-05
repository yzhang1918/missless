# Reviewer Output Schema

Each subagent reviewer writes one JSON file to `.local/loop/review-<round-id>-<dimension>.json`.

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
  ]
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
