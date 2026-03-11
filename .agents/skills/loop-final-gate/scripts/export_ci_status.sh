#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <base-branch> --docs-updated <true|false> [--pr <number>] [--output <path>]" >&2
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
# shellcheck source=stateful_gate_lib.sh
source "$script_dir/stateful_gate_lib.sh"

base_branch="$1"
shift

docs_updated=""
pr_selector=""
out_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs-updated)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --docs-updated" >&2
        exit 1
      fi
      docs_updated="$2"
      shift 2
      ;;
    --pr)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --pr" >&2
        exit 1
      fi
      pr_selector="$2"
      shift 2
      ;;
    --output)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --output" >&2
        exit 1
      fi
      out_file="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

case "$docs_updated" in
  true|false)
    ;;
  *)
    echo "--docs-updated must be true or false" >&2
    exit 1
    ;;
esac

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated" >&2
  exit 1
fi

stateful_gate_require_codex_branch
stateful_gate_require_clean_worktree
stateful_gate_sync_origin "$base_branch"

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

if [[ "$(jq -r '.baseRefName' <<<"$pr_meta")" != "$base_branch" ]]; then
  echo "PR base branch does not match requested base: $base_branch" >&2
  exit 1
fi

current_head_sha="$(stateful_gate_current_head_sha)"
if [[ "$(jq -r '.headRefOid' <<<"$pr_meta")" != "$current_head_sha" ]]; then
  echo "PR head SHA does not match current HEAD; publish the latest commits before exporting CI status" >&2
  exit 1
fi

set +e
checks_raw="$(gh pr checks "$pr_selector" --required --json name,bucket 2>&1)"
checks_status=$?
set -e

if [[ "$checks_status" -ne 0 && "$checks_status" -ne 8 ]]; then
  printf '%s\n' "$checks_raw" >&2
  exit "$checks_status"
fi

if ! jq -e 'type == "array"' >/dev/null <<<"$checks_raw"; then
  echo "gh pr checks did not return JSON output" >&2
  exit 1
fi

required_checks="$(jq '[.[] | {name: .name, status: .bucket}]' <<<"$checks_raw")"
base_sha="$(stateful_gate_current_base_sha "$base_branch")"
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ -z "$out_file" ]]; then
  mkdir -p .local/loop
  short_sha="${current_head_sha:0:12}"
  out_file=".local/loop/ci-status-${short_sha}.json"
else
  mkdir -p "$(dirname "$out_file")"
fi

jq -n \
  --arg generated_at "$timestamp" \
  --arg head_sha "$current_head_sha" \
  --arg base_ref "$base_branch" \
  --arg base_sha "$base_sha" \
  --arg pr_url "$(jq -r '.url' <<<"$pr_meta")" \
  --argjson pr_number "$(jq -r '.number' <<<"$pr_meta")" \
  --argjson docs_updated "$docs_updated" \
  --argjson required_checks "$required_checks" \
  '{
    schema_version: 1,
    source: "github-pr-checks",
    generated_at: $generated_at,
    head_sha: $head_sha,
    base_ref: $base_ref,
    base_sha: $base_sha,
    pr_number: $pr_number,
    pr_url: $pr_url,
    required_checks: $required_checks,
    docs_updated: $docs_updated
  }' > "$out_file"

printf '%s\n' "$out_file"
