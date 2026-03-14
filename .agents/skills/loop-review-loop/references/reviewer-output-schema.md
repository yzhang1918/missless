# Reviewer Output Schema

Each subagent reviewer writes one JSON file to `.local/loop/review-<round-id>-<dimension-slug>.json`.

## Minimum shape

```json
{
  "scope": "delta",
  "dimension": "security",
  "status": "complete",
  "summary": "One current-slice blocker, one accepted deferred risk, and one strategic observation.",
  "current_slice_findings": [
    {
      "id": "SEC-1",
      "severity": "IMPORTANT",
      "title": "Missing input validation",
      "area": "src/module/file.ts",
      "fix": "Validate boundary input with explicit schema checks"
    }
  ],
  "accepted_deferred_risks": [
    {
      "id": "SEC-D1",
      "severity": "IMPORTANT",
      "title": "Cross-provider fallback audit remains deferred",
      "area": "packages/core/src/providers",
      "tracking_issue": "#20",
      "accepted_reason": "Accepted follow-up outside the current slice"
    }
  ],
  "strategic_observations": [
    {
      "id": "SEC-S1",
      "title": "Consider a shared risk-taxonomy example library",
      "area": ".agents/skills/loop-reviewer/SKILL.md",
      "recommendation": "Extract reusable examples after the layered review contract stabilizes"
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

- Use `current_slice_findings[]` only for must-fix issues in the current diff or slice.
- Use `accepted_deferred_risks[]` for real out-of-slice concerns that the owner has explicitly accepted to defer.
- Use `strategic_observations[]` for longer-horizon guidance that should not block the current slice.
- Keep entries actionable and avoid duplicates across reviewer dimensions when possible.
- Each `accepted_deferred_risks[]` entry must include at least one of:
  - `tracking_issue`
  - `accepted_reason`
- Each `strategic_observations[]` entry should include a concrete `recommendation`.
- The main agent owns de-duplication and final severity normalization for `current_slice_findings[]`.
- `producer` is optional for normal subagent output.
- When a manual fallback artifact is used to recover from missing reviewer output,
  keep the designated `output_path`, set `producer.type` to
  `manual-fallback`, and record a non-empty `producer.reason`.
- During the transition to the layered contract, `review_aggregate.sh` still
  accepts legacy reviewer artifacts that use `findings[]` only and interprets
  them as `current_slice_findings[]`. New reviewer outputs should use the
  layered fields above.
