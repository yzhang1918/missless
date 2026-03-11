# Pipeline Contracts

Status: Draft

## Purpose

Define the baseline processing contract from source ingestion to commit-ready
proposal.

## Baseline Stages

1. `fetch`: acquire source and metadata.
2. `normalize`: produce the canonical normalized content snapshot.
3. `extract`: produce candidate atoms and review artifacts from full content.
4. `anchor_evidence`: validate and materialize evidence anchors for
   candidates.
5. `align`: compare with existing knowledge and propose relations.
6. `propose`: assemble a human-review package.
7. `review`: human accepts, rejects, edits, defers, or overrides.
8. `commit`: optional persistence step.

## Evidence Anchoring Contract (Text Baseline)

- `extract` may propose candidate atoms before stable evidence identifiers
  exist.
- `anchor_evidence` runs as `candidate -> validate -> anchor`.
- Candidate evidence is proposed by the extraction agent as quote-oriented
  selectors rather than direct offsets.
- Runtime validates candidates against the canonical normalized source text.
- When validation succeeds, runtime writes atom-local anchored evidence into
  `evidence_result.json`.
- When validation fails, runtime returns a concrete reason and requests
  refinement.
- Validated text locators are stored as `exact quote + prefix/suffix +
  char_range + context_excerpt`.
- Reusable `Segment` identities remain a deferred persistence-layer concern,
  not part of the current first-slice runtime contract.

## First Delivery Slice Profile

- Required source kind: URL-backed text sources with a canonical normalized
  markdown snapshot.
- Required stages in the first slice: `fetch`, `normalize`, `extract`,
  `anchor_evidence`, `propose`, `review`.
- Current run handle after ingest: `run_dir`.
- Current extractor boundary: agent-authored extraction outside the
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
- `align` and `commit` remain part of the broader baseline architecture but
  may be omitted or no-op for the first delivery slice.

## First Deterministic CLI Contracts

`fetch-normalize <url>`:
- accepts one HTTP(S) URL plus optional `--runs-dir <dir>`
- creates a stable `run_dir`
- writes `run.json`, `source.json`, and `canonical_text.md`
- registers the run in runtime-owned cleanup state under missless runtime
  state, outside caller-supplied runs roots
- current cleanup state includes a runs-root registry plus a per-run
  attestation so cleanup decisions do not depend on caller-writable files
  inside the run directory
- runtime also writes a signed run-local cleanup token so restored local runs
  can still prove stale-output ownership without trusting a plaintext
  in-directory marker
- records both the requested source URL and the resolved safe fetch destination
  in `source.json`
- resolves redirect hops under the runtime SSRF policy before provider access
- uses a provider abstraction with explicit recoverable versus terminal
  failures
- uses `Jina Reader -> direct origin fetch` as the default provider sequence
- allows local/mock provider overrides through `MISSLESS_JINA_BASE_URL`
- rejects source URLs with embedded credentials and rejects localhost,
  private, link-local, and single-label hosts by default
- rejects hostnames that resolve to loopback, private, or link-local
  addresses before provider fetch begins
- rejects redirect hops and final destinations that become localhost, private,
  or link-local before any provider may follow them
- may use `JINA_API_KEY` when an authenticated Jina environment is required
- only forwards `JINA_API_KEY` to the official `r.jina.ai` reader host unless
  `MISSLESS_JINA_FORWARD_API_KEY_TO_OVERRIDE` explicitly opts into forwarding
  credentials to a custom override host
- only falls back after recoverable Jina failures; terminal policy failures
  remain fail-closed and do not continue to another provider
- direct-origin fallback performs local HTML-to-markdown normalization after a
  safe public fetch

`validate-draft --run-dir <dir>`:
- reads `run.json`, `canonical_text.md`, and `extraction_draft.json`
- validates the extraction draft schema
- validates that the run directory still describes a normalized missless run
- validates deterministic contract invariants that do not require evidence
  materialization
- remains the authoritative runtime gate regardless of which agent backend
  authored the draft
- returns concise summary output by default
- returns structured JSON diagnostics when `--json` is requested
- fails closed with a non-zero exit code when required artifacts are missing,
  JSON is malformed, the run manifest is invalid, schema validation fails, or
  duplicate atom claims are detected

`anchor-evidence --run-dir <dir>`:
- reads `canonical_text.md` and `extraction_draft.json`
- reuses `validate-draft` as a hard precondition
- resolves quote-oriented selectors into deterministic evidence records with
  `char_range` and `context_excerpt`
- writes `evidence_result.json`
- records the draft and canonical-text snapshot identities used for anchoring
- fails closed when exact quotes are missing, selector context does not narrow
  the match, or the selector still resolves ambiguously

`render-review --run-dir <dir>`:
- requires a valid normalized `run.json` for the run
- requires a successful `evidence_result.json`
- requires `evidence_result.json` to come from the current `extraction_draft.json`
- requires `evidence_result.json` to come from the current `canonical_text.md`
- only cleans stale rendered outputs when the run is still trusted by the
  runtime-owned cleanup state outside caller-supplied runs roots or by a
  valid signed run-local cleanup token
- assembles `review_bundle.json` from draft, anchored evidence, and canonical
  text
- writes a read-only local `review.html`
- preserves the same ordered candidate list that came from extraction and
  draft validation

Real E2E:
- must use a live agent backend against the canonical text produced by
  `fetch-normalize`
- must author `extraction_draft.json` directly rather than relying on a
  product-level structured-output subset contract
- must still pass `validate-draft`, `anchor-evidence`, and `render-review`
  without special-case runtime behavior

## Review Contract

Long-term review actions must support:
- accept selected items
- reject selected items
- edit candidate fields
- defer selected items
- override alignment decisions
- inspect evidence in the internal canonical source view

First-slice review requires only:
- inspect the TLDR and explicit reading decision
- inspect ordered claim-first candidates
- inspect evidence in the internal canonical source view
- read fail-closed diagnostics when draft or evidence validation fails

## Interface Contract (Adapter-Agnostic)

Any interface such as skill, CLI, web, or mobile must preserve:
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
