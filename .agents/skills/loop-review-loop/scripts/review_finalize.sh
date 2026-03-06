#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <round-id YYYYMMDD-HHMMSS> <reviewer-json> [<reviewer-json> ...]" >&2
  exit 1
fi

round_id="$1"
shift

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
aggregate_script="$script_dir/review_aggregate.sh"
gate_script="$script_dir/review_gate.sh"

aggregated_file="$("$aggregate_script" "$round_id" "$@")"

"$gate_script" "$aggregated_file"

echo "$aggregated_file"
