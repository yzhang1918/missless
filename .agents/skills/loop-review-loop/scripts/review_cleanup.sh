#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<USAGE
Usage: $0 [--dry-run] [--keep-rounds N] [--keep-round-id ROUND_ID]

Cleanup ephemeral loop-review artifacts under .local/loop while keeping
recent review rounds.

Options:
  --dry-run             Show what would be removed without deleting
  --keep-rounds N       Keep latest N timestamp rounds (default: 1)
  --keep-round-id ID    Keep a specific round id (YYYYMMDD-HHMMSS, repeatable)
USAGE
}

dry_run=false
keep_rounds=1
declare -a keep_round_ids=()

is_timestamp_round_id() {
  local value="$1"
  [[ "$value" =~ ^[0-9]{8}-[0-9]{6}$ ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --keep-rounds)
      if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        usage
        exit 1
      fi
      keep_rounds="$2"
      shift 2
      ;;
    --keep-round-id)
      if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        usage
        exit 1
      fi
      if ! is_timestamp_round_id "$2"; then
        echo "--keep-round-id must match YYYYMMDD-HHMMSS" >&2
        exit 1
      fi
      keep_round_ids+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$keep_rounds" =~ ^[0-9]+$ ]]; then
  echo "--keep-rounds must be a non-negative integer" >&2
  exit 1
fi

out_dir=".local/loop"
if [[ ! -d "$out_dir" ]]; then
  echo "No loop artifact directory: $out_dir"
  exit 0
fi
abs_out_dir="$(cd "$out_dir" && pwd -P)"

normalize_target_path() {
  local target="$1"
  local parent
  local base
  local abs_parent

  parent="$(dirname "$target")"
  base="$(basename "$target")"
  abs_parent="$(cd "$parent" 2>/dev/null && pwd -P)" || return 1
  printf '%s/%s\n' "$abs_parent" "$base"
}

is_safe_target() {
  local target="$1"
  local abs_target

  abs_target="$(normalize_target_path "$target")" || return 1
  [[ "$abs_target" != "$abs_out_dir" ]] || return 1
  [[ "$abs_target" == "$abs_out_dir/"* ]]
}

# Collect latest timestamp-based aggregate rounds: review-YYYYMMDD-HHMMSS.json
declare -a all_round_ids=()
declare -a orphan_aggregate_files=()
while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  if [[ "$base" =~ ^review-([0-9]{8}-[0-9]{6})\.json$ ]]; then
    rid="${BASH_REMATCH[1]}"
    # Treat as a real round only if at least one per-dimension file exists.
    if find "$out_dir" -maxdepth 1 -type f -name "review-${rid}-*.json" -print -quit | grep -q .; then
      all_round_ids+=("$rid")
    else
      if ! is_safe_target "$f"; then
        echo "Refusing unsafe cleanup target: $f" >&2
        exit 1
      fi
      orphan_aggregate_files+=("$f")
    fi
  fi
done < <(find "$out_dir" -maxdepth 1 -type f -name 'review-*.json' -print0)

# Unique + sort descending (lexical works with timestamp format)
declare -a unique_sorted_round_ids=()
while IFS= read -r rid; do
  unique_sorted_round_ids+=("$rid")
done < <(printf '%s\n' "${all_round_ids[@]:-}" | awk 'NF {print}' | sort -u | sort -r)

# Build keep list (bash 3.2 compatible; no associative arrays)
declare -a keep_set=()
contains_keep_id() {
  local needle="$1"
  local item
  for item in "${keep_set[@]-}"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

for rid in "${keep_round_ids[@]-}"; do
  if ! contains_keep_id "$rid"; then
    keep_set+=("$rid")
  fi
done

if (( keep_rounds > 0 )); then
  count=0
  for rid in "${unique_sorted_round_ids[@]-}"; do
    if ! contains_keep_id "$rid"; then
      keep_set+=("$rid")
    fi
    ((count += 1))
    if (( count >= keep_rounds )); then
      break
    fi
  done
fi

declare -a delete_files=()
declare -a delete_dirs=()

while IFS= read -r -d '' path; do
  base="$(basename "$path")"

  # Timestamp rounds and their per-dimension artifacts
  if [[ "$base" =~ ^review-([0-9]{8}-[0-9]{6})(-.+)?\.json$ ]]; then
    rid="${BASH_REMATCH[1]}"
    if ! contains_keep_id "$rid"; then
      if ! is_safe_target "$path"; then
        echo "Refusing unsafe cleanup target: $path" >&2
        exit 1
      fi
      delete_files+=("$path")
    fi
    continue
  fi

  # Cleanup launch manifests plus ad-hoc smoke/probe and ci/final-gate scratch artifacts
  if [[ "$base" =~ ^(ci-.*\.json|final-gate-.*\.json|review-launch-.*\.json|review-dispatch-.*\.json|review-smoke.*\.json|review-secprobe.*\.json|review-reg-case\.json|review-testround\.json|review-[0-9]{8}\.json)$ ]]; then
    if ! is_safe_target "$path"; then
      echo "Refusing unsafe cleanup target: $path" >&2
      exit 1
    fi
    delete_files+=("$path")
    continue
  fi

done < <(find "$out_dir" -maxdepth 1 -type f -print0)

# Delete malformed/orphan aggregate rounds unless explicitly kept by round-id.
for f in "${orphan_aggregate_files[@]-}"; do
  [[ -n "$f" ]] || continue
  base="$(basename "$f")"
  if [[ "$base" =~ ^review-([0-9]{8}-[0-9]{6})\.json$ ]]; then
    rid="${BASH_REMATCH[1]}"
    if contains_keep_id "$rid"; then
      continue
    fi
  fi
  if ! is_safe_target "$f"; then
    echo "Refusing unsafe cleanup target: $f" >&2
    exit 1
  fi
  delete_files+=("$f")
done

while IFS= read -r -d '' d; do
  if ! is_safe_target "$d"; then
    echo "Refusing unsafe cleanup target: $d" >&2
    exit 1
  fi
  delete_dirs+=("$d")
done < <(find "$out_dir" -maxdepth 1 -type d \( -name 'tmp-regression*' \) -print0)

echo "Cleanup plan for $out_dir"
if ((${#keep_set[@]} > 0)); then
  echo "Keeping round IDs:"
  for rid in "${keep_set[@]-}"; do
    echo "  - $rid"
  done | sort
else
  echo "Keeping round IDs: none"
fi

echo "Files to remove: ${#delete_files[@]}"
for f in "${delete_files[@]-}"; do
  [[ -n "$f" ]] || continue
  echo "  - $f"
done

echo "Directories to remove: ${#delete_dirs[@]}"
for d in "${delete_dirs[@]-}"; do
  [[ -n "$d" ]] || continue
  echo "  - $d"
done

if [[ "$dry_run" == true ]]; then
  echo "Dry run only. No files removed."
  exit 0
fi

for f in "${delete_files[@]-}"; do
  [[ -n "$f" ]] || continue
  if ! is_safe_target "$f"; then
    echo "Refusing unsafe cleanup target: $f" >&2
    exit 1
  fi
  rm -f -- "$f"
done
for d in "${delete_dirs[@]-}"; do
  [[ -n "$d" ]] || continue
  if ! is_safe_target "$d"; then
    echo "Refusing unsafe cleanup target: $d" >&2
    exit 1
  fi
  rm -rf -- "$d"
done

echo "Cleanup completed."
