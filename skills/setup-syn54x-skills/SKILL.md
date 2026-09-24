---
name: setup-syn54x-skills
description: Configure a repo for the syn54x skills. Checks that mattpocock/skills is installed and configured for GitHub Issues, checks the gh version, creates the readiness and size labels, enables issue types on org repos, writes the routing block into CLAUDE.md or AGENTS.md, and optionally installs the GitHub Actions workflows. Run once per repo before to-tickets-plus, build-epic or implement-issue.
disable-model-invocation: true
---

# Setup syn54x skills

Configure the repo so specs, plans and progress all live in **GitHub Issues** and the build skills can find them. Prompt-driven: explore, present, confirm, then write.

Only the SDD set needs this: `to-tickets-plus`, `build-epic`, `implement-issue`, `review-pr`, `review-panel`, `sync-progress`, `close-epic`. The rest of the pack (`scaffold-python-project`, `scaffold-frontend-project`, `prepare-release-notes`, `adhd`, `eli5`) works with no per-repo configuration.

The SDD set sits on [mattpocock/skills](https://github.com/mattpocock/skills): its setup owns the issue tracker choice and the base triage labels, and this skill adds what the build side needs on top. Step 0 checks that the user has done both. This skill never installs or configures the upstream pack; both are the user's to run.

## 0. The spine: mattpocock/skills

Check, then stop or continue. Never install or configure anything in this step.

**Installed?** Are `to-spec`, `to-tickets`, `tdd`, `grill-with-docs` and `setup-matt-pocock-skills` among your available skills, or present on disk (`~/.agents/skills/<name>`, `.agents/skills/<name>`, `~/.claude/skills/<name>`, or the `mattpocock-skills` plugin)? Any one path counts.

If not, print this and stop:

> The syn54x SDD skills sit on mattpocock/skills, which is not installed. Install it, then run `/setup-syn54x-skills` again.
>
> As skills (any agent):
>
> ```bash
> npx skills add mattpocock/skills              # this project only
> npx skills add mattpocock/skills -g           # every project
> npx skills add mattpocock/skills --agent '*'  # every detected agent
> ```
>
> As a Claude Code plugin (editable in place):
>
> ```
> /plugin marketplace add mattpocock/skills
> /plugin install mattpocock-skills@mattpocock
> ```
>
> Pick one form; do not install both. New skills may need a session restart before they are invocable.

**Configured?** Does `docs/agents/issue-tracker.md` exist in the repo? `setup-matt-pocock-skills` writes it, so its presence means the upstream setup has run here.

If not, print this and stop:

> mattpocock/skills is installed but not configured for this repo. Run `/setup-matt-pocock-skills`, choose **GitHub** as the issue tracker and keep the default triage labels, then run `/setup-syn54x-skills` again.

`setup-matt-pocock-skills` is user-invoked only, so the user has to type it; do not try to reproduce it by hand.

**GitHub?** Read `docs/agents/issue-tracker.md`. Its first heading names the tracker. If it is not GitHub, stop:

> `docs/agents/issue-tracker.md` says issues live in <tracker>. The SDD skills need GitHub Issues: sub-issues, `--blocked-by` edges and the ready queue only exist there. Re-run `/setup-matt-pocock-skills` and choose GitHub, or skip the SDD set for this repo.

All three checks pass → step 1.

## 1. Preflight

```bash
gh --version                      # need 2.94+ for --parent / --blocked-by / --type
gh auth status
gh repo view --json nameWithOwner,owner --jq '{repo: .nameWithOwner, ownerType: .owner.type}'
```

- `gh` older than 2.94 → stop and tell the user to upgrade. Nothing else works without native sub-issues and dependencies.
- `ownerType` is `Organization` → **org mode**: issue types and issue fields are available.
- `ownerType` is `User` → **labels-only mode**: personal repos have no issue types or fields; sizes and priority are labels.
- `ownerType` is `null` → `gh repo view` hides it on some versions; fall back to `gh api repos/<owner>/<repo> --jq .owner.type`.

Also check: which of `CLAUDE.md` or `AGENTS.md` did the upstream setup write its `## Agent skills` block into? That is the file the routing block goes in. Does it already contain `<!-- sdd-routing -->`? Is `.github/workflows/` present?

## 2. Labels

Idempotent (`--force` updates colour and description if the label exists):

```bash
gh label create needs-plan      --color 0E8A16 --description "Epic approved as a spec; sub-issues not yet cut" --force
gh label create ready-for-agent --color 1D76DB --description "Unblocked and fully specified; an agent may claim it" --force
gh label create ready-for-human --color D93F0B --description "Needs a human decision, secret, or review" --force
gh label create needs-info      --color FBCA04 --description "Ticket is ambiguous; ask before building" --force
gh label create blocked         --color 5319E7 --description "Waiting on a dependency the tracker knows about" --force
gh label create size:S          --color C2E0C6 --description "One context window, <= 3 files; cloud-eligible" --force
gh label create size:M          --color BFD4F2 --description "Needs a plan; one or two local workers" --force
gh label create size:L          --color F9D0C4 --description "Cross-cutting or multi-worker; local waves only" --force
```

`needs-triage`, `wontfix` and the rest of the canonical triage vocabulary belong to mattpocock's `triage` skill, which creates them on first use; do not redefine them here.

## 3. Org mode extras (skip in labels-only mode)

Ask before creating. Issue types are org-wide, so the user may already have them.

```bash
ORG=$(gh repo view --json owner --jq .owner.login)
gh api "orgs/$ORG/issue-types" --jq '.[].name'
```

If `Epic` and `Task` are missing, offer to create them:

```bash
gh api -X POST "orgs/$ORG/issue-types" -f name=Epic -f description="A spec: problem, solution, stories, decisions" -F is_enabled=true -f color=purple
gh api -X POST "orgs/$ORG/issue-types" -f name=Task -f description="One tracer-bullet sub-issue of an epic" -F is_enabled=true -f color=blue
```

Issue **fields** (Priority, Effort) are optional. If the user wants them, they configure them in the repo's issue settings; record the field names in the routing block so `to-tickets-plus` sets them instead of `size:*` labels.

## 4. Routing block

Write the block from [routing-block.md](routing-block.md) into the file found in step 1, below the `## Agent skills` section:

- If `<!-- sdd-routing -->` is already present, replace that block in place. Never append a duplicate.
- Fill in the mode line (`org` / `labels-only`) and the field names if any.
- Ask about **upstream feedback**, default **off**: "When an epic closes, may `close-epic` propose skill-defect issues on syn54x/skills? Each one is shown to you first, contains only counts and category names (never repo names, URLs, titles, paths or code), and is filed under your GitHub account." Record `on` or `off` in the block. Show them the allowlisted template in `close-epic/references/skill-feedback.md` if they ask what leaves.

Show the user the rendered block before writing. The block **disables competing planners** on purpose: with mattpocock's `to-spec` owning the spec and `to-tickets-plus` owning the plan, a second brainstorming or plan-writing skill produces plan files that nobody reads. Leave Superpowers, Compound Engineering and similar suites uninstalled in this repo; if they are installed globally, the block tells the agent not to route through them.

## 5. GitHub Actions (optional)

Ask whether the user wants the **cloud path** for `size:S` tickets. If yes, copy both templates from [workflows/](workflows/) into `.github/workflows/`:

- `sdd-implement.yml` — runs `/implement-issue <N>` in `claude-code-action` when an issue is labelled `ready-for-agent` and carries `size:S`.
- `sdd-review.yml` — runs `/review-pr <N>` on every pull request that closes a sub-issue.

Then tell the user what to add and do not do it for them:

- A repository secret `ANTHROPIC_API_KEY`, **or** switch the `anthropic_api_key` input to OIDC workload identity per the action's docs. Which one is a project decision; the templates default to the secret and mark the OIDC lines.
- The `plugin_marketplaces` input in both templates points at `syn54x/skills`; change it if the repo uses a fork.

## 6. Done

Report in one table: what existed, what was created, what was skipped and why. Point at the next step: `/grill-with-docs` → `/to-spec` → `/to-tickets-plus`, then `/build-epic <epic#>` or a `ready-for-agent` label.
