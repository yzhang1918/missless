#!/usr/bin/env bash

# Shared helpers for stateful publish/final-gate/land checks.

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
