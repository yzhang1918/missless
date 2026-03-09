#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
URL="${1:-}"
BACKEND="${MISSLESS_AGENT_BACKEND:-codex}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SESSION_ROOT="$ROOT_DIR/.local/e2e/$STAMP"
RUNS_DIR="$SESSION_ROOT/runs"
LOGS_DIR="$SESSION_ROOT/logs"
RUN_PROMPT="$SESSION_ROOT/review_prompt.md"
FETCH_LOG="$LOGS_DIR/fetch-normalize.log"

if [[ -z "$URL" ]]; then
  echo "Usage: scripts/e2e/run_missless_review.sh <public-url>" >&2
  exit 64
fi

mkdir -p "$RUNS_DIR" "$LOGS_DIR"

run_backend_prompt() {
  local prompt_file="$1"
  local last_message_file="$2"
  local jsonl_file="$3"

  case "$BACKEND" in
    codex)
      set +e
      codex exec \
        --ephemeral \
        --full-auto \
        --json \
        -C "$ROOT_DIR" \
        -o "$last_message_file" \
        - < "$prompt_file" | tee "$jsonl_file"
      local exit_code=${PIPESTATUS[0]}
      set -e
      return "$exit_code"
      ;;
    *)
      echo "Unsupported MISSLESS_AGENT_BACKEND: $BACKEND" >&2
      return 64
      ;;
  esac
}

write_status_file() {
  local output_file="$1"
  local phase="$2"
  local attempt="$3"
  local exit_code="$4"
  local artifact_file="$5"
  local log_file="$6"
  local last_message_file="$7"
  local note="$8"

  node - "$output_file" "$phase" "$attempt" "$exit_code" "$artifact_file" "$log_file" "$last_message_file" "$note" <<'EOF'
const fs = require("node:fs");

const [
  outputFile,
  phase,
  attempt,
  exitCode,
  artifactFile,
  logFile,
  lastMessageFile,
  note
] = process.argv.slice(2);

const payload = {
  phase,
  attempt,
  exit_code: Number(exitCode),
  artifact_path: artifactFile,
  artifact_exists: fs.existsSync(artifactFile),
  log_path: logFile,
  last_message_path: lastMessageFile,
  note
};

fs.writeFileSync(outputFile, JSON.stringify(payload, null, 2) + "\n", "utf8");
EOF
}

validate_ai_review_file() {
  local file_path="$1"

  node - "$file_path" <<'EOF'
const fs = require("node:fs");

const [filePath] = process.argv.slice(2);
const payload = JSON.parse(fs.readFileSync(filePath, "utf8"));

if (typeof payload !== "object" || payload === null) {
  throw new Error("AI review must be a JSON object");
}

if (typeof payload.ok !== "boolean") {
  throw new Error("AI review must include boolean ok");
}

if (typeof payload.summary !== "string" || payload.summary.length === 0) {
  throw new Error("AI review must include non-empty summary");
}

if (!Array.isArray(payload.findings)) {
  throw new Error("AI review must include findings[]");
}

if (typeof payload.reviewer_backend !== "string" || payload.reviewer_backend.length === 0) {
  throw new Error("AI review must include non-empty reviewer_backend");
}

if (!Array.isArray(payload.reviewed_artifacts) || payload.reviewed_artifacts.length === 0) {
  throw new Error("AI review must include reviewed_artifacts[]");
}
EOF
}

pnpm -r build

set +e
FETCH_OUTPUT="$(
  node apps/cli/dist/index.js fetch-normalize "$URL" --runs-dir "$RUNS_DIR" 2>&1 | tee "$FETCH_LOG"
)"
FETCH_EXIT=$?
set -e

if [[ $FETCH_EXIT -ne 0 ]]; then
  echo "fetch-normalize failed. See $FETCH_LOG" >&2
  exit 1
fi

RUN_DIR="$(
  printf '%s\n' "$FETCH_OUTPUT" |
    awk -F': ' '/^Created run directory: / {print $2}' |
    tail -n 1
)"

if [[ -z "$RUN_DIR" ]]; then
  echo "Could not parse run directory from fetch-normalize output." >&2
  exit 1
fi

cat > "$RUN_PROMPT" <<EOF
Use the repository skill at 'skills/missless/SKILL.md' to finish a missless review package for this public URL:

$URL

A run directory has already been created for this URL:

'$RUN_DIR'

Requirements:
- Use the runtime-owned contract surface first:
  - 'node apps/cli/dist/index.js --help'
  - 'node apps/cli/dist/index.js print-draft-contract'
