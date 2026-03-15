# CLI Contracts

Status: Draft

## Purpose

Define the stable first-slice CLI surface for `missless`, including command
names, argument contracts, stdout JSON envelopes, and the boundary between
agent-friendly workflow output and auxiliary contract inspection.

## Design Goals

- Keep the primary workflow short and verb-first: `fetch`, `validate`,
  `anchor`, `review`.
- Make agents the default CLI consumer without making human review harder.
- Keep stdout stable and machine-readable by default.
- Keep durable source provenance separate from execution-trace or
  provider-attempt details.

## Command Catalog

| Command | Purpose | Notes |
| --- | --- | --- |
| `fetch <url>` | Create a normalized run from one public URL. | Accepts `--runs-dir <dir>` and `--fetch-method <auto|jina|direct>`. |
| `validate --run-dir <dir>` | Validate an agent-authored draft against runtime contracts. | Returns diagnostics in the default JSON envelope. |
| `anchor --run-dir <dir>` | Validate selectors and materialize anchored evidence. | Writes `evidence_result.json`. |
| `review --run-dir <dir>` | Build `review_bundle.json` and `review.html`. | Returns review artifact paths in the default JSON envelope. |
| `print-draft-contract` | Print the runtime-owned `extraction_draft.json` contract. | Auxiliary introspection command; output stays JSON. |

## Global Workflow Output Rules

- The primary workflow commands are `fetch`, `validate`, `anchor`, and
  `review`.
- Default stdout for workflow commands is one JSON object.
- The JSON object should remain concise enough for a human to scan directly,
  so each command includes a short `summary`.
- The workflow commands should emit the JSON object on both success and
  contract-level fail-closed outcomes. Invocation parsing errors may still use
  stderr and a non-zero exit code.
- The default workflow output is JSON-first; no separate human-default output
  contract is assumed for the first slice.

## Common Workflow Envelope

Each workflow command should emit a JSON object with at least:

- `ok`: boolean outcome of the command
- `command`: `fetch|validate|anchor|review`
- `summary`: short human-readable summary
- `run_dir`: absolute run directory path
- `artifacts`: object of absolute artifact paths relevant to the command

Recommended command-specific additions:

- `fetch`
  - `source`: the persisted `source.json` provenance payload
  - `ready_for`: ordered next-step hints such as
    `read_canonical_text|write_extraction_draft|validate`
- `validate`
  - `diagnostics`
  - `decision`
  - `atom_count`
- `anchor`
  - `diagnostics`
  - `draft_sha256`
  - `canonical_text_sha256`
- `review`
  - `review_bundle`
  - `review_html`
  - `ready_for`

## Exit And Error Semantics

- `0` means the command finished successfully and `ok` is `true`.
- `1` means the command failed closed or the invocation was invalid.
- Contract-level failures should prefer a structured JSON payload on stdout.
- Invalid invocation may emit concise stderr without a JSON payload.

## Fetch Contract

`fetch <url>` must:

- accept one public HTTP(S) URL
- create a stable `run_dir`
- write `run.json`, `source.json`, and `canonical_text.md`
- respect `--fetch-method <auto|jina|direct>`
- persist canonical fetch-method values as
  `auto|jina_reader|direct_origin`
- require injected custom providers to report the durable chosen fetch method
  through either a built-in durable `providerName`
  (`jina_reader|direct_origin`) or an explicit `durableFetchMethod`
- fail closed when an explicit `--fetch-method jina|direct` request conflicts
  with the provider result's durable chosen fetch method
- use `source.json` for durable provenance only, not transport/debug metadata

## Source Provenance Contract

The durable `source.json` payload is shallow and provenance-first:

```json
{
  "requested": {
    "url": "https://example.com/post",
    "fetch_method": "auto"
  },
  "decision_basis": {
    "url": "https://www.example.com/final-post",
    "fetch_method": "direct_origin",
    "snapshot_sha256": "8f3c...9ab1"
  },
  "fetched_at": "2026-03-14T08:00:00.000Z"
}
```

Contract notes:

- `decision_basis.url` is the final content URL used for the reading
  decision, not a provider endpoint URL.
- `decision_basis.fetch_method` records the actual method that produced the
  canonical content snapshot.
- Provider endpoint URLs, response headers, response status codes, and attempt
  sequencing are outside this durable artifact contract.

## Auxiliary Draft Contract Command

`print-draft-contract` remains machine-readable JSON and should describe:

- the current draft file and schema path
- required draft fields
- decision labels
- derived artifact names
- the current workflow repair loop using `validate`, `anchor`, and `review`

This command is an introspection helper, not a substitute for the CLI output
contract of the workflow commands themselves.
