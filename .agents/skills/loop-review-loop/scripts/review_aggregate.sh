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
dispatch_file="$out_dir/review-dispatch-${round_id}.json"
mkdir -p "$out_dir"

if [[ ! -f "$manifest_file" ]]; then
  echo "Missing reviewer launch manifest: $manifest_file" >&2
  exit 1
fi

if ! jq -e --arg round_id "$round_id" --arg dispatch_file "$dispatch_file" '
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
  and (.dispatch_record_path == $dispatch_file)
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

if [[ ! -f "$dispatch_file" ]]; then
  echo "Missing reviewer dispatch record: $dispatch_file" >&2
  exit 1
fi

if ! jq -e --arg round_id "$round_id" --arg manifest_path "$manifest_file" '
  def valid_status:
    . == "pending"
    or . == "launch-started"
    or . == "artifact-written"
    or . == "launch-failed"
    or . == "timeout"
    or . == "invalid-artifact"
    or . == "runtime-blocked";
  (.round_id == $round_id)
  and (.manifest_path == $manifest_path)
  and (.generated_at | type == "string")
  and (.reviewers | type == "array")
  and ((.reviewers | length) > 0)
  and all(.reviewers[]?;
    (.dimension | type == "string")
    and (.dimension_slug | type == "string")
    and (.output_path | type == "string")
    and (.last_status | type == "string")
    and (.last_status | valid_status)
    and (.last_reason | type == "string")
    and ((.last_recorded_at // null) == null or (.last_recorded_at | type == "string"))
    and (.last_artifact_path | type == "string")
    and (.attempts | type == "array")
    and all(.attempts[]?;
      (.status | type == "string")
      and (.status | valid_status)
      and (.recorded_at | type == "string")
      and ((.reason // "") | type == "string")
      and ((.artifact_path // "") | type == "string")
    )
  )
  and (([.reviewers[] | .dimension_slug] | unique | length) == (.reviewers | length))
  and (([.reviewers[] | .output_path] | unique | length) == (.reviewers | length))
' "$dispatch_file" >/dev/null; then
  echo "Invalid reviewer dispatch record: contract shape mismatch" >&2
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
    def valid_severity:
      . == "BLOCKER"
      or . == "IMPORTANT"
      or . == "MINOR"
      or . == "NIT";
    def has_valid_layered_fields:
      ((.current_slice_findings // null) != null)
      and ((.accepted_deferred_risks // null) != null)
      and ((.strategic_observations // null) != null)
      and (.current_slice_findings | type == "array")
      and (.accepted_deferred_risks | type == "array")
      and (.strategic_observations | type == "array");
    def current_slice_findings:
      (.current_slice_findings // []);
    def accepted_deferred_risks:
      (.accepted_deferred_risks // []);
    def strategic_observations:
      (.strategic_observations // []);
    def valid_current_slice_item:
      (.severity | type == "string")
      and (.severity | valid_severity);
    def valid_deferred_item:
      (.severity | type == "string")
      and (.severity | valid_severity)
      and ((.title // "") | type == "string")
      and ((.title // "") | length > 0)
      and ((.area // "") | type == "string")
      and ((.tracking_issue // "") | type == "string")
      and ((.accepted_reason // "") | type == "string")
      and (
        ((.tracking_issue // "") | length > 0)
        or ((.accepted_reason // "") | length > 0)
      );
    def valid_strategic_item:
      (.title | type == "string")
      and (.title | length > 0)
      and ((.area // "") | type == "string")
      and (.recommendation | type == "string")
      and (.recommendation | length > 0);
    all(.[]; (.payload | type == "object"))
    and
    all(.[]; (.payload.dimension | type == "string"))
    and
    all(.[]; (.payload.status | type == "string"))
    and
    all(.[]; ((.payload.summary // "") | type == "string"))
    and
    all(.[]; (.payload | has_valid_layered_fields))
    and
    all(.[]; all((.payload | current_slice_findings)[]?; valid_current_slice_item))
    and
    all(.[]; all((.payload | accepted_deferred_risks)[]?; valid_deferred_item))
    and
    all(.[]; all((.payload | strategic_observations)[]?; valid_strategic_item))
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
    echo "Invalid reviewer artifact: layered review fields must be complete and well-typed, accepted deferred risks must record title plus tracking_issue/accepted_reason, strategic observations must include recommendation, and manual-fallback artifacts must record a reason" >&2
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
  --slurpfile dispatch "$dispatch_file" \
  --slurpfile actual_bundle "$actual_bundle" \
  --arg round_id "$round_id" \
  --arg manifest_path "$manifest_file" \
  --arg dispatch_path "$dispatch_file" \
  --arg current_head_sha "$current_head_sha" \
  --argjson current_tracked_worktree "$current_tracked_worktree" \
  --argjson duplicate_input_paths "$duplicate_input_paths_json" \
  '
    def valid_severity:
      . == "BLOCKER"
      or . == "IMPORTANT"
      or . == "MINOR"
      or . == "NIT";
    def has_valid_layered_fields($payload):
      (($payload.current_slice_findings // null) != null)
      and (($payload.accepted_deferred_risks // null) != null)
      and (($payload.strategic_observations // null) != null)
      and ($payload.current_slice_findings | type == "array")
      and ($payload.accepted_deferred_risks | type == "array")
      and ($payload.strategic_observations | type == "array");
    def expected_reviewers($manifest):
      ($manifest.reviewers // []);
    def expected_paths($manifest):
      [ expected_reviewers($manifest)[] | .output_path ];
    def dispatch_reviewers($dispatch):
      ($dispatch.reviewers // []);
    def artifact_for_path($actual; $path):
      ([ $actual[] | select(.artifact_path == $path) ] | first);
    def dispatch_for_path($dispatch; $path):
      ([ dispatch_reviewers($dispatch)[] | select(.output_path == $path) ] | first);
    def current_slice_findings($payload):
      ($payload.current_slice_findings // []);
    def accepted_deferred_risks($payload):
      ($payload.accepted_deferred_risks // []);
    def strategic_observations($payload):
      ($payload.strategic_observations // []);
    def reviewer_records($manifest; $dispatch; $actual):
      [
        expected_reviewers($manifest)[] as $expected
        | (artifact_for_path($actual; $expected.output_path)) as $artifact
        | (dispatch_for_path($dispatch; $expected.output_path)) as $dispatch_record
        | {
            dimension: $expected.dimension,
            dimension_slug: $expected.dimension_slug,
            output_path: $expected.output_path,
            status: (if $artifact == null then "missing" else ($artifact.payload.status // "unknown") end),
            summary: (if $artifact == null then "" else ($artifact.payload.summary // "") end),
            artifact_path: (if $artifact == null then null else $artifact.artifact_path end),
            current_slice_count: (if $artifact == null then 0 else ([ current_slice_findings($artifact.payload)[] ] | length) end),
            accepted_deferred_risk_count: (if $artifact == null then 0 else ([ accepted_deferred_risks($artifact.payload)[] ] | length) end),
            strategic_observation_count: (if $artifact == null then 0 else ([ strategic_observations($artifact.payload)[] ] | length) end),
            dispatch_status: (if $dispatch_record == null then "missing" else ($dispatch_record.last_status // "unknown") end),
            dispatch_reason: (if $dispatch_record == null then "" else ($dispatch_record.last_reason // "") end),
            dispatch_attempt_count: (if $dispatch_record == null then 0 else ([ $dispatch_record.attempts[] ] | length) end)
          }
          + (
            if $artifact != null and (($artifact.payload.producer // null) != null) then
              {producer: $artifact.payload.producer}
            else
              {}
            end
          )
      ];
    def unexpected_dispatch_entries($manifest; $dispatch):
      [
        dispatch_reviewers($dispatch)[] as $record
        | select((expected_paths($manifest) | index($record.output_path)) == null)
        | {
            output_path: $record.output_path,
            dimension_slug: ($record.dimension_slug // "")
          }
      ];
    def missing_dispatch_entries($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[]
        | select(.dispatch_status == "missing")
        | {
            dimension,
            output_path
          }
      ];
    def missing_dispatch_attempts($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[]
        | select(.dispatch_status != "missing" and .dispatch_attempt_count == 0)
        | {
            dimension,
            output_path
          }
      ];
    def runtime_blocked_reviewers($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[]
        | select(.dispatch_status == "runtime-blocked")
        | {
            dimension,
            output_path,
            reason: .dispatch_reason
          }
      ];
    def runtime_blocked_not_terminal_reviewers($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[] as $record
        | (dispatch_for_path($dispatch; $record.output_path)) as $dispatch_record
        | select($dispatch_record != null)
        | ($dispatch_record.attempts // []) as $attempts
        | ([ $attempts | to_entries[] | select(.value.status == "runtime-blocked") | .key ] | first) as $runtime_blocked_index
        | select($runtime_blocked_index != null and $runtime_blocked_index < (($attempts | length) - 1))
        | {
            dimension: $record.dimension,
            output_path: $record.output_path,
            last_status: $record.dispatch_status
          }
      ];
    def has_valid_launch_sequence($dispatch_record):
      ($dispatch_record.attempts // []) as $attempts
      | all(range(0; ($attempts | length));
          . as $idx
          | ($attempts[$idx].status // "") as $status
          | if (
              $status == "launch-failed"
              or $status == "artifact-written"
              or $status == "timeout"
              or $status == "invalid-artifact"
            ) then
              ($idx > 0 and (($attempts[$idx - 1].status // "") == "launch-started"))
            else
              true
            end
        );
    def missing_launch_started_reviewers($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[] as $record
        | select(
            $record.dispatch_status == "launch-failed"
            or $record.dispatch_status == "artifact-written"
            or $record.dispatch_status == "timeout"
            or $record.dispatch_status == "invalid-artifact"
          )
        | (dispatch_for_path($dispatch; $record.output_path)) as $dispatch_record
        | select($dispatch_record != null and (has_valid_launch_sequence($dispatch_record) | not))
        | {
            dimension: $record.dimension,
            output_path: $record.output_path,
            dispatch_status: $record.dispatch_status
          }
      ];
    def invalid_dispatch_tail_statuses($dispatch):
      [
        dispatch_reviewers($dispatch)[] as $record
        | ($record.attempts // []) as $attempts
        | select(
            (($attempts | length) == 0 and (($record.last_status // "pending") != "pending"))
            or (($attempts | length) > 0 and (($attempts[-1].status // "") != ($record.last_status // "")))
          )
        | {
            dimension: ($record.dimension // ""),
            output_path: ($record.output_path // ""),
            last_status: ($record.last_status // "unknown")
          }
      ];
    def invalid_fallback_reviewers($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[]
        | select((.producer.type // "") == "manual-fallback")
        | select(.dispatch_status != "launch-failed" and .dispatch_status != "timeout" and .dispatch_status != "invalid-artifact")
        | {
            dimension,
            output_path,
            dispatch_status,
            reason: .dispatch_reason
          }
      ];
    def subagent_dispatch_mismatches($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[]
        | select(.artifact_path != null and (.producer.type // "") != "manual-fallback")
        | select(.dispatch_status != "artifact-written")
        | {
            dimension,
            output_path,
            dispatch_status
          }
      ];
    def missing_reviewers($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[]
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
            dimension: $expected.dimension,
            expected_scope: ($manifest.scope // ""),
            actual_scope: ($artifact.payload.scope // "")
          }
      ];
    def recovery($manifest; $dispatch; $actual):
      [
        reviewer_records($manifest; $dispatch; $actual)[]
        | select((.producer.type // "") == "manual-fallback")
        | {
            dimension,
            artifact_path,
            type: .producer.type,
            reason: (.producer.reason // "")
          }
      ];
    def contract_violations($manifest; $dispatch; $actual):
      (
        [
          missing_reviewers($manifest; $dispatch; $actual)[]
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
          missing_dispatch_entries($manifest; $dispatch; $actual)[]
          | {
              kind: "missing-dispatch-entry",
              dimension,
              output_path,
              message: ("Missing reviewer dispatch entry for " + .dimension)
            }
        ]
        + [
          missing_dispatch_attempts($manifest; $dispatch; $actual)[]
          | {
              kind: "missing-dispatch-attempt",
              dimension,
              output_path,
              message: ("Reviewer dispatch has no recorded subagent attempt for " + .dimension)
            }
        ]
        + [
          unexpected_dispatch_entries($manifest; $dispatch)[]
          | {
              kind: "unexpected-dispatch-entry",
              output_path,
              message: ("Unexpected reviewer dispatch entry for output path: " + .output_path)
            }
        ]
        + [
          invalid_dispatch_tail_statuses($dispatch)[]
          | {
              kind: "invalid-dispatch-tail-status",
              dimension,
              output_path,
              last_status,
              message: ("Reviewer dispatch tail status is inconsistent for " + .dimension)
            }
        ]
        + [
          runtime_blocked_reviewers($manifest; $dispatch; $actual)[]
          | {
              kind: "runtime-blocked",
              dimension,
              output_path,
              reason,
              message: ("Reviewer runtime was blocked for " + .dimension)
            }
        ]
        + [
          runtime_blocked_not_terminal_reviewers($manifest; $dispatch; $actual)[]
          | {
              kind: "runtime-blocked-not-terminal",
              dimension,
              output_path,
              last_status,
              message: ("Reviewer dispatch for " + .dimension + " recorded later events after runtime-blocked")
            }
        ]
        + [
          missing_launch_started_reviewers($manifest; $dispatch; $actual)[]
          | {
              kind: "missing-launch-start",
              dimension,
              output_path,
              dispatch_status,
              message: ("Reviewer dispatch for " + .dimension + " recorded " + .dispatch_status + " without a prior launch-started event")
            }
        ]
        + [
          invalid_fallback_reviewers($manifest; $dispatch; $actual)[]
          | {
              kind: "invalid-fallback-dispatch-status",
              dimension,
              output_path,
              dispatch_status,
              message: ("Manual fallback is not allowed for " + .dimension + " with dispatch status " + .dispatch_status)
            }
        ]
        + [
          subagent_dispatch_mismatches($manifest; $dispatch; $actual)[]
          | {
              kind: "dispatch-status-mismatch",
              dimension,
              output_path,
              dispatch_status,
              message: ("Reviewer artifact for " + .dimension + " did not record artifact-written in dispatch history")
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
              dimension,
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
    def incomplete_reviewers($manifest; $dispatch; $actual):
      ([ reviewer_records($manifest; $dispatch; $actual)[] | .status | select(. != "complete") ] | length);
    def blocking_current_slice_findings($actual):
      ([ $actual[] | current_slice_findings(.payload)[] | select((.severity // "") == "BLOCKER" or (.severity // "") == "IMPORTANT") ] | length);

    $manifest[0] as $manifest
    | $dispatch[0] as $dispatch
    | $actual_bundle[0] as $actual
    | {
        round_id: $round_id,
        scope: ($manifest.scope // "delta"),
        status: (
          if (incomplete_reviewers($manifest; $dispatch; $actual) > 0 or (contract_violations($manifest; $dispatch; $actual) | length) > 0)
          then "incomplete"
          else "complete"
          end
        ),
        reviewers: reviewer_records($manifest; $dispatch; $actual),
        unexpected_reviewers: unexpected_outputs($manifest; $actual),
        current_slice_findings: [ $actual[] | current_slice_findings(.payload)[] ],
        accepted_deferred_risks: [ $actual[] | accepted_deferred_risks(.payload)[] ],
        strategic_observations: [ $actual[] | strategic_observations(.payload)[] ],
        counts: {
          blocker: ([ $actual[] | current_slice_findings(.payload)[] | select((.severity // "") == "BLOCKER") ] | length),
          important: ([ $actual[] | current_slice_findings(.payload)[] | select((.severity // "") == "IMPORTANT") ] | length),
          minor: ([ $actual[] | current_slice_findings(.payload)[] | select((.severity // "") == "MINOR") ] | length),
          nit: ([ $actual[] | current_slice_findings(.payload)[] | select((.severity // "") == "NIT") ] | length),
          accepted_deferred_risks: ([ $actual[] | accepted_deferred_risks(.payload)[] ] | length),
          strategic_observations: ([ $actual[] | strategic_observations(.payload)[] ] | length)
        },
        contract: {
          manifest_path: $manifest_path,
          dispatch_path: $dispatch_path,
          status: (
            if (contract_violations($manifest; $dispatch; $actual) | length) > 0 then
              "violated"
            else
              "ok"
            end
          ),
          expected_reviewers: (expected_reviewers($manifest) | length),
          actual_reviewers: ([ reviewer_records($manifest; $dispatch; $actual)[] | select(.artifact_path != null) ] | length),
          allowed_output_paths: ($manifest.allowed_output_paths // expected_paths($manifest)),
          dispatch_reviewers: (dispatch_reviewers($dispatch) | length),
          missing_reviewers: missing_reviewers($manifest; $dispatch; $actual),
          missing_dispatch_entries: missing_dispatch_entries($manifest; $dispatch; $actual),
          missing_dispatch_attempts: missing_dispatch_attempts($manifest; $dispatch; $actual),
          unexpected_dispatch_entries: unexpected_dispatch_entries($manifest; $dispatch),
          invalid_dispatch_tail_statuses: invalid_dispatch_tail_statuses($dispatch),
          runtime_blocked_reviewers: runtime_blocked_reviewers($manifest; $dispatch; $actual),
          runtime_blocked_not_terminal_reviewers: runtime_blocked_not_terminal_reviewers($manifest; $dispatch; $actual),
          missing_launch_started_reviewers: missing_launch_started_reviewers($manifest; $dispatch; $actual),
          invalid_fallback_reviewers: invalid_fallback_reviewers($manifest; $dispatch; $actual),
          subagent_dispatch_mismatches: subagent_dispatch_mismatches($manifest; $dispatch; $actual),
          unexpected_outputs: unexpected_outputs($manifest; $actual),
          duplicate_input_paths: $duplicate_input_paths,
          dimension_mismatches: dimension_mismatches($manifest; $actual),
          scope_mismatches: scope_mismatches($manifest; $actual),
          recovery: recovery($manifest; $dispatch; $actual),
          violations: contract_violations($manifest; $dispatch; $actual),
          baseline_repo_state: $manifest.baseline_repo_state,
          current_repo_state: {
            head_sha: $current_head_sha,
            tracked_worktree: $current_tracked_worktree
          },
          head_moved: ($manifest.baseline_repo_state.head_sha != $current_head_sha),
          tracked_worktree_changed: ($manifest.baseline_repo_state.tracked_worktree != $current_tracked_worktree)
        },
        recommendation: (
          if (incomplete_reviewers($manifest; $dispatch; $actual) > 0 or blocking_current_slice_findings($actual) > 0 or (contract_violations($manifest; $dispatch; $actual) | length) > 0)
          then "needs-fixes"
          else "ready"
          end
        ),
        updated_at: (now | todateiso8601)
      }
  ' > "$out_file"

echo "$out_file"
