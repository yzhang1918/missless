#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <round-id> <scope>" >&2
  exit 1
fi

round_id="$1"
scope="$2"
out_dir=".local/loop"
out_file="$out_dir/review-${round_id}.json"

mkdir -p "$out_dir"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$out_file" <<JSON
{
  "round_id": "${round_id}",
  "scope": "${scope}",
  "status": "in_progress",
  "reviewers": [],
  "findings": [],
  "counts": {
    "blocker": 0,
    "important": 0,
    "minor": 0,
    "nit": 0
  },
  "recommendation": "pending",
  "created_at": "${timestamp}"
}
JSON

echo "$out_file"
