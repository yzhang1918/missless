---
template_version: 0.2.0
created_at: "2026-04-19T11:52:52+08:00"
approved_at: "2026-04-19T11:54:35+08:00"
source_type: direct_request
source_refs: []
size: XL
---

# Migrate Missless To Easyharness

<!-- If this plan uses supplements/<plan-stem>/, keep the markdown concise,
absorb any repository-facing normative content into formal tracked locations
before archive, and record archive-time supplement absorption in Archive
Summary or Outcome Summary. Lightweight plans should normally avoid
supplements. -->

## Goal

Adopt the new `easyharness` repository contract in `missless` so harness
workflow ownership no longer lives in this repository. After this migration,
`missless` should keep only a thin product-specific overlay: product source of
truth, product document navigation, and explicit expectations about updating
product docs when behavior changes.

Move product plan history from the old `docs/exec-plans/` layout into the new
`docs/plans/` layout with history-preserving normalization. Remove the old
repo-local harness workflow surface, including `docs/harness/` and the legacy
`loop-*` skills, so the repository no longer presents two competing workflow
systems.

## Scope

### In Scope

- keep the `easyharness`-managed `AGENTS.md` block and `harness-*` skills as
  the active workflow contract
- rewrite repository-owned docs so they describe `missless` product truth
  surfaces without redefining the harness plan lifecycle
- migrate tracked product plan history from `docs/exec-plans/` to
  `docs/plans/`
- normalize archived product plans with historical fidelity first, including
  navigation-critical path updates and index/catalog updates
- remove the old `docs/harness/` tree from `missless`
- remove the legacy repo-local `loop-*` skills that represented the old
  harness workflow
- update repository references that still point at the removed plan and
  harness locations when those references are part of active navigation or
  active source-of-truth docs

### Out of Scope

- redesigning GitHub issue intake, triage, labels, or issue-management skills
- changing `easyharness` itself or editing the external harness repository
- deeply rewriting historical archived plan narratives to match current prose
  style when a lighter normalization preserves the record
- non-migration product feature work

## Acceptance Criteria

- [x] `AGENTS.md` and active repository docs describe `missless` as an
      `easyharness`-managed product repository with only a thin product
      overlay.
- [x] The old repo-local harness workflow assets are removed from `missless`,
      including `docs/harness/` and legacy `loop-*` skills.
- [x] Product plans live under `docs/plans/`, and the old
      `docs/exec-plans/` layout is retired from active repository guidance.
- [x] Every archived product plan currently under `docs/exec-plans/completed/`
      is migrated into the new archived plan location with history-preserving
      normalization.
- [x] Navigation-critical references to product plan history and active product
      truth surfaces resolve through the new paths instead of the retired
      harness-era layout.
- [x] Repository-owned guidance still makes clear which product docs must be
      updated when behavior, UX intent, or architecture boundaries change.
- [x] Validation proves the new tracked plan package lints, the worktree has
      no broken migration leftovers in active guidance, and key path searches
      reflect the intended removals.

## Deferred Items

- GitHub issue intake, label semantics, and any cleanup of remaining
  `issue-*` skills or issue-management guidance.
- Any follow-up migration inside the external `easyharness` repository.

## Work Breakdown

### Step 1: Redefine the repository contract around easyharness

- Done: [x]

#### Objective

Rewrite the active repository guidance so `missless` clearly adopts
`easyharness` while keeping only product-specific rules that still belong in
this repository.

#### Details

Capture the discovery decisions directly in tracked docs: the old `loop-*`
workflow is retired, the product plan contract is owned by harness rather than
repo-local standards, and the repository should only keep product-specific
truth-surface guidance. This step should remove or rewrite old wording in
`AGENTS.md`, `ARCHITECTURE.md`, `docs/index.md`, and any active standards docs
that still describe the old harness split.

#### Expected Files

- `AGENTS.md`
- `ARCHITECTURE.md`
- `docs/index.md`
- `docs/standards/repository-standards.md`
- any other active repository doc that still defines the retired harness-era
  workflow as current truth

#### Validation

- Active repository docs consistently describe `easyharness` as the workflow
  owner and describe only the intended thin product overlay.
- `rg -n "loop-|docs/harness|docs/exec-plans"` across active guidance shows
  only intentional residual references after the rewrite.
- No behavior tests are required; validation is documentation- and
  contract-consistency focused.

#### Execution Notes

- Rewrote `AGENTS.md` into a thin `missless` product overlay above the
  `easyharness`-managed block.
- Updated `ARCHITECTURE.md`, `docs/index.md`, and
  `docs/standards/repository-standards.md` to point at `docs/plans/` and to
  stop defining a parallel repo-local harness workflow.
- Updated `docs/standards/index.md` so the standards surface now describes the
  slimmer, product-only repository standards.

#### Review Notes

