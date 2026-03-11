#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
review_init="$script_dir/review_init.sh"
review_prepare="$script_dir/review_prepare_reviewers.sh"
review_aggregate="$script_dir/review_aggregate.sh"
review_gate="$script_dir/review_gate.sh"
review_finalize="$script_dir/review_finalize.sh"
review_cleanup="$script_dir/review_cleanup.sh"
final_gate="$script_dir/../../loop-final-gate/scripts/final_gate.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || fail "missing expected path: $path"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "unexpected path exists: $path"
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
work_dir="$tmp_root/work"
mkdir -p "$work_dir/.local/loop"

# 1) review_init rejects non-timestamp round ids.
if (
  cd "$work_dir" &&
  "$review_init" bad-round-id full-pr >/dev/null 2>&1
); then
  fail "review_init accepted invalid round-id"
fi

# 2) review_prepare rejects non-timestamp round ids.
if (
  cd "$work_dir" &&
  "$review_prepare" bad-round-id full-pr security >/dev/null 2>&1
); then
  fail "review_prepare accepted invalid round-id"
fi

# 3) review_prepare rejects invalid scopes.
if (
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 review-all security >/dev/null 2>&1
); then
  fail "review_prepare accepted invalid scope"
fi

# 4) review_prepare rejects focus for a dimension that was not selected.
if (
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 full-pr --focus "security=Check secrets handling" correctness >/dev/null 2>&1
); then
  fail "review_prepare accepted focus for an unselected dimension"
fi

# 5) review_prepare rejects dimensions that normalize to the same artifact slug.
if (
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 full-pr "docs/spec consistency" "docs-spec-consistency" >/dev/null 2>&1
); then
  fail "review_prepare accepted dimensions with duplicate normalized slugs"
fi

# 6) review_prepare emits a launch manifest with stable prompt/output fields.
prepare_manifest_rel="$(
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 full-pr --focus "security=Check secrets handling" security "docs/spec consistency"
)"
prepare_manifest="$work_dir/$prepare_manifest_rel"
assert_exists "$prepare_manifest"
prepare_count="$(jq -r '.reviewers | length' "$prepare_manifest")"
[[ "$prepare_count" == "2" ]] || fail "expected reviewer count=2, got $prepare_count"
security_output="$(jq -r '.reviewers[] | select(.dimension == "security") | .output_path' "$prepare_manifest")"
[[ "$security_output" == ".local/loop/review-20260305-230000-security.json" ]] || fail "unexpected security output path: $security_output"
docs_output="$(jq -r '.reviewers[] | select(.dimension == "docs/spec consistency") | .output_path' "$prepare_manifest")"
[[ "$docs_output" == ".local/loop/review-20260305-230000-docs-spec-consistency.json" ]] || fail "unexpected docs output path: $docs_output"
security_focus="$(jq -r '.reviewers[] | select(.dimension == "security") | .focus' "$prepare_manifest")"
[[ "$security_focus" == "Check secrets handling" ]] || fail "unexpected security focus: $security_focus"
docs_has_focus="$(jq -r '.reviewers[] | select(.dimension == "docs/spec consistency") | has("focus")' "$prepare_manifest")"
[[ "$docs_has_focus" == "false" ]] || fail "expected docs/spec consistency reviewer to omit focus"
security_prompt="$(jq -r '.reviewers[] | select(.dimension == "security") | .prompt' "$prepare_manifest")"
[[ "$security_prompt" == *"\$loop-reviewer"* ]] || fail "review_prepare prompt did not reference loop-reviewer"
[[ "$security_prompt" == *".local/loop/review-20260305-230000-security.json"* ]] || fail "review_prepare prompt did not include reviewer output path"

# 7) initialize a valid review round.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230000 full-pr >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230000.json"

# 8) aggregate rejects dash-prefixed reviewer filenames.
cat > "$work_dir/-bad.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
cat > "$work_dir/reviewer-empty.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 -bad.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted dash-prefixed reviewer file"
fi

