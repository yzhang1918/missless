# Repository Standards

Status: Active

## Purpose

Define detailed operational standards for documentation, status semantics, review flow, and skill alignment.

## Authority

- `AGENTS.md` is the primary collaboration contract.
- This file provides detailed enforcement-level conventions.
- If a skill conflicts with `AGENTS.md` or this file, update the skill.

## Documentation Standards

- Write all docs in English.
- Keep docs concrete and concise.
- Keep each folder `index.md` updated when docs change.
- Avoid duplicating the same policy text across many files.

## Intake Standards

- Open backlog, asynchronous ideas, and community-reported work live in GitHub Issues for `yzhang1918/missless`.
- Only `state:accepted` issues are eligible to enter discovery and planning. `needs-triage`, `state:blocked`, and `state:parked` issues remain outside the execution queue until triage changes them.
- A direct human request may enter discovery without a pre-existing issue, but the resulting active plan must record its intake source.
- Once work has an active plan, the repository becomes the authoritative execution record for that task.
- Every backlog issue body must record its origin/provenance. At minimum, say whether it came from a direct idea, spawned follow-up, linked issue, plan, or PR, and link the source record when available.
- New backlog issues should default to `needs-triage`.
- Triage should assign exactly one `scope:*` label, exactly one `kind:*` label, and at most one `state:*` label.
- Supported `state:*` labels are `state:accepted`, `state:blocked`, and `state:parked`.
- Active execution is represented by a repository plan, not by a separate GitHub `state:active` label.

## Placement Standards

- Product intent/workflow -> `docs/product-specs/`
- Design rationale/tradeoffs -> `docs/design-docs/`
- Technical contracts -> `docs/specs/`
- Product tactical execution/progress tracking -> `docs/exec-plans/`
- Harness/process workflow tracking -> `docs/harness/`
- External distillations and terms -> `docs/references/`

## Status Standards

Use these statuses for docs:
- `Draft`: under discussion, not yet stable
- `Active`: current approved source of truth
- `Superseded`: replaced by a newer document

Clarification:
- Do not use `Completed` as a product/spec status.
- Completion is tracked in plan archives (`docs/exec-plans/*` for product, `docs/harness/*` for harness/process).

## Review and Merge Standards

For non-trivial work:
- run step-level delta review during execution
- run full review before final merge
- PRs must identify linked issue(s), or explicitly say `direct request (no issue)` when no intake issue exists. Use closing keywords only for issues that should close on merge.
- Do not close implementation issues as resolved before the merge result is known; after merge, verify auto-close happened or close them manually with the merge reference.
- review artifacts must separate `current_slice_findings`, `accepted_deferred_risks`, and `strategic_observations`
- resolve blocking/important findings before final gate
- only current-slice `BLOCKER` or `IMPORTANT` findings may block review/final gate; accepted deferred risks and strategic observations stay visible but non-blocking
- accepted deferred risks should link the accepted follow-up issue when available, or record an explicit defer reason when no issue exists yet
- convert unresolved follow-ups or debt into GitHub issues before closing the current plan
- keep completed-plan docs linked to any spawned or source issues
- keep tracked plan/PR evidence summary-first rather than treating local JSON paths as durable evidence
- record resolved findings in tracked docs only when they materially changed the shipped outcome

## Stateful Gate Standards

- Before stateful review, publish, final-gate, or land decisions, synchronize remote repository state first (`git fetch --prune origin` or stricter equivalent).
- Plans that intentionally carry known out-of-slice concerns should include a `## Accepted Deferred Risks` section with issue links or defer reasons so later review loops can distinguish accepted deferment from unresolved current-slice work.
- Repositories that use publish/final-gate must provide one explicit repository-readiness preflight entry point and reuse that same readiness contract inside both surfaces.
- Before publish/final-gate/land, the working tree must be clean so the evidence and decision point match the published `HEAD`.
- `loop-publish`, `loop-final-gate`, and `loop-land` must fail closed when they are given stale repository state, stale gate artifacts, or an incomplete plan record.
- Publish/final-gate/land must operate on an archived completed plan path under `docs/exec-plans/completed/` or `docs/harness/completed/`; a completed plan that still lives only in `active/` is not gate-ready.
- Publish/final-gate/land must also reject an archived plan when the same filename still exists under the matching `active/` folder, because that indicates archival drift rather than a true move.
- Repositories that use `loop-final-gate` must configure at least one required GitHub status check on the protected base branch; a PR with zero required checks is not gate-ready.
- Readiness preflight must fail closed for gate-critical blockers, including detached or non-`codex/*` branch state, stale base sync, missing required checks, and incompatible GitHub Actions policy.
- Plans intended for those stateful gate checks must keep a stable minimal structure:
  - `## Acceptance Criteria` with markdown checkboxes
  - `## Work Breakdown` with `### Step N` sections
  - one `- Status: pending|in_progress|completed|blocked` line per step
- Final-gate CI/status artifacts must be small machine-readable JSON directly consumable by `final_gate.sh`, and they must include the evaluated `head_sha`, `base_ref`, `base_sha`, required-check results, and docs/spec update status.
- After a passing final gate, retain exactly one latest local evidence bundle per plan under `.local/final-evidence/<plan-slug>/`, containing the promoted `review aggregate`, `ci-status`, and `final-gate` artifacts with stable filenames.
- That local bundle is only a convenience copy for inspection; the authoritative validation evidence and execution history remain the git-tracked plan/PR summary.
- Cleanup may remove ephemeral `.local/loop` artifacts, but it must not delete promoted bundles under `.local/final-evidence/`.
- Landing semantics are determined by the remote merge outcome; local worktree cleanup failures must be recorded as warnings rather than treated as merge failures.

## Skills Alignment Standards

- Skills under `.agents/skills/` are operational playbooks.
- Standards remain normative.
- Skills should be self-contained when practical: scripts used by a skill should live under that skill folder.
- Use `issue-triage` for recurring backlog triage, label cleanup, and cron-driven disposition work.
- Use `issue-create` when current work needs to open a new backlog issue or backfill issue provenance.
- When standards change, update affected skills in the same branch.
