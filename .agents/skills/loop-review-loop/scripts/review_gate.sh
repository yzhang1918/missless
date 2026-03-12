#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <aggregated-review-json>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

review_file="$1"

if [[ ! -f "$review_file" ]]; then
  echo "Missing review artifact: $review_file" >&2
  exit 1
fi

# Fail closed if required gate fields are missing or invalid.
if ! jq -e '
  (.status | type == "string")
  and (
    .status == "complete"
    or .status == "incomplete"
  )
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
  exit 3
fi

derived_blocker="$(jq -r '[.findings[]? | select((.severity // "") == "BLOCKER")] | length' "$review_file")"
derived_important="$(jq -r '[.findings[]? | select((.severity // "") == "IMPORTANT")] | length' "$review_file")"
counts_match="$(jq -r '
  (.counts.blocker == ([.findings[]? | select((.severity // "") == "BLOCKER")] | length))
  and
  (.counts.important == ([.findings[]? | select((.severity // "") == "IMPORTANT")] | length))
' "$review_file")"

if [[ "$counts_match" != "true" ]]; then
  echo "Invalid review artifact: counts do not match findings payload" >&2
  exit 3
fi

blocker="$derived_blocker"
important="$derived_important"
status="$(jq -r '.status' "$review_file")"

if [[ "$status" == "complete" && "$blocker" == "0" && "$important" == "0" ]]; then
  echo "PASS: review gate clear (BLOCKER=0, IMPORTANT=0)"
  exit 0
fi

echo "FAIL: review gate blocked (status=${status}, BLOCKER=${blocker}, IMPORTANT=${important})"
exit 2
