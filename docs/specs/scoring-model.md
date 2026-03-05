# Scoring Model

Status: Active

## Goal

Produce an explainable read-priority decision:
- `skip`
- `skim`
- `read`
- `deep_read`

## Component Scores (Baseline)

- `novelty_score`
  - weighted count of new atoms
  - evidence gain for existing atoms
- `overlap_penalty`
  - fraction mapped to `duplicate_of`/`equivalent_to` claims
- `slop_penalty`
  - near-dup source similarity
  - low-signal source history
- `quality_score`
  - historical acceptance
  - citations/code/dataset link signals
  - density proxies
- `relevance_score`
  - keyword-based relevance (cold-start acceptable)
- `time_cost`
  - estimated reading/viewing cost

## Output Contract

- `rating_label`
- `rating_breakdown` with component values and concise reasons

## Governance

- Weights must be configurable.
- Reasons must remain human-readable and auditable.
