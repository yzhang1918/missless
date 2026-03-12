#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <base-branch>" >&2
  exit 1
fi

base_branch="$1"
workflow_path=".github/workflows/harness-checks.yml"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=stateful_gate_lib.sh
source "$script_dir/stateful_gate_lib.sh"

stateful_gate_require_repository_readiness "$base_branch" "$workflow_path"

printf 'PASS: repository readiness clear for origin/%s\n' "$base_branch"
