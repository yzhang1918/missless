# Product Foundation

Status: Active

## Purpose

State the durable product promise, decision model, and first-slice boundary.

## Positioning

- From FOMO to Focus.
- missless turns information overload into decision clarity.
- Read less. Know more. Miss less.
- Drop a link. Get a decision.

## Problem

- Information overload and derivative content reduce signal.
- Summaries without evidence are hard to trust.
- Link collection alone does not tell a user what deserves more attention.

## Product Promise

`missless` gives the user a reading decision with enough evidence to inspect
why that decision was made.

## Core Principles

- Decision over collection.
- Evidence over unsupported judgment.
- Review before persistence.
- Interface-agnostic product semantics.
- Repository-legible contracts.

## Decision Model

- `deep_read`
  - the source contains detail or density that the extracted package cannot
    safely replace
- `skim`
  - the TLDR and ordered atoms capture most of the value, with selective
    source reading still useful
- `skip`
  - the TLDR and supporting evidence are enough; further reading has low
    expected return in this slice

These first-slice decisions are knowledge-base-agnostic. They do not yet use
the user's existing knowledge to judge novelty.

## First Delivery Slice

- Input: one public URL.
- Output:
  - a 1-2 sentence TLDR
  - a `deep_read|skim|skip` recommendation
  - concise reasons for that recommendation
  - ordered claim-first atoms
  - evidence-backed review artifacts, including a local read-only review page
- Interaction model:
  - the first slice is `single-run URL -> review package`
  - human inspection happens at the review-package boundary
- Boundary:
  - the first slice stops before persistence, commit, or knowledge-base
    alignment
- Evidence model:
  - important conclusions must remain inspectable against the canonical source
    text
- Surface:
  - the runtime may have multiple technical entrypoints, but the product story
    is one user action: drop a link and get a decision

## Acceptance Bar

- The user can submit one public URL and receive a review package.
- The package includes a TLDR, an explicit reading decision, reasons, ordered
  claim-first atoms, and inspectable evidence.
- Runtime validation fails closed when draft or evidence requirements are not
  met.
- The first slice does not persist accepted atoms.

## Long-Term Differentiator

The long-term product differentiator is knowledge-aware personalized judgment:
the same source may be `deep_read`, `skim`, or `skip` for different users
depending on what they already know.

That differentiator is core to `missless`, but it is intentionally outside the
first delivery slice.

## Deferred Beyond the First Slice

- Knowledge-aware personalized decisions backed by the user's existing
  knowledge base.
- Persistence and commit flows for accepted atoms.
- Cross-source alignment and relation-heavy reasoning.
- Non-text source support such as audio or PDF-native evidence.
- Web, mobile, and extension delivery surfaces.
