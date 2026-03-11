#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: review_prepare_reviewers.sh <round-id YYYYMMDD-HHMMSS> <scope> [--focus "<dimension>=<focus>"]... <dimension> [<dimension> ...]

Emit a runtime-agnostic JSON manifest for one review round. Each reviewer entry
includes the selected dimension, a normalized output artifact path, and a
launch-ready prompt for the loop-reviewer skill.

Options:
  --focus "<dimension>=<focus>"  Add optional extra focus text for one selected dimension
USAGE
}

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

trim_value() {
  printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

normalize_dimension_slug() {
  local value
  value="$(trim_value "$1")"
  printf '%s' "$value" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

contains_value() {
  local needle="$1"
  shift || true
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

build_prompt() {
  local dimension="$1"
  local scope="$2"
  local output_path="$3"
  local focus="${4:-}"
  local schema_path=".agents/skills/loop-review-loop/references/reviewer-output-schema.md"

  printf 'Use $loop-reviewer to run the `%s` review dimension for scope `%s`.\n' "$dimension" "$scope"
  printf 'Inspect repository context with local git commands (`git diff`, `git show`, `git log`).\n'
  printf 'Write one schema-valid JSON artifact to `%s` using `%s`.\n' "$output_path" "$schema_path"
  printf 'Focus on risks relevant to `%s`.\n' "$dimension"
  if [[ -n "$focus" ]]; then
    printf 'Additional focus: %s.\n' "$focus"
  fi
  printf 'Return a short confirmation with the output path and finding counts.\n'
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

round_id="$1"
scope="$2"
shift 2

if [[ ! "$round_id" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
  echo "Invalid round-id: expected format YYYYMMDD-HHMMSS" >&2
  exit 1
fi

case "$scope" in
  delta|full-pr)
    ;;
  *)
    echo "Invalid scope: expected delta or full-pr" >&2
    exit 1
    ;;
esac

declare -a raw_dimensions=()
declare -a focus_dimensions=()
declare -a focus_texts=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --focus)
      if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        usage
        exit 1
      fi
      if [[ "$2" != *=* ]]; then
        echo "--focus must use <dimension>=<focus>" >&2
        exit 1
      fi
      focus_dimension="$(trim_value "${2%%=*}")"
      focus_text="$(trim_value "${2#*=}")"
      if [[ -z "$focus_dimension" || -z "$focus_text" ]]; then
        echo "--focus must use non-empty <dimension>=<focus>" >&2
        exit 1
      fi
      if ((${#focus_dimensions[@]} > 0)) && contains_value "$focus_dimension" "${focus_dimensions[@]}"; then
        echo "Duplicate --focus dimension: $focus_dimension" >&2
        exit 1
      fi
      focus_dimensions+=("$focus_dimension")
      focus_texts+=("$focus_text")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        raw_dimensions+=("$1")
        shift
      done
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      raw_dimensions+=("$1")
      shift
      ;;
  esac
done

if ((${#raw_dimensions[@]} == 0)); then
  echo "At least one review dimension is required" >&2
  usage
  exit 1
fi

declare -a dimensions=()
declare -a dimension_slugs=()

for raw_dimension in "${raw_dimensions[@]}"; do
  dimension="$(trim_value "$raw_dimension")"
  if [[ -z "$dimension" ]]; then
    echo "Review dimensions must be non-empty" >&2
    exit 1
  fi

  slug="$(normalize_dimension_slug "$dimension")"
  if [[ -z "$slug" ]]; then
    echo "Review dimension cannot normalize to an empty slug: $dimension" >&2
    exit 1
  fi

  if ((${#dimension_slugs[@]} > 0)) && contains_value "$slug" "${dimension_slugs[@]}"; then
    echo "Duplicate review dimension slug: $slug" >&2
    exit 1
  fi

  dimensions+=("$dimension")
  dimension_slugs+=("$slug")
done

if ((${#focus_dimensions[@]} > 0)); then
  for focus_dimension in "${focus_dimensions[@]}"; do
    if ! contains_value "$focus_dimension" "${dimensions[@]}"; then
      echo "Focus provided for unselected dimension: $focus_dimension" >&2
      exit 1
    fi
  done
fi

focus_for_dimension() {
  local target="$1"
  local idx
  for ((idx = 0; idx < ${#focus_dimensions[@]}; idx += 1)); do
    if [[ "${focus_dimensions[$idx]}" == "$target" ]]; then
      printf '%s' "${focus_texts[$idx]}"
      return 0
    fi
  done
  return 1
}

out_dir=".local/loop"
out_file="$out_dir/review-launch-${round_id}.json"
mkdir -p "$out_dir"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/review-prepare.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

declare -a reviewer_entries=()

for ((idx = 0; idx < ${#dimensions[@]}; idx += 1)); do
  dimension="${dimensions[$idx]}"
  slug="${dimension_slugs[$idx]}"
  output_path="$out_dir/review-${round_id}-${slug}.json"
  focus=""
  if focus="$(focus_for_dimension "$dimension")"; then
    :
  else
    focus=""
  fi
  prompt="$(build_prompt "$dimension" "$scope" "$output_path" "$focus")"
  entry_file="$tmp_dir/${slug}.json"
  jq -n \
    --arg skill "loop-reviewer" \
    --arg scope "$scope" \
    --arg dimension "$dimension" \
    --arg dimension_slug "$slug" \
    --arg output_path "$output_path" \
    --arg prompt "$prompt" \
    --arg focus "$focus" \
    '
      {
        skill: $skill,
        scope: $scope,
        dimension: $dimension,
        dimension_slug: $dimension_slug,
        output_path: $output_path,
        prompt: $prompt
      }
      + (if $focus == "" then {} else {focus: $focus} end)
    ' > "$entry_file"
  reviewer_entries+=("$entry_file")
done

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

jq -s \
  --arg round_id "$round_id" \
  --arg scope "$scope" \
  --arg generated_at "$timestamp" \
  '
    {
      round_id: $round_id,
      scope: $scope,
      generated_at: $generated_at,
      reviewers: .
    }
  ' -- "${reviewer_entries[@]}" > "$out_file"

echo "$out_file"