NO_STEP_REVIEW_NEEDED: This migration changed the active repository contract,
plan-history layout, and retired-asset surface as one tightly coupled slice, so
step-level review would have created artificial boundaries. Review is deferred
to one finalize-stage full-candidate pass.

### Step 2: Migrate product plan history into docs/plans

- Done: [x]

#### Objective

Move product plan history out of the old `docs/exec-plans/` layout and into
the new `docs/plans/` structure without losing historical meaning.

#### Details

This step should create the minimal tracked product-plan navigation needed for
`missless`, move archived product plans into the archived plan location, and
normalize them with history-preserving edits. Use hybrid path cleanup: update
navigation-critical links, indexes, and path references that a reader needs to
follow today, while preserving purely historical prose where practical. Retire
the old repo-local execution-plan template instead of rehoming it as active
repository truth, because harness now owns the plan contract.

#### Expected Files

- `docs/plans/`
- `docs/plans/active/2026-04-19-migrate-missless-to-easyharness.md`
- `docs/plans/index.md`
- `docs/plans/archived/`
- migrated archived plan files from `docs/exec-plans/completed/`
- any archived-plan catalog/readme files needed in the new location
- removed or retired files under `docs/exec-plans/`

#### Validation

- Every archived product plan from the old completed folder exists under the
  new archived location.
- Catalog/index navigation for product plans points at `docs/plans/`.
- `rg -n "docs/exec-plans"` in active guidance and migrated plan indexes shows
  only intentional historical leftovers.
- A catalog-sync check is updated and passes if the new archived area keeps a
  catalog file.

#### Execution Notes

- Created `docs/plans/index.md` as the new product-plan entry point.
- Moved the archived product plans from `docs/exec-plans/completed/` into
  `docs/plans/archived/`.
- Reworked `docs/plans/archived/README.md` into the new archive catalog and
  updated the catalog sync command.
- Applied history-preserving path normalization to the archived plans and
  updated navigation-critical references in `docs/design-docs/decision-log.md`.

#### Review Notes

NO_STEP_REVIEW_NEEDED: The archived-plan migration was reviewed as part of the
same repository-wide migration candidate rather than as an isolated step,
because path rewrites and doc navigation depended on the surrounding contract
rewrite.

### Step 3: Remove the retired harness-era assets and references

- Done: [x]

#### Objective

Delete the old harness-specific repository assets so `missless` no longer
ships two competing workflow systems.

#### Details

Remove `docs/harness/` entirely and delete the legacy repo-local `loop-*`
skills that powered the old workflow. Update surviving references so active
repository guidance no longer points at removed harness assets. Keep issue work
out of scope unless a reference must be neutralized to avoid broken active
navigation.

#### Expected Files

- `docs/harness/` (removed)
- `.agents/skills/loop-discovery/` (removed)
- `.agents/skills/loop-plan/` (removed)
- `.agents/skills/loop-execute/` (removed)
- `.agents/skills/loop-review-loop/` (removed)
- `.agents/skills/loop-reviewer/` (removed)
- `.agents/skills/loop-final-gate/` (removed)
- `.agents/skills/loop-publish/` (removed)
- `.agents/skills/loop-land/` (removed)
- `.agents/skills/loop-janitor/` (removed)
- any active docs that still reference those removed assets

#### Validation

- `find .agents/skills -maxdepth 1 -type d | sort` shows the new
  `harness-*` skills but not the retired `loop-*` directories.
- `test ! -d docs/harness` passes.
- `rg -n "loop-(discovery|plan|execute|review-loop|reviewer|final-gate|publish|land|janitor)|docs/harness"` across active guidance shows only intentional historical references in archived records, if any.

#### Execution Notes

- Removed the retired `docs/exec-plans/` and `docs/harness/` trees from the
  working repository.
- Removed the old `AGENT_LOOP_WORKFLOW` file and the legacy `loop-*` skills and
  scripts.
- Removed the harness-only reference note from `docs/references/` and updated
  the surviving references index.
- Updated the surviving `commit` helper so it no longer points at the removed
  `loop-*` workflow names.

#### Review Notes

NO_STEP_REVIEW_NEEDED: Retired-asset deletion and surviving-reference cleanup
were reviewed as part of the same full migration candidate, because the value
of the deletion depends on the new product-only surfaces already being in
place.

### Step 4: Validate the one-shot migration package

- Done: [x]

#### Objective

Run the migration checks needed to prove the repository now presents one
coherent workflow and one coherent product-plan history layout.

#### Details

Use harness-aware validation for the new tracked plan plus repository-level
searches and diff hygiene checks for the migration. Validation should confirm
that the current migration plan is still lint-clean under the new layout,
documentation references no longer send readers to retired active surfaces, and
the final repository state is internally navigable.

#### Expected Files

- `docs/plans/active/2026-04-19-migrate-missless-to-easyharness.md`
- migrated docs and deleted legacy paths from prior steps

#### Validation

