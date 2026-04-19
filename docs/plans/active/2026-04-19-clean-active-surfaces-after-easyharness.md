---
template_version: 0.2.0
created_at: "2026-04-19T16:19:00+08:00"
approved_at: "2026-04-19T16:21:25+08:00"
source_type: direct_request
source_refs: []
size: M
---

# Clean Active Surfaces After Easyharness Migration

## Goal

Remove the remaining repository-owned active surfaces that still present
`docs/plans` or old issue taxonomy as part of `missless`'s current operating
contract after the `easyharness` migration.

After this cleanup, active repository guidance should rely on `harness status`
and the managed harness workflow for plan navigation, while repo-local issue
helpers and live GitHub issues should stop classifying work with the retired
`scope:*` labels. Archived plans remain historical records and are not part of
this cleanup slice.

## Scope

### In Scope

- remove active doc references to `docs/plans/index.md` and delete that file
- update active repository guidance so it no longer presents a repo-owned plans
  index as part of the current navigation model
- remove CI checks that still treat archived plan catalog maintenance as an
  active repository contract
- simplify repo-local issue workflow guidance to use `needs-triage`,
  `kind:*`, and optional `state:*` labels without `scope:*`
- inspect live GitHub issues and migrate open issues off `scope:harness` and
  `scope:product`
- remove obsolete `scope:*` labels from the GitHub repository if they are no
  longer used after the issue migration

### Out of Scope

- editing archived plan bodies or archived-plan history wording
- changing the external `easyharness` repository or its managed workflow
  behavior
- redesigning the remaining `kind:*` or `state:*` label semantics beyond
  removing `scope:*`

## Acceptance Criteria

- [ ] `docs/plans/index.md` is removed, and active repository docs no longer
      point readers at a repo-owned plans index.
- [ ] Active guidance still explains that tracked plans live under
      `docs/plans/active/` when harness is working, but plan discovery happens
      through `harness status` rather than a repository navigation page.
- [ ] CI no longer enforces archived-plan catalog maintenance as part of the
      active repository contract.
- [ ] Repo-local issue creation/triage guidance no longer requires or mentions
      `scope:*` labels.
- [ ] All open GitHub issues are migrated off `scope:harness` and
      `scope:product`, and the obsolete repository labels are removed if they
      are unused.
- [ ] Validation demonstrates that active surfaces no longer reference
      `docs/plans/index.md` or `scope:*` taxonomy, while archived plans remain
      untouched.

## Deferred Items

- Any cleanup inside archived plans or archived-plan catalogs.
- Any broader redesign of backlog labels beyond removing `scope:*`.

## Work Breakdown

### Step 1: Remove repo-owned active plan navigation surfaces

- Done: [x]

#### Objective

Delete the active `docs/plans/index.md` navigation page and update the active
repository docs and checks so they no longer present plan/index maintenance as
part of `missless`'s own contract.

#### Details

Keep the harness-managed truth that active tracked plans live under
`docs/plans/active/`, but stop documenting a repository-owned plans landing
page or archived-plan catalog maintenance as a current navigation requirement.
This step should update only active docs and automation checks, not archived
plan history.

#### Expected Files

- `docs/plans/index.md` (removed)
- `AGENTS.md`
- `docs/index.md`
- `docs/design-docs/decision-log.md`
- `.github/workflows/harness-checks.yml`
- any other active file that still points at `docs/plans/index.md`

#### Validation

- `rg -n "docs/plans/index\\.md|Product Plans|Archived Plans Catalog|Active Plans Folder" AGENTS.md docs .github .agents/skills --glob '!docs/plans/archived/**'`
  shows only intentional remaining references, if any.
- A markdown-link check over active docs finds no broken local links after
  removing `docs/plans/index.md`.
- CI config no longer contains the archived-plan catalog sync job.

#### Execution Notes

Removed the repo-owned plans landing page by deleting `docs/plans/index.md`
and rewired the active guidance to use `harness status` plus
`docs/plans/active/` or `docs/plans/archived/` only when needed. Updated
`AGENTS.md`, `docs/index.md`, `docs/design-docs/decision-log.md`, and the
active harness CI workflow so this slice no longer treats plans-index
navigation or archived-plan catalog sync as part of the repository-owned
active contract.

TDD was not practical for this step because the change only affected active
documentation and CI contract wording rather than executable product behavior.
Validation used targeted active-surface searches, an active-doc markdown-link
check, and `git diff --check`.

#### Review Notes

NO_STEP_REVIEW_NEEDED: This step was a low-risk docs-and-CI navigation cleanup
with focused validation and a small anchor commit, so a separate reviewer round
would not add much signal beyond the direct checks already run.

### Step 2: Retire scope labels from repo issue workflow and live backlog

- Done: [ ]

#### Objective

Simplify the repo-local issue taxonomy by removing `scope:*` from helper
guidance and migrate the live GitHub backlog to match.

#### Details

This step should update issue-related skills and templates so new work no
longer depends on `scope:harness` or `scope:product`. It should also migrate
all currently open issues to the simplified taxonomy, preserving `kind:*`,
`state:*`, and `needs-triage` where applicable, then remove the obsolete
`scope:*` labels from GitHub if no issue still uses them.

#### Expected Files

- `.agents/skills/issue-create/SKILL.md`
- `.agents/skills/issue-triage/SKILL.md`
- `.github/ISSUE_TEMPLATE/backlog-intake.md`
- any other active issue-workflow doc or helper that still mentions `scope:*`

#### Validation

- `rg -n "scope:harness|scope:product|scope:\\*" AGENTS.md docs .github .agents/skills --glob '!docs/plans/archived/**'`
  shows no active-surface matches.
- `gh issue list --repo yzhang1918/missless --state open --limit 200 --json number,labels`
  shows no open issue still carrying `scope:*`.
- `gh label list --repo yzhang1918/missless --limit 200` no longer includes
  `scope:harness` or `scope:product`.

#### Execution Notes

PENDING_STEP_EXECUTION

#### Review Notes

PENDING_STEP_REVIEW

## Validation Strategy

- treat this as an active-surface contract cleanup rather than a product
  runtime change
- use targeted `rg` checks to ensure active docs, skills, and CI no longer
  point to `docs/plans/index.md` or `scope:*`
- run an active-doc markdown-link check after deleting the plans index
- use live GitHub queries to confirm open issues and repository labels match
  the simplified issue taxonomy
- run `git diff --check` before review

## Risks

- Risk: Removing the repo-owned plans index could also remove useful guidance
  about where harness stores tracked plans.
  - Mitigation: Keep that detail in active docs such as `AGENTS.md` while
    routing humans and agents to `harness status` for discovery.
- Risk: Live issue migration could accidentally strip labels that still carry
  meaning for open backlog items.
  - Mitigation: Remove only `scope:*`, preserve `kind:*`, `state:*`, and
    `needs-triage`, and verify the final open-issue label set directly from
    GitHub.

## Validation Summary

PENDING_UNTIL_ARCHIVE

## Review Summary

PENDING_UNTIL_ARCHIVE

## Archive Summary

PENDING_UNTIL_ARCHIVE

## Outcome Summary

### Delivered

PENDING_UNTIL_ARCHIVE

### Not Delivered

PENDING_UNTIL_ARCHIVE

### Follow-Up Issues

NONE
