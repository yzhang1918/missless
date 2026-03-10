# Issue-First Intake Migration

## Metadata

- Plan name: Issue-First Intake Migration
- Owner: Human+Codex
- Date opened: 2026-03-10
- Date completed: 2026-03-10
- Intake source: direct user request approved in discovery on 2026-03-10
- Work type: harness/process
- GitHub repository: `yzhang1918/missless`

## Objective

Replace the current tracker-first backlog model with an issue-first intake model that keeps GitHub Issues as the backlog and triage surface, while preserving the repository as the source of truth for discovery-approved execution plans, specs, validation evidence, and completed execution history.

## Scope

- In scope:
  - Define the issue-first intake lifecycle, including the direct-request exception for synchronous owner-driven work.
  - Update governing docs and workflow docs so they no longer instruct agents to start from repo trackers.
  - Add repository-native GitHub issue templates and label conventions for `needs-triage`, `scope:*`, `kind:*`, and `state:*`.
  - Update plan templates and completed-plan rules to use `intake source` and linked/spawned issues instead of tracker IDs.
  - Migrate the open tracker items currently on `main` into GitHub issues.
  - Remove the old tracker docs and update repository entry points to the new issue-first workflow.
- Out of scope:
  - Automating issue creation, label sync, or project sync beyond manual `gh issue` usage.
  - Implementing any migrated product or harness backlog item itself.
  - Rewriting completed plan history beyond the minimum wording needed to keep the new model coherent.

## Acceptance Criteria

- [x] `AGENTS.md`, `.agents/skills/AGENT_LOOP_WORKFLOW.md`, and standards/index docs define GitHub Issues as the backlog/intake surface and repo plans as the execution source of truth.
- [x] The documented issue lifecycle is stable and minimal: new issues default to `needs-triage`; triage resolves to `state:accepted`, `state:parked`, or `closed`; active execution is represented by a repo plan rather than a GitHub state label; blocking is represented by `state:blocked`.
- [x] Direct owner requests are explicitly allowed to enter `loop-discovery` without first creating an issue, and active plans must record `Intake source` for those runs.
- [x] `.github/ISSUE_TEMPLATE/` exists with a minimal generic intake template/config that supports rough capture without requiring full labels at creation time.
- [x] The open backlog currently recorded on `main` in `docs/harness/tracker.md` and `docs/exec-plans/tracker.md` is recreated as GitHub issues with triage-ready labels and recorded issue numbers.
- [x] `docs/harness/tracker.md` and `docs/exec-plans/tracker.md` are removed, and active repository docs no longer send agents to tracker files.

## Migration Inventory From `main`

### Harness Items To Recreate As Issues

| Current tracker ID | Title | Current source | Migrated issue |
| --- | --- | --- | --- |
| FUP-0001 | Add optional CI status exporter for final-gate input | `main:docs/harness/tracker.md` | `#9` |
| FUP-0002 | Add helper to spawn reviewer subagents by selected dimensions | `main:docs/harness/tracker.md` | `#10` |
| FUP-0004 | Make review-loop reviewer fallback fail closed and explicit | `main:docs/harness/tracker.md` | `#11` |
| FUP-0005 | Enforce plan completion and archival before publish and final gate | `main:docs/harness/tracker.md` | `#12` |
| FUP-0006 | Add rubric-based AI review for real E2E runs | `main:docs/harness/tracker.md` | `#13` |

### Product Items To Recreate As Issues

| Current tracker ID | Title | Current source | Migrated issue |
| --- | --- | --- | --- |
| FUP-0003 | Package missless as an installable skill plus stable runtime entrypoint | `main:docs/exec-plans/tracker.md` | `#14` |
| FUP-0004 | Add provider fallback strategy beyond the default Jina reader | `main:docs/exec-plans/tracker.md` | `#15` |
| FUP-0005 | Finish provider-boundary SSRF policy beyond initial resolved-host checks | `main:docs/exec-plans/tracker.md` | `#16` |
| DEBT-0001 | Re-evaluate document split policy after first delivery slice | `main:docs/exec-plans/tracker.md` | `#17` |

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define the new operating contract so issue-first intake, direct-request discovery, and repo-plan source-of-truth rules are explicit and non-conflicting.
- Expected files:
  - `AGENTS.md`
  - `.agents/skills/AGENT_LOOP_WORKFLOW.md`
  - `docs/standards/repository-standards.md`
  - `docs/index.md`
  - `docs/harness/index.md`
  - `docs/exec-plans/index.md`
  - `docs/harness/active/README.md`
