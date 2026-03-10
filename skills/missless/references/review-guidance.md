# Review Guidance

Use this guidance for judgment quality. Use
`node apps/cli/dist/index.js print-draft-contract` for the mechanical draft
contract.

## Decision Semantics

- `deep_read`
  - use when the source contains detail or density that the extracted package
    cannot safely replace
- `skim`
  - use when the TLDR and ordered atoms capture most of the value, with
    selective source reading still useful
- `skip`
  - use when the TLDR and supporting evidence are enough for this slice

## Atom Guidance

- Write claim-first atoms, not section headings.
- Order atoms by importance.
- Prefer fewer, stronger atoms over exhaustive fragmentation.
- Use as many atoms as the source needs, but do not split one idea into
  several weakly different claims.

## Evidence Guidance

- Copy selector text from the canonical text rather than paraphrasing it.
- Make selectors specific enough to survive repeated phrases.
- Use `prefix` or `suffix` to disambiguate when the exact quote appears more
  than once.

## Self-Check Guidance

- `self_check` is optional.
- Keep it short.
- Use it only for compact quality notes such as a corrected duplication issue
  or one unresolved uncertainty worth human attention.
