# Decision Log

Status: Active

Use this file to record high-impact design decisions and reversals.

## Entry Template

- Date:
- Decision:
- Context:
- Options considered:
- Chosen option:
- Consequences:
- Related docs:

## Entries

- Date: 2026-03-03
- Decision: Repository documentation is established before implementation code.
- Context: The project starts from an empty repository and must support long-term agent-first delivery.
- Options considered: code-first bootstrap, docs-first bootstrap.
- Chosen option: docs-first bootstrap.
- Consequences: slower first commit, better long-term legibility and execution consistency.
- Related docs: `AGENTS.md`, `ARCHITECTURE.md`, `docs/index.md`

- Date: 2026-03-05
- Decision: Separate semantic extraction from evidence anchoring in the baseline flow.
- Context: Full-content understanding should not depend on pre-cut segments.
- Options considered: segment-first extraction, extraction-first then evidence anchoring.
- Chosen option: extraction-first then evidence anchoring.
- Consequences: clearer stage boundaries and better support for different evidence storage profiles.
- Related docs: `docs/design-docs/system-design.md`, `docs/specs/pipeline-contracts.md`

- Date: 2026-03-05
- Decision: Use a compact initial documentation layout and split later by explicit triggers.
- Context: Early repository had too many narrow files for the current discussion stage.
- Options considered: many specialized docs, compact foundation docs with split policy.
- Chosen option: compact foundation docs with split policy.
- Consequences: easier navigation now, controlled growth later.
- Related docs: `docs/product-specs/index.md`, `AGENTS.md`, `docs/standards/repository-standards.md`

- Date: 2026-03-06
- Decision: Use first-class `Segment` objects as the text-source evidence contract for the first delivery slice.
- Context: Evidence needed to stay reusable and auditable without forcing ingest-time pre-segmentation or relying on external webpages for stable highlighting.
- Options considered: embedded-only anchors, optional/hybrid materialization profiles, first-class runtime-materialized `Segment` objects.
- Chosen option: extraction agents propose candidate evidence, runtime validates and materializes reusable `Segment` objects using validated text locators.
- Consequences: text evidence identity is owned by runtime; the first slice depends on canonical stored source text and an internal evidence-reading surface; refresh/versioning and non-text locator variants stay deferred.
- Related docs: `docs/design-docs/system-design.md`, `docs/specs/core-data-model.md`, `docs/specs/pipeline-contracts.md`, `docs/product-specs/product-foundation.md`

- Date: 2026-03-09
- Decision: Supersede the planned first-slice `Segment` materialization with runtime-validated anchored evidence records in run artifacts.
- Context: TASK-0003 shipped a review-package-first runtime that stops before persistence and emits `evidence_result.json` plus `review_bundle.json` rather than reusable graph nodes.
- Options considered: implement Segment persistence in the first runtime slice, keep the shipped runtime contract aligned with emitted anchored evidence artifacts.
- Chosen option: the shipped first slice treats anchored evidence in run artifacts as the authoritative contract; reusable `Segment` identities remain deferred to a later persistence layer.
- Consequences: current docs/specs must describe atom-local anchored evidence as the live contract, while older Segment-oriented plans remain historical design history rather than current repository truth.
- Related docs: `docs/design-docs/system-design.md`, `docs/specs/core-data-model.md`, `docs/specs/pipeline-contracts.md`, `docs/plans/archived/2026-03-09-first-review-package-product-facing-v0.md`

- Date: 2026-04-19
- Decision: Remove repository-owned active plan navigation and scope-based issue taxonomy after the `easyharness` migration.
- Context: The migration to `easyharness` moved plan discovery and execution flow ownership into the managed harness contract, but active repo surfaces still exposed a repo-owned plans landing page, archived-plan catalog enforcement in CI, and a scope-based GitHub issue taxonomy.
- Options considered: keep a thin repo-owned plans entrypoint and workflow-vs-product scope labels as local navigation aids, rely on `harness status` plus `docs/plans/` storage paths and simplify backlog labels to `needs-triage`, `kind:*`, and optional `state:*`.
- Chosen option: remove the repo-owned plans navigation surface, stop treating archived-plan catalog sync as active CI contract, and retire the scope-based issue taxonomy from repo guidance and GitHub labels.
- Consequences: active repository guidance now discovers plan state through `harness status`, while `docs/plans/active/` and `docs/plans/archived/` remain storage locations rather than a repo-owned navigation product. GitHub backlog labels are simpler and no longer split workflow work from product work with a local scope taxonomy.
- Related docs: `AGENTS.md`, `docs/index.md`, `.github/workflows/harness-checks.yml`, `.agents/skills/issue-create/SKILL.md`, `.agents/skills/issue-triage/SKILL.md`
