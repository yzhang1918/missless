#!/usr/bin/env bash

if [[ -n "${ZSH_VERSION:-}" ]]; then
  case "${ZSH_EVAL_CONTEXT:-}" in
    *:file) ;;
    *)
      echo "This script must be sourced: source scripts/dev-activate-missless.sh" >&2
      exit 1
      ;;
  esac
elif [[ -n "${BASH_VERSION:-}" ]]; then
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "This script must be sourced: source scripts/dev-activate-missless.sh" >&2
    exit 1
  fi
fi

missless_activate_fail() {
  echo "$1" >&2
  return 1
}

missless_path_prepend_unique() {
  local target="$1"
  local trimmed_path=":${PATH:-}:"

  trimmed_path="${trimmed_path//:$target:/:}"
  trimmed_path="${trimmed_path#:}"
  trimmed_path="${trimmed_path%:}"

  if [[ -n "$trimmed_path" ]]; then
    export PATH="$target:$trimmed_path"
    return 0
  fi

  export PATH="$target"
}

missless_require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    missless_activate_fail "Missing required command: $name" || return 1
  fi
}

missless_require_local_directory() {
  local path="$1"

  if [[ ! -e "$path" ]]; then
    return 0
  fi

  local resolved_path
  resolved_path="$(cd "$path" && pwd -P)" || return 1

  case "$resolved_path" in
    "$repo_root"|"$repo_root"/*) ;;
    *)
      missless_activate_fail "Expected $path to stay inside $repo_root, got $resolved_path" || return 1
      ;;
  esac
}

missless_require_no_shell_override() {
  local name="$1"

  if [[ -n "${BASH_VERSION:-}" ]]; then
    local kind
    kind="$(type -t "$name" 2>/dev/null || true)"
    case "$kind" in
      alias|function|builtin|keyword)
        missless_activate_fail "Expected $name to resolve through PATH, but the current shell defines it as a $kind" || return 1
        ;;
    esac
    return 0
  fi

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    local descriptor
    descriptor="$(whence -w "$name" 2>/dev/null || true)"
    case "$descriptor" in
      *": alias"|*": function"|*": builtin"|*": reserved")
        missless_activate_fail "Expected $name to resolve through PATH, but the current shell defines it as ${descriptor#*: }" || return 1
        ;;
    esac
  fi
}

missless_needs_install() {
  if [[ "${MISSLESS_FORCE_INSTALL:-0}" == "1" ]]; then
    return 0
  fi

  if [[ ! -d "$repo_root/node_modules" || ! -f "$modules_state" ]]; then
    return 0
  fi

  if [[ -f "$lockfile_path" && "$lockfile_path" -nt "$modules_state" ]]; then
    return 0
  fi

  (
    cd "$repo_root/apps/cli" &&
      pnpm exec node --input-type=module -e "import 'esbuild';"
  ) >/dev/null 2>&1 || return 0

  return 1
}

missless_resolve_command_path() {
  local name="$1"

  if [[ -n "${BASH_VERSION:-}" ]]; then
    type -P "$name" 2>/dev/null || command -v "$name"
    return 0
  fi

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    whence -p "$name" 2>/dev/null || command -v "$name"
    return 0
  fi

  command -v "$name"
}

if [[ -n "${BASH_VERSION:-}" ]]; then
  script_path="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  script_path="${(%):-%x}"
else
  script_path="$0"
fi

script_dir="$(cd "$(dirname "$script_path")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"
dev_bin_dir="$repo_root/scripts/bin"
expected_missless="$dev_bin_dir/missless"
modules_state="$repo_root/node_modules/.modules.yaml"
lockfile_path="$repo_root/pnpm-lock.yaml"

missless_require_command node || return 1
missless_require_command pnpm || return 1

missless_require_local_directory "$repo_root/node_modules" || return 1
missless_require_local_directory "$repo_root/apps/cli/node_modules" || return 1

if missless_needs_install; then
  (
    cd "$repo_root" &&
      pnpm install
  ) || missless_activate_fail "pnpm install failed" || return 1
fi

missless_require_local_directory "$repo_root/node_modules" || return 1
missless_require_local_directory "$repo_root/apps/cli/node_modules" || return 1

(
  cd "$repo_root/apps/cli" &&
    pnpm exec node scripts/build.mjs
) || missless_activate_fail "CLI build failed in apps/cli" || return 1

missless_path_prepend_unique "$dev_bin_dir"

export MISSLESS_ACTIVE_WORKTREE="$repo_root"

hash -r 2>/dev/null || true
rehash 2>/dev/null || true

resolved_missless="$(missless_resolve_command_path missless)"
if [[ "$resolved_missless" != "$expected_missless" ]]; then
  missless_activate_fail "Expected missless to resolve to $expected_missless, got ${resolved_missless:-<unresolved>}" || return 1
fi

missless_require_no_shell_override missless || return 1

"$expected_missless" --help >/dev/null || missless_activate_fail "missless --help failed after activation" || return 1

echo "Activated missless for this shell session from: $repo_root"
