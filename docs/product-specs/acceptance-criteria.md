# Acceptance Criteria (POC Done)

Status: Active

## Ingestion Coverage

- Supports typical blog/web articles (HTML).
- Supports arXiv papers with text extraction from HTML or PDF fallback.

## Output Quality

- Atoms are short, scan-friendly, and evidence-traceable to segments.
- Artifacts support at least `paper.method` and `paper.result`.
- Obvious duplicates/equivalents are merged instead of creating redundant atoms.
- Obvious contradictions produce `contradicts` edges, with auditable rationale.

## Rating Output

- Produces `skip|skim|read|deep_read` plus interpretable component breakdown.

## Observability

- Each ingest run is replayable via run records or event logs.
- Each atom can be traced back to source segment locator and snippet.
