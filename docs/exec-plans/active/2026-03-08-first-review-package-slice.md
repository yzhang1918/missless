# First URL-to-Review Package Slice

## Metadata

- Plan name: First URL-to-Review Package Slice
- Owner: Human+Codex
- Date: 2026-03-08
- Related tasks: TASK-0003
- Tracker IDs: TASK-0003

## Objective

Implement the first real `missless` product slice as a pnpm-workspace monorepo with a Node+TypeScript CLI/runtime plus a product-facing skill that lives in repository code, not in developer-only helper folders. Given a URL, the system should create a run directory, fetch and normalize canonical text, use Codex as the current extraction engine to produce a structured review draft, validate and anchor evidence, and render a read-only local HTML review package.

## Scope

- In scope:
  - Bootstrap a pnpm workspace monorepo with a future-friendly `apps/`, `packages/`, and `skills/` layout.
  - Use Node+TypeScript for the first-slice runtime packages and CLI.
  - Use a `run_dir` as the primary handle after initial URL ingestion.
  - Support `URL only` input for the first slice.
  - Implement a Jina-backed fetch/normalize provider behind a provider abstraction.
  - Define and validate the `extraction_draft.json` contract.
  - Generate knowledge-base-agnostic reading decisions: `deep_read|skim|skip`.
  - Produce `TLDR`, ordered claim-first atoms, quote-oriented evidence selectors, and optional compact self-check notes.
  - Validate and materialize evidence against canonical text with fail-closed diagnostics.
  - Render a read-only HTML review page from run artifacts.
  - Add a product-facing skill under `skills/` that orchestrates the deterministic CLI while using Codex as the current extraction engine.
  - Validate the slice with deterministic automated tests plus a real Codex CLI manual E2E run.
- Out of scope:
  - Persistence or commit of accepted atoms.
  - Knowledge-aware personalized decisions based on the user's existing knowledge base.
  - Runtime-embedded custom agent core.
  - Database, BM25, vector search, or server-first architecture.
  - Web UI, Docker packaging, browser extension, or iOS app implementation.
  - Auto-installers, binary packaging, or zero-dependency distribution.
  - Public CLI publishing or `npx` distribution decisions.
  - Editable review UI or browser-based app flows.
  - Fine-grained patch/update APIs for draft mutation.

## Acceptance Criteria

- [ ] `fetch-normalize <url>` creates a run directory with source metadata and a canonical normalized text snapshot.
- [ ] The repository is bootstrapped as a pnpm workspace monorepo with product code separated from developer-only `.agents/` helpers, leaving room for later `web`, `docker`, mobile, or extension surfaces without flattening everything into one package.
- [ ] The runtime defines and validates an `extraction_draft.json` contract that includes `tldr`, `decision`, `decision_reasons`, ordered claim-first `atom_candidates`, quote-oriented `evidence_selectors`, and optional `self_check`.
- [ ] The first-slice decision taxonomy is `deep_read|skim|skip`, and repository docs explicitly state that these first-slice decisions are knowledge-base-agnostic.
- [ ] `validate-draft --run-dir <dir>` checks schema and contract invariants and returns summary output by default plus structured JSON diagnostics when `--json` is requested.
- [ ] `anchor-evidence --run-dir <dir>` validates candidate evidence selectors against canonical text, emits evidence result artifacts, and fails closed on unresolved evidence issues.
- [ ] `render-review --run-dir <dir>` produces a read-only local HTML page that shows the TLDR, decision, reasons, ordered claim-first atoms, and highlighted evidence in the canonical source text.
- [ ] A product-facing skill under `skills/` orchestrates the slice using a staged single-agent Codex extraction workflow: decision -> atoms -> evidence selectors -> internal self-check.
- [ ] Deterministic behavior is covered by unit and integration tests; real Codex extraction is exercised through an opt-in manual E2E flow using `codex exec`, not through CI-only gating.
- [ ] Product/design/spec docs and the execution tracker are updated in the same branch, including an explicit note that knowledge-aware personalized decisions are the long-term product differentiator but are deferred from this slice.
- [ ] The plan and runtime docs explicitly distinguish repository package management (`pnpm workspace`) from future user-facing runtime distribution (`npx`, Docker, app bundles), which remains deferred.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Bootstrap the pnpm-workspace monorepo, define the first package boundaries, lock the run directory and extraction draft contracts, and update source-of-truth docs before runtime behavior grows.
- Expected files:
  - `pnpm-workspace.yaml`
  - `package.json`
  - `apps/cli/`
  - `packages/core/`
  - `packages/contracts/`
  - `packages/rendering/`
  - `skills/`
  - `packages/contracts/extraction-draft.schema.json`
  - `docs/product-specs/product-foundation.md`
  - `docs/design-docs/system-design.md`
  - `docs/specs/pipeline-contracts.md`
  - `docs/exec-plans/tracker.md`
