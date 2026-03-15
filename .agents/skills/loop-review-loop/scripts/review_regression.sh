#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
review_init="$script_dir/review_init.sh"
review_prepare="$script_dir/review_prepare_reviewers.sh"
review_aggregate="$script_dir/review_aggregate.sh"
review_gate="$script_dir/review_gate.sh"
review_finalize="$script_dir/review_finalize.sh"
review_cleanup="$script_dir/review_cleanup.sh"
review_record_dispatch="$script_dir/review_record_dispatch.sh"
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

record_dispatch() {
  (
    cd "$work_dir" &&
    "$review_record_dispatch" "$@"
  ) >/dev/null
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
dispatch_path="$(jq -r '.dispatch_record_path' "$prepare_manifest")"
[[ "$dispatch_path" == ".local/loop/review-dispatch-20260305-230000.json" ]] || fail "unexpected dispatch record path: $dispatch_path"
dispatch_file="$work_dir/$dispatch_path"
assert_exists "$dispatch_file"
dispatch_count="$(jq -r '.reviewers | length' "$dispatch_file")"
[[ "$dispatch_count" == "2" ]] || fail "expected dispatch reviewer count=2, got $dispatch_count"
[[ "$(jq -r '.reviewers[] | select(.dimension_slug == "security") | .last_status' "$dispatch_file")" == "pending" ]] || fail "expected security dispatch slot to start pending"
[[ "$(jq -r '.reviewers[] | select(.dimension_slug == "security") | .attempts | length' "$dispatch_file")" == "0" ]] || fail "expected security dispatch slot to start with zero attempts"
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
[[ "$security_prompt" == *"current_slice_findings"* ]] || fail "review_prepare prompt did not describe current_slice_findings"
[[ "$security_prompt" == *"accepted_deferred_risks"* ]] || fail "review_prepare prompt did not describe accepted_deferred_risks"
[[ "$security_prompt" == *"strategic_observations"* ]] || fail "review_prepare prompt did not describe strategic_observations"

# 7.1) review_record_dispatch rejects terminal reviewer states before launch-started.
if (
  cd "$work_dir" &&
  "$review_record_dispatch" 20260305-230000 security artifact-written --artifact-path .local/loop/review-20260305-230000-security.json >/dev/null 2>&1
); then
  fail "review_record_dispatch accepted artifact-written before launch-started"
fi
if (
  cd "$work_dir" &&
  "$review_record_dispatch" 20260305-230000 security launch-failed --reason "reviewer launcher exited immediately" >/dev/null 2>&1
); then
  fail "review_record_dispatch accepted launch-failed before launch-started"
fi

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
missing_dispatch_attempt_count="$(jq -r '.contract.missing_dispatch_attempts | length' "$work_dir/.local/loop/review-20260305-230000.json")"
[[ "$missing_dispatch_attempt_count" == "2" ]] || fail "expected two missing dispatch attempts, got $missing_dispatch_attempt_count"

# 9) aggregate rejects dash-prefixed reviewer filenames.
cat > "$work_dir/.local/loop/-bad.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
JSON
cat > "$work_dir/.local/loop/reviewer-empty.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
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
{"scope":"full-pr","dimension":"security","status":"complete","current_slice_findings":[{"id":"Sx","severity":"WARN"}],"accepted_deferred_risks":[],"strategic_observations":[]}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/review-20260305-230000-security.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted unknown severity token"
fi

# 11.1) aggregate rejects legacy findings-only reviewer artifacts.
cat > "$work_dir/.local/loop/review-20260305-230000-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","findings":[]}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/review-20260305-230000-security.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted a legacy findings-only reviewer artifact"
fi