- `harness plan lint docs/plans/active/2026-04-19-migrate-missless-to-easyharness.md`
- `harness status`
- `git diff --check`
- targeted `rg` searches for retired paths and skill names in active guidance
- any catalog-sync command used for the archived plan area

#### Execution Notes

- Ran `harness plan lint docs/plans/active/2026-04-19-migrate-missless-to-easyharness.md`.
- Ran `git diff --check`.
- Ran the active-surface `rg` checks for retired harness-era paths and skill
  names, allowing only intentional mentions inside this active migration plan.
- Ran the archived-plan catalog sync check for `docs/plans/archived/README.md`.

#### Review Notes

NO_STEP_REVIEW_NEEDED: This step only collected repository-wide validation
evidence for the already-implemented migration. The candidate still requires a
finalize-stage full review before archive.

## Validation Strategy

- treat this as a repository-contract and documentation migration rather than a
  runtime feature change
- lint the tracked migration plan with `harness plan lint`
- use `harness status` to confirm the repository resolves the new tracked plan
  correctly during and after the migration
- use `git diff --check` to catch formatting drift
- use targeted `rg` searches to verify active guidance no longer points at the
  retired harness-era locations or `loop-*` skills, while allowing intentional
  historical mentions inside archived records when needed
- if a new archived-plan catalog is created, run its sync check so the archive
  index matches the migrated files

## Risks

- Risk: The migration could leave `missless` in a mixed state where
  `easyharness` is installed but active docs still tell future agents to use
  the retired local workflow.
  - Mitigation: Rewrite active repository guidance first, then use targeted
    `rg` checks across the active doc surface before considering the migration
    done.
- Risk: Archived product plans could lose historical context or gain broken
  links during the move from `docs/exec-plans/` to `docs/plans/`.
  - Mitigation: Use history-preserving normalization, keep prose changes
    minimal, and fix navigation-critical links plus catalogs as part of the
    migration.
- Risk: Removing the old harness assets could accidentally delete repository
  guidance that still matters for product work.
  - Mitigation: Keep a thin product overlay in `AGENTS.md` and active docs
    that explicitly states product truth surfaces and doc-sync expectations.

## Validation Summary

- `harness plan lint docs/plans/active/2026-04-19-migrate-missless-to-easyharness.md`
  passed before finalize review and again after the migration edits settled.
- `git diff --check` passed after the migration edits and again after the
  finalize-review repair for archived-plan path cleanup.
- Active-surface `rg` checks for `docs/exec-plans`, `docs/harness`,
  `loop-*`, `AGENT_LOOP_WORKFLOW`, and `harness-engineering-notes` showed no
  unintended surviving guidance outside the active migration plan itself.
- The archived-plan catalog sync check for `docs/plans/archived/README.md`
  reported no missing entries.
- Targeted archived-plan path checks after review repair found no remaining
  reader-facing `docs/harness` links or stale `docs/plans/active/` references
  in the repaired archived plans.

## Review Summary

- Finalize review round `review-001-full` requested changes with two important
  findings:
  - one archived plan still pointed at a removed active-path file
  - two archived plans still carried reader-facing references into removed
    `docs/harness` history
- Repaired those archive-surface issues and reran finalize review as
  `review-002-full`.
- Finalize review round `review-002-full` passed with no blocking or
  non-blocking findings.

## Archive Summary

- Archived At: 2026-04-19T12:07:50+08:00
- Revision: 1
- PR: pending publish after archive; no PR URL exists yet at archive-prep time.
- Ready: yes for archive closeout; finalize review is passing and the candidate
  is ready to move into publish/CI handoff after archival.
- Merge Handoff: archive the plan, commit the migration plus archive move, push
  the branch, open/update the PR, record publish/CI evidence, and then wait
  for explicit merge approval before using `harness-land`.

## Outcome Summary

### Delivered

- Adopted the `easyharness`-managed workflow contract in `missless`.
- Rewrote the active repository guidance so `missless` keeps only a thin
  product-specific overlay above the managed harness block.
- Migrated archived product plans from `docs/exec-plans/completed/` into
  `docs/plans/archived/` and created the new `docs/plans/index.md` entrypoint.
- Removed the retired `docs/harness/` tree, `docs/exec-plans/` tree,
  `AGENT_LOOP_WORKFLOW`, and the legacy `loop-*` skills and scripts.
- Removed the harness-only reference note and cleaned the remaining active
  helper/guide surfaces so they no longer point at the retired workflow.

### Not Delivered

- GitHub issue intake and label-semantic cleanup remained explicitly out of
  scope for this migration.
- No follow-up migration was made inside the external `easyharness`
  repository.

### Follow-Up Issues

- No follow-up issue was created in this slice.
- Deferred by explicit scope choice: future cleanup of GitHub issue intake,
  label semantics, and any remaining `issue-*` skill policy should be handled
  in a separate task.
