#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
publish_script="$script_dir/../../loop-publish/scripts/publish_pr.sh"
export_ci_script="$script_dir/export_ci_status.sh"
final_gate_script="$script_dir/final_gate.sh"
land_preflight_script="$script_dir/../../loop-land/scripts/land_preflight.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || fail "missing expected path: $path"
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

origin_dir="$tmp_root/origin.git"
work_dir="$tmp_root/work"
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
cmd2="${2:-}"
if [[ -z "$cmd1" ]]; then
  echo "missing gh command" >&2
  exit 1
fi
if [[ -z "$cmd2" ]]; then
  echo "missing gh subcommand" >&2
  exit 1
fi
shift 2

case "$cmd1 $cmd2" in
  "auth status")
    exit 0
    ;;
  "pr list")
    payload='[]'
    if [[ -n "${FAKE_GH_PR_NUMBER:-}" ]]; then
      payload="[{\"number\": ${FAKE_GH_PR_NUMBER}}]"
    fi
    emit "$payload" "$@"
    ;;
  "pr create")
    printf '%s\n' "${FAKE_GH_PR_URL:-https://example.test/pr/101}"
    ;;
  "pr edit")
    exit 0
    ;;
  "pr view")
    if [[ $# -gt 0 && "${1#-}" == "$1" ]]; then
      shift
    fi
    payload="$(cat <<JSON
{"number": ${FAKE_GH_PR_NUMBER:-101}, "url": "${FAKE_GH_PR_URL:-https://example.test/pr/101}", "state": "${FAKE_GH_PR_STATE:-OPEN}", "headRefOid": "${FAKE_GH_PR_HEAD_SHA:-missing}", "baseRefName": "${FAKE_GH_PR_BASE_REF:-main}"}
JSON
)"
    emit "$payload" "$@"
    ;;
  "pr checks")
    emit "${FAKE_GH_CHECKS_JSON:-[]}" "$@"
    exit "${FAKE_GH_CHECKS_EXIT_CODE:-0}"
    ;;
  *)
    echo "unsupported gh invocation: $cmd1 $cmd2" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$fake_bin/gh"

git init --bare "$origin_dir" >/dev/null 2>&1
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
  git checkout -b codex/stateful-gate-regression >/dev/null &&
  mkdir -p docs/harness/active docs/harness/completed &&
  cat > docs/harness/active/2026-03-11-active-plan.md <<'PLAN'
# Active Plan Fixture

## Acceptance Criteria

- [x] This plan is intentionally still active.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Stay active to prove publish rejects non-archived plans.
- Expected files:
  - `docs/harness/active/2026-03-11-active-plan.md`
- Validation commands:
  - `true`
- Documentation impact:
  - None.
PLAN
  cat > docs/harness/completed/2026-03-11-incomplete-plan.md <<'PLAN'
# Incomplete Archived Plan Fixture

## Acceptance Criteria

- [ ] This archived plan is intentionally incomplete.

## Work Breakdown

### Step 1

- Status: pending
- Objective: Prove publish rejects incomplete archived plans.
- Expected files:
  - `docs/harness/completed/2026-03-11-incomplete-plan.md`
- Validation commands:
  - `true`
- Documentation impact:
  - None.
PLAN
  cat > docs/harness/completed/2026-03-11-complete-plan.md <<'PLAN'
# Complete Archived Plan Fixture

## Acceptance Criteria

- [x] This archived plan is complete and gateable.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Provide a gateable archived plan fixture.
- Expected files:
  - `docs/harness/completed/2026-03-11-complete-plan.md`
- Validation commands:
  - `true`
- Documentation impact:
  - None.

## Validation Summary

- Fixture prepared for stateful gate regression.

## Completion Summary

- Delivered: Complete archived-plan fixture.
- Not delivered: None.
- Linked issue updates: None.
- Spawned follow-up issues: None.
PLAN
  cat > docs/harness/active/2026-03-11-twin-plan.md <<'PLAN'
# Stale Twin Active Plan Fixture

## Acceptance Criteria

- [x] This file should have been moved, not left behind.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Prove stale active twins are rejected.
- Expected files:
  - `docs/harness/active/2026-03-11-twin-plan.md`
- Validation commands:
  - `true`
- Documentation impact:
  - None.
PLAN
  cat > docs/harness/completed/2026-03-11-twin-plan.md <<'PLAN'
# Stale Twin Archived Plan Fixture

## Acceptance Criteria

- [x] This archived plan has a stale twin in active/.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Prove stale active twins are rejected.
- Expected files:
  - `docs/harness/completed/2026-03-11-twin-plan.md`
- Validation commands:
  - `true`
- Documentation impact:
  - None.
PLAN
  git add docs/harness/active/2026-03-11-active-plan.md docs/harness/active/2026-03-11-twin-plan.md docs/harness/completed/2026-03-11-incomplete-plan.md docs/harness/completed/2026-03-11-complete-plan.md docs/harness/completed/2026-03-11-twin-plan.md &&
  git commit -m "add gate regression fixtures" >/dev/null
)

