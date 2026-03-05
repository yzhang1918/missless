#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <review-json> <ci-json> [output-json]" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

review_file="$1"
ci_file="$2"
out_file="${3:-.local/loop/final-gate.json}"

if [[ ! -f "$review_file" ]]; then
  echo "Missing review artifact: $review_file" >&2
  exit 1
fi

if [[ ! -f "$ci_file" ]]; then
  echo "Missing CI artifact: $ci_file" >&2
  exit 1
fi

mkdir -p "$(dirname "$out_file")"

# Fail closed if required review fields are missing or invalid.
if ! jq -e '
  (.status | type == "string")
  and
  (.findings | type == "array")
  and
  all(.findings[]?;
    (.severity | type == "string")
    and (
      .severity == "BLOCKER"
      or .severity == "IMPORTANT"
      or .severity == "MINOR"
      or .severity == "NIT"
    )
  )
  and
  (.counts | type == "object")
  and (.counts.blocker | type == "number")
  and (.counts.important | type == "number")
' "$review_file" >/dev/null; then
  echo "Invalid review artifact: status/findings/counts contract failed" >&2
  exit 1
fi

review_blocker="$(jq -r '[.findings[]? | select((.severity // "") == "BLOCKER")] | length' "$review_file")"
review_important="$(jq -r '[.findings[]? | select((.severity // "") == "IMPORTANT")] | length' "$review_file")"
review_counts_match=true
if [[ "$(jq -r '
  (.counts.blocker == ([.findings[]? | select((.severity // "") == "BLOCKER")] | length))
  and
  (.counts.important == ([.findings[]? | select((.severity // "") == "IMPORTANT")] | length))
' "$review_file")" != "true" ]]; then
  review_counts_match=false
  echo "Invalid review artifact: counts do not match findings payload" >&2
  exit 1
fi

review_status_ok=false
if jq -e '(.status | type == "string") and (.status == "complete")' "$review_file" >/dev/null; then
  review_status_ok=true
fi

review_ok=false
if [[ "$review_status_ok" == "true" && "$review_blocker" == "0" && "$review_important" == "0" ]]; then
  review_ok=true
fi

required_checks_present="$(jq -e '(.required_checks | type == "array") and ((.required_checks | length) > 0)' "$ci_file" >/dev/null && echo true || echo false)"
ci_failures="$(jq -r '[.required_checks[]? | select((.status // "") != "pass")] | length' "$ci_file")"
ci_ok=false
if [[ "$required_checks_present" == "true" && "$ci_failures" == "0" ]]; then
  ci_ok=true
fi

# Fail closed for malformed CI metadata types.
ci_meta_valid=false
branch_ok=false
docs_ok=false
if jq -e '(.branch_up_to_date | type == "boolean") and (.docs_updated | type == "boolean")' "$ci_file" >/dev/null; then
  ci_meta_valid=true
  branch_ok="$(jq -r '.branch_up_to_date' "$ci_file")"
  docs_ok="$(jq -r '.docs_updated' "$ci_file")"
fi

result="fail"
if [[ "$review_ok" == "true" && "$ci_ok" == "true" && "$ci_meta_valid" == "true" && "$branch_ok" == "true" && "$docs_ok" == "true" ]]; then
  result="pass"
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg result "$result" \
  --argjson review_ok "$review_ok" \
  --argjson review_status_ok "$review_status_ok" \
  --argjson review_counts_match "$review_counts_match" \
  --argjson ci_ok "$ci_ok" \
  --argjson ci_meta_valid "$ci_meta_valid" \
  --argjson branch_ok "$branch_ok" \
  --argjson docs_ok "$docs_ok" \
  --argjson review_blocker "$review_blocker" \
  --argjson review_important "$review_important" \
  --argjson ci_failures "$ci_failures" \
  --arg timestamp "$timestamp" \
  '{
    result: $result,
    review_ok: $review_ok,
    review_status_ok: $review_status_ok,
    review_counts_match: $review_counts_match,
    ci_ok: $ci_ok,
    ci_meta_valid: $ci_meta_valid,
    branch_ok: $branch_ok,
    docs_ok: $docs_ok,
    review_counts: {
      blocker: $review_blocker,
      important: $review_important
    },
    ci_failures: $ci_failures,
    evaluated_at: $timestamp
  }' > "$out_file"

if [[ "$result" == "pass" ]]; then
  echo "PASS: final gate clear"
  echo "$out_file"
  exit 0
fi

echo "FAIL: final gate blocked"
echo "$out_file"
exit 3
