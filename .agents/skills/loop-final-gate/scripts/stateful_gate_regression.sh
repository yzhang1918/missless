#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
publish_script="$script_dir/../../loop-publish/scripts/publish_pr.sh"
preflight_script="$script_dir/repository_readiness_preflight.sh"
export_ci_script="$script_dir/export_ci_status.sh"
final_gate_script="$script_dir/final_gate.sh"
land_preflight_script="$script_dir/../../loop-land/scripts/land_preflight.sh"
land_merge_script="$script_dir/../../loop-land/scripts/land_merge.sh"

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
updater_dir="$tmp_root/updater"
publish_base_dir="$tmp_root/publish-base"
fake_bin="$tmp_root/bin"
mkdir -p "$fake_bin"
export REAL_GIT_PATH="$(command -v git)"

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

require_base_ref_if_requested() {
  local base_ref=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)
        if [[ $# -lt 2 ]]; then
          echo "missing value for --base" >&2
          exit 1
        fi
        base_ref="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  if [[ "${FAKE_GH_REQUIRE_BASE_REF:-false}" == "true" ]]; then
    if [[ -z "$base_ref" ]]; then
      echo "fake gh expected --base" >&2
      exit 1
    fi
    if ! git rev-parse --verify --quiet "origin/$base_ref" >/dev/null; then
      echo "fake gh missing local remote base ref: origin/$base_ref" >&2
      exit 1
    fi
  fi
}

build_repo_view_payload() {
  jq -n \
    --arg name_with_owner "${FAKE_GH_REPO_NAME_WITH_OWNER:-example/missless}" \
    --argjson merge_commit_allowed "${FAKE_GH_REPO_MERGE_COMMIT_ALLOWED:-false}" \
    --argjson rebase_merge_allowed "${FAKE_GH_REPO_REBASE_MERGE_ALLOWED:-true}" \
    --argjson squash_merge_allowed "${FAKE_GH_REPO_SQUASH_MERGE_ALLOWED:-true}" \
    --argjson delete_branch_on_merge "${FAKE_GH_REPO_DELETE_BRANCH_ON_MERGE:-true}" \
    '{
      nameWithOwner: $name_with_owner,
      mergeCommitAllowed: $merge_commit_allowed,
      rebaseMergeAllowed: $rebase_merge_allowed,
      squashMergeAllowed: $squash_merge_allowed,
      deleteBranchOnMerge: $delete_branch_on_merge
    }'
}

build_pr_payload() {
  jq -n \
    --argjson number "${FAKE_GH_PR_NUMBER:-101}" \
    --arg url "${FAKE_GH_PR_URL:-https://example.test/pr/101}" \
    --arg state "${FAKE_GH_PR_STATE:-OPEN}" \
    --arg head_sha "${FAKE_GH_PR_HEAD_SHA:-missing}" \
    --arg head_ref_name "${FAKE_GH_PR_HEAD_REF_NAME:-codex/stateful-gate-regression}" \
    --arg base_ref "${FAKE_GH_PR_BASE_REF:-main}" \
    --arg merged_at "${FAKE_GH_PR_MERGED_AT:-}" \
    --arg merge_commit_sha "${FAKE_GH_PR_MERGE_COMMIT_SHA:-}" \
    '{
      number: $number,
      url: $url,
      state: $state,
      headRefOid: $head_sha,
      headRefName: $head_ref_name,
      baseRefName: $base_ref,
      mergedAt: (if $merged_at == "" then null else $merged_at end),
      mergeCommit: (if $merge_commit_sha == "" then null else {oid: $merge_commit_sha} end)
    }'
}

current_pr_payload() {
  if [[ -n "${FAKE_GH_PR_STATE_FILE:-}" && -f "${FAKE_GH_PR_STATE_FILE:-}" ]]; then
    cat "$FAKE_GH_PR_STATE_FILE"
  else
    build_pr_payload
  fi
}