- Validation commands:
  - `corepack enable pnpm`
  - `pnpm install`
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `node apps/cli/dist/index.js --help`
  - `rg -n "deep_read|skim|skip|knowledge-aware|review package|Codex-backed extraction|run directory|pnpm workspace|skills/" docs/product-specs/product-foundation.md docs/design-docs/system-design.md docs/specs/pipeline-contracts.md docs/exec-plans/tracker.md`
- Validation evidence:
  - Bootstrapped a pnpm workspace and recorded the resolved toolchain in `package.json` and `pnpm-lock.yaml`.
  - Added `apps/cli`, `packages/contracts`, `packages/core`, `packages/rendering`, and `skills/` with package boundaries that typecheck and build.
  - Locked first-slice contracts in code through `packages/contracts/extraction-draft.schema.json`, `getRunArtifactPaths`, and deterministic contract tests.
  - Verified the built CLI can print the planned command surface from `apps/cli/dist/index.js`.
- Documentation impact:
  - Promote the approved discovery decisions into product/design/spec docs.
  - Record the first runtime/skill boundary, monorepo layout, and deferred knowledge-aware differentiator explicitly.

### Step 2

- Status: completed
- Objective: Implement deterministic ingestion and contract validation for `fetch-normalize` and `validate-draft`, including Jina-backed normalization and fail-closed diagnostics.
- Expected files:
  - `apps/cli/src/commands/fetch-normalize.ts`
  - `apps/cli/src/commands/validate-draft.ts`
  - `packages/core/src/source/`
  - `packages/core/src/diagnostics/`
  - `packages/core/src/providers/jina.ts`
  - `packages/contracts/`
  - `tests/unit/`
  - `tests/integration/`
  - `tests/fixtures/`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
- Validation evidence:
  - Implemented `fetch-normalize` with a provider abstraction and a Jina Reader default in `packages/core/src/providers/jina.ts` and `packages/core/src/source/fetch-normalize.ts`.
  - Implemented `validate-draft` with fail-closed summary and `--json` diagnostics in `packages/core/src/diagnostics/validate-draft.ts`.
  - Added deterministic core unit tests plus CLI integration tests using fixture-backed runs and a mocked Jina HTTP server.
  - Verified the full workspace passes `pnpm -r build`, `pnpm -r typecheck`, and `pnpm -r test`.
- Documentation impact:
  - Capture any contract refinements required by the implemented run directory or diagnostics shape.
  - Keep provider assumptions and environment requirements explicit in repository docs.

### Step 3

- Status: in_progress
- Objective: Implement evidence anchoring, review bundle assembly, and read-only HTML rendering for the first review package.
- Expected files:
  - `apps/cli/src/commands/anchor-evidence.ts`
  - `apps/cli/src/commands/render-review.ts`
  - `packages/core/src/evidence/`
  - `packages/rendering/src/`
  - `tests/unit/`
  - `tests/integration/`
  - `tests/fixtures/`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
- Documentation impact:
  - Align pipeline/doc language with the implemented evidence validation and review surface.
  - Keep fail-closed behavior and read-only review semantics explicit in the docs.

### Step 4

