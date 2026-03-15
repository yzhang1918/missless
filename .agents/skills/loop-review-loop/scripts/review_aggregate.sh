#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <round-id YYYYMMDD-HHMMSS> [<reviewer-json> ...]" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

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

repo_relative_path() {
  local input="$1"
  local abs_path
  local dir
  local base

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
      echo "Path is outside repository: $input" >&2
      return 1
      ;;
  esac
}

json_array_from_args() {
  if [[ $# -eq 0 ]]; then
    printf '[]\n'
    return 0
  fi

  printf '%s\n' "$@" | jq -R -s '
    split("\n")
    | map(select(length > 0))
  '
}

tracked_worktree_json() {
  git status --porcelain --untracked-files=no \
    | LC_ALL=C sort \
    | jq -R -s '
        split("\n")
        | map(select(length > 0))
      '
}

round_id="$1"
shift || true

# Enforce timestamp round IDs used by retention/cleanup logic.
if [[ ! "$round_id" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
  echo "Invalid round-id: expected format YYYYMMDD-HHMMSS" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
out_dir=".local/loop"
out_file="$out_dir/review-${round_id}.json"
manifest_file="$out_dir/review-launch-${round_id}.json"
mkdir -p "$out_dir"

if [[ ! -f "$manifest_file" ]]; then
  echo "Missing reviewer launch manifest: $manifest_file" >&2
  exit 1
fi

if ! jq -e --arg round_id "$round_id" '
  (.round_id == $round_id)
  and (.scope | type == "string")
  and (.baseline_repo_state | type == "object")
  and (.baseline_repo_state.head_sha | type == "string")
  and (.baseline_repo_state.tracked_worktree | type == "array")
  and all(.baseline_repo_state.tracked_worktree[]?; type == "string")
  and (.ownership_boundary | type == "object")
  and (.ownership_boundary.mode == "repo-observable")
  and (.ownership_boundary.declared_reviewer_output_paths_only == true)
  and (.ownership_boundary.observable_side_effect_checks | type == "array")
  and all(.ownership_boundary.observable_side_effect_checks[]?; type == "string")
  and (.ownership_boundary.detects_arbitrary_untracked_files == false)
  and (.ownership_boundary.detects_remote_side_effects == false)
  and (.allowed_output_paths | type == "array")
  and all(.allowed_output_paths[]?; type == "string")
  and (.reviewers | type == "array")
  and ((.reviewers | length) > 0)
  and all(.reviewers[]?;
    (.dimension | type == "string")
    and (.dimension_slug | type == "string")
    and (.output_path | type == "string")
    and (.prompt | type == "string")
  )
  and (
    ([.reviewers[] | .output_path] | unique | length)
    == (.reviewers | length)
  )
' "$manifest_file" >/dev/null; then
  echo "Invalid reviewer launch manifest: contract shape mismatch" >&2
  exit 1
fi

declare -a input_paths=()
declare -a duplicate_input_paths=()
declare -a actual_files=()

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing reviewer file: $file" >&2
    exit 1
  fi
  rel_path="$(repo_relative_path "$file")" || exit 1
  if contains_value "$rel_path" "${input_paths[@]-}"; then
    if ! contains_value "$rel_path" "${duplicate_input_paths[@]-}"; then
      duplicate_input_paths+=("$rel_path")
    fi
  else
    input_paths+=("$rel_path")
  fi
  if ! contains_value "$rel_path" "${actual_files[@]-}"; then
    actual_files+=("$rel_path")
  fi
done

while IFS= read -r -d '' file; do
  rel_path="$(repo_relative_path "$file")" || exit 1
  if ! contains_value "$rel_path" "${actual_files[@]-}"; then
    actual_files+=("$rel_path")
  fi
done < <(find "$out_dir" -maxdepth 1 -type f -name "review-${round_id}-*.json" -print0)

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/review-aggregate.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

declare -a wrapper_files=()
idx=0
for rel_path in "${actual_files[@]-}"; do
  [[ -n "$rel_path" ]] || continue
  abs_path="$repo_root/$rel_path"
  if [[ ! -f "$abs_path" ]]; then
    echo "Missing reviewer file: $rel_path" >&2
    exit 1
  fi
  base="$(basename "$rel_path")"
  if [[ "$base" == -* ]]; then
    echo "Invalid reviewer filename: $base" >&2
    exit 1
  fi
  if [[ ! "$base" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.json$ ]]; then
    echo "Invalid reviewer filename shape: $base" >&2
    exit 1
  fi

  wrapper_file="$tmp_dir/reviewer-${idx}.json"
  if ! jq -n \
    --arg artifact_path "$rel_path" \
    --slurpfile payload "$abs_path" \
    '
      {
        artifact_path: $artifact_path,
        payload: $payload[0]
      }
    ' > "$wrapper_file"; then
    echo "Invalid reviewer artifact JSON: $rel_path" >&2
    exit 1
  fi

  wrapper_files+=("$wrapper_file")
  idx=$((idx + 1))
done

if ((${#wrapper_files[@]} > 0)); then
  if ! jq -s -e '
    all(.[]; (.payload | type == "object"))
    and
    all(.[]; (.payload.scope | type == "string"))
    and
    all(.[]; (.payload.dimension | type == "string"))
    and
    all(.[]; (.payload.status | type == "string"))
    and
    all(.[]; ((.payload.findings // []) | type == "array"))
    and
    all(.[]; all((.payload.findings // [])[]?;
      (.severity | type == "string")
      and (
        .severity == "BLOCKER"
        or .severity == "IMPORTANT"
        or .severity == "MINOR"
        or .severity == "NIT"
      )
    ))
    and
    all(.[];
      if (.payload.producer // null) == null then
        true
      else
        (
          (.payload.producer | type == "object")
          and (.payload.producer.type | type == "string")
          and (
            if .payload.producer.type == "manual-fallback" then
              ((.payload.producer.reason | type == "string") and (.payload.producer.reason | length > 0))
            else
              true
            end
          )
        )
      end
    )
  ' -- "${wrapper_files[@]}" >/dev/null; then
    echo "Invalid reviewer artifact: findings[].severity must be BLOCKER/IMPORTANT/MINOR/NIT and manual-fallback artifacts must record a reason" >&2
    exit 1
  fi
fi

actual_bundle="$tmp_dir/actual-reviewers.json"
if ((${#wrapper_files[@]} == 0)); then
  printf '[]\n' > "$actual_bundle"
else
  jq -s '.' -- "${wrapper_files[@]}" > "$actual_bundle"
fi

duplicate_input_paths_json="$(json_array_from_args "${duplicate_input_paths[@]-}")"
current_head_sha="$(git rev-parse HEAD)"
current_tracked_worktree="$(tracked_worktree_json)"

jq -n \
  --slurpfile manifest "$manifest_file" \
  --slurpfile actual_bundle "$actual_bundle" \
  --arg round_id "$round_id" \
  --arg manifest_path "$manifest_file" \
  --arg current_head_sha "$current_head_sha" \
  --argjson current_tracked_worktree "$current_tracked_worktree" \
  --argjson duplicate_input_paths "$duplicate_input_paths_json" \
  '
    def expected_reviewers($manifest):
      ($manifest.reviewers // []);
    def expected_paths($manifest):
      [ expected_reviewers($manifest)[] | .output_path ];
    def artifact_for_path($actual; $path):
      ([ $actual[] | select(.artifact_path == $path) ] | first);
    def reviewer_records($manifest; $actual):
      [
        expected_reviewers($manifest)[] as $expected
        | (artifact_for_path($actual; $expected.output_path)) as $artifact
        | {
            dimension: $expected.dimension,
            dimension_slug: $expected.dimension_slug,
            output_path: $expected.output_path,
            status: (if $artifact == null then "missing" else ($artifact.payload.status // "unknown") end),
            summary: (if $artifact == null then "" else ($artifact.payload.summary // "") end),
            artifact_path: (if $artifact == null then null else $artifact.artifact_path end)
          }
          + (
            if $artifact != null and (($artifact.payload.producer // null) != null) then
              {producer: $artifact.payload.producer}
            else
              {}
            end
          )
      ];
    def missing_reviewers($manifest; $actual):
      [
        reviewer_records($manifest; $actual)[]
        | select(.artifact_path == null)
        | {
            dimension,
            output_path
          }
      ];
    def unexpected_outputs($manifest; $actual):
      [
        $actual[] as $artifact
        | select((expected_paths($manifest) | index($artifact.artifact_path)) == null)
        | {
            artifact_path: $artifact.artifact_path,
            dimension: ($artifact.payload.dimension // "unknown"),
            status: ($artifact.payload.status // "unknown")
          }
      ];
    def dimension_mismatches($manifest; $actual):
      [
        expected_reviewers($manifest)[] as $expected
        | (artifact_for_path($actual; $expected.output_path)) as $artifact
        | select($artifact != null and (($artifact.payload.dimension // "") != $expected.dimension))
        | {
            artifact_path: $artifact.artifact_path,
            expected_dimension: $expected.dimension,
            actual_dimension: ($artifact.payload.dimension // "")
          }
      ];
    def scope_mismatches($manifest; $actual):
      [
        expected_reviewers($manifest)[] as $expected
        | (artifact_for_path($actual; $expected.output_path)) as $artifact
        | select($artifact != null and (($artifact.payload.scope // "") != ($manifest.scope // "")))
        | {
            artifact_path: $artifact.artifact_path,
            expected_scope: ($manifest.scope // ""),
            actual_scope: ($artifact.payload.scope // "")
          }
      ];
    def recovery($manifest; $actual):
      [
        reviewer_records($manifest; $actual)[]
        | select((.producer.type // "") == "manual-fallback")
        | {
            dimension,
            artifact_path,
            type: .producer.type,
            reason: (.producer.reason // "")
          }
      ];
    def contract_violations($manifest; $actual):
      (
        [
          missing_reviewers($manifest; $actual)[]
          | {
              kind: "missing-reviewer",
              dimension,
              output_path,
              message: ("Missing reviewer artifact for " + .dimension)
            }
        ]
        + [
          unexpected_outputs($manifest; $actual)[]
          | {
              kind: "unexpected-output",
              artifact_path,
              message: ("Unexpected reviewer artifact path: " + .artifact_path)
            }
        ]
        + [
          $duplicate_input_paths[]
          | {
              kind: "duplicate-input",
              artifact_path: .,
              message: ("Duplicate reviewer artifact input: " + .)
            }
        ]
        + [
          dimension_mismatches($manifest; $actual)[]
          | {
              kind: "dimension-mismatch",
              artifact_path,
              expected_dimension,
              actual_dimension,
              message: ("Reviewer artifact dimension mismatch at " + .artifact_path)
            }
        ]
        + [
          scope_mismatches($manifest; $actual)[]
          | {
              kind: "scope-mismatch",
              artifact_path,
              expected_scope,
              actual_scope,
              message: ("Reviewer artifact scope mismatch at " + .artifact_path)
            }
        ]
        + (
          if ($manifest.baseline_repo_state.head_sha != $current_head_sha) then
            [
              {
                kind: "head-moved",
                baseline_head_sha: $manifest.baseline_repo_state.head_sha,
                current_head_sha: $current_head_sha,
                message: "HEAD moved after the reviewer manifest was prepared"
              }
            ]
          else
            []
          end
        )
        + (
          if ($manifest.baseline_repo_state.tracked_worktree != $current_tracked_worktree) then
            [
              {
                kind: "tracked-worktree-changed",
                baseline_tracked_worktree: $manifest.baseline_repo_state.tracked_worktree,
                current_tracked_worktree: $current_tracked_worktree,
                message: "Tracked worktree changed after the reviewer manifest was prepared"
              }
            ]
          else
            []
          end
        )
      );
    def incomplete_reviewers($manifest; $actual):
      ([ reviewer_records($manifest; $actual)[] | .status | select(. != "complete") ] | length);
    def important_or_blocker_findings($actual):
      ([ $actual[] | (.payload.findings // [])[] | select((.severity // "") == "BLOCKER" or (.severity // "") == "IMPORTANT") ] | length);

    $manifest[0] as $manifest
    | $actual_bundle[0] as $actual
    | {
        round_id: $round_id,
        scope: ($manifest.scope // "delta"),
        status: (
          if (incomplete_reviewers($manifest; $actual) > 0 or (contract_violations($manifest; $actual) | length) > 0)
          then "incomplete"
          else "complete"
          end
        ),
        reviewers: reviewer_records($manifest; $actual),
        unexpected_reviewers: unexpected_outputs($manifest; $actual),
        findings: [ $actual[] | (.payload.findings // [])[] ],
        counts: {
          blocker: ([ $actual[] | (.payload.findings // [])[] | select((.severity // "") == "BLOCKER") ] | length),
          important: ([ $actual[] | (.payload.findings // [])[] | select((.severity // "") == "IMPORTANT") ] | length),
          minor: ([ $actual[] | (.payload.findings // [])[] | select((.severity // "") == "MINOR") ] | length),
          nit: ([ $actual[] | (.payload.findings // [])[] | select((.severity // "") == "NIT") ] | length)
        },
        contract: {
          manifest_path: $manifest_path,
          status: (
            if (contract_violations($manifest; $actual) | length) > 0 then
              "violated"
            else
              "ok"
            end
          ),
          expected_reviewers: (expected_reviewers($manifest) | length),
          actual_reviewers: ([ reviewer_records($manifest; $actual)[] | select(.artifact_path != null) ] | length),
          allowed_output_paths: ($manifest.allowed_output_paths // expected_paths($manifest)),
          missing_reviewers: missing_reviewers($manifest; $actual),
          unexpected_outputs: unexpected_outputs($manifest; $actual),
          duplicate_input_paths: $duplicate_input_paths,
          dimension_mismatches: dimension_mismatches($manifest; $actual),
          scope_mismatches: scope_mismatches($manifest; $actual),
          recovery: recovery($manifest; $actual),
          violations: contract_violations($manifest; $actual),
          baseline_repo_state: $manifest.baseline_repo_state,
          current_repo_state: {
            head_sha: $current_head_sha,
            tracked_worktree: $current_tracked_worktree
          },
          head_moved: ($manifest.baseline_repo_state.head_sha != $current_head_sha),
          tracked_worktree_changed: ($manifest.baseline_repo_state.tracked_worktree != $current_tracked_worktree)
        },
        recommendation: (
          if (incomplete_reviewers($manifest; $actual) > 0 or important_or_blocker_findings($actual) > 0 or (contract_violations($manifest; $actual) | length) > 0)
          then "needs-fixes"
          else "ready"
          end
        ),
        updated_at: (now | todateiso8601)
      }
  ' > "$out_file"

echo "$out_file"
