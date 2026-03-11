# Provider Boundary SSRF Hardening And Fallback

## Metadata

- Plan name: Provider Boundary SSRF Hardening And Fallback
- Owner: Human+Codex
- Date opened: 2026-03-11
- Date completed: 2026-03-11
- Intake source: GitHub issues `#15` and `#16`
- Related issues:
  - `#15` Add provider fallback strategy beyond the default Jina reader
  - `#16` Finish provider-boundary SSRF policy beyond initial resolved-host checks
- Scope note: This is one coherent product task because both issues land on the same provider boundary: provider outcome classification, redirect safety, and fallback behavior.

## Objective

Deliver one provider-boundary slice that hardens SSRF enforcement beyond the initial source URL and defines a fallback strategy beyond the default Jina reader. The shipped runtime must keep unsafe/private/local destinations fail-closed across redirect hops and final fetch destinations, while allowing a bounded fallback from Jina Reader to direct origin fetch plus local markdown normalization for recoverable provider failures only.

## Scope

- In scope:
  - Extend the provider contract so provider outcomes can distinguish terminal policy failures from recoverable fetch failures.
  - Enforce SSRF policy across provider-controlled redirect hops and final fetch destinations, not only the original requested URL.
  - Add a direct-origin fallback provider that fetches safe public content and converts HTML into canonical markdown-friendly text locally.
  - Use `Jina Reader -> direct origin fetch` as the default provider sequence for recoverable Jina failures.
  - Preserve current fail-closed behavior for unsafe, private, localhost, link-local, or otherwise blocked destinations.
  - Add targeted regression coverage for redirect handling, fallback eligibility, and policy failures, and keep the existing CLI integration suite passing.
  - Update design/spec docs in the same branch so the provider boundary is explicit and reviewable.
- Out of scope:
  - Stable runtime entrypoint or installable skill packaging from `#14`.
  - Harness publish, final-gate automation, or harness review-loop feature work.
  - Repository documentation split policy from `#17`.
  - Broad multi-provider marketplace abstractions beyond what this fallback slice requires.

## Acceptance Criteria

- [x] Provider fetch logic distinguishes recoverable provider failures from terminal policy failures.
- [x] `fetch-normalize` continues to reject unsafe source URLs before provider access.
- [x] Redirect hops and final destinations are checked against the same SSRF policy as the original source boundary.
- [x] Any blocked redirect or blocked final destination fails closed and does not trigger fallback.
- [x] Default runtime provider behavior is `Jina Reader -> direct origin fetch` for recoverable failures only.
- [x] Direct-origin fallback produces canonical text suitable for existing downstream pipeline contracts.
- [x] Targeted provider/fetch tests cover redirect blocking, destination blocking, recoverable fallback, and non-fallback policy failures.
- [x] `docs/design-docs/system-design.md` and `docs/specs/pipeline-contracts.md` describe the shipped provider boundary truthfully.

## Work Breakdown

### Step 1

- Status: completed
- Objective: Define the provider-boundary contract for policy enforcement, redirect validation, and fallback eligibility.
- Expected files:
  - `packages/core/src/providers/provider.ts`
  - `packages/core/src/source/url-safety.ts`
  - `packages/core/src/source/fetch-normalize.ts`
  - `docs/design-docs/system-design.md`
  - `docs/specs/pipeline-contracts.md`
- Validation commands:
  - `pnpm -r typecheck`
  - `pnpm exec tsx --test tests/unit/core/fetch-normalize.test.ts`
- Documentation impact:
  - Design/spec docs gain explicit language for provider outcome classes, redirect checks, and terminal policy failures.

### Step 2

- Status: completed
- Objective: Implement the direct-origin fallback provider and wire the default provider sequence without weakening SSRF protections.
- Expected files:
  - `packages/core/src/providers/provider.ts`
  - `packages/core/src/providers/default.ts`
  - `packages/core/src/providers/direct-origin.ts`
  - `packages/core/src/providers/jina.ts`
  - `packages/core/src/source/fetch-normalize.ts`
  - `packages/core/package.json`
