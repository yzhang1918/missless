# First URL-to-Review Package Slice

## Metadata

- Plan name: First URL-to-Review Package Slice
- Owner: Human+Codex
- Date opened: 2026-03-08
- Date completed: 2026-03-10
- Related tasks: TASK-0003
- Tracker IDs: TASK-0003, FUP-0003
- Consolidation note: This completed plan is the single durable record for TASK-0003. It replaces the earlier split between the initial implementation plan and later product-facing corrections by recording the whole branch as one task from first plan through final review-driven hardening.
- PR: [#8](https://github.com/yzhang1918/missless/pull/8)

## Objective

Deliver the first real `missless` slice as a product-facing, repository-coupled `v0`. Given one public URL, the system should create a run directory, fetch and normalize canonical text, let the current agent backend write `extraction_draft.json`, validate and anchor evidence, render a read-only HTML review package, and expose the whole flow through the product skill at `skills/missless/`.

## Scope

- In scope:
  - Bootstrap the pnpm-workspace monorepo layout for product code under `apps/`, `packages/`, and `skills/`.
  - Keep the first slice as `single-run URL -> review package`.
  - Support `URL only` input in this slice.
  - Use a deterministic runtime boundary for `fetch`, `validate`, `anchor`, `render`, artifact lifecycle, and contract help surfaces.
  - Keep runtime fail-closed on unsafe host/run inputs and unresolved evidence.
  - Let the agent write `extraction_draft.json` directly and have runtime validate/materialize it.
  - Generate knowledge-base-agnostic reading decisions: `deep_read|skim|skip`.
  - Produce `TLDR`, ordered claim-first atoms, quote-oriented evidence selectors, and optional compact self-check notes.
  - Render a read-only local HTML review package from run artifacts.
  - Make `skills/missless/` the product entrypoint and keep backend-specific behavior out of the product contract.
  - Add one repository-native live E2E path that closes the loop with AI review.
  - Record harness/process gaps exposed by this slice in harness docs and tracker follow-ups without treating them as product implementation work.
- Out of scope:
  - Open-ended product-level multi-turn sessions.
  - Knowledge-aware personalized decisions backed by a user knowledge base.
  - Persistence or commit of accepted atoms.
  - Database, BM25, vector search, or server-first architecture.
  - Web UI, Docker packaging, browser extension, or iOS implementation.
  - Auto-installers, binary packaging, or public `npx` distribution decisions.
  - New backend implementations beyond the currently available live-validation backend.
  - Harness code changes beyond documentation, workflow clarification, and tracker capture.

## Acceptance Criteria

- [x] The repository is bootstrapped as a pnpm workspace monorepo with product code separated from developer-only `.agents/` helpers.
- [x] `fetch-normalize <url>` creates a run directory with source metadata and a canonical normalized text snapshot.
- [x] The runtime defines and validates an `extraction_draft.json` contract that includes `tldr`, `decision`, `decision_reasons`, ordered claim-first `atom_candidates`, quote-oriented `evidence_selectors`, and optional compact `self_check`.
- [x] The first-slice decision taxonomy is `deep_read|skim|skip`, and repository docs explicitly state that these first-slice decisions are knowledge-base-agnostic.
- [x] The runtime CLI exposes a small deterministic help/contract surface that the skill can consult instead of depending on an oversized embedded prompt.
- [x] The agent writes `extraction_draft.json` directly, and runtime remains responsible for validation, evidence anchoring, and HTML review rendering.
- [x] The runtime rejects unsafe host/run inputs and remains fail-closed on unresolved evidence issues.
- [x] The primary product skill is `skills/missless/`, not `skills/missless-review/`.
- [x] Product docs no longer rely on `codex exec --output-schema` or other Codex-only features to explain the slice.
- [x] A repository-native live E2E script can drive the current backend through `URL -> artifacts -> AI review` without requiring human judgment to close the loop.
- [x] AI review is constrained to the current run artifacts rather than depending on unrelated repository docs or prior runs for contract inference.
- [x] `README.md`, `skills/README.md`, and `docs/product-specs/product-foundation.md` read as a coherent product-first story for the same slice.
- [x] The plan/tracker/archive state for TASK-0003 is truthful and consolidated as one completed task record.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Bootstrap the monorepo, lock the first-slice contracts, and align the core docs before runtime behavior grows.
- Key changes:
  - Bootstrap the `pnpm` workspace layout under `apps/`, `packages/`, and `skills/`.
  - Define the first runtime package boundaries and the `run_dir`-first execution model.
  - Lock the `extraction_draft.json` and first-slice decision contracts in product/design/spec docs.
  - Record the deferred knowledge-aware differentiator explicitly so it does not disappear behind the article-only slice.
- Expected files:
  - `pnpm-workspace.yaml`
  - `package.json`
  - `apps/cli/`
  - `packages/core/`
  - `packages/contracts/`
  - `packages/rendering/`
  - `skills/`
  - `docs/product-specs/product-foundation.md`
  - `docs/design-docs/system-design.md`
  - `docs/specs/pipeline-contracts.md`
  - `docs/exec-plans/tracker.md`
- Validation commands:
  - `pnpm install`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `rg -n "deep_read|skim|skip|knowledge-aware|review package|run directory|skills/" docs/product-specs/product-foundation.md docs/design-docs/system-design.md docs/specs/pipeline-contracts.md docs/exec-plans/tracker.md`
- Documentation impact:
  - Product/design/spec docs agree on the first-slice boundary before runtime code expands.
- Exit criteria:
  - The repo has stable package boundaries and a written contract for the first slice.

### Step 2

- Status: completed
- Objective: Implement deterministic ingestion and draft validation, then harden the runtime boundary where live review exposed unsafe edge cases.
- Key changes:
  - Implement `fetch-normalize` with a Jina-backed provider, run-directory creation, and canonical text snapshotting.
  - Implement `validate-draft` with schema checks, contract invariants, and summary-by-default plus `--json` diagnostics.
  - Ensure the default run-directory parent path exists on a fresh repository before writes.
  - Remove `packages/contracts/extraction-draft.codex-output-schema.json` from the product path.
  - Expose a small runtime-owned help/contract surface so the skill can query runtime behavior instead of duplicating it in prompt text.
  - Harden host safety checks by normalizing trailing DNS dots before localhost/private blocking logic runs.
  - Reject unsafe `runId` values so run artifacts cannot escape the configured runs directory.
- Expected files:
  - `apps/cli/src/index.ts`
  - `apps/cli/src/commands/fetch-normalize.ts`
  - `apps/cli/src/commands/validate-draft.ts`
  - `packages/core/src/source/fetch-normalize.ts`
  - `packages/core/src/providers/jina.ts`
  - `packages/core/src/diagnostics/`
  - `packages/contracts/`
  - `tests/unit/`
  - `tests/integration/`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `node apps/cli/dist/index.js --help`
  - `node apps/cli/dist/index.js fetch-normalize https://example.com --runs-dir .local/tmp/runs`
- Documentation impact:
  - Runtime contract docs reflect fail-closed ingestion, diagnostics, and runtime-owned help surfaces.
- Exit criteria:
  - Ingestion and validation work on real runs, and runtime hardening is absorbed into the same deterministic contract.

### Step 3

- Status: completed
- Objective: Implement evidence anchoring, review-bundle assembly, and read-only HTML rendering for the review package.
- Key changes:
  - Implement `anchor-evidence` to validate candidate selectors against canonical text and emit evidence artifacts.
  - Assemble the review bundle as runtime-derived artifacts rather than prompt-only output.
  - Render a read-only local HTML review page that shows the TLDR, decision, reasons, atoms, and highlighted evidence.
  - Keep the review surface read-only in this slice; editing remains deferred.
- Expected files:
  - `apps/cli/src/commands/anchor-evidence.ts`
  - `apps/cli/src/commands/render-review.ts`
  - `packages/core/src/evidence/`
  - `packages/rendering/src/`
  - `tests/unit/`
  - `tests/integration/`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
- Documentation impact:
  - The pipeline docs now describe evidence materialization and read-only review semantics as runtime behavior.
- Exit criteria:
  - The runtime can turn a valid draft into a review package with inspectable evidence.

### Step 4

- Status: completed
- Objective: Promote the product skill to `skills/missless/` and rewrite the user-facing docs so the slice reads as `missless`, not as a Codex-specific demo.
- Key changes:
  - Rename `skills/missless-review/` to `skills/missless/`.
  - Rewrite the skill to start from runtime help/contract discovery, then run the deterministic steps in order.
  - Keep the skill focused on `URL -> review package`; do not over-promise product-level follow-up support.
  - Let the agent write `extraction_draft.json` directly, then call `validate-draft`, `anchor-evidence`, and `render-review`.
  - Rewrite `README.md`, `skills/README.md`, and `docs/product-specs/product-foundation.md` so they explain one coherent product slice and keep the deferred knowledge-aware differentiator visible.
- Expected files:
  - `skills/missless/`
  - `README.md`
  - `skills/README.md`
  - `docs/product-specs/product-foundation.md`
  - `docs/design-docs/system-design.md`
  - `docs/specs/pipeline-contracts.md`
- Validation commands:
  - `rg -n "missless-review|output-schema|codex-output|\\.agents/skills" README.md skills/README.md skills/missless docs/product-specs/product-foundation.md docs/design-docs/system-design.md docs/specs/pipeline-contracts.md`
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
- Documentation impact:
  - The repo now presents a product-first entrypoint while keeping runtime/backend detail in design/spec docs.
- Exit criteria:
  - A new reader can understand what `missless` is and how this slice behaves without reading backend-specific prompting tricks first.

### Step 5

- Status: completed
- Objective: Make live validation repository-native and close the loop on the branch with AI review, truthful plan state, and archived records.
- Key changes:
  - Add a repository-native E2E script entrypoint that runs the current backend against a real URL and captures the resulting run artifacts.
  - Drive the deterministic runtime from the same flow: `fetch-normalize -> agent-authored draft -> validate-draft -> anchor-evidence -> render-review`.
  - Add an AI review stage that inspects the produced artifacts and records a pass/fail-style judgment plus evidence notes.
  - Keep AI review artifact-scoped so the reviewer judges the current run rather than reading unrelated repo docs or prior runs for context.
  - Record review-loop fallback behavior as evidence and harness follow-up rather than silent success.
  - Tighten live-E2E acceptance so the run fails when AI review returns `ok: false` or when required review artifacts are missing.
  - Keep `anchor-evidence` fail-closed even for nonexistent run directories by returning diagnostics instead of turning the failure into an uncaught filesystem error.
  - Update this plan's step statuses and acceptance checkboxes so they match the branch state.
  - Sync `docs/exec-plans/tracker.md` and `docs/harness/tracker.md` with any new follow-ups or debt discovered during implementation.
  - Archive TASK-0003 as one completed plan instead of leaving a baseline plan plus a later patch-up plan.
  - Re-run full-PR review and final gate only after plan state, docs, and validation evidence are current.
- Expected files:
  - `scripts/e2e/`
  - `docs/exec-plans/completed/2026-03-09-first-review-package-product-facing-v0.md`
  - `docs/exec-plans/completed/README.md`
  - `docs/harness/tracker.md`
  - `docs/harness/completed/2026-03-09-post-first-slice-loop-remediation.md`
  - `docs/exec-plans/tracker.md`
- Validation commands:
  - `git diff --check`
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - Full-PR review round artifact(s)
  - Final-gate artifact
- Documentation impact:
  - The branch narrative, live evidence, and tracker state now describe one finished task instead of two loosely-related plans.
- Exit criteria:
  - The branch is reviewable without hidden context, and TASK-0003 has one complete durable record.

## Validation Strategy

- Deterministic unit tests:
  - Cover runtime-owned logic with fixtures and mocks only.
  - Prioritize ingestion safety, run-directory creation, diagnostics shaping, selector matching, and HTML review generation.
- Deterministic integration tests:
  - Exercise CLI boundaries and fixture-backed run directories.
  - Verify that validation/render stages are safe to rerun.
  - Verify failure paths remain fail-closed.
- Live E2E:
  - Use a repository-native script as the single entrypoint for live validation.
  - The script may use the currently available backend under the hood, but the product contract must remain backend-neutral.
  - Capture one real run against a real public URL as branch evidence.
- AI review:
  - Use AI review to judge the produced review package and close the loop.
  - Do not rely on human judgment as the official E2E verdict for this slice.
  - If reviewer output is missing, retry or fallback and record the reason.
  - Keep reviewer context constrained to the current run artifacts unless the harness explicitly records a fallback reason.
- Out-of-scope for this slice:
  - Broad rubric-based AI review automation remains a backlog item.

## Review Cadence

- Run delta review after each implementation step.
- Resolve blocking and important findings before moving to the next major step when practical.
- Run one full-PR review before final gate.
- Treat missing reviewer output as an explicit review-loop event that must be handled and recorded, not as silent success.

## Final Gate Conditions

- All acceptance criteria are checked.
- Deterministic tests pass locally.
- One repository-native real E2E run has been captured.
- One AI review result exists for that E2E run.
- Product, design, and spec docs agree on the slice boundary and entrypoint.
- Product and harness trackers match the repository state.

## Risks and Mitigations

- Risk: The branch remains optimized for one backend instead of the product contract.
  - Mitigation: Keep backend-specific behavior behind the live-validation script and out of the product-facing contract.
- Risk: The skill becomes another oversized prompt that duplicates runtime rules.
  - Mitigation: Move stable constraints into runtime help/contract surfaces and repo docs, then keep the skill short.
- Risk: Real-E2E validation drifts into ad-hoc manual work again.
  - Mitigation: Give the repository one script entrypoint and require AI review evidence.
- Risk: Harness/process issues get ignored because product work is urgent.
  - Mitigation: Record the observed gaps in a harness completed follow-up-capture document and tracker follow-ups in this same branch.

## Completion Evidence

- Final repository-native live E2E:
  - Session root: `.local/e2e/20260309T150137Z`
  - Run directory: `.local/e2e/20260309T150137Z/runs/run-20260309T150138Z-a5c6ed21`
  - AI review: `.local/e2e/20260309T150137Z/runs/run-20260309T150138Z-a5c6ed21/ai_review.json`
- Notable live-validation result:
  - The final E2E exercised the repair loop: the first draft failed `validate-draft --json` on missing selector context, the agent repaired the draft in-place, and the same run then passed `validate-draft`, `anchor-evidence`, `render-review`, and AI review.
- Full-PR review artifact:
  - `.local/loop/review-20260309-150816.json`
- Final-gate artifact:
  - `.local/loop/final-gate-20260309-151010.json`
- Review-loop note:
  - Subagent orchestration in the desktop session was unstable, so the round finished through explicit fallback reviewer artifacts rather than silent abandonment. That failure mode is captured in `docs/harness/completed/2026-03-09-post-first-slice-loop-remediation.md`.
- Open follow-up/debt IDs:
  - FUP-0003
  - FUP-0004
