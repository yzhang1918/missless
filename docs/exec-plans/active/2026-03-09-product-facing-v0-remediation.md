# Product-Facing v0 Remediation for PR #8

## Metadata

- Plan name: Product-Facing v0 Remediation for PR #8
- Owner: Human+Codex
- Date: 2026-03-09
- Related tasks: TASK-0003
- Tracker IDs: TASK-0003
- Baseline implementation plan: `docs/exec-plans/active/2026-03-08-first-review-package-slice.md`
- PR: [#8](https://github.com/yzhang1918/missless/pull/8)

## Objective

Refit the existing first slice into a user-facing `missless v0` without expanding scope. The branch should keep the same product boundary, but the product story, skill entrypoint, runtime contract, and validation loop must become agent-agnostic and product-first rather than Codex-specific implementation notes.

## Scope

- In scope:
  - Resolve the two open GitHub review comments on `fetch-normalize`.
  - Keep the first slice as `single-run URL -> review package`.
  - Reframe product docs and skill docs around `missless` as the primary user entrypoint.
  - Remove `codex-output schema` from the product path and from the main repo narrative.
  - Keep runtime responsibility deterministic: `fetch`, `validate`, `anchor`, `render`, artifact lifecycle, and contract help surfaces.
  - Let the agent write `extraction_draft.json` directly and have runtime validate/materialize it.
  - Add a repository-native real E2E entrypoint that runs a real agent backend and closes the loop with AI review.
  - Record harness/process gaps exposed by this slice in harness docs and tracker follow-ups without implementing harness changes now.
- Out of scope:
  - Open-ended product-level multi-turn sessions.
  - New backend implementations beyond the currently available backend used for live validation.
  - Web app, server, Docker distribution, browser extension, or iOS work.
  - Knowledge-aware personalized decisions backed by a user knowledge base.
  - Database, BM25, vector search, or persistence of accepted atoms.
  - Harness code changes beyond documentation and tracker capture.

## Acceptance Criteria

- [x] PR #8's two unresolved review threads are fixed and resolved.
- [x] The primary product skill is `skills/missless/`, not `skills/missless-review/`.
- [x] `packages/contracts/extraction-draft.codex-output-schema.json` is removed from the product path.
- [x] Product docs no longer rely on `codex exec --output-schema` or other Codex-only features to explain the slice.
- [x] The runtime CLI exposes a small deterministic help/contract surface that the skill can consult instead of depending on an oversized embedded prompt.
- [x] The agent writes `extraction_draft.json` directly, and runtime remains responsible for validation, evidence anchoring, and HTML review rendering.
- [x] A repository-native real E2E script can drive the current backend through `URL -> artifacts -> AI review` without requiring human judgment to close the loop.
- [x] Review-loop behavior is documented so that missing reviewer-agent output triggers retry or fallback plus recorded evidence rather than silent abandonment.
- [x] AI review is constrained to the current run artifacts rather than depending on unrelated repository docs or prior runs for contract inference.
- [x] `README.md` explains the product from a user perspective and points to the `missless` entrypoint.
- [x] `skills/README.md` describes repository product skills without exposing `.agents/skills` as part of the user story.
- [x] `docs/product-specs/product-foundation.md` returns to product foundations only; implementation-specific detail is moved back into design/spec/plan docs.
- [x] The active plan uses explicit step content, step-level exit criteria, and truthful checkbox/status updates before publish/final gate.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Reset the source-of-truth narrative so the branch reads like a product slice instead of backend-specific engineering notes.
- Key changes:
  - Rewrite the root `README.md` so it answers what `missless` is, what input the user gives, and what output the user gets.
  - Rewrite `skills/README.md` so it only describes product skills in repository code, not developer-only `.agents/skills`.
  - Rewrite `docs/product-specs/product-foundation.md` so it keeps only stable product foundations: the problem, the user promise, the first-slice boundary, the decision semantics, and the deferred knowledge-aware differentiator.
  - Move backend/runtime details back into the appropriate design/spec/plan docs instead of leaving them in product-foundation.
  - Make the formal product entrypoint explicit as `skills/missless/` with a `single-run URL -> review package` contract.
- Expected files:
  - `README.md`
  - `skills/README.md`
  - `docs/product-specs/product-foundation.md`
  - `docs/design-docs/system-design.md`
  - `docs/specs/pipeline-contracts.md`
- Validation commands:
  - `rg -n "codex exec|output-schema|\\.agents/skills|missless-review" README.md skills/README.md docs/product-specs/product-foundation.md docs/design-docs/system-design.md docs/specs/pipeline-contracts.md`
  - `rg -n "single-run|review package|deep_read|skim|skip|knowledge-aware" README.md docs/product-specs/product-foundation.md docs/design-docs/system-design.md docs/specs/pipeline-contracts.md`
- Documentation impact:
  - Product docs become user-facing again.
  - Design/spec docs keep the deterministic runtime boundary and deferred differentiator explicit.
- Exit criteria:
  - A new reader can understand the slice from product docs without learning Codex-specific implementation tricks first.

### Step 2

- Status: completed
- Objective: Harden the deterministic runtime surface, remove Codex-specific contract leakage, and fix the open ingestion review comments.
- Key changes:
  - Fix IPv4-mapped IPv6 private-address handling in `fetch-normalize` so localhost/private-network guards cannot be bypassed by address normalization.
  - Ensure the default run-directory parent path exists on a fresh repository before writes.
  - Remove `packages/contracts/extraction-draft.codex-output-schema.json`.
  - Remove Codex-only wording from CLI help and expose a small runtime-owned contract/help surface that the skill can query.
  - Keep runtime fail-closed and deterministic: it validates agent-authored artifacts instead of constraining the agent with a product-level structured-output contract.
- Expected files:
  - `apps/cli/src/index.ts`
  - `apps/cli/src/commands/fetch-normalize.ts`
  - `packages/core/src/source/fetch-normalize.ts`
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
  - Design/spec docs reflect runtime-owned deterministic contracts rather than Codex-only handoff rules.
- Exit criteria:
  - The open GitHub review comments are addressed in code and tests.
  - No user-facing contract depends on `--output-schema`.

### Step 3

- Status: completed
- Objective: Rebuild the product skill so it is short, product-first, and driven by runtime contracts instead of a giant embedded prompt.
- Key changes:
  - Rename `skills/missless-review/` to `skills/missless/`.
  - Rewrite the skill to start from runtime help/contract discovery, then run the deterministic steps in order.
  - Keep the skill focused on `URL -> review package`; do not over-promise product-level follow-up support.
  - Let the agent write `extraction_draft.json` directly, then call `validate-draft`, `anchor-evidence`, and `render-review`.
  - Keep backend-specific instructions minimal and isolate them from the core product contract.
- Expected files:
  - `skills/missless/`
  - `skills/README.md`
  - `docs/design-docs/system-design.md`
  - `docs/specs/pipeline-contracts.md`
- Validation commands:
  - `rg -n "missless-review|output-schema|codex-output" skills/missless skills/README.md docs/design-docs/system-design.md docs/specs/pipeline-contracts.md`
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
- Documentation impact:
  - The repo makes a clean distinction between product skill behavior and backend implementation details.
- Exit criteria:
  - The product skill can be explained as a user entrypoint without leading with backend-specific flags or giant prompt scaffolding.

### Step 4

- Status: completed
- Objective: Make live validation repository-native by adding a real E2E entrypoint and closing the loop with AI review instead of human judgment.
- Key changes:
  - Add a repository-native E2E script entrypoint that runs the current backend against a real URL and captures the resulting run artifacts.
  - Drive the deterministic runtime from the same flow: `fetch-normalize -> agent-authored draft -> validate-draft -> anchor-evidence -> render-review`.
  - Add an AI review stage that inspects the produced artifacts and records a pass/fail-style judgment plus evidence notes.
  - Keep AI review artifact-scoped so the reviewer judges the current run rather than reading unrelated repo docs or prior runs for context.
  - Document and enforce review-loop fallback behavior: if a reviewer agent does not respond, retry or fallback and record the reason instead of silently dropping the review.
  - Record rubric-based AI review as backlog rather than implementing a broad rubric system in this slice.
- Expected files:
  - `scripts/e2e/`
  - `docs/exec-plans/active/2026-03-09-product-facing-v0-remediation.md`
  - `docs/harness/active/2026-03-09-post-first-slice-loop-remediation.md`
  - `docs/exec-plans/tracker.md`
  - `docs/harness/tracker.md`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `scripts/e2e/run_missless_review.sh https://ghuntley.com/loop/`
- Documentation impact:
  - Real-E2E evidence becomes a repository-owned asset instead of chat-only narration.
  - Harness gaps are made explicit instead of getting lost in conversation.
- Exit criteria:
  - The branch has one repeatable real-E2E path and one recorded AI review outcome for it.

### Step 5

- Status: completed
- Objective: Close the loop on the branch before publish/final gate by syncing the plan, trackers, and review state to reality.
- Key changes:
  - Resolve GitHub review comments after the corresponding fixes land.
  - Update this plan's step statuses and acceptance checkboxes so they match the branch state.
  - Sync `docs/exec-plans/tracker.md` and `docs/harness/tracker.md` with any new follow-ups or debt discovered during implementation.
  - Re-run full-PR review and final gate only after plan state, docs, and validation evidence are current.
- Expected files:
  - `docs/exec-plans/active/2026-03-09-product-facing-v0-remediation.md`
  - `docs/exec-plans/tracker.md`
  - `docs/harness/tracker.md`
- Validation commands:
  - `git diff --check`
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - Full-PR review round artifact(s)
  - Final-gate artifact
- Documentation impact:
  - Plan/tracker state is trustworthy before any publish or landing step.
- Exit criteria:
  - The branch is reviewable without hidden context, and plan/tracker state no longer lags behind the implementation.

## Validation Strategy

- Deterministic unit tests:
  - Cover runtime-owned logic with fixtures and mocks only.
  - Prioritize ingestion safety, run-directory creation, diagnostics shaping, selector matching, and HTML review generation.
- Deterministic integration tests:
  - Exercise CLI boundaries and fixture-backed run directories.
  - Verify that validation/render stages are safe to rerun.
  - Verify failure paths remain fail-closed.
- Real E2E:
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
- The two open PR review threads are resolved.
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
  - Mitigation: Record the observed gaps in a harness active plan and tracker follow-ups in this same branch.

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
  - Subagent orchestration in the desktop session was unstable, so the round finished through explicit fallback reviewer artifacts rather than silent abandonment. That failure mode is captured in `docs/harness/active/2026-03-09-post-first-slice-loop-remediation.md`.