# 11.2) aggregate rejects accepted deferred risks without issue linkage or a defer reason.
cat > "$work_dir/.local/loop/review-20260305-230000-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "Deferred risk is malformed.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [
    {
      "id": "D1",
      "severity": "IMPORTANT",
      "title": "Known deferred risk",
      "area": "README.md"
    }
  ],
  "strategic_observations": []
}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/review-20260305-230000-security.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted an accepted_deferred_risks entry without tracking or defer reason"
fi

# 11.3) aggregate rejects malformed layered fields even when a legacy findings array is also present.
cat > "$work_dir/.local/loop/review-20260305-230000-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "Malformed layered fields should not fall back to legacy findings.",
  "findings": [],
  "current_slice_findings": "not-an-array",
  "accepted_deferred_risks": [],
  "strategic_observations": []
}
JSON
if (
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/review-20260305-230000-security.json >/dev/null 2>&1
); then
  fail "review_aggregate accepted malformed layered fields when a legacy findings array was also present"
fi

# 12) aggregate computes counts from layered review payloads while keeping non-blocking layers visible.
cat > "$work_dir/.local/loop/review-20260305-230000-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "One current-slice finding, one accepted deferred risk, and one strategic observation.",
  "current_slice_findings": [
    {"id":"S1","severity":"IMPORTANT","title":"Current slice gap"}
  ],
  "accepted_deferred_risks": [
    {"id":"D1","severity":"IMPORTANT","title":"Known deferred risk","area":"README.md","tracking_issue":"#20"}
  ],
  "strategic_observations": [
    {"id":"SO1","title":"Long-term cleanup","recommendation":"Document reviewer examples"}
  ]
}
JSON
cat > "$work_dir/.local/loop/review-20260305-230000-docs-spec-consistency.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "docs/spec consistency",
  "status": "complete",
  "summary": "No current-slice docs blockers.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": []
}
JSON
record_dispatch 20260305-230000 security launch-started
record_dispatch 20260305-230000 security artifact-written --artifact-path .local/loop/review-20260305-230000-security.json
record_dispatch 20260305-230000 docs-spec-consistency launch-started
record_dispatch 20260305-230000 docs-spec-consistency artifact-written --artifact-path .local/loop/review-20260305-230000-docs-spec-consistency.json
(
  cd "$work_dir" &&
  "$review_aggregate" 20260305-230000 .local/loop/review-20260305-230000-security.json .local/loop/review-20260305-230000-docs-spec-consistency.json >/dev/null
)
agg_file="$work_dir/.local/loop/review-20260305-230000.json"
assert_exists "$agg_file"
important_count="$(jq -r '.counts.important' "$agg_file")"
[[ "$important_count" == "1" ]] || fail "expected important count=1, got $important_count"
deferred_count="$(jq -r '.counts.accepted_deferred_risks' "$agg_file")"
[[ "$deferred_count" == "1" ]] || fail "expected accepted_deferred_risks count=1, got $deferred_count"
strategic_count="$(jq -r '.counts.strategic_observations' "$agg_file")"
[[ "$strategic_count" == "1" ]] || fail "expected strategic_observations count=1, got $strategic_count"
[[ "$(jq -r '.accepted_deferred_risks[0].tracking_issue' "$agg_file")" == "#20" ]] || fail "aggregate did not preserve accepted deferred risk tracking_issue"
[[ "$(jq -r '.reviewers[] | select(.dimension == "security") | .dispatch_status' "$agg_file")" == "artifact-written" ]] || fail "aggregate did not preserve security dispatch artifact-written status"

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

