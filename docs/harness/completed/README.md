# Completed Harness Plans

Status: Completed

## Purpose

Store completed harness/workflow plans as durable execution history.

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
find docs/harness/completed -maxdepth 1 -name '*.md' ! -name 'README.md' -exec basename {} \; \
  | while read -r file; do
      rg -q "$file" docs/harness/completed/README.md || echo "missing:$file"
    done
```

## Catalog

| Plan | Date | Summary |
| --- | --- | --- |
| [`2026-03-05-skill-flow-calibration.md`](./2026-03-05-skill-flow-calibration.md) | 2026-03-05 | Calibrated task intake, discovery behavior, and plan handoff rules. |
| [`2026-03-06-discovery-option-framing.md`](./2026-03-06-discovery-option-framing.md) | 2026-03-06 | Refined discovery option framing to support concise 2-4 options with brief tradeoffs. |
| [`2026-03-09-post-first-slice-loop-remediation.md`](./2026-03-09-post-first-slice-loop-remediation.md) | 2026-03-09 | Captured the harness/process gaps exposed by the first product slice and separated delivered workflow clarifications from deferred harness follow-ups. |
| [`2026-03-10-issue-first-intake-migration.md`](./2026-03-10-issue-first-intake-migration.md) | 2026-03-10 | Migrated backlog intake from repository trackers to GitHub Issues and removed the old tracker files. |
| [`2026-03-11-reviewer-spawn-helper.md`](./2026-03-11-reviewer-spawn-helper.md) | 2026-03-11 | Added a runtime-agnostic reviewer launch manifest helper so review-loop dimension selection stays configurable while orchestration becomes less manual. |
| [`2026-03-11-stateful-harness-gate-hardening.md`](./2026-03-11-stateful-harness-gate-hardening.md) | 2026-03-11 | Hardened publish/final-gate/land state checks against stale repo refs, stale plan state, and incomplete machine-readable gate inputs. |
| [`2026-03-12-harness-closeout-reliability.md`](./2026-03-12-harness-closeout-reliability.md) | 2026-03-12 | Made closeout records summary-first, added repository-readiness preflight reuse, retained one final-evidence bundle per plan, and treated remote merge success as authoritative during landing. |
| [`2026-03-13-reviewer-contract-hardening.md`](./2026-03-13-reviewer-contract-hardening.md) | 2026-03-13 | Hardened reviewer-round contracts so missing reviewer output fails closed, fallback reasons are explicit, and repo-observable reviewer side effects become contract violations. |
| [`2026-03-14-review-outcome-taxonomy-and-deferred-risks.md`](./2026-03-14-review-outcome-taxonomy-and-deferred-risks.md) | 2026-03-14 | Separated current-slice findings from accepted deferred risks and strategic observations, then enforced reviewer-subagent-first fallback eligibility with machine-readable dispatch records. |
| [`2026-03-15-local-cli-dev-install.md`](./2026-03-15-local-cli-dev-install.md) | 2026-03-15 | Added a session-local `missless` activation workflow for local development, removed the old global-link path, and archived the packaged-tarball blocker as follow-up issue `#42`. |
| [`2026-03-15-reviewer-scope-contract-hardening.md`](./2026-03-15-reviewer-scope-contract-hardening.md) | 2026-03-15 | Hardened reviewer aggregation so scope-mismatched reviewer artifacts fail closed and the contract is archived under harness history. |
