# Core Data Model (Heterogeneous Graph)

Status: Draft

## Design Constraints

- Atoms/Claims must remain short and scan-friendly.
- Evidence must be traceable to source segments.
- Data model must support slop resistance and deduplication.
- Artifact growth should happen through subtype schemas, not constant core migrations.

## Node Types (Minimum)

- Source
- Atom
- Artifact
- Segment (optional materialized evidence-anchor node; recommended for high-reuse profiles)
- Optional: Concept/Entity
- Optional: Publisher/Author

## Edge Types (Minimum)

- `Source -> Atom`: `evidences` (materialized/aggregated)
- `Source -> Artifact`: `describes|proposes|introduces`
- `Artifact -> Atom`: `claims|validated_by|implies`
- `Atom <-> Atom`: `equivalent_to|duplicate_of|qualifies|entails|contradicts|extends`
- If segment nodes are materialized:
  - `Source -> Segment`: `has_segment`
  - `Segment -> Atom`: `states`
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
- `content_ref`
- `fingerprints`: `content_hash`, `simhash/minhash`, `embedding_ref`
- `quality_signals`
- `derived`: `summary`, `estimated_time_cost`, `rating_label`, `rating_breakdown`

## Segment Fields (When Materialized)

- `id`, `source_id`
- `locator` object with at least text-quote anchor support
- optional location ranges (`char`, `line`, `page`, `time`)
- optional `dom_path/css_selector`
- `quote_hash`, `snippet`, `created_at`

## Atom Fields

- `id`, `text`, `type`
- optional `scope_text`
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

### `Segment -> Atom` (`states`) (When Segment Nodes Are Materialized)

- `polarity`: `supports|refutes|neutral`
- `strength`: `0..1`
- optional `note`

### `Source -> Atom` (`evidences`)

- `strength_agg`: `0..1`
- `top_evidence_refs[]` (segment ids or embedded anchor refs, implementation-defined)

### `Atom <-> Atom`

- `relation_type`
- `strength`
- optional `rationale`
- `created_by`: `extractor|aligner|human`

### `Source -> Artifact`

- `relation_type`
- `key_evidence_refs[]` (segment ids or embedded anchor refs, implementation-defined)

### `Artifact -> Atom`

- `relation_type`
- `strength`
- `evidence_refs[]` (segment ids or embedded anchor refs, implementation-defined)

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
