# Documentation Style Guide

Status: Active

## Language

- Write all repository docs in English.
- Keep terms consistent with glossary definitions.

## Writing Rules

- Prefer short sections with explicit headings.
- Use concrete statements over vague recommendations.
- Separate normative requirements (`must`, `should`) from notes.

## Structure

Each major document should include:
- purpose
- scope
- explicit constraints
- links to related docs

Each `index.md` should include:
- status legend
- document catalog with status and one-line summary per document
- usage guidance (`when to read`)

## Change Hygiene

- Update links when files move.
- Mark deprecations explicitly with replacement references.
- Avoid duplicate policy text across multiple files.
- When deprecating a document, keep it listed in the nearest index with status `Deprecated`.
- For new documents, validate location with `docs/standards/document-placement-matrix.md`.
