#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <base-branch> <title> <body-file> [--draft]" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required" >&2
  exit 1
fi

base_branch="$1"
title="$2"
body_file="$3"
draft_flag="${4:-}"

if [[ ! -f "$body_file" ]]; then
  echo "Missing body file: $body_file" >&2
  exit 1
fi

head_branch="$(git branch --show-current)"
if [[ -z "$head_branch" ]]; then
  echo "Unable to determine current branch" >&2
  exit 1
fi

if [[ "$head_branch" == "main" ]]; then
  echo "Refusing to publish from main; use a codex/* branch" >&2
  exit 1
fi

if [[ "$head_branch" != codex/* ]]; then
  echo "Refusing to publish from non-codex branch: $head_branch" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean; commit or stash changes before publish" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated" >&2
  exit 1
fi

if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push
else
  git push -u origin "$head_branch"
fi

existing_number="$(gh pr list --head "$head_branch" --state open --json number --jq '.[0].number')"

if [[ -n "${existing_number:-}" && "${existing_number:-null}" != "null" ]]; then
  gh pr edit "$existing_number" --base "$base_branch" --title "$title" --body-file "$body_file" >/dev/null
  pr_url="$(gh pr view "$existing_number" --json url --jq '.url')"
  echo "updated $pr_url"
  exit 0
fi

create_args=(--base "$base_branch" --head "$head_branch" --title "$title" --body-file "$body_file")
if [[ "$draft_flag" == "--draft" ]]; then
  create_args+=(--draft)
fi

pr_url="$(gh pr create "${create_args[@]}")"
echo "created $pr_url"
