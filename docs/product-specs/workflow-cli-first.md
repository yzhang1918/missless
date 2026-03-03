# CLI-First User Workflow

Status: Active

## Main Flow

1. User runs `missless ingest <url_or_arxiv>`.
2. System fetches and parses source content into segments.
3. Extension extracts atoms/artifacts and evidence relations.
4. Aligner compares extracted outputs against KB candidates.
5. System computes a proposal with rating and explanation.
6. User reviews proposal and takes actions.
7. User runs `missless commit <run_id>` to persist approved changes.
8. System commits approved changes and logs events.

## Review Actions

- Accept all or selected items
- Reject selected items
- Edit atom/artifact fields
- Override alignment decisions

## Commit Outcome

- Persist accepted nodes/edges
- Persist event trail for replay and learning
- Update historical quality/overlap signals
