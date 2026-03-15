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
origin_dir="$tmp_root/origin.git"
git init --bare "$origin_dir" >/dev/null 2>&1
work_dir="$tmp_root/work"
updater_dir="$tmp_root/updater"
fake_bin="$tmp_root/bin"
mkdir -p "$fake_bin"

cat > "$fake_bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

emit() {
  local payload="$1"
  shift
  local jq_query=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --jq|-q)
        jq_query="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  if [[ -n "$jq_query" ]]; then
    jq -r "$jq_query" <<<"$payload"
  else
    printf '%s\n' "$payload"
  fi
}

cmd1="${1:-}"
if [[ -z "$cmd1" ]]; then
  echo "missing gh command" >&2
  exit 1
fi
shift

case "$cmd1" in
  auth)
    if [[ "${1:-}" == "status" ]]; then
      exit 0
    fi
    ;;
  repo)
    if [[ "${1:-}" == "view" ]]; then
      shift || true
      emit "{\"nameWithOwner\":\"${FAKE_GH_REPO_NAME_WITH_OWNER:-example/missless}\"}" "$@"
      exit 0
    fi
    ;;
  api)
    api_path="${1:-}"
    shift || true
    case "$api_path" in
      repos/*/branches/*/protection)
        payload="${FAKE_GH_BRANCH_PROTECTION_JSON:-}"
        if [[ -z "$payload" ]]; then
          payload='{"required_status_checks":{"strict":true,"contexts":["local-smoke"],"checks":[{"context":"local-smoke"}]}}'
        fi
        emit "$payload" "$@"
        exit 0
        ;;
      repos/*/actions/permissions)
        payload="${FAKE_GH_ACTIONS_PERMISSIONS_JSON:-}"
        if [[ -z "$payload" ]]; then
          payload='{"enabled":true,"allowed_actions":"local_only","sha_pinning_required":true}'
        fi
        emit "$payload" "$@"
        exit 0
        ;;
    esac
    ;;
esac

echo "unsupported fake gh invocation: $cmd1 ${1:-}" >&2
exit 1
EOF
chmod +x "$fake_bin/gh"

git clone "$origin_dir" "$work_dir" >/dev/null 2>&1
(
  cd "$work_dir" &&
  git config user.name "Codex" &&
  git config user.email "codex@example.com" &&
  printf '.local/\n' >> .git/info/exclude &&
  git checkout -b main >/dev/null &&
  printf 'seed\n' > README.md &&
  git add README.md &&
  git commit -m "seed" >/dev/null &&
  git push -u origin main >/dev/null &&
  git checkout -b codex/review-regression >/dev/null &&
  mkdir -p .github/workflows docs/harness/completed &&
  cat > .github/workflows/harness-checks.yml <<'YAML'
name: harness-checks
on:
  push:
    branches:
      - main
jobs:
  harness-checks:
    runs-on: ubuntu-latest
    steps:
      - name: Verify diff formatting
        run: git diff --check
YAML
  cat > docs/harness/completed/2026-03-11-review-regression-plan.md <<'PLAN'
# Review Regression Plan

## Acceptance Criteria

- [x] Regression fixture is archived and complete.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Seed a gateable archived plan fixture.
- Expected files:
  - `docs/harness/completed/2026-03-11-review-regression-plan.md`
- Validation commands:
  - `true`
- Documentation impact:
  - Provides a stable archived plan path for regression checks.

## Validation Summary

- Fixture prepared for regression checks.

## Completion Summary

- Delivered: Archived completed-plan fixture.
- Not delivered: None.
- Linked issue updates: None.
- Spawned follow-up issues: None.
PLAN
  git add .github/workflows/harness-checks.yml docs/harness/completed/2026-03-11-review-regression-plan.md &&
  git commit -m "add regression plan fixture" >/dev/null
)

export FAKE_GH_REPO_NAME_WITH_OWNER="example/missless"
export FAKE_GH_BRANCH_PROTECTION_JSON='{"required_status_checks":{"strict":true,"contexts":["local-smoke"],"checks":[{"context":"local-smoke"}]}}'
export FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":true,"allowed_actions":"local_only","sha_pinning_required":true}'

mkdir -p "$work_dir/.local/loop"
plan_path="docs/harness/completed/2026-03-11-review-regression-plan.md"
head_sha="$(cd "$work_dir" && git rev-parse HEAD)"
base_sha="$(cd "$work_dir" && git rev-parse origin/main)"

# 1) review_init repo-syncs remote refs before starting the round.
git clone "$origin_dir" "$updater_dir" >/dev/null 2>&1
(
  cd "$updater_dir" &&
  git config user.name "Codex" &&
  git config user.email "codex@example.com" &&
  git checkout -b codex/remote-probe origin/main >/dev/null &&
  printf 'probe\n' > probe.txt &&
  git add probe.txt &&
  git commit -m "probe" >/dev/null &&
  git push -u origin codex/remote-probe >/dev/null
)
if (
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/codex/remote-probe >/dev/null
); then
  fail "expected origin/codex/remote-probe to be absent before repo-sync preflight"
fi
(
  cd "$work_dir" &&
  "$review_init" 20260305-225959 full-pr >/dev/null
)
(
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/codex/remote-probe >/dev/null
) || fail "review_init did not repo-sync remote refs"

# 1.1) review_init prunes stale remote-tracking refs before starting the round.
(
  cd "$updater_dir" &&
  git checkout -b codex/prune-probe origin/main >/dev/null &&
  printf 'stale\n' > stale.txt &&
  git add stale.txt &&
  git commit -m "stale probe" >/dev/null &&
  git push -u origin codex/prune-probe >/dev/null
)
(
  cd "$work_dir" &&
  git fetch origin codex/prune-probe:refs/remotes/origin/codex/prune-probe >/dev/null 2>&1
)
(
  cd "$updater_dir" &&
  git push origin --delete codex/prune-probe >/dev/null
)
(
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/codex/prune-probe >/dev/null
) || fail "expected origin/codex/prune-probe to exist before repo-sync prune preflight"
(
  cd "$work_dir" &&
  "$review_init" 20260305-225960 full-pr >/dev/null
)
if (
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/codex/prune-probe >/dev/null
); then
  fail "review_init did not prune stale remote-tracking refs"
fi

# 2) review_init rejects non-timestamp round ids.
if (
  cd "$work_dir" &&
  "$review_init" bad-round-id full-pr >/dev/null 2>&1
); then
  fail "review_init accepted invalid round-id"
fi

# 3) review_prepare rejects non-timestamp round ids.
if (
  cd "$work_dir" &&
  "$review_prepare" bad-round-id full-pr security >/dev/null 2>&1
); then
  fail "review_prepare accepted invalid round-id"
fi

# 4) review_prepare rejects invalid scopes.
if (
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 review-all security >/dev/null 2>&1
); then
  fail "review_prepare accepted invalid scope"
fi

# 5) review_prepare rejects focus for a dimension that was not selected.
if (
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 full-pr --focus "security=Check secrets handling" correctness >/dev/null 2>&1
); then
  fail "review_prepare accepted focus for an unselected dimension"
fi

# 6) review_prepare rejects dimensions that normalize to the same artifact slug.
if (
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 full-pr "docs/spec consistency" "docs-spec-consistency" >/dev/null 2>&1
); then
  fail "review_prepare accepted dimensions with duplicate normalized slugs"
fi

# 7) review_prepare emits a launch manifest with stable prompt/output fields.
prepare_manifest_rel="$(
  cd "$work_dir" &&
  "$review_prepare" 20260305-230000 full-pr --focus "security=Check secrets handling" security "docs/spec consistency"
)"
prepare_manifest="$work_dir/$prepare_manifest_rel"
assert_exists "$prepare_manifest"
prepare_count="$(jq -r '.reviewers | length' "$prepare_manifest")"
[[ "$prepare_count" == "2" ]] || fail "expected reviewer count=2, got $prepare_count"
manifest_head_sha="$(jq -r '.baseline_repo_state.head_sha' "$prepare_manifest")"
[[ "$manifest_head_sha" == "$head_sha" ]] || fail "unexpected manifest head sha: $manifest_head_sha"
manifest_worktree_count="$(jq -r '.baseline_repo_state.tracked_worktree | length' "$prepare_manifest")"
[[ "$manifest_worktree_count" == "0" ]] || fail "expected empty tracked worktree snapshot, got $manifest_worktree_count"
allowed_output_count="$(jq -r '.allowed_output_paths | length' "$prepare_manifest")"
[[ "$allowed_output_count" == "2" ]] || fail "expected allowed output count=2, got $allowed_output_count"
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
[[ "$security_prompt" == *"Only write"* ]] || fail "review_prepare prompt did not include write-scope guidance"

# 8) initialize a valid review round.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230000 full-pr >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230000.json"

# 8.1) review_finalize fails closed when the expected reviewer artifacts are missing.
set +e
missing_finalize_output="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230000 2>&1
)"
missing_finalize_status=$?
set -e
if [[ "$missing_finalize_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed with missing reviewer artifacts"
fi
[[ "$missing_finalize_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for missing reviewer artifacts, got $missing_finalize_status"
[[ "$missing_finalize_output" == *".local/loop/review-20260305-230000.json"* ]] || fail "review_finalize did not print aggregate path when reviewer artifacts were missing"
missing_count="$(jq -r '.contract.missing_reviewers | length' "$work_dir/.local/loop/review-20260305-230000.json")"
[[ "$missing_count" == "2" ]] || fail "expected two missing reviewers, got $missing_count"

# 9) aggregate rejects dash-prefixed reviewer filenames.
cat > "$work_dir/.local/loop/-bad.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
cat > "$work_dir/.local/loop/reviewer-empty.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/-bad.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted dash-prefixed reviewer file"
fi

# 10) aggregate rejects non-timestamp round ids.
if (
  cd "$work_dir" &&
  "$review_aggregate" bad-round-id .local/loop/reviewer-empty.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted invalid round-id"
fi

# 11) aggregate rejects unknown severity values.
cat > "$work_dir/.local/loop/review-20260305-230000-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[{"id":"Sx","severity":"WARN"}]}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/review-20260305-230000-security.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted unknown severity token"
fi

# 12) aggregate computes counts from findings payload.
cat > "$work_dir/.local/loop/review-20260305-230000-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[{"id":"S1","severity":"IMPORTANT"}]}
JSON
cat > "$work_dir/.local/loop/review-20260305-230000-docs-spec-consistency.json" <<'JSON'
{"scope":"full-pr","dimension":"docs/spec consistency","status":"complete","findings":[]}
JSON
(
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/review-20260305-230000-security.json .local/loop/review-20260305-230000-docs-spec-consistency.json >/dev/null
)
agg_file="$work_dir/.local/loop/review-20260305-230000.json"
assert_exists "$agg_file"
important_count="$(jq -r '.counts.important' "$agg_file")"
[[ "$important_count" == "1" ]] || fail "expected important count=1, got $important_count"

# 12.1) review_finalize fails when important findings remain and still prints aggregate path.
set +e
finalize_fail_output="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230000 .local/loop/review-20260305-230000-security.json .local/loop/review-20260305-230000-docs-spec-consistency.json 2>&1
)"
finalize_fail_status=$?
set -e
if [[ "$finalize_fail_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed with IMPORTANT findings"
fi
[[ "$finalize_fail_status" -eq 2 ]] || fail "review_finalize expected exit status 2, got $finalize_fail_status"
[[ "$finalize_fail_output" == *".local/loop/review-20260305-230000.json"* ]] || fail "review_finalize did not print aggregate path on failure"

# 12.2) review_finalize accepts an explicit manual-fallback artifact when the reason is recorded.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230100 full-pr >/dev/null
)
(
  cd "$work_dir" &&
  "$review_prepare" 20260305-230100 full-pr security "docs/spec consistency" >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230100-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
cat > "$work_dir/.local/loop/review-20260305-230100-docs-spec-consistency.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "docs/spec consistency",
  "status": "complete",
  "summary": "Manual fallback reviewer found no material issues.",
  "findings": [],
  "producer": {
    "type": "manual-fallback",
    "reason": "reviewer subagent did not return before review finalize"
  }
}
JSON
(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230100 .local/loop/review-20260305-230100-security.json .local/loop/review-20260305-230100-docs-spec-consistency.json >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230100.json"
fallback_reason="$(jq -r '.contract.recovery[] | select(.dimension == "docs/spec consistency") | .reason' "$work_dir/.local/loop/review-20260305-230100.json")"
[[ "$fallback_reason" == "reviewer subagent did not return before review finalize" ]] || fail "manual fallback reason was not preserved in the aggregate review artifact"

# 13) review_finalize fails when an undeclared reviewer output is present on disk.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230101 full-pr >/dev/null &&
  "$review_prepare" 20260305-230101 full-pr security >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230101-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
cat > "$work_dir/.local/loop/review-20260305-230101-rogue.json" <<'JSON'
{"scope":"full-pr","dimension":"rogue","status":"complete","findings":[]}
JSON
set +e
unexpected_output_finalize="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230101 .local/loop/review-20260305-230101-security.json 2>&1
)"
unexpected_output_status=$?
set -e
if [[ "$unexpected_output_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed with an undeclared reviewer output"
fi
[[ "$unexpected_output_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for an undeclared reviewer output, got $unexpected_output_status"
unexpected_output_count="$(jq -r '.contract.unexpected_outputs | length' "$work_dir/.local/loop/review-20260305-230101.json")"
[[ "$unexpected_output_count" == "1" ]] || fail "expected one undeclared reviewer output, got $unexpected_output_count"

# 13.1) review_finalize fails when a reviewer artifact scope does not match the manifest scope.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230101 full-pr >/dev/null &&
  "$review_prepare" 20260305-230101 full-pr security >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230101-security.json" <<'JSON'
{"scope":"delta","dimension":"security","status":"complete","findings":[]}
JSON
set +e
scope_mismatch_finalize="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230101 .local/loop/review-20260305-230101-security.json 2>&1
)"
scope_mismatch_status=$?
set -e
if [[ "$scope_mismatch_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed with a scope-mismatched reviewer artifact"
fi
[[ "$scope_mismatch_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for a scope-mismatched reviewer artifact, got $scope_mismatch_status"
scope_mismatch_count="$(jq -r '.contract.scope_mismatches | length' "$work_dir/.local/loop/review-20260305-230101.json")"
[[ "$scope_mismatch_count" == "1" ]] || fail "expected one scope mismatch, got $scope_mismatch_count"

# 14) review_finalize fails when tracked worktree state changes after manifest preparation.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230102 full-pr >/dev/null &&
  "$review_prepare" 20260305-230102 full-pr security >/dev/null
)
printf 'tracked-drift\n' >> "$work_dir/README.md"
cat > "$work_dir/.local/loop/review-20260305-230102-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
set +e
worktree_drift_finalize="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230102 .local/loop/review-20260305-230102-security.json 2>&1
)"
worktree_drift_status=$?
set -e
if [[ "$worktree_drift_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed after tracked worktree drift"
fi
[[ "$worktree_drift_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for tracked worktree drift, got $worktree_drift_status"
worktree_drift_detected="$(jq -r '.contract.tracked_worktree_changed' "$work_dir/.local/loop/review-20260305-230102.json")"
[[ "$worktree_drift_detected" == "true" ]] || fail "tracked worktree drift was not recorded in the aggregate review artifact"
(
  cd "$work_dir" &&
  git checkout -- README.md >/dev/null 2>&1
)

# 15) review_finalize fails when HEAD moves after manifest preparation.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230103 full-pr >/dev/null &&
  "$review_prepare" 20260305-230103 full-pr security >/dev/null &&
  printf 'head moved\n' > post-prepare.txt &&
  git add post-prepare.txt &&
  git commit -m "post prepare head move" >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230103-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
set +e
head_move_finalize="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230103 .local/loop/review-20260305-230103-security.json 2>&1
)"
head_move_status=$?
set -e
if [[ "$head_move_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed after HEAD moved"
fi
[[ "$head_move_status" -eq 2 ]] || fail "review_finalize expected exit status 2 after HEAD moved, got $head_move_status"
head_move_detected="$(jq -r '.contract.head_moved' "$work_dir/.local/loop/review-20260305-230103.json")"
[[ "$head_move_detected" == "true" ]] || fail "HEAD movement was not recorded in the aggregate review artifact"
head_sha="$(cd "$work_dir" && git rev-parse HEAD)"

# 16) review_gate fails when counts do not match findings payload.
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

# 17) final_gate also fails closed on counts mismatch.
cat > "$work_dir/.local/loop/ci-good.json" <<'JSON'
{
  "schema_version": 1,
  "source": "local-regression",
  "generated_at": "2026-03-11T00:00:00Z",
  "head_sha": "__HEAD_SHA__",
  "base_ref": "main",
  "base_sha": "__BASE_SHA__",
  "required_checks": [{"name":"local-smoke","status":"pass"}],
  "docs_updated": true
}
JSON
perl -0pi -e "s/__HEAD_SHA__/$head_sha/g; s/__BASE_SHA__/$base_sha/g" "$work_dir/.local/loop/ci-good.json"
if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate" .local/loop/review-mismatch.json .local/loop/ci-good.json "$plan_path" main .local/loop/final-gate.json >/dev/null 2>&1
); then
  fail "final_gate accepted mismatched counts"
fi

# 18) gate scripts reject unknown severity values in findings.
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
  PATH="$fake_bin:$PATH" \
  "$final_gate" .local/loop/review-unknown-severity.json .local/loop/ci-good.json "$plan_path" main .local/loop/final-gate-unknown-severity.json >/dev/null 2>&1
); then
  fail "final_gate accepted unknown severity token"
fi

# 19) review_gate accepts numerically equivalent count formats.
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

# 20) final_gate accepts numerically equivalent count formats.
(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate" .local/loop/review-decimal-zero.json .local/loop/ci-good.json "$plan_path" main .local/loop/final-gate-decimal.json >/dev/null
)
assert_exists "$work_dir/.local/loop/final-gate-decimal.json"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/review.json"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/ci-status.json"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/final-gate.json"

# 21) final_gate rejects stale CI head/base metadata.
cat > "$work_dir/.local/loop/ci-stale.json" <<'JSON'
{
  "schema_version": 1,
  "source": "local-regression",
  "generated_at": "2026-03-11T00:00:00Z",
  "head_sha": "deadbeef",
  "base_ref": "main",
  "base_sha": "feedface",
  "required_checks": [{"name":"local-smoke","status":"pass"}],
  "docs_updated": true
}
JSON
if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate" .local/loop/review-decimal-zero.json .local/loop/ci-stale.json "$plan_path" main .local/loop/final-gate-stale.json >/dev/null 2>&1
); then
  fail "final_gate accepted stale CI head/base metadata"
fi

# 22) cleanup rejects invalid keep-round arguments.
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

# 23) explicit keep-round-id preserves orphan aggregate rounds.
cat > "$work_dir/.local/loop/review-20260305-230099.json" <<'JSON'
{"round_id":"20260305-230099"}
JSON
(
  cd "$work_dir" &&
  "$review_cleanup" --keep-round-id 20260305-230099 --keep-rounds 0 >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230099.json"

# 24) cleanup dry-run does not delete; real cleanup keeps only latest round and removes launch manifests.
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
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/review.json"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/ci-status.json"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/final-gate.json"

echo "PASS: review loop regression checks"
