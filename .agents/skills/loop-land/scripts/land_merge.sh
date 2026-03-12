#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <final-gate-json> <plan-path> <base-branch> [--pr <number>] [--method <auto|merge|squash|rebase>] [--delete-branch <auto|true|false>] [--output <path>]" >&2
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
land_preflight_script="$script_dir/land_preflight.sh"
# shellcheck source=../../loop-final-gate/scripts/stateful_gate_lib.sh
source "$script_dir/../../loop-final-gate/scripts/stateful_gate_lib.sh"

final_gate_file="$1"
plan_file="$2"
base_branch="$3"
shift 3

pr_selector=""
requested_method="auto"
delete_branch_mode="auto"
out_file=".local/loop/land.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      [[ $# -ge 2 ]] || { echo "Missing value for --pr" >&2; exit 1; }
      pr_selector="$2"
      shift 2
      ;;
    --method)
      [[ $# -ge 2 ]] || { echo "Missing value for --method" >&2; exit 1; }
      requested_method="$2"
      shift 2
      ;;
    --delete-branch)
      [[ $# -ge 2 ]] || { echo "Missing value for --delete-branch" >&2; exit 1; }
      delete_branch_mode="$2"
      shift 2
      ;;
    --output)
      [[ $# -ge 2 ]] || { echo "Missing value for --output" >&2; exit 1; }
      out_file="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

case "$requested_method" in
  auto|merge|squash|rebase) ;;
  *)
    echo "--method must be one of auto, merge, squash, or rebase" >&2
    exit 1
    ;;
esac

case "$delete_branch_mode" in
  auto|true|false) ;;
  *)
    echo "--delete-branch must be auto, true, or false" >&2
    exit 1
    ;;
esac

choose_merge_method() {
  local repo_json="$1"
  local requested="$2"

  if [[ "$requested" == "merge" ]]; then
    [[ "$(jq -r '.allow_merge_commit // false' <<<"$repo_json")" == "true" ]] || {
      echo "Repository does not allow merge commits" >&2
      return 1
    }
    printf 'merge\n'
    return 0
  fi
  if [[ "$requested" == "squash" ]]; then
    [[ "$(jq -r '.allow_squash_merge // false' <<<"$repo_json")" == "true" ]] || {
      echo "Repository does not allow squash merges" >&2
      return 1
    }
    printf 'squash\n'
    return 0
  fi
  if [[ "$requested" == "rebase" ]]; then
    [[ "$(jq -r '.allow_rebase_merge // false' <<<"$repo_json")" == "true" ]] || {
      echo "Repository does not allow rebase merges" >&2
      return 1
    }
    printf 'rebase\n'
    return 0
  fi

  if [[ "$(jq -r '.allow_rebase_merge // false' <<<"$repo_json")" == "true" ]]; then
    printf 'rebase\n'
    return 0
  fi
  if [[ "$(jq -r '.allow_squash_merge // false' <<<"$repo_json")" == "true" ]]; then
    printf 'squash\n'
    return 0
  fi
  if [[ "$(jq -r '.allow_merge_commit // false' <<<"$repo_json")" == "true" ]]; then
    printf 'merge\n'
    return 0
  fi

  echo "Repository does not allow any supported merge method" >&2
  return 1
}

resolve_delete_branch() {
  local repo_json="$1"
  local mode="$2"

  if [[ "$mode" == "auto" ]]; then
    jq -r 'if (.delete_branch_on_merge | type) == "boolean" then .delete_branch_on_merge else false end' <<<"$repo_json"
    return 0
  fi
  printf '%s\n' "$mode"
}

declare -a cleanup_warnings=()
record_warning() {
  local message="$1"
  cleanup_warnings+=("$message")
  printf 'WARNING: %s\n' "$message" >&2
}

preflight_args=("$final_gate_file" "$plan_file" "$base_branch")
if [[ -n "$pr_selector" ]]; then
  preflight_args+=(--pr "$pr_selector")
fi
"$land_preflight_script" "${preflight_args[@]}" >/dev/null

normalized_final_gate_path="$(stateful_gate_normalize_repo_path "$final_gate_file")"
normalized_plan_path="$(stateful_gate_normalize_repo_path "$plan_file")"
head_branch="$(stateful_gate_current_branch)"
current_head_sha="$(stateful_gate_current_head_sha)"

if [[ -z "$pr_selector" ]]; then
  pr_selector="$(gh pr list --head "$head_branch" --state open --json number --jq '.[0].number')"
fi

if [[ -z "${pr_selector:-}" || "${pr_selector:-null}" == "null" ]]; then
  echo "Unable to determine an open PR for branch: $head_branch" >&2
  exit 1
fi

repo="$(stateful_gate_repo_name_with_owner)"
repo_json="$(gh api "repos/$repo")" || {
  echo "Unable to read repository merge policy for $repo" >&2
  exit 1
}
merge_method="$(choose_merge_method "$repo_json" "$requested_method")"
delete_branch="$(resolve_delete_branch "$repo_json" "$delete_branch_mode")"