active_plan="docs/harness/active/2026-03-11-active-plan.md"
incomplete_plan="docs/harness/completed/2026-03-11-incomplete-plan.md"
complete_plan="docs/harness/completed/2026-03-11-complete-plan.md"
twin_plan="docs/harness/completed/2026-03-11-twin-plan.md"
body_file="$tmp_root/pr-body.md"
printf 'direct request (no issue)\n' > "$body_file"

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  "$publish_script" main "Regression PR" "$body_file" --plan "$active_plan" --direct-request >/dev/null 2>&1
); then
  fail "publish_pr accepted a plan that still lives under active/"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  "$publish_script" main "Regression PR" "$body_file" --plan "$incomplete_plan" --direct-request >/dev/null 2>&1
); then
  fail "publish_pr accepted an incomplete archived plan"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  "$publish_script" main "Regression PR" "$body_file" --plan "$twin_plan" --direct-request >/dev/null 2>&1
); then
  fail "publish_pr accepted an archived plan with a stale twin under active/"
fi

publish_output="$(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  "$publish_script" main "Regression PR" "$body_file" --plan "$complete_plan" --direct-request
)"
[[ "$publish_output" == "created https://example.test/pr/101" ]] || fail "unexpected publish output: $publish_output"

head_sha="$(cd "$work_dir" && git rev-parse HEAD)"
base_sha="$(cd "$work_dir" && git rev-parse origin/main)"

ci_path="$(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  FAKE_GH_CHECKS_JSON='[{"name":"required-ci","bucket":"pass"}]' \
  FAKE_GH_CHECKS_EXIT_CODE="0" \
  "$export_ci_script" main --docs-updated true
)"
assert_exists "$work_dir/$ci_path"

ci_head_sha="$(jq -r '.head_sha' "$work_dir/$ci_path")"
[[ "$ci_head_sha" == "$head_sha" ]] || fail "export_ci_status wrote the wrong head SHA"

(
  cd "$work_dir" &&
  printf 'dirty\n' >> README.md
)
if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  FAKE_GH_CHECKS_JSON='[{"name":"required-ci","bucket":"pass"}]' \
  FAKE_GH_CHECKS_EXIT_CODE="0" \
  "$export_ci_script" main --docs-updated true >/dev/null 2>&1
); then
  fail "export_ci_status accepted a dirty working tree"
fi
(
  cd "$work_dir" &&
  git checkout -- README.md
)

pending_ci_path="$tmp_root/ci-pending.json"
pending_ci_output="$(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  FAKE_GH_CHECKS_JSON='[{"name":"required-ci","bucket":"pending"}]' \
  FAKE_GH_CHECKS_EXIT_CODE="8" \
  "$export_ci_script" main --docs-updated true --output "$pending_ci_path"
)"
[[ "$pending_ci_output" == "$pending_ci_path" ]] || fail "unexpected pending export output: $pending_ci_output"
assert_exists "$pending_ci_path"
[[ "$(jq -r '.required_checks[0].status' "$pending_ci_path")" == "pending" ]] || fail "export_ci_status did not preserve pending check status"

cat > "$work_dir/.local/loop/review-clean.json" <<'JSON'
{
  "status": "complete",
  "findings": [],
  "counts": {"blocker": 0, "important": 0, "minor": 0, "nit": 0}
}
JSON

(
  cd "$work_dir" &&
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate.json >/dev/null
)
assert_exists "$work_dir/.local/loop/final-gate.json"
[[ "$(jq -r '.result' "$work_dir/.local/loop/final-gate.json")" == "pass" ]] || fail "final_gate did not pass with fresh inputs"

(
  cd "$work_dir" &&
  printf 'dirty\n' >> README.md
)
if (
  cd "$work_dir" &&
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate-dirty.json >/dev/null 2>&1
); then
  fail "final_gate accepted a dirty working tree"
fi
(
  cd "$work_dir" &&
  git checkout -- README.md
)

jq '.head_sha = "deadbeef"' "$work_dir/$ci_path" > "$work_dir/.local/loop/ci-stale.json"
if (
  cd "$work_dir" &&
  "$final_gate_script" .local/loop/review-clean.json .local/loop/ci-stale.json "$complete_plan" main .local/loop/final-gate-stale.json >/dev/null 2>&1
); then
  fail "final_gate accepted stale CI head metadata"
fi

if (
  cd "$work_dir" &&
  "$final_gate_script" .local/loop/review-clean.json "$pending_ci_path" "$complete_plan" main .local/loop/final-gate-pending.json >/dev/null 2>&1
); then
  fail "final_gate accepted pending required checks"
fi

(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  "$land_preflight_script" .local/loop/final-gate.json "$complete_plan" main >/dev/null
)

(
  cd "$work_dir" &&
  printf 'dirty\n' >> README.md
)
if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  "$land_preflight_script" .local/loop/final-gate.json "$complete_plan" main >/dev/null 2>&1
); then
  fail "land_preflight accepted a dirty working tree"
fi
(
  cd "$work_dir" &&
  git checkout -- README.md
)

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="deadbeef" \
  FAKE_GH_PR_BASE_REF="main" \
  "$land_preflight_script" .local/loop/final-gate.json "$complete_plan" main >/dev/null 2>&1
); then
  fail "land_preflight accepted a stale PR head SHA"
fi

echo "PASS: stateful gate regression checks"
