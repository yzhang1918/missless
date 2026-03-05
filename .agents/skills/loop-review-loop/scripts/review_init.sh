#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <round-id YYYYMMDD-HHMMSS> <scope>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

round_id="$1"
scope="$2"

# Enforce timestamp round IDs used by retention/cleanup logic.
if [[ ! "$round_id" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
  echo "Invalid round-id: expected format YYYYMMDD-HHMMSS" >&2
  exit 1
fi

out_dir=".local/loop"
out_file="$out_dir/review-${round_id}.json"

mkdir -p "$out_dir"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg round_id "$round_id" \
  --arg scope "$scope" \
  --arg timestamp "$timestamp" \
  '{
    round_id: $round_id,
    scope: $scope,
    status: "in_progress",
    reviewers: [],
    findings: [],
    counts: {
      blocker: 0,
      important: 0,
      minor: 0,
      nit: 0
    },
    recommendation: "pending",
    created_at: $timestamp
  }' > "$out_file"

echo "$out_file"
