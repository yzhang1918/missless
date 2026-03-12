#!/usr/bin/env bash

# Shared helpers for stateful publish/final-gate/land checks.

stateful_gate_require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required" >&2
    return 1
  fi
}

stateful_gate_repo_root() {
  git rev-parse --show-toplevel
}

stateful_gate_current_branch() {
  git branch --show-current
}

stateful_gate_require_codex_branch() {
  local branch
  branch="$(stateful_gate_current_branch)"
  if [[ -z "$branch" ]]; then
    echo "Unable to determine current branch" >&2
    return 1
  fi
  if [[ "$branch" == "main" ]]; then
    echo "Refusing to operate from main; use a codex/* branch" >&2
    return 1
  fi
  if [[ "$branch" != codex/* ]]; then
    echo "Refusing to operate from non-codex branch: $branch" >&2
    return 1
  fi
}

stateful_gate_require_clean_worktree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree is not clean; commit or stash changes before continuing" >&2
    return 1
  fi
}

stateful_gate_require_gh_auth() {
  stateful_gate_require_command gh || return 1
  if ! gh auth status >/dev/null 2>&1; then
    echo "gh is not authenticated" >&2
    return 1
  fi
}

stateful_gate_sync_origin() {
  local base_branch="${1:-}"
  if ! git fetch --prune origin >/dev/null 2>&1; then
    echo "Repo-sync preflight failed: git fetch --prune origin" >&2
    return 1
  fi
  if [[ -n "$base_branch" ]] && ! git rev-parse --verify --quiet "origin/$base_branch" >/dev/null; then
    echo "Missing remote base ref after repo sync: origin/$base_branch" >&2
    return 1
  fi
}

stateful_gate_current_head_sha() {
  git rev-parse HEAD
}

stateful_gate_current_base_sha() {
  local base_branch="$1"
  git rev-parse "origin/$base_branch"
}

stateful_gate_branch_includes_base() {
  local base_branch="$1"
  git merge-base --is-ancestor "origin/$base_branch" HEAD
}

stateful_gate_repo_name_with_owner() {
  local repo

  repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')" || {
    echo "Unable to determine GitHub repository slug via gh repo view" >&2
    return 1
  }
  if [[ -z "$repo" || "$repo" == "null" ]]; then
    echo "Unable to determine GitHub repository slug via gh repo view" >&2
    return 1
  fi

  printf '%s\n' "$repo"
}

stateful_gate_required_checks_protection_json() {
  local repo="$1"
  local base_branch="$2"

  gh api "repos/$repo/branches/$base_branch/protection"
}

stateful_gate_required_check_names_from_protection_json() {
  jq -r '
    [
      ((.required_status_checks.checks // [])[] | (.context // .name // empty)),
      ((.required_status_checks.contexts // [])[])
    ]
    | map(select(type == "string" and length > 0))
    | unique
    | .[]
  '
}

stateful_gate_require_required_checks_configured() {
  local repo="$1"
  local base_branch="$2"
  local protection_json
  local count

  protection_json="$(stateful_gate_required_checks_protection_json "$repo" "$base_branch")" || {
    echo "Unable to read branch protection for $base_branch; configure required status checks before continuing" >&2
    return 1
  }

  count="$(
    stateful_gate_required_check_names_from_protection_json <<<"$protection_json" | awk 'NF {count += 1} END {print count + 0}'
  )"
  if (( count == 0 )); then
    echo "No required status checks are configured for $base_branch; configure at least one required check before continuing" >&2
    return 1
  fi
}

stateful_gate_actions_permissions_json() {
  local repo="$1"

  gh api "repos/$repo/actions/permissions"
}

stateful_gate_workflow_action_refs() {
  local workflow_path="$1"
  local resolved_workflow_path

  if [[ -z "$workflow_path" ]]; then
    return 0
  fi

  resolved_workflow_path="$(stateful_gate_resolve_repo_path "$workflow_path")" || return 1
  if [[ ! -f "$resolved_workflow_path" ]]; then
    return 0
  fi

  awk '
    /^[[:space:]-]*uses:[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]-]*uses:[[:space:]]*/, "", line)
      sub(/[[:space:]]+#.*/, "", line)
      if (length(line) > 0) {
        print line
      }
    }
  ' "$resolved_workflow_path"
}

stateful_gate_workflow_external_action_refs() {
  local workflow_path="$1"

  stateful_gate_workflow_action_refs "$workflow_path" | awk '
    index($0, "./") != 1 {
      print
    }
  '
}

stateful_gate_workflow_unpinned_action_refs() {
  local workflow_path="$1"

  stateful_gate_workflow_external_action_refs "$workflow_path" | awk '
    $0 !~ /@[0-9a-fA-F]{40}$/ {
      print
    }
  '
}

stateful_gate_require_actions_policy_compatible() {
  local repo="$1"
  local workflow_path="$2"
  local resolved_workflow_path=""
  local permissions_json
  local actions_enabled
  local allowed_actions
  local sha_pinning_required
  local action_refs
  local unpinned_action_refs

  permissions_json="$(stateful_gate_actions_permissions_json "$repo")" || {
    echo "Unable to read repository Actions permissions; confirm the Actions policy before continuing" >&2
    return 1
  }

  actions_enabled="$(jq -r '
    if (.enabled | type) == "boolean" then
      .enabled
    else
      "__missing__"
    end
  ' <<<"$permissions_json")" || {
    echo "Repository Actions permissions payload is missing enabled" >&2
    return 1
  }

  case "$actions_enabled" in
    true)
      ;;
    false)
      echo "Repository Actions is disabled; enable Actions before continuing" >&2
      return 1
      ;;
    *)
      echo "Repository Actions permissions payload is missing enabled" >&2
      return 1
      ;;
  esac

  allowed_actions="$(jq -r '
    if (.allowed_actions | type) == "string" and (.allowed_actions | length) > 0 then
      .allowed_actions
    else
      "__missing__"
    end
  ' <<<"$permissions_json")" || {
    echo "Repository Actions permissions payload is missing allowed_actions" >&2
    return 1
  }

  if [[ "$allowed_actions" == "__missing__" ]]; then
    echo "Repository Actions permissions payload is missing allowed_actions" >&2
    return 1
  fi

  if [[ -n "$workflow_path" ]]; then
    resolved_workflow_path="$(stateful_gate_resolve_repo_path "$workflow_path")" || return 1
  fi

  if [[ -z "$workflow_path" || ! -f "$resolved_workflow_path" ]]; then
    return 0
  fi

  action_refs="$(stateful_gate_workflow_external_action_refs "$resolved_workflow_path" || true)"
  sha_pinning_required="$(jq -r '
    if (.sha_pinning_required | type) == "boolean" then
      .sha_pinning_required
    else
      "false"
    end
  ' <<<"$permissions_json")" || {
    echo "Unable to read repository Actions sha_pinning_required policy" >&2
    return 1
  }

  case "$allowed_actions" in
    local_only)
      if [[ -n "$action_refs" ]]; then
        echo "Repository Actions policy allowed_actions=local_only is incompatible with $workflow_path because it uses external actions:" >&2
        printf '%s\n' "$action_refs" | sed 's/^/  - /' >&2
        return 1
      fi
      ;;
    selected)
      echo "Repository Actions policy allowed_actions=selected is not yet supported by readiness preflight; verify the allowlist for $workflow_path before continuing" >&2
      return 1
      ;;
  esac

  if [[ "$sha_pinning_required" == "true" ]]; then
    unpinned_action_refs="$(stateful_gate_workflow_unpinned_action_refs "$resolved_workflow_path" || true)"
    if [[ -n "$unpinned_action_refs" ]]; then
      echo "Repository Actions policy requires SHA-pinned external actions, but $workflow_path uses unpinned refs:" >&2
      printf '%s\n' "$unpinned_action_refs" | sed 's/^/  - /' >&2
      return 1
    fi
  fi
}

