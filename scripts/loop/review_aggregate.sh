#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <round-id> <reviewer-json> [<reviewer-json> ...]" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

round_id="$1"
shift

out_dir=".local/loop"
out_file="$out_dir/review-${round_id}.json"
mkdir -p "$out_dir"

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing reviewer file: $file" >&2
    exit 1
  fi
done

jq -s --arg round_id "$round_id" '
  {
    round_id: $round_id,
    scope: ((map(.scope) | map(select(. != null)) | first) // "delta"),
    status: "complete",
    reviewers: [ .[] | {
      dimension: (.dimension // .reviewer // "unknown"),
      status: (.status // "complete"),
      summary: (.summary // "")
    } ],
    findings: [ .[] | (.findings // [])[] ],
    counts: {
      blocker: ([ .[] | (.findings // [])[] | select((.severity // "") == "BLOCKER") ] | length),
      important: ([ .[] | (.findings // [])[] | select((.severity // "") == "IMPORTANT") ] | length),
      minor: ([ .[] | (.findings // [])[] | select((.severity // "") == "MINOR") ] | length),
      nit: ([ .[] | (.findings // [])[] | select((.severity // "") == "NIT") ] | length)
    },
    recommendation: (
      if (([ .[] | (.findings // [])[] | select((.severity // "") == "BLOCKER" or (.severity // "") == "IMPORTANT") ] | length) > 0)
      then "needs-fixes"
      else "ready"
      end
    ),
    updated_at: (now | todateiso8601)
  }
' "$@" > "$out_file"

echo "$out_file"
