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
behavior. They should target stable installed runtime commands rather than
repository-relative `node .../dist/index.js` paths, and they should not depend
on developer workflow notes to explain the user-facing contract.
