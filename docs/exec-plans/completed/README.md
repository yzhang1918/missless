# Completed Execution Plans

Status: Active

## Purpose

Store completed plans as durable execution history.

## Rules

Each completed plan should include:
- intake source (`issue #...` or `direct request`)
- checked acceptance criteria
- completed step statuses
- delivered scope
- validation summary
- linked issue updates (if any)
- spawned follow-up issues (if any)
- when the catalog changes, a validation check that every completed plan file in this folder is listed below

Older archived plans may preserve equivalent metadata or evidence wording when the workflow later evolved.

Recommended catalog sync check:

```sh
find docs/exec-plans/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \; \
  | while read -r file; do
      rg -q "$file" docs/exec-plans/completed/README.md || echo "missing:$file"
    done
```

## Catalog

| Plan | Date | Summary |
| --- | --- | --- |
| [`2026-03-06-evidence-contract-first-slice.md`](./2026-03-06-evidence-contract-first-slice.md) | 2026-03-06 | Locked a pre-implementation `Segment`-oriented evidence plan and the first delivery slice acceptance bar; later implementation history superseded the shipped first-slice contract with anchored evidence run artifacts. |
| [`2026-03-09-first-review-package-product-facing-v0.md`](./2026-03-09-first-review-package-product-facing-v0.md) | 2026-03-09 | Delivered the first URL-to-review-package slice and archived the whole branch as one unified TASK-0003 record. |
| [`2026-03-11-installable-skill-stable-cli.md`](./2026-03-11-installable-skill-stable-cli.md) | 2026-03-11 | Repackaged the first-slice runtime behind an installable `missless` command, added tarball-install regression coverage, and closed the branch with recorded review-loop plus final-gate evidence. |
| [`2026-03-11-provider-boundary-ssrf-and-fallback.md`](./2026-03-11-provider-boundary-ssrf-and-fallback.md) | 2026-03-11 | Hardened provider-boundary SSRF checks across redirect hops and final destinations, added the default `Jina Reader -> direct origin fetch` fallback policy, and recorded review/final-gate evidence with the remaining branch-refresh blocker. |
| [`2026-03-12-hermetic-packaged-cli-regressions.md`](./2026-03-12-hermetic-packaged-cli-regressions.md) | 2026-03-12 | Kept the packaged CLI ESM, made fresh-cache offline tarball installs deterministic with bundled runtime dependencies, and extended installed-bin regressions to prove fallback plus redirect-preflight behavior without live network access. |

Harness/process plan history is stored separately under `docs/harness/completed/`.
