# Product-Facing Skills

This directory holds repository-owned product skills and prompt assets that
ship with `missless`.

## Current Skill

- `skills/missless/`
  - turns one public URL into a review package
  - produces a TLDR, a reading decision, evidence-backed atoms, and a local
    review page

## Scope

Product skills in this directory should describe repository-owned product
behavior. They should target stable runtime command names rather than
repository-relative `node .../dist/index.js` paths.

In the current development phase, the only supported way to expose the
`missless` command is:

```bash
source scripts/dev-activate-missless.sh
missless ...
```

Skills should document that activation step whenever they rely on `missless`
and stay aligned with the canonical entrypoint described in the repository
docs.
