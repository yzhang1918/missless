# Core Data Model (Heterogeneous Graph)

Status: Draft

## Design Constraints

- Atoms/Claims must remain short and scan-friendly.
- Evidence must be traceable to source text spans.
- Data model must support slop resistance and deduplication.
- Artifact growth should happen through subtype schemas, not constant core migrations.

## Node Types (Minimum)

- Source
- Atom
- Artifact
- Optional future persistence node: Segment
- Optional: Concept/Entity
- Optional: Publisher/Author

## Edge Types (Minimum)

- `Source -> Atom`: `evidences`
- `Source -> Artifact`: `describes|proposes|introduces`
- `Artifact -> Atom`: `claims|validated_by|implies`
- `Atom <-> Atom`: `equivalent_to|duplicate_of|qualifies|entails|contradicts|extends`
- Optional `Source -> Source`: `duplicates|rewrites|quotes`
- Optional `Atom -> Concept`: `about`
- Optional `Artifact <-> Artifact`: `duplicate_of|equivalent_to|variant_of|improves|uses|compares_to`

## Atom Constraints

- Prefer one sentence.
- If a second sentence exists, it must only clarify scope/condition.
- Keep claims verifiable and avoid narrative-only phrasing.
- Put broad significance in a separate short field, not inside long claim prose.

## Source Fields

- `id`, `kind`, `locator`
- `fetched_at`, `published_at`
- `author`, `publisher`
- `access`: `public|login_required|paywalled|unknown`
- `content_ref` to the canonical normalized text snapshot
- `fingerprints`: `content_hash`, `simhash/minhash`, `embedding_ref`
- `quality_signals`
- `derived`: `summary`, `estimated_time_cost`, `rating_label`, `rating_breakdown`
- First-slice policy: the stored normalized text snapshot is immutable after ingest.

## First-Slice Runtime Evidence Shape

- `AnchoredEvidence`
  - `selector_index`
  - `exact`
  - optional `prefix`
  - optional `suffix`
  - `char_range`: `start`, `end`
  - `context_excerpt`
- `AnchoredAtom`
  - `claim`
  - `significance`
  - `evidence[]`
- Current first-slice rule: these anchored evidence records live inside
  `evidence_result.json` and `review_bundle.json`; they are not yet persisted
  as reusable graph nodes.

## Segment Fields (Deferred Persistence Layer)

- `id`, `source_id`
- `locator` object with:
  - `exact`
  - `prefix`
  - `suffix`
  - `char_range`: `start`, `end`
- `excerpt` snapshot derived from the canonical source text
- `quote_hash`
- `created_at`
- Identity rule for a future persistence layer: a `Segment` is unique within a
  `Source` by validated locator, not by raw LLM candidate text.

## Atom Fields

- `id`, `text`, `type`
- optional `scope_text`
- first-slice review artifacts use inline anchored evidence, not `Segment` ids
- `confidence`
- `canonical_form`
- `embedding_ref`
- `created_at`, `updated_at`
- `stats`: evidence/refute/contradiction counters

## Artifact Fields

- `id`, `subtype`, `name`
- `summary`
- `payload` (schema-driven by subtype and version)
- `embedding_ref`
- `created_at`, `updated_at`

## Core Edge Properties

### `Source -> Atom` (`evidences`)

- `strength_agg`: `0..1`
- `top_evidence_refs[]` (first-slice: anchored evidence records; future graph
  persistence may swap this to stable `Segment` ids)

### `Atom <-> Atom`

- `relation_type`
- `strength`
- optional `rationale`
- `created_by`: `extractor|aligner|human`

### `Source -> Artifact`

- `relation_type`
- `key_evidence_refs[]` (first-slice: anchored evidence records)

### `Artifact -> Atom`

- `relation_type`
- `strength`
- `evidence_refs[]` (first-slice: anchored evidence records)

### Optional `Source -> Source`

- `relation_type`: `duplicates|rewrites|quotes`
- `strength`: `0..1`
- optional `rationale`

### Optional `Artifact <-> Artifact`

- `relation_type`: `duplicate_of|equivalent_to|variant_of|improves|uses|compares_to`
- `strength`: `0..1`
- optional `rationale`

## Scope Modeling Guidance

- Baseline default: `Atom.scope_text`.
- Add structured scope facets only when query/aggregation needs justify it.
- Promote scope into shared nodes only when reuse is high.
