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
repository-relative `node .../dist/index.js` paths. When the current supported
contract is repo-local activation, the skill should document the activation
step needed to expose that command name and stay aligned with the canonical
entrypoint described in the repository docs.