- Validation commands:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm exec tsx --test tests/unit/core/jina-provider.test.ts`
  - `pnpm exec tsx --test tests/unit/core/direct-origin-provider.test.ts`
  - `pnpm exec tsx --test tests/unit/core/provider-fallback.test.ts`
  - `pnpm exec tsx --test tests/unit/core/fetch-normalize.test.ts`
- Documentation impact:
  - Docs/specs describe the shipped fallback sequence and its boundaries, not a generic future abstraction.

### Step 3

- Status: completed
- Objective: Add regression coverage for provider redirects, fallback sequencing, and CLI-level behavior.
- Expected files:
  - `tests/unit/core/fetch-normalize.test.ts`
  - `tests/unit/core/direct-origin-provider.test.ts`
  - `tests/unit/core/jina-provider.test.ts`
  - `tests/unit/core/provider-fallback.test.ts`
- Validation commands:
  - `pnpm -r test`
  - `pnpm exec tsx --test tests/unit/core/*.test.ts`
- Documentation impact:
  - No new product-facing docs, but plan evidence cites both the new unit regressions and the passing existing CLI integration suite.

## Validation Strategy

- Unit tests:
  - Cover SSRF blocking for entry URLs, redirect hops, and final destinations.
  - Cover provider outcome classification and fallback eligibility decisions.
  - Cover direct-origin normalization behavior for representative HTML/text responses.
- Integration tests:
  - Keep the existing CLI `fetch-normalize` and downstream pipeline integration suite passing after the provider-boundary change.
  - Leave redirect-specific and fallback-specific regressions at the unit level for this slice.
- Full validation:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`

## Review Cadence

- Run delta review through targeted test coverage after each implementation step.
- Review doc/spec changes against the shipped code before marking the plan complete.
- Run one final full validation pass before archiving the plan.

## Final Gate Conditions

- All acceptance criteria are checked.
- Full workspace build, typecheck, and test commands pass locally.
- Provider-boundary docs/specs match the shipped code.
- Issues `#15` and `#16` can be updated with plan/disposition links based on the branch state.

## Risks And Mitigations

- Risk: Fallback accidentally bypasses SSRF checks on redirects or final destinations.
  - Mitigation: Make policy failures first-class provider outcomes and test them explicitly.
- Risk: Local HTML-to-markdown conversion drifts too far from current canonical-text expectations.
  - Mitigation: Keep normalization conservative and regression-test representative HTML/text responses.
- Risk: Provider errors stay too generic, making fallback behavior ambiguous.
  - Mitigation: Encode recoverable vs terminal outcomes in the provider boundary rather than string-matching ad hoc errors in callers.

## Completion Evidence

- Branch: `codex/15-16-provider-boundary-ssrf-fallback`
- Validation:
  - `pnpm -r build`
  - `pnpm -r typecheck`
  - `pnpm -r test`
- Targeted regressions added:
  - Redirect-chain SSRF rejection before provider fetch
  - Default `Jina Reader -> direct_origin` fallback on recoverable Jina failure
  - Default `Jina Reader -> direct_origin` fallback on Jina interstitial-warning failure
  - Default `Jina Reader -> direct_origin` fallback on Jina empty-canonical-text failure
  - Direct-origin redirect handling and local HTML-to-markdown normalization
  - Retryable versus fail-closed provider disposition handling
- Review evidence:
  - Initial full-PR round `20260311-143648` surfaced two `IMPORTANT` findings:
    `runId` validation happened after redirect preflight, and the completed plan overstated added integration coverage.
  - Follow-up fixes moved `runId` validation ahead of redirect preflight, extracted provider-agnostic normalization into `packages/core/src/providers/normalize.ts`, and tightened the completed-plan wording.
  - Delta review round `20260311-143942` passed review gate with `BLOCKER=0` and `IMPORTANT=0` in `.local/loop/review-20260311-143942.json`.
  - One residual `MINOR` remains: CLI integration coverage still does not exercise the shipped fallback boundary directly.
- Final gate evidence:
  - Local-equivalent CI metadata in `.local/loop/ci-local-20260311-143942.json` recorded passing `build`, `typecheck`, and `test` checks plus `docs_updated=true`.
  - `.local/loop/final-gate-20260311-143942.json` failed because `branch_up_to_date=false` after `origin/main` advanced during the session.
  - Final gate status is `no-go` until the branch is refreshed against `origin/main`; review and local validation signals are otherwise green.
- Issue update note:
  - Work was executed against GitHub issues `#15` and `#16`; issue comments should reference this completed plan path and the validation result until a landing PR exists.
