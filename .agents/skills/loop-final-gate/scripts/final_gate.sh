#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <review-json> <ci-json> <plan-path> <base-branch> [output-json]" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=stateful_gate_lib.sh
source "$script_dir/stateful_gate_lib.sh"

review_file="$1"
ci_file="$2"
plan_file="$3"
base_branch="$4"
out_file="${5:-.local/loop/final-gate.json}"

if [[ ! -f "$review_file" ]]; then
  echo "Missing review artifact: $review_file" >&2
  exit 1
fi

if [[ ! -f "$ci_file" ]]; then
  echo "Missing CI artifact: $ci_file" >&2
  exit 1
fi

stateful_gate_require_codex_branch
stateful_gate_require_clean_worktree
stateful_gate_sync_origin "$base_branch"
normalized_plan="$(stateful_gate_validate_archived_plan "$plan_file")"

mkdir -p "$(dirname "$out_file")"

# Fail closed if required review fields are missing or invalid.
if ! jq -e '
  (.status | type == "string")
  and
  (.findings | type == "array")
  and
  all(.findings[]?;
    (.severity | type == "string")
    and (
      .severity == "BLOCKER"
      or .severity == "IMPORTANT"
      or .severity == "MINOR"
      or .severity == "NIT"
    )
  )
  and
  (.counts | type == "object")
  and (.counts.blocker | type == "number")
  and (.counts.important | type == "number")
' "$review_file" >/dev/null; then
  echo "Invalid review artifact: status/findings/counts contract failed" >&2
  exit 1
fi

review_blocker="$(jq -r '[.findings[]? | select((.severity // "") == "BLOCKER")] | length' "$review_file")"
review_important="$(jq -r '[.findings[]? | select((.severity // "") == "IMPORTANT")] | length' "$review_file")"
review_counts_match=true
if [[ "$(jq -r '
  (.counts.blocker == ([.findings[]? | select((.severity // "") == "BLOCKER")] | length))
  and
  (.counts.important == ([.findings[]? | select((.severity // "") == "IMPORTANT")] | length))
' "$review_file")" != "true" ]]; then
  review_counts_match=false
  echo "Invalid review artifact: counts do not match findings payload" >&2
  exit 1
fi

review_status_ok=false
if jq -e '(.status | type == "string") and (.status == "complete")' "$review_file" >/dev/null; then
  review_status_ok=true
fi

review_ok=false
if [[ "$review_status_ok" == "true" && "$review_blocker" == "0" && "$review_important" == "0" ]]; then
  review_ok=true
fi

if ! jq -e '
  (.schema_version == 1)
  and (.generated_at | type == "string")
  and (.head_sha | type == "string")
  and (.base_ref | type == "string")
  and (.base_sha | type == "string")
  and (.required_checks | type == "array")
  and all(.required_checks[]?;
    (.name | type == "string")
    and (.status | type == "string")
    and (
      .status == "pass"
      or .status == "fail"
      or .status == "pending"
      or .status == "skipping"
      or .status == "cancel"
    )
  )
  and (.docs_updated | type == "boolean")
' "$ci_file" >/dev/null; then
  echo "Invalid CI artifact: schema/head/base/check contract failed" >&2
  exit 1
fi

ci_meta_valid=true
required_checks_present="$(jq -e '(.required_checks | length) > 0' "$ci_file" >/dev/null && echo true || echo false)"
ci_failures="$(jq -r '[.required_checks[]? | select((.status // "") != "pass")] | length' "$ci_file")"
ci_ok=false
if [[ "$required_checks_present" == "true" && "$ci_failures" == "0" ]]; then
  ci_ok=true
fi

current_head_sha="$(stateful_gate_current_head_sha)"
current_base_sha="$(stateful_gate_current_base_sha "$base_branch")"
ci_head_matches="$(jq -r --arg head_sha "$current_head_sha" '.head_sha == $head_sha' "$ci_file")"
ci_base_ref_matches="$(jq -r --arg base_ref "$base_branch" '.base_ref == $base_ref' "$ci_file")"
ci_base_sha_matches="$(jq -r --arg base_sha "$current_base_sha" '.base_sha == $base_sha' "$ci_file")"

branch_ok=false
if stateful_gate_branch_includes_base "$base_branch"; then
  branch_ok=true
fi

docs_ok="$(jq -r '.docs_updated' "$ci_file")"
plan_ok=true
repo_sync_ok=true

result="fail"
if [[ "$review_ok" == "true" \
  && "$ci_ok" == "true" \
  && "$ci_meta_valid" == "true" \
  && "$ci_head_matches" == "true" \
  && "$ci_base_ref_matches" == "true" \
  && "$ci_base_sha_matches" == "true" \
  && "$branch_ok" == "true" \
  && "$docs_ok" == "true" \
  && "$plan_ok" == "true" \
  && "$repo_sync_ok" == "true" ]]; then
  result="pass"
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -n \
  --arg result "$result" \
  --arg plan_path "$normalized_plan" \
  --arg head_sha "$current_head_sha" \
  --arg base_ref "$base_branch" \
  --arg base_sha "$current_base_sha" \
  --argjson review_ok "$review_ok" \
  --argjson review_status_ok "$review_status_ok" \
  --argjson review_counts_match "$review_counts_match" \
  --argjson ci_ok "$ci_ok" \
  --argjson ci_meta_valid "$ci_meta_valid" \
  --argjson ci_head_matches "$ci_head_matches" \
  --argjson ci_base_ref_matches "$ci_base_ref_matches" \
  --argjson ci_base_sha_matches "$ci_base_sha_matches" \
  --argjson branch_ok "$branch_ok" \
  --argjson docs_ok "$docs_ok" \
  --argjson plan_ok "$plan_ok" \
  --argjson repo_sync_ok "$repo_sync_ok" \
  --argjson review_blocker "$review_blocker" \
  --argjson review_important "$review_important" \
  --argjson ci_failures "$ci_failures" \
  --arg timestamp "$timestamp" \
  '{
    result: $result,
    plan_path: $plan_path,
    head_sha: $head_sha,
    base_ref: $base_ref,
    base_sha: $base_sha,
    review_ok: $review_ok,
    review_status_ok: $review_status_ok,
    review_counts_match: $review_counts_match,
    ci_ok: $ci_ok,
    ci_meta_valid: $ci_meta_valid,
    ci_head_matches: $ci_head_matches,
    ci_base_ref_matches: $ci_base_ref_matches,
    ci_base_sha_matches: $ci_base_sha_matches,
    branch_ok: $branch_ok,
    docs_ok: $docs_ok,
    plan_ok: $plan_ok,
    repo_sync_ok: $repo_sync_ok,
    review_counts: {
      blocker: $review_blocker,
      important: $review_important
    },
    ci_failures: $ci_failures,
    evaluated_at: $timestamp
  }' > "$out_file"

if [[ "$result" == "pass" ]]; then
  echo "PASS: final gate clear"
  echo "$out_file"
  exit 0
fi

echo "FAIL: final gate blocked"
echo "$out_file"
exit 3
