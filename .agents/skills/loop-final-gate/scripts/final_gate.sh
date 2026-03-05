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

review_blocker="$(jq -r '.counts.blocker // 0' "$review_file")"
review_important="$(jq -r '.counts.important // 0' "$review_file")"

review_ok=false
if [[ "$review_blocker" == "0" && "$review_important" == "0" ]]; then
  review_ok=true
fi

ci_failures="$(jq -r '[.required_checks[]? | select((.status // "") != "pass")] | length' "$ci_file")"
ci_ok=false
if [[ "$ci_failures" == "0" ]]; then
  ci_ok=true
fi

branch_ok="$(jq -r '.branch_up_to_date // false' "$ci_file")"
docs_ok="$(jq -r '.docs_updated // false' "$ci_file")"

result="fail"
if [[ "$review_ok" == "true" && "$ci_ok" == "true" && "$branch_ok" == "true" && "$docs_ok" == "true" ]]; then
  result="pass"
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg result "$result" \
  --argjson review_ok "$review_ok" \
  --argjson ci_ok "$ci_ok" \
  --argjson branch_ok "$branch_ok" \
  --argjson docs_ok "$docs_ok" \
  --argjson review_blocker "$review_blocker" \
  --argjson review_important "$review_important" \
  --argjson ci_failures "$ci_failures" \
  --arg timestamp "$timestamp" \
  '{
    result: $result,
    review_ok: $review_ok,
    ci_ok: $ci_ok,
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