stateful_gate_require_repository_readiness() {
  local base_branch="$1"
  local workflow_path="${2:-}"
  local repo

  stateful_gate_require_command gh || return 1
  stateful_gate_require_command jq || return 1
  stateful_gate_require_codex_branch || return 1
  stateful_gate_require_clean_worktree || return 1
  stateful_gate_require_gh_auth || return 1
  stateful_gate_sync_origin "$base_branch" || return 1

  if ! stateful_gate_branch_includes_base "$base_branch"; then
    echo "Current branch is behind origin/$base_branch; rebase or merge the latest $base_branch before continuing" >&2
    return 1
  fi

  repo="$(stateful_gate_repo_name_with_owner)" || return 1
  stateful_gate_require_required_checks_configured "$repo" "$base_branch" || return 1
  stateful_gate_require_actions_policy_compatible "$repo" "$workflow_path" || return 1
}

stateful_gate_normalize_repo_path() {
  local input="$1"
  local repo_root abs_path dir base

  repo_root="$(stateful_gate_repo_root)" || return 1
  if [[ "$input" = /* ]]; then
    abs_path="$input"
  else
    abs_path="$repo_root/$input"
  fi

  dir="$(dirname "$abs_path")"
  base="$(basename "$abs_path")"
  if ! abs_path="$(cd "$dir" && pwd -P)/$base"; then
    echo "Unable to resolve path inside repository: $input" >&2
    return 1
  fi

  case "$abs_path" in
    "$repo_root"/*)
      printf '%s\n' "${abs_path#$repo_root/}"
      ;;
    *)
      echo "Path is outside repository: $input" >&2
      return 1
      ;;
  esac
}

stateful_gate_resolve_repo_path() {
  local input="$1"
  local repo_root normalized_path

  if [[ -z "$input" ]]; then
    return 0
  fi

  repo_root="$(stateful_gate_repo_root)" || return 1
  normalized_path="$(stateful_gate_normalize_repo_path "$input")" || return 1
  printf '%s/%s\n' "$repo_root" "$normalized_path"
}

stateful_gate_plan_acceptance_stats() {
  local plan_file="$1"
  awk '
    BEGIN {
      in_section = 0
      total = 0
      open = 0
    }
    /^## Acceptance Criteria$/ {
      in_section = 1
      next
    }
    /^## / && in_section {
      in_section = 0
    }
    in_section && /^- \[[ xX]\] / {
      total++
    }
    in_section && /^- \[ \] / {
      open++
    }
    END {
      printf "%d %d\n", total, open
    }
  ' "$plan_file"
}

stateful_gate_plan_step_stats() {
  local plan_file="$1"
  awk '
    BEGIN {
      in_work = 0
      steps = 0
      statuses = 0
      completed = 0
      invalid = 0
    }
    /^## Work Breakdown$/ {
      in_work = 1
      next
    }
    /^## / && in_work {
      in_work = 0
    }
    in_work && /^### Step( |$)/ {
      steps++
      next
    }
    in_work && /^- Status: / {
      statuses++
      if ($0 == "- Status: completed") {
        completed++
      } else if ($0 == "- Status: pending" || $0 == "- Status: in_progress" || $0 == "- Status: blocked") {
        # valid non-terminal status
      } else {
        invalid++
      }
    }
    END {
      printf "%d %d %d %d\n", steps, statuses, completed, invalid
    }
  ' "$plan_file"
}

stateful_gate_validate_archived_plan() {
  local input_path="$1"
  local repo_root plan_rel plan_abs active_twin=""
  local acceptance_total acceptance_open
  local step_count status_count completed_count invalid_count

  repo_root="$(stateful_gate_repo_root)" || return 1
  plan_rel="$(stateful_gate_normalize_repo_path "$input_path")" || return 1
  plan_abs="$repo_root/$plan_rel"

  if [[ ! -f "$plan_abs" ]]; then
    echo "Missing plan file: $plan_rel" >&2
    return 1
  fi

  case "$plan_rel" in
    docs/harness/completed/*.md|docs/exec-plans/completed/*.md)
      ;;
    docs/harness/active/*.md|docs/exec-plans/active/*.md)
      echo "Plan must be archived before stateful gate checks: $plan_rel" >&2
      return 1
      ;;
    *)
      echo "Plan path must live under docs/harness/completed/ or docs/exec-plans/completed/: $plan_rel" >&2
      return 1
      ;;
  esac

  case "$plan_rel" in
    docs/harness/completed/*.md)
      active_twin="docs/harness/active/$(basename "$plan_rel")"
      ;;
    docs/exec-plans/completed/*.md)
      active_twin="docs/exec-plans/active/$(basename "$plan_rel")"
      ;;
  esac
  if [[ -n "$active_twin" && -e "$repo_root/$active_twin" ]]; then
    echo "Archived plan still has a stale twin under active/: $active_twin" >&2
    return 1
  fi

  read -r acceptance_total acceptance_open <<EOF
$(stateful_gate_plan_acceptance_stats "$plan_abs")
EOF
  if (( acceptance_total == 0 )); then
    echo "Archived plan is missing Acceptance Criteria checkboxes: $plan_rel" >&2
    return 1
  fi
  if (( acceptance_open > 0 )); then
    echo "Archived plan still has unchecked acceptance criteria: $plan_rel" >&2
    return 1
  fi

  read -r step_count status_count completed_count invalid_count <<EOF
$(stateful_gate_plan_step_stats "$plan_abs")
EOF
  if (( step_count == 0 )); then
    echo "Archived plan is missing Work Breakdown steps: $plan_rel" >&2
    return 1
  fi
  if (( invalid_count > 0 )); then
    echo "Archived plan has invalid step status values: $plan_rel" >&2
    return 1
  fi
  if (( status_count != step_count )); then
    echo "Archived plan must have exactly one status line per step: $plan_rel" >&2
    return 1
  fi
  if (( completed_count != step_count )); then
    echo "Archived plan still has non-completed step statuses: $plan_rel" >&2
    return 1
  fi

  printf '%s\n' "$plan_rel"
}

stateful_gate_plan_slug() {
  local input_path="$1"
  local plan_rel

  plan_rel="$(stateful_gate_normalize_repo_path "$input_path")" || return 1
  basename "$plan_rel" .md
}
