# Skills and Standards Alignment

Status: Active

## Purpose

Clarify overlap boundaries between repository standards and repository-local skills.

## Rule of Authority

- Standards in `docs/standards/` are normative policy.
- Skills in `.agents/skills/` are operational playbooks that implement policy.
- If a skill and a standard conflict, standards win and the skill must be updated.

## Mapping

| Standard Area | Normative Source | Operational Skill/Asset |
| --- | --- | --- |
| Discovery and planning | `AGENTS.md`, `docs/exec-plans/templates/execution-plan-template.md` | `loop-discovery`, `loop-plan` |
| Step execution | `AGENTS.md` | `loop-execute` |
| Review loop | `docs/standards/review-and-merge-workflow.md` | `loop-review-loop`, `scripts/loop/review_*` |
| Final readiness | `docs/standards/review-and-merge-workflow.md` | `loop-final-gate`, `scripts/loop/final_gate.sh` |
| Landing discipline | `AGENTS.md`, `docs/standards/review-and-merge-workflow.md` | `loop-land` |
| Entropy control | `docs/standards/repo-governance.md` | `loop-janitor` |

## Maintenance Rule

When standards change, update affected skills in the same branch.
