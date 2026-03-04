# Core Data Model (Heterogeneous Graph)

Status: Active

## Design Constraints

- Atoms/Claims must remain short and scan-friendly.
- Evidence must be traceable to source segments.
- Data model must support slop resistance and deduplication.
- Artifact growth should happen through subtype schemas, not constant core migrations.

## Node Types (Minimum)

- Source
- Segment
- Atom
- Artifact
- Optional: Concept/Entity
- Optional: Publisher/Author

## Edge Types (Minimum)

- `Source -> Segment`: `has_segment`
- `Segment -> Atom`: `states`
- `Source -> Atom`: `evidences` (materialized/aggregated)
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
- `content_ref`
- `fingerprints`: `content_hash`, `simhash/minhash`, `embedding_ref`
- `quality_signals`
- `derived`: `tldr_l0`, `tldr_l1`, `estimated_time_cost`, `rating_label`, `rating_breakdown`

## Segment Fields

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
- `l0_abstract`, `l1_overview`
- `payload` (schema-driven by subtype and version)
- `embedding_ref`
- `created_at`, `updated_at`

## Core Edge Properties

### `Segment -> Atom` (`states`)

- `polarity`: `supports|refutes|neutral`
- `strength`: `0..1`
- optional `note`

### `Source -> Atom` (`evidences`)

- `strength_agg`: `0..1`
- `top_segments[]`

### `Atom <-> Atom`

- `relation_type`
- `strength`
- optional `rationale`
- `created_by`: `extractor|aligner|human`

### `Source -> Artifact`

- `relation_type`
- `key_segments[]`

### `Artifact -> Atom`

- `relation_type`
- `strength`
- `segments[]`

## Scope Modeling Guidance

- POC default: `Atom.scope_text`.
- Add structured scope facets only when query/aggregation needs justify it.
- Promote scope into shared nodes only when reuse is high.
