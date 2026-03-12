#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <plan-path> <review-json> <ci-json> <final-gate-json>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

plan_path="$1"
review_file="$2"
ci_file="$3"
final_gate_file="$4"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=stateful_gate_lib.sh
source "$script_dir/stateful_gate_lib.sh"

for path in "$review_file" "$ci_file" "$final_gate_file"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing artifact to promote: $path" >&2
    exit 1
  fi
done

normalized_plan="$(stateful_gate_normalize_repo_path "$plan_path")" || exit 1
plan_slug="$(stateful_gate_plan_slug "$plan_path")" || exit 1

if [[ "$(jq -r '.result // empty' "$final_gate_file")" != "pass" ]]; then
  echo "Final gate artifact must be pass before promotion: $final_gate_file" >&2
  exit 1
fi

if [[ "$(jq -r '.plan_path // empty' "$final_gate_file")" != "$normalized_plan" ]]; then
  echo "Final gate artifact plan path does not match promoted plan: $normalized_plan" >&2
  exit 1
fi

repo_root="$(stateful_gate_repo_root)"
target_rel=".local/final-evidence/$plan_slug"
target_dir="$repo_root/$target_rel"
mkdir -p "$target_dir"

cp "$review_file" "$target_dir/review.json"
cp "$ci_file" "$target_dir/ci-status.json"
cp "$final_gate_file" "$target_dir/final-gate.json"

printf '%s\n' "$target_rel"
