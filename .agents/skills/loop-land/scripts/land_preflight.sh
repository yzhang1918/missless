#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <final-gate-json> <plan-path> <base-branch> [--pr <number>]" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../loop-final-gate/scripts/stateful_gate_lib.sh
source "$script_dir/../../loop-final-gate/scripts/stateful_gate_lib.sh"

final_gate_file="$1"
plan_file="$2"
base_branch="$3"
shift 3

pr_selector=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --pr" >&2
        exit 1
      fi
      pr_selector="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$final_gate_file" ]]; then
  echo "Missing final gate artifact: $final_gate_file" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated" >&2
  exit 1
fi

stateful_gate_require_codex_branch
stateful_gate_sync_origin "$base_branch"
normalized_plan="$(stateful_gate_validate_archived_plan "$plan_file")"

if ! jq -e '
  (.result | type == "string")
  and (.result == "pass")
  and (.plan_path | type == "string")
  and (.head_sha | type == "string")
  and (.base_ref | type == "string")
  and (.base_sha | type == "string")
  and (.evaluated_at | type == "string")
' "$final_gate_file" >/dev/null; then
  echo "Invalid final gate artifact: missing pass/head/base/plan contract" >&2
  exit 1
fi

current_head_sha="$(stateful_gate_current_head_sha)"
current_base_sha="$(stateful_gate_current_base_sha "$base_branch")"

if [[ "$(jq -r '.plan_path' "$final_gate_file")" != "$normalized_plan" ]]; then
  echo "Final gate artifact plan path does not match requested plan: $normalized_plan" >&2
  exit 1
fi

if [[ "$(jq -r '.head_sha' "$final_gate_file")" != "$current_head_sha" ]]; then
  echo "Final gate artifact head SHA is stale relative to current HEAD" >&2
  exit 1
fi

if [[ "$(jq -r '.base_ref' "$final_gate_file")" != "$base_branch" ]]; then
  echo "Final gate artifact base ref does not match requested base: $base_branch" >&2
  exit 1
fi

if [[ "$(jq -r '.base_sha' "$final_gate_file")" != "$current_base_sha" ]]; then
  echo "Final gate artifact base SHA is stale relative to origin/$base_branch" >&2
  exit 1
fi

if ! stateful_gate_branch_includes_base "$base_branch"; then
  echo "Current branch is behind origin/$base_branch; refresh before landing" >&2
  exit 1
fi

head_branch="$(stateful_gate_current_branch)"
if [[ -z "$pr_selector" ]]; then
  pr_selector="$(gh pr list --head "$head_branch" --state open --json number --jq '.[0].number')"
fi

if [[ -z "${pr_selector:-}" || "${pr_selector:-null}" == "null" ]]; then
  echo "Unable to determine an open PR for branch: $head_branch" >&2
  exit 1
fi

pr_meta="$(gh pr view "$pr_selector" --json number,url,state,headRefOid,baseRefName)"

if [[ "$(jq -r '.state' <<<"$pr_meta")" != "OPEN" ]]; then
  echo "PR is not open: $pr_selector" >&2
  exit 1
fi

if [[ "$(jq -r '.headRefOid' <<<"$pr_meta")" != "$current_head_sha" ]]; then
  echo "PR head SHA does not match current HEAD; publish the latest commits before landing" >&2
  exit 1
fi

if [[ "$(jq -r '.baseRefName' <<<"$pr_meta")" != "$base_branch" ]]; then
  echo "PR base branch does not match requested base: $base_branch" >&2
  exit 1
fi

printf 'PASS: land preflight clear (%s)\n' "$(jq -r '.url' <<<"$pr_meta")"
