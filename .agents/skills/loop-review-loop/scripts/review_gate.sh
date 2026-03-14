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
  def valid_severity:
    . == "BLOCKER"
    or . == "IMPORTANT"
    or . == "MINOR"
    or . == "NIT";
  def current_slice_findings:
    if (.current_slice_findings // null) != null then
      .current_slice_findings
    else
      (.findings // [])
    end;
  def accepted_deferred_risks:
    (.accepted_deferred_risks // []);
  def strategic_observations:
    (.strategic_observations // []);
  (.status | type == "string")
  and (
    .status == "complete"
    or .status == "incomplete"
  )
  and
  (current_slice_findings | type == "array")
  and
  all(current_slice_findings[]?;
    (.severity | type == "string")
    and (.severity | valid_severity)
  )
  and
  (accepted_deferred_risks | type == "array")
  and
  all(accepted_deferred_risks[]?;
    (.severity | type == "string")
    and (.severity | valid_severity)
    and ((.title // "") | type == "string")
    and ((.title // "") | length > 0)
    and ((.area // "") | type == "string")
    and ((.tracking_issue // "") | type == "string")
    and ((.accepted_reason // "") | type == "string")
    and (
      ((.tracking_issue // "") | length) > 0
      or ((.accepted_reason // "") | length) > 0
    )
  )
  and
  (strategic_observations | type == "array")
  and
  all(strategic_observations[]?;
    (.title | type == "string")
    and (.title | length > 0)
    and (.recommendation | type == "string")
    and (.recommendation | length > 0)
  )
  and
  (.counts | type == "object")
  and (.counts.blocker | type == "number")
  and (.counts.important | type == "number")
' "$review_file" >/dev/null; then
  echo "Invalid review artifact: status/current-slice/counts contract failed" >&2
  exit 3
fi

derived_blocker="$(jq -r '[(.current_slice_findings // .findings // [])[]? | select((.severity // "") == "BLOCKER")] | length' "$review_file")"
derived_important="$(jq -r '[(.current_slice_findings // .findings // [])[]? | select((.severity // "") == "IMPORTANT")] | length' "$review_file")"
counts_match="$(jq -r '
  (.counts.blocker == ([((.current_slice_findings // .findings // [])[]?) | select((.severity // "") == "BLOCKER")] | length))
  and
  (.counts.important == ([((.current_slice_findings // .findings // [])[]?) | select((.severity // "") == "IMPORTANT")] | length))
' "$review_file")"

if [[ "$counts_match" != "true" ]]; then
  echo "Invalid review artifact: counts do not match current-slice findings payload" >&2
  exit 3
fi

blocker="$derived_blocker"
important="$derived_important"
status="$(jq -r '.status' "$review_file")"

if [[ "$status" == "complete" && "$blocker" == "0" && "$important" == "0" ]]; then
  echo "PASS: review gate clear (current-slice BLOCKER=0, IMPORTANT=0)"
  exit 0
fi

echo "FAIL: review gate blocked (status=${status}, current-slice BLOCKER=${blocker}, IMPORTANT=${important})"
exit 2
