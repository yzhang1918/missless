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

blocker="$(jq -r '.counts.blocker // 0' "$review_file")"
important="$(jq -r '.counts.important // 0' "$review_file")"

if [[ "$blocker" == "0" && "$important" == "0" ]]; then
  echo "PASS: review gate clear (BLOCKER=0, IMPORTANT=0)"
  exit 0
fi

echo "FAIL: review gate blocked (BLOCKER=${blocker}, IMPORTANT=${important})"
exit 2
