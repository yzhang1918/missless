# Pipeline Contracts

Status: Draft

## Purpose

Define the baseline processing contract from source ingestion to commit-ready proposal.

## Baseline Stages

1. `fetch`: acquire source and metadata.
2. `normalize`: produce the canonical normalized content snapshot.
3. `extract`: produce candidate atoms/artifacts from full content.
4. `anchor_evidence`: validate and materialize evidence anchors for candidates.
5. `align`: compare with existing knowledge and propose relations.
6. `propose`: assemble human-review package.
7. `review`: human accepts/rejects/edits/defers/overrides.
8. `commit`: optional persistence step.

## Evidence Anchoring Contract (Text Baseline)

- `extract` may propose candidate atoms before stable evidence identifiers exist.
- `anchor_evidence` runs as `candidate -> validate -> refine -> materialize`.
- Candidate evidence is proposed by the extraction agent as quote-oriented selectors rather than direct offsets.
- Runtime validates candidates against the canonical normalized source text.
- When validation succeeds, runtime `lookup-or-create`s a reusable `Segment`.
- When validation fails, runtime returns a concrete reason and requests refinement.
- When bounded refinement still fails, the candidate item must be marked `needs_review` instead of persisting as an evidence-free accepted item.
- Validated text locators are stored as `exact quote + prefix/suffix + char_range`.

## First Delivery Slice Profile

- Required source kind: URL-backed text sources with a canonical normalized
  markdown snapshot.
- Required stages in the first slice: `fetch`, `normalize`, `extract`,
  `anchor_evidence`, `propose`, `review`.
- Current run handle after ingest: `run_dir`.
- Current extractor boundary: Codex-backed extraction outside the
  deterministic runtime.
- Required candidate output in the first slice: a TLDR,
  knowledge-base-agnostic `deep_read|skim|skip` decision, ordered claim-first
  `Atom` candidates, and quote-oriented evidence selectors.
- Required persisted output in the first slice: none. The first slice stops at
  a review package.
- Out of scope in the first slice: `Artifact` extraction, persistence,
  knowledge-aware personalized decisions, and user-editable review flows.
- Deferred from the first slice: refresh/versioning, non-text locator
  variants, evidence-role semantics, and external-page deep-link guarantees.
- `align` and `commit` remain part of the broader baseline architecture but may
  be omitted or no-op for the first delivery slice.
- Live `codex exec` structured-output runs currently use
  `packages/contracts/extraction-draft.codex-output-schema.json`, a stricter
  subset of the runtime draft contract that omits `self_check` and requires
  `exact + prefix + suffix` for each evidence selector.

## First Deterministic CLI Contracts

`fetch-normalize <url>`:
- accepts one HTTP(S) URL plus optional `--runs-dir <dir>`
- creates a stable `run_dir`
- writes `run.json`, `source.json`, and `canonical_text.md`
- uses a provider abstraction with Jina Reader as the first implementation
- allows local/mock provider overrides through `MISSLESS_JINA_BASE_URL`
- may use `JINA_API_KEY` when an authenticated Jina environment is required

`validate-draft --run-dir <dir>`:
- reads `canonical_text.md` and `extraction_draft.json`
- validates the extraction draft schema
- validates deterministic contract invariants that do not require evidence
  materialization
- remains the authoritative runtime gate even when the draft was produced via
  the stricter `codex-output` schema used by manual live Codex CLI runs
- returns concise summary output by default
- returns structured JSON diagnostics when `--json` is requested
- fails closed with a non-zero exit code when required artifacts are missing,
  JSON is malformed, schema validation fails, or duplicate atom claims are
  detected

`anchor-evidence --run-dir <dir>`:
- reads `canonical_text.md` and `extraction_draft.json`
- reuses `validate-draft` as a hard precondition
- resolves quote-oriented selectors into deterministic evidence records with
  `char_range` and `context_excerpt`
- writes `evidence_result.json`
- fails closed when exact quotes are missing, selector context does not narrow
  the match, or the selector still resolves ambiguously

`render-review --run-dir <dir>`:
- requires a successful `evidence_result.json`
- assembles `review_bundle.json` from draft, anchored evidence, and canonical
  text
- writes a read-only local `review.html`
- preserves the same ordered candidate list that came from extraction and draft
  validation

Manual real-Codex E2E:
- uses `codex exec` against the live canonical text produced by
  `fetch-normalize`
- uses `packages/contracts/extraction-draft.codex-output-schema.json` for the
  model handoff
- may inline canonical text into the prompt when a direct local-file-read
  prompt proves unstable in the current Codex CLI
- still must pass `validate-draft`, `anchor-evidence`, and `render-review`
  without special-case runtime behavior

## Review Contract

Long-term review actions must support:
- accept selected items
- reject selected items
- edit candidate fields
- defer selected items
- override alignment decisions
- inspect evidence in the internal canonical source view
- identify items blocked in `needs_review`

First-slice review requires only:
- inspect the TLDR and explicit reading decision
- inspect ordered claim-first candidates
- inspect evidence in the internal canonical source view
- read fail-closed diagnostics when draft or evidence validation fails

## Interface Contract (Adapter-Agnostic)

Any interface (skill/CLI/web/mobile) must preserve:
- stable run identifier for non-dry runs
- review-before-commit semantics
- auditable evidence references
- replayable run artifacts
- an internal evidence-reading surface for canonical-source highlighting

## Run Artifact Contract (Baseline)

Each non-trivial run should emit machine-readable artifacts:
- `run.json`
- `source.json`
- `canonical_text.md`
- `extraction_draft.json`
- `evidence_result.json`
- `review_bundle.json`
- `review.html`
- `alignment_result.json` when `align` executes
- `commit_plan.json`

Exact schemas remain draft and should evolve with implementation feedback, but
the first-slice artifact names above are now part of the runtime contract.

## Scoring Contract (Baseline)

The system may output a read-priority label with reasons.

Contract requirements:
- label is explicit
- first-slice labels are `deep_read`, `skim`, or `skip`
- first-slice labels are knowledge-base-agnostic
- reasons are human-readable
- scoring inputs are auditable
