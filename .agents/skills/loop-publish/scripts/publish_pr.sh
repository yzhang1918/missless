#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <base-branch> <title> <body-file> --plan <archived-plan-path> [--draft] [--direct-request] [--link-issue <issue-ref>]... [--close-issue <issue-ref>]..." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../../loop-final-gate/scripts/stateful_gate_lib.sh
source "$script_dir/../../loop-final-gate/scripts/stateful_gate_lib.sh"

base_branch="$1"
title="$2"
body_file="$3"
shift 3

draft_flag=""
direct_request=false
plan_file=""
declare -a linked_issues=()
declare -a closing_issues=()

normalize_issue_ref() {
  local raw="$1"
  if [[ "$raw" =~ ^#?[0-9]+$ ]]; then
    raw="${raw#\#}"
    printf '#%s' "$raw"
    return 0
  fi
  echo "Invalid issue reference: $raw" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --draft)
      draft_flag="--draft"
      shift
      ;;
    --direct-request)
      direct_request=true
      shift
      ;;
    --plan)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --plan" >&2
        exit 1
      fi
      plan_file="$2"
      shift 2
      ;;
    --link-issue)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --link-issue" >&2
        exit 1
      fi
      linked_issues+=("$(normalize_issue_ref "$2")")
      shift 2
      ;;
    --close-issue)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --close-issue" >&2
        exit 1
      fi
      ref="$(normalize_issue_ref "$2")"
      linked_issues+=("$ref")
      closing_issues+=("$ref")
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$body_file" ]]; then
  echo "Missing body file: $body_file" >&2
  exit 1
fi

if [[ -z "$plan_file" ]]; then
  echo "Provide --plan <archived-plan-path> before publish" >&2
  exit 1
fi

if [[ "$direct_request" == true ]] && (( ${#linked_issues[@]} > 0 || ${#closing_issues[@]} > 0 )); then
  echo "Use either --direct-request or issue linkage flags, not both" >&2
  exit 1
fi

if [[ "$direct_request" == false ]] && (( ${#linked_issues[@]} == 0 && ${#closing_issues[@]} == 0 )); then
  echo "Provide linked issue metadata or --direct-request before publish" >&2
  exit 1
fi

if [[ "$direct_request" == true ]]; then
  if ! grep -Fqi 'direct request (no issue)' "$body_file"; then
    echo "PR body must include 'direct request (no issue)' when --direct-request is used" >&2
    exit 1
  fi
fi

if (( ${#linked_issues[@]} > 0 )); then
  for ref in "${linked_issues[@]}"; do
    if ! grep -Fq "$ref" "$body_file"; then
      echo "PR body is missing linked issue reference: $ref" >&2
      exit 1
    fi
  done
fi

if (( ${#closing_issues[@]} > 0 )); then
  for ref in "${closing_issues[@]}"; do
    if ! grep -Eqi "(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)[[:space:]]+$ref([^0-9]|$)" "$body_file"; then
      echo "PR body is missing a closing keyword for issue: $ref" >&2
      exit 1
    fi
  done
fi

if (( ${#linked_issues[@]} > 0 )); then
  for ref in "${linked_issues[@]}"; do
    is_closing_ref=false
    if (( ${#closing_issues[@]} > 0 )); then
      for closing_ref in "${closing_issues[@]}"; do
        if [[ "$closing_ref" == "$ref" ]]; then
          is_closing_ref=true
          break
        fi
      done
    fi
    if [[ "$is_closing_ref" == false ]] && grep -Eqi "(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)[[:space:]]+$ref([^0-9]|$)" "$body_file"; then
      echo "PR body must not use a closing keyword for linked-only issue: $ref" >&2
      exit 1
    fi
  done
fi

stateful_gate_require_codex_branch
stateful_gate_require_clean_worktree
stateful_gate_sync_origin "$base_branch"
normalized_plan="$(stateful_gate_validate_archived_plan "$plan_file")"

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated" >&2
  exit 1
fi

head_branch="$(stateful_gate_current_branch)"

if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push >/dev/null
else
  git push -u origin "$head_branch" >/dev/null
fi

existing_number="$(gh pr list --head "$head_branch" --state open --json number --jq '.[0].number')"

if [[ -n "${existing_number:-}" && "${existing_number:-null}" != "null" ]]; then
  gh pr edit "$existing_number" --base "$base_branch" --title "$title" --body-file "$body_file" >/dev/null
  pr_url="$(gh pr view "$existing_number" --json url --jq '.url')"
  echo "updated $pr_url"
  exit 0
fi

create_args=(--base "$base_branch" --head "$head_branch" --title "$title" --body-file "$body_file")
if [[ "$draft_flag" == "--draft" ]]; then
  create_args+=(--draft)
fi

pr_url="$(gh pr create "${create_args[@]}")"
echo "created $pr_url"