- Validation commands:
  - `rg -n "tracker|GitHub Issues|needs-triage|Intake source|direct request" AGENTS.md .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md docs/index.md docs/harness/index.md docs/exec-plans/index.md docs/harness/active/README.md`
- Documentation impact:
  - Repository entry points and workflow rules stop telling agents to start from the tracker files.
- Exit criteria:
  - A new agent session can determine the intake path and execution truth without consulting obsolete tracker rules.
- Validation evidence:
  - Updated `AGENTS.md`, `.agents/skills/AGENT_LOOP_WORKFLOW.md`, `docs/standards/repository-standards.md`, `docs/index.md`, `docs/harness/index.md`, `docs/exec-plans/index.md`, `docs/harness/active/README.md`, and `docs/exec-plans/active/README.md`.
  - Ran `rg -n "tracker|GitHub Issues|needs-triage|Intake source|direct request" AGENTS.md .agents/skills/AGENT_LOOP_WORKFLOW.md docs/standards/repository-standards.md docs/index.md docs/harness/index.md docs/exec-plans/index.md docs/harness/active/README.md docs/exec-plans/active/README.md`.
  - Ran `git diff --check`.

### Step 2

- Status: completed
- Objective: Add the minimal GitHub issue scaffolding and plan/archive wording needed for the new lifecycle to work in both private-owner and future-public modes.
- Expected files:
  - `.github/ISSUE_TEMPLATE/config.yml`
  - `.github/ISSUE_TEMPLATE/backlog-intake.md`
  - `docs/exec-plans/templates/execution-plan-template.md`
  - `docs/harness/completed/README.md`
  - `docs/exec-plans/completed/README.md`
  - `docs/exec-plans/active/README.md`
- Validation commands:
  - `rg -n "needs-triage|scope:|kind:|state:accepted|state:blocked|state:parked|Intake source|spawned issues" .github docs/exec-plans/templates/execution-plan-template.md docs/harness/completed/README.md docs/exec-plans/completed/README.md docs/exec-plans/active/README.md`
- Documentation impact:
  - Issue intake becomes repository-legible and plan artifacts record issue links or direct-request origin consistently.
- Exit criteria:
  - A human or agent can create a rough issue from desktop or mobile without hidden label knowledge, and a plan can record its intake source without tracker IDs.
- Validation evidence:
  - Added `.github/ISSUE_TEMPLATE/config.yml` and `.github/ISSUE_TEMPLATE/backlog-intake.md`.
  - Updated `docs/standards/repository-standards.md`, `docs/exec-plans/templates/execution-plan-template.md`, `docs/harness/completed/README.md`, and `docs/exec-plans/completed/README.md`.
  - Ran `rg -n "needs-triage|scope:|kind:|state:accepted|state:blocked|state:parked|Intake source|spawned follow-up issues|Issue updates" .github docs/standards/repository-standards.md docs/exec-plans/templates/execution-plan-template.md docs/harness/completed/README.md docs/exec-plans/completed/README.md docs/exec-plans/active/README.md docs/harness/active/README.md`.
  - Ran `git diff --check`.

### Step 3

- Status: completed
- Objective: Migrate the current open tracker backlog from `main` into GitHub issues and remove the obsolete tracker docs from the active workflow.
- Expected files:
  - `docs/harness/tracker.md` (removed)
  - `docs/exec-plans/tracker.md` (removed)
  - Active repo docs from Step 1 or Step 2 if they need cleanup after tracker removal
- Validation commands:
  - `gh issue list --repo yzhang1918/missless --state open --limit 200`
  - `gh issue view <issue-number> --repo yzhang1918/missless`
  - `find docs -name 'tracker.md'`
- Documentation impact:
  - Intake starts from GitHub issues or direct owner requests rather than repository tracker files.
