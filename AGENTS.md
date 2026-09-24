# AGENTS.md — syn54x/skills

Read `CONTEXT.md` for the domain glossary before working on any skill.

## Agent skills

### Issue tracker

Issues and specs live in this repo's GitHub Issues, driven by the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles use their default label names (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` at the repo root plus `docs/adr/`. See `docs/agents/domain.md`.

<!-- sdd-routing -->
## Agent workflow

- Specs and plans live in GitHub Issues. Never create `docs/plans`, `docs/specs`, `.scratch/*/issues` or any plan file in the repo.
- Plan with `/grill-with-docs` → `/to-spec` → `/to-tickets-plus`. Build with `/build-epic <epic#>` (M/L/XL) or `/implement-issue <N>` (one ticket).
- Do not use brainstorming, writing-plans, ce-plan or any other plan-writing skill. `/to-spec` owns the spec; `/to-tickets-plus` owns the plan.
- Workers: TDD, run the issue's **Verify** block, open a PR with `Closes #N`, never merge.
- Readiness = open + not blocked + unassigned + `ready-for-agent`. Claim by assigning yourself. Unclaim if you stop without a PR.
- Progress is one comment per issue under `<!-- sdd-progress -->`, rewritten in place. Never post a second one.
- Mode: org. Sizes: `size:S/M/L` labels. Priority: none.
- Upstream feedback: on. When on, `close-epic` may propose skill-defect issues on syn54x/skills, allowlisted fields only, each one shown and approved by a human before filing; never from a non-interactive run.
<!-- /sdd-routing -->