declare -a merge_args
merge_args=(pr merge "$pr_selector" --match-head-commit "$current_head_sha")
case "$merge_method" in
  merge) merge_args+=(--merge) ;;
  squash) merge_args+=(--squash) ;;
  rebase) merge_args+=(--rebase) ;;
esac
if [[ "$delete_branch" == "true" ]]; then
  merge_args+=(--delete-branch)
fi

set +e
merge_output="$(gh "${merge_args[@]}" 2>&1)"
merge_exit_code=$?
set -e

pr_meta="$(gh pr view "$pr_selector" --json number,url,state,headRefOid,headRefName,baseRefName,mergedAt,mergeCommit)" || {
  if [[ -n "$merge_output" ]]; then
    printf '%s\n' "$merge_output" >&2
  fi
  echo "Unable to confirm PR state after gh pr merge" >&2
  exit 1
}

if [[ "$(jq -r '.state' <<<"$pr_meta")" != "MERGED" ]]; then
  if [[ -n "$merge_output" ]]; then
    printf '%s\n' "$merge_output" >&2
  fi
  echo "Remote merge did not complete for PR: $pr_selector" >&2
  exit 1
fi

merge_commit_sha="$(jq -r '.mergeCommit.oid // empty' <<<"$pr_meta")"
merged_at="$(jq -r '.mergedAt // empty' <<<"$pr_meta")"
if [[ -z "$merge_commit_sha" || -z "$merged_at" ]]; then
  echo "Merged PR metadata is incomplete for PR: $pr_selector" >&2
  exit 1
fi

if [[ "$merge_exit_code" -ne 0 ]]; then
  record_warning "gh pr merge exited with status $merge_exit_code after remote merge completed"
fi

if [[ -n "$merge_output" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    record_warning "$line"
  done <<<"$merge_output"
fi

if [[ "$(stateful_gate_current_branch)" == "$head_branch" ]]; then
  record_warning "Current worktree remains on merged branch $head_branch; local cleanup is deferred"
elif git rev-parse --verify --quiet "refs/heads/$head_branch" >/dev/null 2>&1; then
  record_warning "Local branch $head_branch still exists after remote merge; delete it manually when convenient"
fi

if ! git fetch --prune origin >/dev/null 2>&1; then
  record_warning "Failed to refresh local remote-tracking refs after remote merge"
fi

if [[ "$delete_branch" == "true" ]] && git rev-parse --verify --quiet "refs/remotes/origin/$head_branch" >/dev/null 2>&1; then
  record_warning "Remote-tracking ref origin/$head_branch still exists after merge despite delete-branch being requested"
fi

mkdir -p "$(dirname "$out_file")"
local_cleanup_ok=true
if ((${#cleanup_warnings[@]} > 0)); then
  local_cleanup_ok=false
fi

cleanup_warnings_json="$(
  if ((${#cleanup_warnings[@]} == 0)); then
    printf '[]\n'
  else
    printf '%s\n' "${cleanup_warnings[@]}" | jq -R . | jq -s .
  fi
)"

jq -n \
  --arg result "pass" \
  --arg final_gate_path "$normalized_final_gate_path" \
  --arg plan_path "$normalized_plan_path" \
  --arg base_ref "$base_branch" \
  --arg head_branch "$head_branch" \
  --arg head_sha "$current_head_sha" \
  --argjson pr_number "$(jq -r '.number' <<<"$pr_meta")" \
  --arg pr_url "$(jq -r '.url' <<<"$pr_meta")" \
  --arg merge_method "$merge_method" \
  --arg merge_commit_sha "$merge_commit_sha" \
  --arg merged_at "$merged_at" \
  --arg landed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --argjson delete_branch "$delete_branch" \
  --argjson merge_command_exit_code "$merge_exit_code" \
  --argjson remote_merge_ok true \
  --argjson local_cleanup_ok "$local_cleanup_ok" \
  --argjson cleanup_warnings "$cleanup_warnings_json" \
  '{
    result: $result,
    final_gate_path: $final_gate_path,
    plan_path: $plan_path,
    base_ref: $base_ref,
    head_branch: $head_branch,
    head_sha: $head_sha,
    pr_number: $pr_number,
    pr_url: $pr_url,
    merge_method: $merge_method,
    merge_commit_sha: $merge_commit_sha,
    merged_at: $merged_at,
    landed_at: $landed_at,
    delete_branch: $delete_branch,
    merge_command_exit_code: $merge_command_exit_code,
    remote_merge_ok: $remote_merge_ok,
    local_cleanup_ok: $local_cleanup_ok,
    cleanup_warnings: $cleanup_warnings
  }' > "$out_file"

printf 'PASS: remote merge recorded'
if [[ "$local_cleanup_ok" != "true" ]]; then
  printf ' (cleanup warnings=%s)' "${#cleanup_warnings[@]}"
fi
printf '\n%s\n' "$out_file"
