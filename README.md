# syn54x/skills

Public [Agent Skills](https://agentskills.io) for coding agents (Cursor, Claude Code, Codex, and others).

## Skills

| Skill | Description |
|-------|-------------|
| [`coordinate`](coordinate/) | Run a batch of implementation work through sub-agents — research, brief, dispatch, and gate their PRs |
| [`coordinate-team`](coordinate-team/) | Run a batch of implementation work through Claude Code Agent Teams — research, brief, spawn teammates, and gate their plans and PRs |
| [`adhd`](adhd/) | Explains a topic in the shortest possible form — tiny sentences, lead with the point, then stop |
| [`eli5`](eli5/) | Explains a complex topic in plain language with one concrete analogy |
| [`prepare-release-notes`](prepare-release-notes/) | Drafts bloggy GitHub Release highlights from the delta since the last tag and prints the release command — never cuts the release |
| [`scaffold-python-project`](scaffold-python-project/) | Opinionated Python project bootstrap with uv, prek, ruff, ty, pytest, zensical, GitHub Actions, and optional CLI/API/DB/AI stacks |
| [`scaffold-frontend-project`](scaffold-frontend-project/) | Opinionated Vite + React SPA bootstrap with pnpm, Biome, TanStack Router/Query, Tailwind, shadcn/ui, prek, vitest, and GitHub Actions |

### Issue-native SDD

Spec-driven development where the **spec is an epic issue**, the **plan is its sub-issues** (native `--parent` / `--blocked-by`, `gh >= 2.94`), and **no plan files land in the repo**. The spine is [mattpocock/skills](https://github.com/mattpocock/skills) (`/grill-with-docs` → `/to-spec` → `/to-tickets` → `/triage`, `/tdd`); these skills sit on top of it for the build side.

#### Why this exists

Every spec-driven suite we surveyed (Superpowers, Compound Engineering, GSD, CCPM, PRPs, Spec Kit, BMAD, OpenSpec, cc-sdd, and a dozen smaller ones) keeps its plan in markdown files under `docs/plans/`, `.kiro/`, `openspec/` or similar. That has three costs:

- **Nobody reads the plan file.** Reviewers read issues and PRs. A plan that lives outside the tracker drifts from what shipped the moment the first PR merges, and the humans who need to approve the work never see it.
- **Two planners collide.** Install any two suites and they fight over who owns the plan, who owns the `CLAUDE.md` block, and which `/plan` command wins. Each one also preloads several thousand tokens into every session.
- **Orchestration is bespoke.** Each suite has its own executor loop reading its own file format, so the plan cannot be picked up by a different tool, a cloud runner, or a second person.

GitHub closed the gap in 2025–2026: sub-issues and issue types (Apr 2025), native blocked-by / blocking dependencies (Aug 2025), issue fields on org repos (Jul 2026), and `gh` 2.94 exposing all of it as flags (`--parent`, `--blocked-by`, `--type`) with JSON output. That makes the tracker itself a plan format any agent can read with one CLI and no extension.

So the design is a **cherry-pick, not a suite**:

- **mattpocock/skills is the spine** and stays untouched, so `npx skills update` keeps working. `/to-spec` already writes the epic; `/to-tickets` already cuts tracer-bullet sub-issues with blocking edges.
- **What was worth stealing became ticket sections**, not plugins: Compound Engineering's file ownership and verification contract, Superpowers' interfaces list, no-placeholder rule, fresh implementer and reviewer per task, CCPM's marker-based idempotent comments, gh-aw's sub-issue closer. All of it is `gh` and prose, so it runs the same under Claude Code, Codex, Cursor, or a shell.
- **Readiness is derived, never a status label**: open + no open blockers + unassigned + `ready-for-agent`. Claiming is assigning yourself. A status field that agents set is a status field that lies.
- **Worktree waves, not Agent Teams.** Teammates get no worktree isolation, the task tools are gated on an experimental flag, and a team costs several times the tokens of a wave. Every suite that tried teams either retreated to `Agent(isolation: "worktree")` or kept teams for discussion only.
- **Size decides the runtime.** Small tickets go to `claude-code-action` on a label; medium and large run as local waves; XL escalates to a dynamic workflow. Same `implement-issue` skill in every case.
- **The gates are hooks, not prose.** A worker on an `sdd/*` branch cannot stop without a recorded Verify run; a worktree with unpushed work cannot be removed.

Not adopted, and why: CCPM (unmaintained, wrong `gh-sub-issue` syntax), original GSD (archived, token rug-pull), Spec Kit's `taskstoissues` (one-way, no parent links), Agent OS (removed execution), oh-my-claudecode (teams-first, tmux), and the full Superpowers / Compound Engineering / ECC bundles as installed plugins alongside mattpocock (planner collisions, 3–22k tokens of preload). The ideas from the good ones are in the ticket sections above; the packages themselves are not dependencies.

| Skill | Description |
|-------|-------------|
| [`sdd-setup`](sdd-setup/) | Once per repo: check `gh`, create the readiness and size labels, enable issue types on org repos, write the CLAUDE.md routing block, optionally install the Actions workflows |
| [`to-tickets-plus`](to-tickets-plus/) | Run `/to-tickets`, then link sub-issues natively, add **Files owned / Interfaces / Test scenarios / Verify**, size them, and pin one plan comment on the epic |
| [`build-epic`](build-epic/) | Orchestrator: ready queue → layers → parallel-safety check → isolated worker waves (3–5) → fresh review per PR → merge in dependency order → close |
| [`implement-issue`](implement-issue/) | One worker, one issue, one PR with `Closes #N`; identical locally and inside `claude-code-action` |
| [`review-pr`](review-pr/) | Fresh reviewer per PR: re-runs Verify, separate **spec** and **quality** verdicts, one fix round, then `ready-for-human` |
| [`sync-progress`](sync-progress/) | Idempotent progress comments under `<!-- sdd-progress -->`; claim and unclaim by assignment |
| [`close-epic`](close-epic/) | All sub-issues closed → summary comment with ticket → PR table and Learnings → close the epic |

**Size ladder** (`to-tickets-plus` labels each ticket; the label picks the runtime):

| Size | Ticket shape | Trigger | Runs where | Reviewer |
|---|---|---|---|---|
| **S** | one context window, ≤ 3 files | label `ready-for-agent` | cloud: `claude-code-action` (`sdd-implement.yml`) | `sdd-review.yml` on the PR |
| **M** | needs its plan sections; 1–2 workers | `/build-epic` or `/implement-issue` | local worker in its own worktree | fresh reviewer subagent |
| **L** / epic | 3+ sub-issues, cross-cutting | `/build-epic` | local waves, 3–5 workers, worktree each | reviewer per PR |
| **XL** | 8+ independent sub-issues | `/build-epic --workflow` | dynamic workflow (Claude Code, `ultracode`) | scripted verify → merge order |

Dispatch is harness-agnostic: `build-epic/references/harness-dispatch.md` gives the concrete call for Claude Code (`Agent` + `isolation: "worktree"`, Agent Teams flag **unset**), Codex (subagent per worktree), Cursor (background agent per worktree), and a sequential fallback for anything else. Everything below the dispatch line is `gh` + prose and identical across tools.

Leave Superpowers, Compound Engineering and similar suites **uninstalled in target repos**; the routing block written by `sdd-setup` disables competing planners.

## Install

### As skills (any agent)

```bash
npx skills add syn54x/skills --skill coordinate
npx skills add syn54x/skills --skill scaffold-python-project
npx skills add syn54x/skills --skill scaffold-frontend-project

# the SDD set
npx skills add syn54x/skills --skill sdd-setup --skill to-tickets-plus --skill build-epic \
  --skill implement-issue --skill review-pr --skill sync-progress --skill close-epic
npx skills add mattpocock/skills          # the spine: to-spec, to-tickets, tdd, …
```

Global install (available across projects):

```bash
npx skills add syn54x/skills --skill coordinate -g
```

Install for all detected agents:

```bash
npx skills add syn54x/skills --skill coordinate --agent '*'
```

### As a Claude Code plugin

The `sdd` plugin bundles the seven SDD skills with the Claude-only extras: two agents (`sdd-worker` on a mid-tier model in a worktree, `sdd-reviewer` read-only + `gh`), hooks (a Stop/SubagentStop verify gate, a WorktreeRemove guard) and helper scripts (`ready.sh`, `layers.py`, `progress-comment.sh`).

```
/plugin marketplace add syn54x/skills
/plugin install sdd@syn54x-skills
```

Then, in each target repo: `/sdd-setup`. For the cloud path, it copies `sdd-implement.yml` and `sdd-review.yml` into `.github/workflows/`; add an `ANTHROPIC_API_KEY` secret or switch the templates to OIDC.

Skills in this repo follow the [Agent Skills](https://agentskills.io) format (`SKILL.md` with YAML frontmatter). The `sdd` plugin manifest lives in `.claude-plugin/`; its Claude-only extras are the root-level `agents/`, `hooks/` and `scripts/` directories, which `npx skills add` ignores.
