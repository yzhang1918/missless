#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <round-id YYYYMMDD-HHMMSS> [<reviewer-json> ...]" >&2
  exit 1
fi

round_id="$1"
shift

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
aggregate_script="$script_dir/review_aggregate.sh"
gate_script="$script_dir/review_gate.sh"

aggregated_file="$("$aggregate_script" "$round_id" "$@")"

if "$gate_script" "$aggregated_file"; then
  echo "$aggregated_file"
  exit 0
else
  status=$?
  echo "$aggregated_file"
  exit "$status"
fi