- Status: pending
- Objective: Add a product-facing skill under `skills/` that orchestrates real Codex-backed extraction on top of the deterministic CLI, then capture manual E2E evidence with the actual Codex CLI.
- Expected files:
  - `skills/missless-review/SKILL.md`
  - `skills/missless-review/agents/openai.yaml`
  - `docs/product-specs/product-foundation.md`
  - `docs/exec-plans/tracker.md`
  - `docs/exec-plans/active/2026-03-08-first-review-package-slice.md`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
  - `codex exec -C "$PWD" --output-schema packages/contracts/extraction-draft.schema.json -o .local/e2e/extraction-draft.json - < .local/e2e/prompt.txt`
- Documentation impact:
  - Document the current extraction engine boundary clearly: Codex-backed now, custom runtime agent later.
  - Document the separation between product-facing `skills/` and developer-only `.agents/`.
  - Capture manual E2E evidence and any resulting follow-ups in the tracker instead of hiding them in conversation.

## Validation Strategy

- Deterministic unit tests:
  - Use synthetic fixtures and mocks for the logic that should be mechanically reliable: run directory creation, schema validation, diagnostics shaping, selector matching, HTML view-model generation, and artifact naming.
  - Do not use live network calls or live Codex runs in unit tests.
- Deterministic integration tests:
  - Exercise CLI command boundaries against fixture-backed run directories and mocked Jina responses.
  - Verify that reruns are safe for validation/render stages and that failure modes remain fail-closed.
- Workspace/package-management layer:
  - Use `pnpm workspace` for repository management because it provides first-class workspace support and explicit local-package linking via the `workspace:` protocol in official docs.
  - Defer user-facing package distribution decisions (`npx`, Docker image, app bundle) until package boundaries stabilize and there is a concrete external runtime surface to publish.
- Real-agent manual E2E:
  - Use the actual `codex exec` CLI rather than only subagents to simulate the real extraction surface.
  - Capture at least one manual end-to-end run against a real URL and a real prompt/schema handoff, then run the deterministic CLI on the resulting draft.
  - Treat this as evidence capture and product-quality validation, not as CI gating for the first slice.
- LLM-based judgment:
  - Avoid LLM-as-judge in automated CI for this slice.
  - If qualitative review is needed, keep it manual and attach the evidence to the plan/review notes instead of treating it as a binary automated test.

## Review Cadence

- Run a delta review after each implementation step.
- Run one full-PR review before final gate.
- If the skill prompt or evidence contract changes materially during execution, rerun the relevant deterministic tests plus the manual Codex CLI E2E check.

## Final Gate Conditions

- All acceptance criteria are checked.
- No blocking review findings remain open.
- Deterministic tests pass locally.
- At least one real Codex CLI E2E run has been captured as evidence for the extraction path.
- Product, design, and spec docs agree on the first-slice decision model, run directory contract, and deferred knowledge-aware differentiator.
- Tracker state matches the repository state.

## Risks and Mitigations

- Risk: The runtime/skill boundary drifts and business logic leaks back into prompt-only orchestration.
  - Mitigation: Keep the runtime responsible for deterministic contracts and fail-closed validation; keep Codex limited to extraction/proposal generation.
- Risk: The repository layout overfits the first CLI and makes future web/mobile/extension surfaces awkward.
  - Mitigation: Start with a minimal monorepo layout now (`apps/`, `packages/`, `skills/`) instead of a single-package root, but avoid introducing extra apps or infrastructure that the first slice does not use yet.
- Risk: Live provider and live Codex behavior make automated tests flaky.
  - Mitigation: Keep CI focused on deterministic unit/integration tests and reserve live Codex/Jina runs for manual E2E evidence.
- Risk: The first HTML review page grows into a premature app surface.
  - Mitigation: Restrict the first page to read-only review and defer editing to the later web app slice.
- Risk: The knowledge-aware personalized decision differentiator gets lost because the first slice is article-only.
  - Mitigation: Record it explicitly in updated docs and in this plan as a deferred but core product capability.

## Completion Summary

- Delivered:
  - Pending.
- Not delivered:
  - Pending.
- Tracker updates:
  - TASK-0003 added as the current product focus for this slice.