# 9) aggregate rejects non-timestamp round ids.
if (
  cd "$work_dir" &&
  "$review_aggregate" bad-round-id reviewer-empty.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted invalid round-id"
fi

# 10) aggregate rejects unknown severity values.
cat > "$work_dir/reviewer-bad-severity.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[{"id":"Sx","severity":"WARN"}]}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 reviewer-bad-severity.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted unknown severity token"
fi

# 11) aggregate computes counts from findings payload.
cat > "$work_dir/reviewer-a.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[{"id":"S1","severity":"IMPORTANT"}]}
JSON
cat > "$work_dir/reviewer-b.json" <<'JSON'
{"scope":"full-pr","dimension":"correctness","status":"complete","findings":[]}
JSON
(
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 reviewer-a.json reviewer-b.json >/dev/null
)
agg_file="$work_dir/.local/loop/review-20260305-230000.json"
assert_exists "$agg_file"
important_count="$(jq -r '.counts.important' "$agg_file")"
[[ "$important_count" == "1" ]] || fail "expected important count=1, got $important_count"

# 11.1) review_finalize fails when important findings remain and still prints aggregate path.
set +e
finalize_fail_output="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230000 reviewer-a.json reviewer-b.json 2>&1
)"
finalize_fail_status=$?
set -e
if [[ "$finalize_fail_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed with IMPORTANT findings"
fi
[[ "$finalize_fail_status" -eq 2 ]] || fail "review_finalize expected exit status 2, got $finalize_fail_status"
[[ "$finalize_fail_output" == *".local/loop/review-20260305-230000.json"* ]] || fail "review_finalize did not print aggregate path on failure"

# 11.2) review_finalize passes for clean reviewer artifacts.
cat > "$work_dir/reviewer-clean-a.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
cat > "$work_dir/reviewer-clean-b.json" <<'JSON'
{"scope":"full-pr","dimension":"correctness","status":"complete","findings":[]}
JSON
(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230002 reviewer-clean-a.json reviewer-clean-b.json >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230002.json"

# 12) review_gate fails when counts do not match findings payload.
cat > "$work_dir/.local/loop/review-mismatch.json" <<'JSON'
{
  "status": "complete",
  "findings": [{"id":"X","severity":"IMPORTANT"}],
  "counts": {"blocker": 0, "important": 0, "minor": 0, "nit": 0}
}
JSON
if (
  cd "$work_dir" &&
  "$review_gate" .local/loop/review-mismatch.json >/dev/null 2>&1
); then
  fail "review_gate accepted mismatched counts"
fi

# 13) final_gate also fails closed on counts mismatch.
cat > "$work_dir/ci-good.json" <<'JSON'
{
  "required_checks": [{"name":"local-smoke","status":"pass"}],
  "branch_up_to_date": true,
  "docs_updated": true
}
JSON
if (
  cd "$work_dir" &&
  "$final_gate" .local/loop/review-mismatch.json ci-good.json .local/loop/final-gate.json >/dev/null 2>&1
); then
  fail "final_gate accepted mismatched counts"
fi

# 14) gate scripts reject unknown severity values in findings.
cat > "$work_dir/.local/loop/review-unknown-severity.json" <<'JSON'
{
  "status": "complete",
  "findings": [{"id":"Z","severity":"WARN"}],
  "counts": {"blocker": 0, "important": 0, "minor": 0, "nit": 0}
}
JSON
if (
  cd "$work_dir" &&
  "$review_gate" .local/loop/review-unknown-severity.json >/dev/null 2>&1
); then
  fail "review_gate accepted unknown severity token"
fi
if (
  cd "$work_dir" &&
  "$final_gate" .local/loop/review-unknown-severity.json ci-good.json .local/loop/final-gate-unknown-severity.json >/dev/null 2>&1
); then
  fail "final_gate accepted unknown severity token"
fi

# 15) review_gate accepts numerically equivalent count formats.
cat > "$work_dir/.local/loop/review-decimal-zero.json" <<'JSON'
{
  "status": "complete",
  "findings": [],
  "counts": {"blocker": 0.0, "important": 0.0, "minor": 0, "nit": 0}
}
JSON
(
  cd "$work_dir" &&
  "$review_gate" .local/loop/review-decimal-zero.json >/dev/null
)

# 16) final_gate accepts numerically equivalent count formats.
(
  cd "$work_dir" &&
  "$final_gate" .local/loop/review-decimal-zero.json ci-good.json .local/loop/final-gate-decimal.json >/dev/null
)
assert_exists "$work_dir/.local/loop/final-gate-decimal.json"

# 17) cleanup rejects invalid keep-round arguments.
if (
  cd "$work_dir" &&
  "$review_cleanup" --keep-round-id --dry-run >/dev/null 2>&1
); then
  fail "review_cleanup accepted flag-like keep-round-id value"
fi
if (
  cd "$work_dir" &&
  "$review_cleanup" --keep-round-id bad-round-id >/dev/null 2>&1
); then
  fail "review_cleanup accepted non-timestamp keep-round-id"
fi
if (
  cd "$work_dir" &&
  "$review_cleanup" --keep-rounds not-a-number >/dev/null 2>&1
); then
  fail "review_cleanup accepted non-numeric keep-rounds"
fi

# 18) explicit keep-round-id preserves orphan aggregate rounds.
cat > "$work_dir/.local/loop/review-20260305-230099.json" <<'JSON'
{"round_id":"20260305-230099"}
JSON
(
  cd "$work_dir" &&
  "$review_cleanup" --keep-round-id 20260305-230099 --keep-rounds 0 >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230099.json"

# 19) cleanup dry-run does not delete; real cleanup keeps only latest round and removes launch manifests.
prepare_cleanup_manifest_rel="$(
  cd "$work_dir" &&
  "$review_prepare" 20260305-230003 delta security
)"
prepare_cleanup_manifest="$work_dir/$prepare_cleanup_manifest_rel"
assert_exists "$prepare_cleanup_manifest"
cat > "$work_dir/.local/loop/review-20260305-230001.json" <<'JSON'
{"round_id":"20260305-230001"}
JSON
cat > "$work_dir/.local/loop/review-20260305-230001-correctness.json" <<'JSON'
{"status":"complete","findings":[]}
JSON
cat > "$work_dir/.local/loop/review-20260305-230002.json" <<'JSON'
{"round_id":"20260305-230002"}
JSON
cat > "$work_dir/.local/loop/review-20260305-230002-security.json" <<'JSON'
{"status":"complete","findings":[]}
JSON
(
  cd "$work_dir" &&
  "$review_cleanup" --dry-run --keep-rounds 1 >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230001.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002.json"
assert_exists "$prepare_cleanup_manifest"
(
  cd "$work_dir" &&
  "$review_cleanup" --keep-rounds 1 >/dev/null
)
assert_not_exists "$work_dir/.local/loop/review-20260305-230001.json"
assert_not_exists "$work_dir/.local/loop/review-20260305-230001-correctness.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002-security.json"
assert_not_exists "$prepare_cleanup_manifest"

echo "PASS: review loop regression checks"
