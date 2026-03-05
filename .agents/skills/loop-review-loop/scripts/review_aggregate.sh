#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <round-id YYYYMMDD-HHMMSS> <reviewer-json> [<reviewer-json> ...]" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

round_id="$1"
shift

# Enforce timestamp round IDs used by retention/cleanup logic.
if [[ ! "$round_id" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
  echo "Invalid round-id: expected format YYYYMMDD-HHMMSS" >&2
  exit 1
fi

out_dir=".local/loop"
out_file="$out_dir/review-${round_id}.json"
mkdir -p "$out_dir"

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing reviewer file: $file" >&2
    exit 1
  fi
  base="$(basename "$file")"
  if [[ "$base" == -* ]]; then
    echo "Invalid reviewer filename: $base" >&2
    exit 1
  fi
  if [[ ! "$base" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.json$ ]]; then
    echo "Invalid reviewer filename shape: $base" >&2
    exit 1
  fi
done

if ! jq -s -e '
  all(.[]; ((.findings // []) | type == "array"))
  and
  all(.[]; all((.findings // [])[]?;
    (.severity | type == "string")
    and (
      .severity == "BLOCKER"
      or .severity == "IMPORTANT"
      or .severity == "MINOR"
      or .severity == "NIT"
    )
  ))
' -- "$@" >/dev/null; then
  echo "Invalid reviewer artifact: findings[].severity must be BLOCKER/IMPORTANT/MINOR/NIT" >&2
  exit 1
fi

jq -s --arg round_id "$round_id" '
  def incomplete_reviewers:
    ([ .[] | (.status // "unknown") | select(. != "complete") ] | length);

  def important_or_blocker_findings:
    ([ .[] | (.findings // [])[] | select((.severity // "") == "BLOCKER" or (.severity // "") == "IMPORTANT") ] | length);

  {
    round_id: $round_id,
    scope: ((map(.scope) | map(select(. != null)) | first) // "delta"),
    status: (if incomplete_reviewers > 0 then "incomplete" else "complete" end),
    reviewers: [ .[] | {
      dimension: (.dimension // .reviewer // "unknown"),
      status: (.status // "unknown"),
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
      if (incomplete_reviewers > 0 or important_or_blocker_findings > 0)
      then "needs-fixes"
      else "ready"
      end
    ),
    updated_at: (now | todateiso8601)
  }
' -- "$@" > "$out_file"

echo "$out_file"