# 12.2) review_finalize rejects manual fallback unless the reviewer slot recorded an eligible failure.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230100 full-pr >/dev/null
)
(
  cd "$work_dir" &&
  "$review_prepare" 20260305-230100 full-pr security "docs/spec consistency" >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230100-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "No current-slice issues.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": []
}
JSON
record_dispatch 20260305-230100 security launch-started
record_dispatch 20260305-230100 security artifact-written --artifact-path .local/loop/review-20260305-230100-security.json
record_dispatch 20260305-230100 docs-spec-consistency launch-started
cat > "$work_dir/.local/loop/review-20260305-230100-docs-spec-consistency.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "docs/spec consistency",
  "status": "complete",
  "summary": "Manual fallback reviewer found no material issues.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": [],
  "producer": {
    "type": "manual-fallback",
    "reason": "reviewer subagent did not return before review finalize"
  }
}
JSON
set +e
invalid_fallback_output="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230100 .local/loop/review-20260305-230100-security.json .local/loop/review-20260305-230100-docs-spec-consistency.json 2>&1
)"
invalid_fallback_status=$?
set -e
if [[ "$invalid_fallback_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed with manual fallback before a recorded reviewer failure"
fi
[[ "$invalid_fallback_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for invalid manual fallback, got $invalid_fallback_status"
[[ "$invalid_fallback_output" == *".local/loop/review-20260305-230100.json"* ]] || fail "review_finalize did not print aggregate path for invalid manual fallback"
invalid_fallback_dispatch_status="$(jq -r '.contract.invalid_fallback_reviewers[] | select(.dimension == "docs/spec consistency") | .dispatch_status' "$work_dir/.local/loop/review-20260305-230100.json")"
[[ "$invalid_fallback_dispatch_status" == "launch-started" ]] || fail "expected invalid manual fallback to preserve launch-started dispatch status, got $invalid_fallback_dispatch_status"

# 12.3) review_finalize accepts an explicit manual-fallback artifact after a recorded reviewer timeout.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230105 full-pr >/dev/null
)
(
  cd "$work_dir" &&
  "$review_prepare" 20260305-230105 full-pr security "docs/spec consistency" >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230105-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "No current-slice issues.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": []
}
JSON
record_dispatch 20260305-230105 security launch-started
record_dispatch 20260305-230105 security artifact-written --artifact-path .local/loop/review-20260305-230105-security.json
record_dispatch 20260305-230105 docs-spec-consistency launch-started
record_dispatch 20260305-230105 docs-spec-consistency timeout --reason "reviewer subagent timed out before artifact write"
cat > "$work_dir/.local/loop/review-20260305-230105-docs-spec-consistency.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "docs/spec consistency",
  "status": "complete",
  "summary": "Manual fallback reviewer found no material issues.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": [],
  "producer": {
    "type": "manual-fallback",
    "reason": "reviewer subagent timed out before review finalize"
  }
}
JSON
(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230105 .local/loop/review-20260305-230105-security.json .local/loop/review-20260305-230105-docs-spec-consistency.json >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230105.json"
fallback_reason="$(jq -r '.contract.recovery[] | select(.dimension == "docs/spec consistency") | .reason' "$work_dir/.local/loop/review-20260305-230105.json")"
[[ "$fallback_reason" == "reviewer subagent timed out before review finalize" ]] || fail "manual fallback reason was not preserved in the aggregate review artifact"
valid_fallback_count="$(jq -r '.contract.invalid_fallback_reviewers | length' "$work_dir/.local/loop/review-20260305-230105.json")"
[[ "$valid_fallback_count" == "0" ]] || fail "recorded timeout should make manual fallback valid"
valid_fallback_launch_start_count="$(jq -r '.contract.missing_launch_started_reviewers | length' "$work_dir/.local/loop/review-20260305-230105.json")"
[[ "$valid_fallback_launch_start_count" == "0" ]] || fail "recorded timeout with launch-started should not trip missing-launch-start"

# 12.4) runtime-blocked reviewer slots fail closed instead of silently allowing manual fallback.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230106 full-pr >/dev/null &&
  "$review_prepare" 20260305-230106 full-pr security >/dev/null
)
record_dispatch 20260305-230106 security runtime-blocked --reason "runtime policy forbids reviewer subagent launch"
if (
  cd "$work_dir" &&
  "$review_record_dispatch" 20260305-230106 security launch-started >/dev/null 2>&1
); then
  fail "review_record_dispatch accepted a later dispatch event after runtime-blocked"
fi
cat > "$work_dir/.local/loop/review-20260305-230106-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "Manual fallback attempted despite runtime block.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": [],
  "producer": {
    "type": "manual-fallback",
    "reason": "runtime policy forbids reviewer subagent launch"
  }
}
JSON
set +e
runtime_blocked_output="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230106 .local/loop/review-20260305-230106-security.json 2>&1
)"
runtime_blocked_status=$?
set -e
if [[ "$runtime_blocked_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed after a runtime-blocked reviewer slot"
fi
[[ "$runtime_blocked_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for runtime-blocked reviewer slot, got $runtime_blocked_status"
[[ "$runtime_blocked_output" == *".local/loop/review-20260305-230106.json"* ]] || fail "review_finalize did not print aggregate path for runtime-blocked reviewer slot"
runtime_blocked_count="$(jq -r '.contract.runtime_blocked_reviewers | length' "$work_dir/.local/loop/review-20260305-230106.json")"
[[ "$runtime_blocked_count" == "1" ]] || fail "expected runtime-blocked reviewer slot to be preserved in contract violations"

# 12.5) aggregate fails closed when a crafted dispatch record appends events after runtime-blocked.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230108 full-pr >/dev/null &&
  "$review_prepare" 20260305-230108 full-pr security >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230108-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "Crafted dispatch history should fail closed when runtime-blocked is not terminal.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": []
}
JSON
tmp_runtime_blocked_dispatch="$work_dir/.local/loop/review-dispatch-20260305-230108.json.tmp"
jq '
  .reviewers |= map(
    if .dimension_slug == "security" then
      .attempts = [
        {
          status: "runtime-blocked",
          reason: "runtime policy forbids reviewer subagent launch",
          recorded_at: "2026-03-05T23:01:08Z"
        },
        {
          status: "launch-started",
          recorded_at: "2026-03-05T23:02:08Z"
        }
      ]
      | .last_status = "launch-started"
      | .last_reason = ""
      | .last_recorded_at = "2026-03-05T23:02:08Z"
      | .last_artifact_path = ""
    else
      .
    end
  )
' "$work_dir/.local/loop/review-dispatch-20260305-230108.json" > "$tmp_runtime_blocked_dispatch"
mv "$tmp_runtime_blocked_dispatch" "$work_dir/.local/loop/review-dispatch-20260305-230108.json"
set +e
runtime_blocked_not_terminal_output="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230108 .local/loop/review-20260305-230108-security.json 2>&1
)"
runtime_blocked_not_terminal_status=$?
set -e
if [[ "$runtime_blocked_not_terminal_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed when runtime-blocked was not terminal"
fi
[[ "$runtime_blocked_not_terminal_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for non-terminal runtime-blocked dispatch history, got $runtime_blocked_not_terminal_status"
[[ "$runtime_blocked_not_terminal_output" == *".local/loop/review-20260305-230108.json"* ]] || fail "review_finalize did not print aggregate path for non-terminal runtime-blocked dispatch history"
runtime_blocked_not_terminal_count="$(jq -r '.contract.runtime_blocked_not_terminal_reviewers | length' "$work_dir/.local/loop/review-20260305-230108.json")"
[[ "$runtime_blocked_not_terminal_count" == "1" ]] || fail "expected non-terminal runtime-blocked dispatch history to be preserved in contract violations"

# 12.6) review_finalize fails when a fallback-eligible dispatch status is recorded without a prior launch-started event.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230107 full-pr >/dev/null &&
  "$review_prepare" 20260305-230107 full-pr security >/dev/null
)
tmp_dispatch="$work_dir/.local/loop/review-dispatch-20260305-230107.json.tmp"
jq '
  .reviewers |= map(
    if .dimension_slug == "security" then
      .attempts = [
        {
          status: "launch-failed",
          reason: "reviewer launch failed before artifact write",
          recorded_at: "2026-03-05T23:01:07Z"
        }
      ]
      | .last_status = "launch-failed"
      | .last_reason = "reviewer launch failed before artifact write"
      | .last_recorded_at = "2026-03-05T23:01:07Z"
      | .last_artifact_path = ""
    else
      .
    end
  )
' "$work_dir/.local/loop/review-dispatch-20260305-230107.json" > "$tmp_dispatch"
mv "$tmp_dispatch" "$work_dir/.local/loop/review-dispatch-20260305-230107.json"
cat > "$work_dir/.local/loop/review-20260305-230107-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "Manual fallback was attempted after a malformed launch-failed record.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": [],
  "producer": {
    "type": "manual-fallback",
    "reason": "reviewer launch failed before artifact write"
  }
}
JSON
set +e
missing_launch_start_output="$(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230107 .local/loop/review-20260305-230107-security.json 2>&1
)"
missing_launch_start_status=$?
set -e
if [[ "$missing_launch_start_status" -eq 0 ]]; then
  fail "review_finalize unexpectedly passed when reviewer dispatch skipped launch-started"
fi
[[ "$missing_launch_start_status" -eq 2 ]] || fail "review_finalize expected exit status 2 for missing launch-started, got $missing_launch_start_status"
[[ "$missing_launch_start_output" == *".local/loop/review-20260305-230107.json"* ]] || fail "review_finalize did not print aggregate path for missing launch-started"
missing_launch_start_count="$(jq -r '.contract.missing_launch_started_reviewers | length' "$work_dir/.local/loop/review-20260305-230107.json")"
[[ "$missing_launch_start_count" == "1" ]] || fail "expected missing-launch-start violation to be preserved"

# 12.7) review_finalize passes when only accepted deferred risks and strategic observations remain.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230104 full-pr >/dev/null &&
  "$review_prepare" 20260305-230104 full-pr security >/dev/null
)
cat > "$work_dir/.local/loop/review-20260305-230104-security.json" <<'JSON'
{
  "scope": "full-pr",
  "dimension": "security",
  "status": "complete",
  "summary": "Only non-blocking review layers remain.",
  "current_slice_findings": [],
  "accepted_deferred_risks": [
    {
      "id": "D2",
      "severity": "IMPORTANT",
      "title": "Known deferred follow-up",
      "area": "README.md",
      "accepted_reason": "Accepted outside the current slice"
    }
  ],
  "strategic_observations": [
    {
      "id": "SO2",
      "title": "Future improvement",
      "recommendation": "Refine reviewer examples after rollout"
    }
  ]
}
JSON
record_dispatch 20260305-230104 security launch-started
record_dispatch 20260305-230104 security artifact-written --artifact-path .local/loop/review-20260305-230104-security.json
(
  cd "$work_dir" &&
  "$review_finalize" 20260305-230104 .local/loop/review-20260305-230104-security.json >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230104.json"
[[ "$(jq -r '.counts.blocker' "$work_dir/.local/loop/review-20260305-230104.json")" == "0" ]] || fail "non-blocking layers should not create blocker counts"
[[ "$(jq -r '.counts.important' "$work_dir/.local/loop/review-20260305-230104.json")" == "0" ]] || fail "non-blocking layers should not create important counts"
[[ "$(jq -r '.counts.accepted_deferred_risks' "$work_dir/.local/loop/review-20260305-230104.json")" == "1" ]] || fail "accepted_deferred_risks count was not preserved"
[[ "$(jq -r '.counts.strategic_observations' "$work_dir/.local/loop/review-20260305-230104.json")" == "1" ]] || fail "strategic_observations count was not preserved"

# 13) review_finalize fails when an undeclared reviewer output is present on disk.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230101 full-pr >/dev/null &&
  "$review_prepare" 20260305-230101 full-pr security >/dev/null
)
record_dispatch 20260305-230101 security launch-started
record_dispatch 20260305-230101 security artifact-written --artifact-path .local/loop/review-20260305-230101-security.json
cat > "$work_dir/.local/loop/review-20260305-230101-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
JSON
cat > "$work_dir/.local/loop/review-20260305-230101-rogue.json" <<'JSON'
{"scope":"full-pr","dimension":"rogue","status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
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

# 14) review_finalize fails when tracked worktree state changes after manifest preparation.
(
  cd "$work_dir" &&
  "$review_init" 20260305-230102 full-pr >/dev/null &&
  "$review_prepare" 20260305-230102 full-pr security >/dev/null
)
printf 'tracked-drift\n' >> "$work_dir/README.md"
cat > "$work_dir/.local/loop/review-20260305-230102-security.json" <<'JSON'
{"scope":"full-pr","dimension":"security","status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
JSON
record_dispatch 20260305-230102 security launch-started
record_dispatch 20260305-230102 security artifact-written --artifact-path .local/loop/review-20260305-230102-security.json
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
{"scope":"full-pr","dimension":"security","status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
JSON
record_dispatch 20260305-230103 security launch-started
record_dispatch 20260305-230103 security artifact-written --artifact-path .local/loop/review-20260305-230103-security.json
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

# 16) review_gate fails when counts do not match current-slice findings payload.
cat > "$work_dir/.local/loop/review-mismatch.json" <<'JSON'
{
  "status": "complete",
  "current_slice_findings": [{"id":"X","severity":"IMPORTANT"}],
  "accepted_deferred_risks": [],
  "strategic_observations": [],
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

# 18) gate scripts reject unknown severity values in current-slice findings.
cat > "$work_dir/.local/loop/review-unknown-severity.json" <<'JSON'
{
  "status": "complete",
  "current_slice_findings": [{"id":"Z","severity":"WARN"}],
  "accepted_deferred_risks": [],
  "strategic_observations": [],
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
  "current_slice_findings": [],
  "accepted_deferred_risks": [],
  "strategic_observations": [],
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
prepare_cleanup_dispatch="$work_dir/$(jq -r '.dispatch_record_path' "$prepare_cleanup_manifest")"
assert_exists "$prepare_cleanup_dispatch"
cat > "$work_dir/.local/loop/review-20260305-230001.json" <<'JSON'
{"round_id":"20260305-230001"}
JSON
cat > "$work_dir/.local/loop/review-20260305-230001-correctness.json" <<'JSON'
{"status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
JSON
cat > "$work_dir/.local/loop/review-20260305-230002.json" <<'JSON'
{"round_id":"20260305-230002"}
JSON
cat > "$work_dir/.local/loop/review-20260305-230002-security.json" <<'JSON'
{"status":"complete","current_slice_findings":[],"accepted_deferred_risks":[],"strategic_observations":[]}
JSON
(
  cd "$work_dir" &&
  "$review_cleanup" --dry-run --keep-rounds 1 >/dev/null
)
assert_exists "$work_dir/.local/loop/review-20260305-230001.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002.json"
assert_exists "$prepare_cleanup_manifest"
assert_exists "$prepare_cleanup_dispatch"
(
  cd "$work_dir" &&
  "$review_cleanup" --keep-rounds 1 >/dev/null
)
assert_not_exists "$work_dir/.local/loop/review-20260305-230001.json"
assert_not_exists "$work_dir/.local/loop/review-20260305-230001-correctness.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002.json"
assert_exists "$work_dir/.local/loop/review-20260305-230002-security.json"
assert_not_exists "$prepare_cleanup_manifest"
assert_not_exists "$prepare_cleanup_dispatch"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/review.json"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/ci-status.json"
assert_exists "$work_dir/.local/final-evidence/2026-03-11-review-regression-plan/final-gate.json"

echo "PASS: review loop regression checks"