- Resume from the existing run_dir; do not create a second run.
- Read '$RUN_DIR/canonical_text.md'.
- Before the first validate-draft attempt, do not inspect older runs,
  runtime source code, or tests.
- Write only '$RUN_DIR/extraction_draft.json' as the agent-authored artifact.
- Write the first draft directly after reading the skill, review guidance, CLI
  help, draft contract, and canonical_text.md.
- Finish only after these commands succeed for the same run:
  - 'validate-draft --run-dir $RUN_DIR'
  - 'anchor-evidence --run-dir $RUN_DIR'
  - 'render-review --run-dir $RUN_DIR'
- Do not use '--output-schema'.
- Reply briefly with the decision, the run directory, and the review.html path.
EOF

if ! run_backend_prompt \
  "$RUN_PROMPT" \
  "$LOGS_DIR/review-last-message.md" \
  "$LOGS_DIR/review-session.jsonl"; then
  echo "Live review generation failed. See $LOGS_DIR/review-session.jsonl" >&2
  exit 1
fi

AI_REVIEW_FILE="$RUN_DIR/ai_review.json"
AI_REVIEW_CONTEXT="$RUN_DIR/ai_review_context.json"
SELECTED_ATTEMPT=""

run_ai_review_attempt() {
  local attempt="$1"
  local note="$2"
  local prompt_file="$SESSION_ROOT/ai_review_${attempt}_prompt.md"
  local last_message_file="$LOGS_DIR/ai-review-${attempt}-last-message.md"
  local jsonl_file="$LOGS_DIR/ai-review-${attempt}.jsonl"
  local status_file="$RUN_DIR/ai_review_${attempt}_status.json"

  cat > "$prompt_file" <<EOF
Review the missless run artifacts in '$RUN_DIR'.

Goals:
- Judge whether this run satisfies the first-slice contract.
- Use the artifacts as the source of truth:
  - 'review_bundle.json'
  - 'evidence_result.json'
  - 'review.html'
  - 'canonical_text.md'
- The contract shape is fully specified here; do not inspect repository docs,
  source files, tests, other runs, or prior ai_review artifacts for guidance.
- Write '$AI_REVIEW_FILE' as JSON with:
  - 'ok': boolean
  - 'summary': short string
  - 'findings': array of short strings
  - 'reviewer_backend': string
  - 'reviewed_artifacts': array of artifact file names
- Do not modify repository source files.
- Note for this attempt: $note
EOF

  if run_backend_prompt "$prompt_file" "$last_message_file" "$jsonl_file"; then
    if [[ -f "$AI_REVIEW_FILE" ]] && validate_ai_review_file "$AI_REVIEW_FILE"; then
      write_status_file \
        "$status_file" \
        "ai_review" \
        "$attempt" \
        "0" \
        "$AI_REVIEW_FILE" \
        "$jsonl_file" \
        "$last_message_file" \
        "$note"
      SELECTED_ATTEMPT="$attempt"
      return 0
    fi

    write_status_file \
      "$status_file" \
      "ai_review" \
      "$attempt" \
      "0" \
      "$AI_REVIEW_FILE" \
      "$jsonl_file" \
      "$last_message_file" \
      "Backend exited successfully but did not produce a valid ai_review.json. $note"
    return 1
  else
    local backend_exit_code=$?

    write_status_file \
      "$status_file" \
      "ai_review" \
      "$attempt" \
      "$backend_exit_code" \
      "$AI_REVIEW_FILE" \
      "$jsonl_file" \
      "$last_message_file" \
      "$note"
    return 1
  fi
}

if ! run_ai_review_attempt "primary" "Primary AI review attempt."; then
  run_ai_review_attempt \
    "fallback" \
    "Fallback AI review attempt after the primary reviewer failed or did not write a valid artifact." || true
fi

if [[ -z "$SELECTED_ATTEMPT" ]]; then
  echo "AI review did not produce a valid artifact. See $RUN_DIR/ai_review_*_status.json" >&2
  exit 1
fi

node - "$AI_REVIEW_CONTEXT" "$BACKEND" "$SELECTED_ATTEMPT" <<'EOF'
const fs = require("node:fs");

const [outputFile, backend, selectedAttempt] = process.argv.slice(2);

fs.writeFileSync(
  outputFile,
  JSON.stringify(
    {
      backend,
      selected_attempt: selectedAttempt
    },
    null,
    2
  ) + "\n",
  "utf8"
);
EOF

echo "Session root: $SESSION_ROOT"
echo "Run directory: $RUN_DIR"
echo "AI review: $AI_REVIEW_FILE"