- Exit criteria:
  - Every open tracker item listed above has a corresponding open GitHub issue, and the obsolete tracker files are removed from the repository.
- Validation evidence:
  - Created labels `needs-triage`, `scope:*`, `kind:*`, and `state:*` in GitHub.
  - Created issues `#9` through `#17` to replace the open harness and product tracker backlog.
  - Removed `docs/harness/tracker.md` and `docs/exec-plans/tracker.md`.
  - Updated active docs and recent completed plans so they no longer depend on tracker files as live references.
  - Ran `gh issue list --repo yzhang1918/missless --state open --limit 200`.
  - Ran `find docs -name 'tracker.md'`.
  - Ran `git diff --check`.

## Review Cadence

- Run delta review after each completed step.
- Run full-change review once all steps are complete and the migrated issue inventory is filled in.

## Validation Plan

- Documentation and workflow checks:
  - `rg -n "needs-triage|state:accepted|state:blocked|state:parked|Intake source|spawned issues" AGENTS.md .agents/skills/AGENT_LOOP_WORKFLOW.md docs/index.md docs/harness/index.md docs/exec-plans/index.md docs/standards/repository-standards.md docs/exec-plans/templates/execution-plan-template.md docs/harness/completed/README.md docs/exec-plans/completed/README.md docs/exec-plans/active/README.md .github`
  - `find docs -name 'tracker.md'`
- GitHub issue migration checks:
  - `gh issue list --repo yzhang1918/missless --state open --limit 200`
  - Spot-check migrated issue bodies and labels for scope and kind.
- Repository hygiene:
  - `git diff --check`

## Risks and Mitigations

- Risk: Two truths remain during migration if tracker files are deleted before issue creation is complete.
  - Mitigation: Create and verify the migrated issues first, then delete the tracker files in the same change.
- Risk: Public issue intake becomes too rigid if templates demand internal classification from the reporter.
  - Mitigation: Default new issues to `needs-triage` and keep reporter-facing required fields minimal.
- Risk: Direct owner requests bypass issue intake and become hard to trace later.
  - Mitigation: Require each active plan to record `Intake source`, including `direct request` when no issue exists.

## Final Gate Conditions

- All acceptance criteria above are checked.
- Governing docs, plan templates, and completed-plan rules agree on the same intake lifecycle.
- All open backlog items from `main` listed in this plan have migrated issue numbers.
- Full review reports no unresolved blocking findings.

## Review Summary

- Full-PR review round `20260310-143423` initially blocked the change with `BLOCKER=0`, `IMPORTANT=4`.
- The blocked findings covered `loop-janitor` drift, stale migration-plan wording, completed-plan rule scope, and archival timing for the finished migration plan.
- Addressed those findings by updating `loop-janitor`, tightening the completed-plan README rules to apply only to plans created on or after `2026-03-10`, and moving this plan into `docs/harness/completed/` before publish.
- Full-PR review round `20260310-143745` passed with `BLOCKER=0`, `IMPORTANT=0`.
- Retained review artifact: `.local/loop/review-20260310-143745.json`.
- The `docs-spec-consistency` reviewer required a manual fallback artifact after two subagent timeouts; the fallback check found no remaining findings.

## Completion Summary

- Delivered:
  - Replaced repository tracker-first intake with an issue-first workflow documented across `AGENTS.md`, harness skills, standards, indexes, and plan templates.
  - Added a minimal GitHub backlog intake template plus issue label conventions for `needs-triage`, `scope:*`, `kind:*`, and `state:*`.
  - Recreated the open backlog as GitHub issues `#9` through `#17`.
  - Removed `docs/harness/tracker.md` and `docs/exec-plans/tracker.md`.
  - Updated recent completed plans and related references so live workflow docs no longer depend on tracker files.
- Not delivered:
  - No automation for issue creation, label sync, or project sync beyond manual `gh issue` usage.
  - No migrated backlog item implementation; this change only updates intake/process behavior.
- Linked issue updates:
  - Created and labeled issues `#9` through `#17` as the accepted open backlog.
- Spawned follow-up issues:
  - None.