write_pr_payload() {
  local payload="$1"
  if [[ -n "${FAKE_GH_PR_STATE_FILE:-}" ]]; then
    printf '%s\n' "$payload" > "$FAKE_GH_PR_STATE_FILE"
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
    cmd2="${1:-}"
    case "$cmd2" in
      status)
        exit 0
        ;;
      *)
        echo "unsupported gh invocation: auth $cmd2" >&2
        exit 1
        ;;
    esac
    ;;
  repo)
    cmd2="${1:-}"
    shift || true
    case "$cmd2" in
      view)
        emit "$(build_repo_view_payload)" "$@"
        ;;
      *)
        echo "unsupported gh invocation: repo $cmd2" >&2
        exit 1
        ;;
    esac
    ;;
  pr)
    cmd2="${1:-}"
    shift || true
    case "$cmd2" in
      list)
        payload='[]'
        if [[ -n "${FAKE_GH_PR_STATE_FILE:-}" && -f "${FAKE_GH_PR_STATE_FILE:-}" ]]; then
          pr_payload="$(current_pr_payload)"
          if [[ "$(jq -r '.state' <<<"$pr_payload")" == "OPEN" ]]; then
            payload="$(jq '[{number: .number}]' <<<"$pr_payload")"
          fi
        elif [[ -n "${FAKE_GH_PR_NUMBER:-}" ]]; then
          pr_payload="$(build_pr_payload)"
          if [[ "$(jq -r '.state' <<<"$pr_payload")" == "OPEN" ]]; then
            payload="$(jq '[{number: .number}]' <<<"$pr_payload")"
          fi
        fi
        emit "$payload" "$@"
        ;;
      create)
        require_base_ref_if_requested "$@"
        printf '%s\n' "${FAKE_GH_PR_URL:-https://example.test/pr/101}"
        ;;
      edit)
        require_base_ref_if_requested "$@"
        exit 0
        ;;
      view)
        if [[ $# -gt 0 && "${1#-}" == "$1" ]]; then
          shift
        fi
        emit "$(current_pr_payload)" "$@"
        ;;
      checks)
        emit "${FAKE_GH_CHECKS_JSON:-[]}" "$@"
        exit "${FAKE_GH_CHECKS_EXIT_CODE:-0}"
        ;;
      merge)
        if [[ $# -gt 0 && "${1#-}" == "$1" ]]; then
          shift
        fi
        match_head_commit=""
        delete_branch_requested=false
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --match-head-commit)
              match_head_commit="${2:-}"
              shift 2
              ;;
            --delete-branch)
              delete_branch_requested=true
              shift
              ;;
            --merge|--rebase|--squash|--admin|--auto|--disable-auto)
              shift
              ;;
            -d)
              delete_branch_requested=true
              shift
              ;;
            -m|-r|-s)
              shift
              ;;
            -A|-b|-F|-t)
              shift 2
              ;;
            *)
              shift
              ;;
          esac
        done

        payload="$(current_pr_payload)"
        current_head_commit="$(jq -r '.headRefOid' <<<"$payload")"
        if [[ -n "$match_head_commit" && "$match_head_commit" != "$current_head_commit" ]]; then
          echo "fake gh head SHA mismatch for merge" >&2
          exit 1
        fi
        if [[ "${FAKE_GH_REQUIRE_DELETE_BRANCH:-false}" == "true" && "$delete_branch_requested" != "true" ]]; then
          echo "fake gh expected --delete-branch" >&2
          exit 1
        fi

        post_merge_state="${FAKE_GH_PR_POST_MERGE_STATE:-MERGED}"
        post_merged_at="${FAKE_GH_PR_POST_MERGED_AT:-2026-03-12T15:00:00Z}"
        post_merge_commit="${FAKE_GH_PR_POST_MERGE_COMMIT_SHA:-0123456789abcdef0123456789abcdef01234567}"
        updated_payload="$(jq \
          --arg state "$post_merge_state" \
          --arg merged_at "$post_merged_at" \
          --arg merge_commit "$post_merge_commit" \
          '.state = $state
          | .mergedAt = $merged_at
          | .mergeCommit = {oid: $merge_commit}' <<<"$payload")"
        write_pr_payload "$updated_payload"

        if [[ "${FAKE_GH_REPO_DELETE_BRANCH_ON_MERGE:-true}" == "true" ]]; then
          head_ref_name="$(jq -r '.headRefName' <<<"$updated_payload")"
          if [[ -n "$head_ref_name" && "$head_ref_name" != "null" ]]; then
            git push origin --delete "$head_ref_name" >/dev/null 2>&1 || true
          fi
        fi

        if [[ -n "${FAKE_GH_PR_MERGE_STDERR:-}" ]]; then
          printf '%s\n' "${FAKE_GH_PR_MERGE_STDERR:-}" >&2
        elif [[ -n "${FAKE_GH_PR_MERGE_OUTPUT:-}" ]]; then
          printf '%s\n' "${FAKE_GH_PR_MERGE_OUTPUT:-}" >&2
        fi

        exit "${FAKE_GH_PR_MERGE_EXIT_CODE:-0}"
        ;;
      *)
        echo "unsupported gh invocation: pr $cmd2" >&2
        exit 1
        ;;
    esac
    ;;
  api)
    api_path="${1:-}"
    shift || true
    case "$api_path" in
      repos/*/branches/*/protection)
        payload="${FAKE_GH_BRANCH_PROTECTION_JSON:-}"
        if [[ -z "$payload" ]]; then
          payload='{"required_status_checks":{"strict":true,"contexts":["required-ci"],"checks":[{"context":"required-ci"}]}}'
        fi
        emit "$payload" "$@"
        ;;
      repos/*/actions/permissions)
        payload="${FAKE_GH_ACTIONS_PERMISSIONS_JSON:-}"
        if [[ -z "$payload" ]]; then
          payload='{"enabled":true,"allowed_actions":"local_only","sha_pinning_required":true}'
        fi
        emit "$payload" "$@"
        ;;
      repos/*)
        payload="${FAKE_GH_REPO_API_JSON:-}"
        if [[ -z "$payload" ]]; then
          payload='{"allow_merge_commit":false,"allow_rebase_merge":true,"allow_squash_merge":true,"delete_branch_on_merge":true}'
        fi
        emit "$payload" "$@"
        ;;
      *)
        echo "unsupported gh api path: $api_path" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "unsupported gh invocation: $cmd1" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$fake_bin/gh"

cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${FAKE_GIT_FAIL_SWITCH_TO:-}" && "${1:-}" == "switch" && "${2:-}" == "${FAKE_GIT_FAIL_SWITCH_TO}" ]]; then
  echo "fake git failed switching to ${FAKE_GIT_FAIL_SWITCH_TO}" >&2
  exit 1
fi

if [[ -n "${FAKE_GIT_FAIL_BRANCH_DELETE:-}" && "${1:-}" == "branch" && ( "${2:-}" == "-D" || "${2:-}" == "-d" ) && "${3:-}" == "${FAKE_GIT_FAIL_BRANCH_DELETE}" ]]; then
  echo "fake git failed deleting branch ${FAKE_GIT_FAIL_BRANCH_DELETE}" >&2
  exit 1
fi

exec "__REAL_GIT_PATH__" "$@"
EOF
escaped_real_git_path="$(printf '%s\n' "$REAL_GIT_PATH" | sed 's/[\/&]/\\&/g')"
tmp_fake_git="$tmp_root/fake-git.tmp"
sed "s/__REAL_GIT_PATH__/$escaped_real_git_path/g" "$fake_bin/git" > "$tmp_fake_git"
mv "$tmp_fake_git" "$fake_bin/git"
chmod +x "$fake_bin/git"

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
  mkdir -p .github/workflows docs/harness/active docs/harness/completed &&
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
  git add .github/workflows/harness-checks.yml docs/harness/active/2026-03-11-active-plan.md docs/harness/active/2026-03-11-twin-plan.md docs/harness/completed/2026-03-11-incomplete-plan.md docs/harness/completed/2026-03-11-complete-plan.md docs/harness/completed/2026-03-11-twin-plan.md &&
  git commit -m "add gate regression fixtures" >/dev/null
)

export FAKE_GH_REPO_NAME_WITH_OWNER="example/missless"
export FAKE_GH_BRANCH_PROTECTION_JSON='{"required_status_checks":{"strict":true,"contexts":["required-ci"],"checks":[{"context":"required-ci"}]}}'
export FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":true,"allowed_actions":"local_only","sha_pinning_required":true}'
export FAKE_GH_REPO_MERGE_COMMIT_ALLOWED="false"
export FAKE_GH_REPO_REBASE_MERGE_ALLOWED="true"
export FAKE_GH_REPO_SQUASH_MERGE_ALLOWED="true"
export FAKE_GH_REPO_DELETE_BRANCH_ON_MERGE="true"

active_plan="docs/harness/active/2026-03-11-active-plan.md"
incomplete_plan="docs/harness/completed/2026-03-11-incomplete-plan.md"
complete_plan="docs/harness/completed/2026-03-11-complete-plan.md"
twin_plan="docs/harness/completed/2026-03-11-twin-plan.md"
body_file="$tmp_root/pr-body.md"
printf 'direct request (no issue)\n' > "$body_file"

git clone "$origin_dir" "$publish_base_dir" >/dev/null 2>&1
(
  cd "$publish_base_dir" &&
  git config user.name "Codex" &&
  git config user.email "codex@example.com" &&
  git checkout -b publish-base origin/main >/dev/null &&
  git push -u origin publish-base >/dev/null
)
(
  cd "$publish_base_dir" &&
  git checkout -b publish-stale-probe origin/main >/dev/null &&
  printf 'stale publish probe\n' > stale-publish.txt &&
  git add stale-publish.txt &&
  git commit -m "stale publish probe" >/dev/null &&
  git push -u origin publish-stale-probe >/dev/null
)
(
  cd "$work_dir" &&
  git fetch origin publish-stale-probe:refs/remotes/origin/publish-stale-probe >/dev/null 2>&1
)
(
  cd "$publish_base_dir" &&
  git push origin --delete publish-stale-probe >/dev/null
)
(
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/publish-stale-probe >/dev/null
) || fail "expected origin/publish-stale-probe to exist before repo-sync prune preflight"

(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$preflight_script" main >/dev/null
)

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_BRANCH_PROTECTION_JSON='{"required_status_checks":{"strict":true,"contexts":[],"checks":[]}}' \
  "$preflight_script" main >/dev/null 2>&1
); then
  fail "repository_readiness_preflight accepted a base branch with zero required checks"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":false,"allowed_actions":"local_only","sha_pinning_required":true}' \
  "$preflight_script" main >/dev/null 2>&1
); then
  fail "repository_readiness_preflight accepted a repository with Actions disabled"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":true}' \
  "$preflight_script" main >/dev/null 2>&1
); then
  fail "repository_readiness_preflight accepted an Actions permissions payload without allowed_actions"
fi

(
  cd "$work_dir" &&
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
      - uses: actions/checkout@v4
YAML
)
if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$preflight_script" main >/dev/null 2>&1
); then
  fail "repository_readiness_preflight accepted a local_only Actions policy with external actions"
fi

if (
  cd "$work_dir/docs" &&
  PATH="$fake_bin:$PATH" \
  "$preflight_script" main >/dev/null 2>&1
); then
  fail "repository_readiness_preflight accepted a local_only Actions policy with external actions from a repo subdirectory"
fi

if (
  cd "$work_dir/docs" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  "$publish_script" publish-base "Regression PR" "$body_file" --plan "$complete_plan" --direct-request >/dev/null 2>&1
); then
  fail "publish_pr accepted a local_only Actions policy with external actions from a repo subdirectory"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":true,"allowed_actions":"all","sha_pinning_required":true}' \
  "$preflight_script" main >/dev/null 2>&1
); then
  fail "repository_readiness_preflight accepted unpinned external actions while SHA pinning is required"
fi
(
  cd "$work_dir" &&
  git checkout -- .github/workflows/harness-checks.yml
)

(
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/publish-base >/dev/null
) || fail "repository_readiness_preflight did not repo-sync the publish base ref"

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
  FAKE_GH_REQUIRE_BASE_REF="true" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  "$publish_script" publish-base "Regression PR" "$body_file" --plan "$complete_plan" --direct-request
)"
[[ "$publish_output" == "created https://example.test/pr/101" ]] || fail "unexpected publish output: $publish_output"
if (
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/publish-stale-probe >/dev/null
); then
  fail "publish_pr did not prune stale remote-tracking refs during repo-sync preflight"
fi

(
  cd "$publish_base_dir" &&
  git checkout -b publish-edit-base origin/main >/dev/null &&
  git push -u origin publish-edit-base >/dev/null
)

if (
  cd "$work_dir" &&
  git rev-parse --verify --quiet origin/publish-edit-base >/dev/null
); then
  fail "expected origin/publish-edit-base to be absent before publish edit repo-sync preflight"
fi

publish_edit_output="$(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_REQUIRE_BASE_REF="true" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  "$publish_script" publish-edit-base "Regression PR" "$body_file" --plan "$complete_plan" --direct-request
)"
[[ "$publish_edit_output" == "updated https://example.test/pr/101" ]] || fail "unexpected publish edit output: $publish_edit_output"

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  FAKE_GH_BRANCH_PROTECTION_JSON='{"required_status_checks":{"strict":true,"contexts":[],"checks":[]}}' \
  "$publish_script" publish-base "Regression PR" "$body_file" --plan "$complete_plan" --direct-request >/dev/null 2>&1
); then
  fail "publish_pr accepted a base branch with zero required checks"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":false,"allowed_actions":"local_only","sha_pinning_required":true}' \
  "$publish_script" publish-base "Regression PR" "$body_file" --plan "$complete_plan" --direct-request >/dev/null 2>&1
); then
  fail "publish_pr accepted a repository with Actions disabled"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":true,"allowed_actions":"selected","sha_pinning_required":true}' \
  "$publish_script" publish-base "Regression PR" "$body_file" --plan "$complete_plan" --direct-request >/dev/null 2>&1
); then
  fail "publish_pr accepted an unsupported selected Actions policy"
fi

head_sha="$(cd "$work_dir" && git rev-parse HEAD)"
head_branch_name="$(cd "$work_dir" && git branch --show-current)"
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

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  FAKE_GH_BRANCH_PROTECTION_JSON='{"required_status_checks":{"strict":true,"contexts":[],"checks":[]}}' \
  "$export_ci_script" main --docs-updated true >/dev/null 2>&1
); then
  fail "export_ci_status accepted a base branch with zero required checks"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":false,"allowed_actions":"local_only","sha_pinning_required":true}' \
  "$export_ci_script" main --docs-updated true >/dev/null 2>&1
); then
  fail "export_ci_status accepted a repository with Actions disabled"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":true,"allowed_actions":"selected","sha_pinning_required":true}' \
  "$export_ci_script" main --docs-updated true >/dev/null 2>&1
); then
  fail "export_ci_status accepted an unsupported selected Actions policy"
fi

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
  PATH="$fake_bin:$PATH" \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate.json >/dev/null
)
assert_exists "$work_dir/.local/loop/final-gate.json"
[[ "$(jq -r '.result' "$work_dir/.local/loop/final-gate.json")" == "pass" ]] || fail "final_gate did not pass with fresh inputs"
retained_dir="$work_dir/.local/final-evidence/2026-03-11-complete-plan"
assert_exists "$retained_dir/review.json"
assert_exists "$retained_dir/ci-status.json"
assert_exists "$retained_dir/final-gate.json"
[[ "$(jq -r '.retained_evidence_dir' "$work_dir/.local/loop/final-gate.json")" == ".local/final-evidence/2026-03-11-complete-plan" ]] || fail "final_gate did not record retained evidence directory"

printf 'sentinel review\n' > "$retained_dir/review.json"
printf 'sentinel ci\n' > "$retained_dir/ci-status.json"
printf 'sentinel final gate\n' > "$retained_dir/final-gate.json"
(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate.json >/dev/null
)
if grep -q 'sentinel' "$retained_dir/review.json"; then
  fail "final_gate promotion did not overwrite the retained review bundle"
fi
if grep -q 'sentinel' "$retained_dir/ci-status.json"; then
  fail "final_gate promotion did not overwrite the retained ci-status bundle"
fi
if grep -q 'sentinel' "$retained_dir/final-gate.json"; then
  fail "final_gate promotion did not overwrite the retained final-gate bundle"
fi
[[ "$(jq -r '.head_sha' "$retained_dir/ci-status.json")" == "$head_sha" ]] || fail "retained ci-status bundle did not refresh after overwrite"
[[ "$(jq -r '.retained_evidence_dir' "$retained_dir/final-gate.json")" == ".local/final-evidence/2026-03-11-complete-plan" ]] || fail "retained final-gate bundle lost its retained_evidence_dir metadata"

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$active_plan" main .local/loop/final-gate-active-plan.json >/dev/null 2>&1
); then
  fail "final_gate accepted a plan that still lives under active/"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$incomplete_plan" main .local/loop/final-gate-incomplete-plan.json >/dev/null 2>&1
); then
  fail "final_gate accepted an incomplete archived plan"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$twin_plan" main .local/loop/final-gate-twin-plan.json >/dev/null 2>&1
); then
  fail "final_gate accepted an archived plan with a stale twin under active/"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_BRANCH_PROTECTION_JSON='{"required_status_checks":{"strict":true,"contexts":[],"checks":[]}}' \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate-zero-required.json >/dev/null 2>&1
); then
  fail "final_gate accepted a base branch with zero required checks"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":false,"allowed_actions":"local_only","sha_pinning_required":true}' \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate-actions-disabled.json >/dev/null 2>&1
); then
  fail "final_gate accepted a repository with Actions disabled"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_ACTIONS_PERMISSIONS_JSON='{"enabled":true,"allowed_actions":"selected","sha_pinning_required":true}' \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate-selected-actions.json >/dev/null 2>&1
); then
  fail "final_gate accepted an unsupported selected Actions policy"
fi

(
  cd "$work_dir" &&
  printf 'dirty\n' >> README.md
)
if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
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
  PATH="$fake_bin:$PATH" \
  "$final_gate_script" .local/loop/review-clean.json .local/loop/ci-stale.json "$complete_plan" main .local/loop/final-gate-stale.json >/dev/null 2>&1
); then
  fail "final_gate accepted stale CI head metadata"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
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

land_pr_state_file="$tmp_root/land-pr-state.json"
jq -n \
  --argjson number 101 \
  --arg url "https://example.test/pr/101" \
  --arg state "OPEN" \
  --arg head_sha "$head_sha" \
  --arg head_ref_name "$head_branch_name" \
  --arg base_ref "main" \
  '{
    number: $number,
    url: $url,
    state: $state,
    headRefOid: $head_sha,
    headRefName: $head_ref_name,
    baseRefName: $base_ref,
    mergedAt: null,
    mergeCommit: null
  }' > "$land_pr_state_file"

land_merge_output="$(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  REAL_GIT_PATH="$(command -v git)" \
  FAKE_GH_PR_STATE_FILE="$land_pr_state_file" \
  FAKE_GH_PR_POST_MERGED_AT="2026-03-12T15:00:00Z" \
  FAKE_GH_PR_POST_MERGE_COMMIT_SHA="0123456789abcdef0123456789abcdef01234567" \
  FAKE_GIT_FAIL_BRANCH_DELETE="$head_branch_name" \
  "$land_merge_script" .local/loop/final-gate.json "$complete_plan" main --output .local/loop/land.json
)"
[[ "$land_merge_output" == *".local/loop/land.json" ]] || fail "unexpected land_merge output: $land_merge_output"
assert_exists "$work_dir/.local/loop/land.json"
[[ "$(jq -r '.result' "$work_dir/.local/loop/land.json")" == "pass" ]] || fail "land_merge did not report pass after remote merge success"
[[ "$(jq -r '.remote_merge_ok' "$work_dir/.local/loop/land.json")" == "true" ]] || fail "land_merge did not record remote merge success"
[[ "$(jq -r '.local_cleanup_ok' "$work_dir/.local/loop/land.json")" == "false" ]] || fail "land_merge did not preserve local cleanup warnings separately from remote merge success"
[[ "$(jq -r '.merge_method' "$work_dir/.local/loop/land.json")" == "rebase" ]] || fail "land_merge did not auto-select the repository-compatible rebase method"
jq -e --arg branch "$head_branch_name" '.cleanup_warnings | any(.[]; test("Current worktree remains on merged branch " + $branch + "; local cleanup is deferred"))' >/dev/null "$work_dir/.local/loop/land.json" || fail "land_merge did not record the current-worktree cleanup warning"
[[ "$(jq -r '.state' "$land_pr_state_file")" == "MERGED" ]] || fail "fake gh merge state was not persisted for land_merge"
[[ "$(jq -r '.mergeCommit.oid' "$land_pr_state_file")" == "0123456789abcdef0123456789abcdef01234567" ]] || fail "land_merge did not report the remote merge commit"
if (
  cd "$work_dir" &&
  git rev-parse --verify --quiet "refs/remotes/origin/$head_branch_name" >/dev/null
); then
  fail "land_merge did not prune the deleted remote-tracking branch after merge"
fi

blocked_method_pr_state_file="$tmp_root/land-pr-state-blocked-method.json"
cp "$land_pr_state_file" "$blocked_method_pr_state_file"
jq '.state = "OPEN" | .mergedAt = null | .mergeCommit = null' "$blocked_method_pr_state_file" > "$blocked_method_pr_state_file.tmp"
mv "$blocked_method_pr_state_file.tmp" "$blocked_method_pr_state_file"
if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_STATE_FILE="$blocked_method_pr_state_file" \
  "$land_merge_script" .local/loop/final-gate.json "$complete_plan" main --pr 101 --method merge >/dev/null 2>&1
); then
  fail "land_merge accepted a merge method that repository policy disallows"
fi

land_pr_cli_warning_state_file="$tmp_root/land-pr-state-cli-warning.json"
jq -n \
  --argjson number 101 \
  --arg url "https://example.test/pr/101" \
  --arg state "OPEN" \
  --arg head_sha "$head_sha" \
  --arg head_ref_name "$head_branch_name" \
  --arg base_ref "main" \
  '{
    number: $number,
    url: $url,
    state: $state,
    headRefOid: $head_sha,
    headRefName: $head_ref_name,
    baseRefName: $base_ref,
    mergedAt: null,
    mergeCommit: null
  }' > "$land_pr_cli_warning_state_file"

land_merge_cli_warning_output="$(
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_STATE_FILE="$land_pr_cli_warning_state_file" \
  FAKE_GH_PR_MERGE_EXIT_CODE="1" \
  FAKE_GH_PR_MERGE_OUTPUT="local cleanup failed because another worktree already has main checked out" \
  FAKE_GH_PR_POST_MERGED_AT="2026-03-12T15:05:00Z" \
  FAKE_GH_PR_POST_MERGE_COMMIT_SHA="fedcba9876543210fedcba9876543210fedcba98" \
  "$land_merge_script" .local/loop/final-gate.json "$complete_plan" main --output .local/loop/land-cli-warning.json
)"
[[ "$land_merge_cli_warning_output" == *".local/loop/land-cli-warning.json" ]] || fail "unexpected land_merge cli-warning output: $land_merge_cli_warning_output"
assert_exists "$work_dir/.local/loop/land-cli-warning.json"
[[ "$(jq -r '.result' "$work_dir/.local/loop/land-cli-warning.json")" == "pass" ]] || fail "land_merge did not keep pass after gh pr merge returned non-zero with remote success"
[[ "$(jq -r '.merge_command_exit_code' "$work_dir/.local/loop/land-cli-warning.json")" == "1" ]] || fail "land_merge did not preserve the gh pr merge exit code"
[[ "$(jq -r '.remote_merge_ok' "$work_dir/.local/loop/land-cli-warning.json")" == "true" ]] || fail "land_merge did not preserve remote merge success after gh pr merge returned non-zero"
[[ "$(jq -r '.local_cleanup_ok' "$work_dir/.local/loop/land-cli-warning.json")" == "false" ]] || fail "land_merge did not downgrade non-zero gh pr merge cleanup to warnings"
jq -e '.cleanup_warnings | any(.[]; test("gh pr merge exited with status 1"))' >/dev/null "$work_dir/.local/loop/land-cli-warning.json" || fail "land_merge did not record the gh pr merge status warning"
jq -e '.cleanup_warnings | any(.[]; test("another worktree already has main checked out"))' >/dev/null "$work_dir/.local/loop/land-cli-warning.json" || fail "land_merge did not preserve gh pr merge cleanup output"
jq -e --arg branch "$head_branch_name" '.cleanup_warnings | any(.[]; test("Current worktree remains on merged branch " + $branch + "; local cleanup is deferred"))' >/dev/null "$work_dir/.local/loop/land-cli-warning.json" || fail "land_merge did not preserve the current-worktree cleanup warning after gh pr merge returned non-zero"

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_STATE_FILE="$tmp_root/land-pr-unmerged.json" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_HEAD_REF_NAME="$head_branch_name" \
  FAKE_GH_PR_BASE_REF="main" \
  FAKE_GH_REPO_API_JSON='{"allow_merge_commit":false,"allow_rebase_merge":true,"allow_squash_merge":true,"delete_branch_on_merge":true}' \
  FAKE_GH_REQUIRE_DELETE_BRANCH="true" \
  FAKE_GH_PR_POST_MERGE_STATE="OPEN" \
  FAKE_GH_PR_MERGE_EXIT_CODE="1" \
  "$land_merge_script" .local/loop/final-gate.json "$complete_plan" main --method squash --output .local/loop/land-failed.json >/dev/null 2>&1
); then
  fail "land_merge reported success even though gh pr merge never produced a remote merge"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  "$land_preflight_script" .local/loop/final-gate.json "$active_plan" main >/dev/null 2>&1
); then
  fail "land_preflight accepted a plan that still lives under active/"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  "$land_preflight_script" .local/loop/final-gate.json "$incomplete_plan" main >/dev/null 2>&1
); then
  fail "land_preflight accepted an incomplete archived plan"
fi

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  FAKE_GH_PR_NUMBER="101" \
  FAKE_GH_PR_URL="https://example.test/pr/101" \
  FAKE_GH_PR_STATE="OPEN" \
  FAKE_GH_PR_HEAD_SHA="$head_sha" \
  FAKE_GH_PR_BASE_REF="main" \
  "$land_preflight_script" .local/loop/final-gate.json "$twin_plan" main >/dev/null 2>&1
); then
  fail "land_preflight accepted an archived plan with a stale twin under active/"
fi

git clone "$origin_dir" "$updater_dir" >/dev/null 2>&1
(
  cd "$updater_dir" &&
  git config user.name "Codex" &&
  git config user.email "codex@example.com" &&
  git checkout main >/dev/null &&
  printf 'upstream drift\n' >> README.md &&
  git add README.md &&
  git commit -m "advance main" >/dev/null &&
  git push origin main >/dev/null
)

if (
  cd "$work_dir" &&
  PATH="$fake_bin:$PATH" \
  "$final_gate_script" .local/loop/review-clean.json "$ci_path" "$complete_plan" main .local/loop/final-gate-behind-main.json >/dev/null 2>&1
); then
  fail "final_gate accepted a branch and CI artifact after origin/main advanced"
fi

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
  fail "land_preflight accepted a stale final-gate artifact after origin/main advanced"
fi

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
