#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: review_record_dispatch.sh <round-id YYYYMMDD-HHMMSS> <dimension-slug> <status> [--reason "<text>"] [--artifact-path <path>]

Statuses:
  launch-started
  artifact-written
  launch-failed
  timeout
  invalid-artifact
  runtime-blocked
USAGE
}

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

repo_relative_path() {
  local input="$1"
  local repo_root
  local abs_path
  local dir
  local base

  repo_root="$(git rev-parse --show-toplevel)"

  if [[ "$input" = /* ]]; then
    abs_path="$input"
  else
    abs_path="$PWD/$input"
  fi

  dir="$(dirname "$abs_path")"
  base="$(basename "$abs_path")"
  abs_path="$(cd "$dir" && pwd -P)/$base" || return 1

  case "$abs_path" in
    "$repo_root"/*)
      printf '%s\n' "${abs_path#$repo_root/}"
      ;;
    *)
      echo "Artifact path is outside repository: $input" >&2
      return 1
      ;;
  esac
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

round_id="$1"
dimension_slug="$2"
status="$3"
shift 3

if [[ ! "$round_id" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
  echo "Invalid round-id: expected format YYYYMMDD-HHMMSS" >&2
  exit 1
fi

if [[ ! "$dimension_slug" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Invalid dimension slug: $dimension_slug" >&2
  exit 1
fi

case "$status" in
  launch-started|artifact-written|launch-failed|timeout|invalid-artifact|runtime-blocked)
    ;;
  *)
    echo "Invalid dispatch status: $status" >&2
    usage
    exit 1
    ;;
esac

reason=""
artifact_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reason)
      if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        echo "Missing value for --reason" >&2
        exit 1
      fi
      reason="$2"
      shift 2
      ;;
    --artifact-path)
      if [[ $# -lt 2 || -z "$2" || "$2" == -* ]]; then
        echo "Missing value for --artifact-path" >&2
        exit 1
      fi
      artifact_path="$(repo_relative_path "$2")" || exit 1
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

case "$status" in
  launch-failed|timeout|invalid-artifact|runtime-blocked)
    if [[ -z "$reason" ]]; then
      echo "$status requires --reason" >&2
      exit 1
    fi
    ;;
esac

dispatch_file=".local/loop/review-dispatch-${round_id}.json"
if [[ ! -f "$dispatch_file" ]]; then
  echo "Missing reviewer dispatch record: $dispatch_file" >&2
  exit 1
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
tmp_file="$(mktemp)"

if ! jq -e --arg slug "$dimension_slug" '
  (.reviewers | type == "array")
  and ([.reviewers[] | select((.dimension_slug // "") == $slug)] | length) == 1
' "$dispatch_file" >/dev/null; then
  echo "Dispatch record does not contain exactly one reviewer slot for: $dimension_slug" >&2
  rm -f "$tmp_file"
  exit 1
fi

if ! jq -e --arg slug "$dimension_slug" '
  (
    [
      .reviewers[]
      | select((.dimension_slug // "") == $slug)
      | (.last_status // "")
      | select(. == "runtime-blocked")
    ]
    | length
  ) == 0
' "$dispatch_file" >/dev/null; then
  echo "Reviewer slot is terminal after runtime-blocked: $dimension_slug" >&2
  rm -f "$tmp_file"
  exit 1
fi

case "$status" in
  artifact-written|launch-failed|timeout|invalid-artifact)
    if ! jq -e --arg slug "$dimension_slug" '
      (
        [
          .reviewers[]
          | select((.dimension_slug // "") == $slug)
          | (.last_status // "pending")
        ]
        | first
      ) == "launch-started"
    ' "$dispatch_file" >/dev/null; then
      echo "$status requires reviewer slot $dimension_slug to be in launch-started state first" >&2
      rm -f "$tmp_file"
      exit 1
    fi
    ;;
esac

jq \
  --arg slug "$dimension_slug" \
  --arg status "$status" \
  --arg reason "$reason" \
  --arg artifact_path "$artifact_path" \
  --arg recorded_at "$timestamp" \
  '
    .reviewers |= map(
      if .dimension_slug == $slug then
        .attempts += [
          ({
            status: $status,
            recorded_at: $recorded_at
          }
          + (if $reason == "" then {} else {reason: $reason} end)
          + (if $artifact_path == "" then {} else {artifact_path: $artifact_path} end))
        ]
        | .last_status = $status
        | .last_reason = $reason
        | .last_recorded_at = $recorded_at
        | .last_artifact_path = (
            if $artifact_path != "" then
              $artifact_path
            elif $status == "artifact-written" then
              .output_path
            else
              (.last_artifact_path // "")
            end
          )
      else
        .
      end
    )
  ' "$dispatch_file" > "$tmp_file"

mv "$tmp_file" "$dispatch_file"
printf '%s\n' "$dispatch_file"
