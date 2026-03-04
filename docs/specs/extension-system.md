# Extension System

Status: Active

## Purpose

Define how source content is transformed into structured knowledge.

## Extension Contract (Conceptual)

`extract(source, segments, retrieval_context) -> extraction_output`
- produces atoms, artifacts, and evidence edges
- may produce TL;DR outputs

`align(extraction_output, kb_candidates) -> alignment_result`
- decides alignment outcomes using type-specific decision enums
- attaches confidence and rationale

`merge(alignment_result, human_edits) -> commit_plan`
- resolves upserts and edge writes

## POC Extensions

### `blog.basic`

- required outputs:
  - atoms (`fact|insight|definition|procedure`)
  - `segment->atom` support edges
- artifacts optional

### `paper.basic`

- required outputs:
  - atoms for problem/findings/results
  - artifacts including `paper.method` (if proposed) and at least one `paper.result`
  - edges: `source->artifact`, `artifact->atom`, `segment->atom`

## Retrieval Context for KB-Assisted Extraction

Before extraction, retrieve top-k candidates:
- similar atoms
- similar artifacts
- similar sources (for slop detection)

Pass only compact views to extractor to reduce context load.

## Alignment Strategy (POC)

### Alignment Decision Vocabulary

Atom decision enum:
- `new`
- `duplicate_of`
- `equivalent_to`
- `qualifies`
- `entails`
- `contradicts`
- `extends`

Artifact decision enum:
- `new`
- `duplicate_of`
- `equivalent_to`
- `variant_of`
- `improves`
- `uses`
- `compares_to`

Allowed display aliases (for human-readable summaries only):
- `duplicate` -> `duplicate_of`
- `equivalent` -> `equivalent_to`

Machine-readable outputs must use enum values valid for the object type.

Multi-signal strategy:
- lexical/canonical matching for precision
- embedding retrieval for recall
- optional NLI-style contradiction/entailment checks

All decisions must be auditable with rationale and candidate scores.

## Human Review Requirements

Proposal groups:
- new atoms
- merge suggestions
- qualify/entail/extend suggestions
- contradiction flags
- new artifacts

User actions:
- accept/reject selected items
- edit text/payload fields
- override alignment decisions

All actions must emit events.

## Event Logging Requirements

Always log events for:
- run start/complete
- extraction output
- alignment output
- review actions
- commit summary

Minimum event fields:
- event id/time
- run id, source id
- object references
- action
- before/after payload (diff or snapshot)
- optional user comment
