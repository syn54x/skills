# Routing block

Paste into `CLAUDE.md` (or `AGENTS.md`) of the target repo. Replace the `<...>` slots; drop the account line when only one `gh` login exists. The markers let `sdd-setup` rewrite the block in place on re-run.

```markdown
<!-- sdd-routing -->
## Agent workflow

- Specs and plans live in GitHub Issues. Never create `docs/plans`, `docs/specs`, `.scratch/*/issues` or any plan file in the repo.
- Plan with `/grill-with-docs` → `/to-spec` → `/to-tickets-plus`. Build with `/build-epic <epic#>` (M/L/XL) or `/implement-issue <N>` (one ticket).
- Do not use brainstorming, writing-plans, ce-plan or any other plan-writing skill. `/to-spec` owns the spec; `/to-tickets-plus` owns the plan.
- Workers: TDD, run the issue's **Verify** block, open a PR with `Closes #N`, never merge.
- Readiness = open + not blocked + unassigned + `ready-for-agent`. Claim by assigning yourself. Unclaim if you stop without a PR.
- Progress is one comment per issue under `<!-- sdd-progress -->`, rewritten in place. Never post a second one.
- Mode: <org | labels-only>. Sizes: <`size:S/M/L` labels | issue field `Effort`>. Priority: <none | issue field `Priority`>.
- GitHub account: <none | `0x054`>. When set, run `export GH_TOKEN="$(gh auth token -h github.com -u <account>)"` before the first `gh` call in a session; git is pinned by the repo's credential helper.
<!-- /sdd-routing -->
```
