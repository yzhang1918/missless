#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
review_init="$script_dir/review_init.sh"
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

# 2) initialize a valid review round.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230000 full-pr >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230000.json"

# 3) aggregate rejects dash-prefixed reviewer filenames.
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

# 4) aggregate rejects non-timestamp round ids.
if (
  cd "$work_dir" &&
  "$review_aggregate" bad-round-id reviewer-empty.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted invalid round-id"
fi

# 5) aggregate rejects unknown severity values.
cat > "$work_dir/reviewer-bad-severity.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[{"id":"Sx","severity":"WARN"}]}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 reviewer-bad-severity.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted unknown severity token"
fi

# 6) aggregate computes counts from findings payload.
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

# 6.1) review_finalize fails when important findings remain.
if (
  cd "$work_dir" &&
  "$review_finalize" 20260305-230000 reviewer-a.json reviewer-b.json >/dev/null 2>&1
); then
  fail "review_finalize unexpectedly passed with IMPORTANT findings"
fi

# 6.2) review_finalize passes for clean reviewer artifacts.
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

# 7) review_gate fails when counts do not match findings payload.
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

# 8) final_gate also fails closed on counts mismatch.
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

# 9) gate scripts reject unknown severity values in findings.
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

# 10) review_gate accepts numerically equivalent count formats.
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

# 11) final_gate accepts numerically equivalent count formats.
(
  cd "$work_dir" &&
  "$final_gate" .local/loop/review-decimal-zero.json ci-good.json .local/loop/final-gate-decimal.json >/dev/null
)
assert_exists "$work_dir/.local/loop/final-gate-decimal.json"

# 12) cleanup rejects invalid keep-round arguments.
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

# 13) explicit keep-round-id preserves orphan aggregate rounds.
cat > "$work_dir/.local/loop/review-20260305-230099.json" <<'JSON'
{"round_id":"20260305-230099"}
JSON
(
  cd "$work_dir" &&
  "$review_cleanup" --keep-round-id 20260305-230099 --keep-rounds 0 >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230099.json"

# 14) cleanup dry-run does not delete; real cleanup keeps only latest round.
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
(
  cd "$work_dir" &&
  "$review_cleanup" --keep-rounds 1 >/dev/null
)
assert_not_exists "$work_dir/.local/loop/review-20260305-230001.json"
assert_not_exists "$work_dir/.local/loop/review-20260305-230001-correctness.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002-security.json"

echo "PASS: review loop regression checks"
