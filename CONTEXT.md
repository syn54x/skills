# Domain context — syn54x/skills

Glossary for this skills package. Architecture terms (`module`, `interface`, `seam`, `depth`, …) follow the codebase-design vocabulary; this file names *skill-domain* concepts.

## Terms

| Term | Meaning |
|------|---------|
| **Skill package** | A directory under `skills/` with `SKILL.md` (+ optional supporting files), installable via `npx skills add` or as part of the `syn54x-skills` plugin. |
| **Orchestrator** | `SKILL.md` — discovery, workflow, feature matrix, and policy. Thin interface over templates. |
| **Template bag** | `reference.md` — sole owner of file bodies agents copy into a new project. |
| **Feature matrix** | Table in the orchestrator: flag → deps / files / prek Δ / workflows / verify. The seam between policy and templates. |
| **Baseline** | Always-on feature row. Python: settings, observability facade, tooling, CI, release. Frontend: Vite/React/Biome/TanStack/shadcn, tooling, CI, tag-driven release. |
| **Feature flag** | Optional matrix row selected in discovery. Python: `cli`, `api`, `database`, `logfire`, `docs`, `pypi`, `mattpocock`. Frontend: `e2e`, `api`, `mattpocock`. |
| **Observability facade** | Python only — always-scaffolded `observability.py`; Logfire is an optional adapter behind the same interface. |
| **Verify** | Baseline gate plus per-flag smoke probes from the matrix `verify` column. |
| **Epic** | The spec: one GitHub issue (type `Epic` on org repos) written by `to-spec`. Its body is the human-readable spec; its `<!-- sdd-plan -->` comment is the plan. |
| **Sub-issue** | One tracer-bullet ticket under an epic, linked natively (`--parent`, `--blocked-by`). Carries **Files owned** (Create/Modify/Test), **Interfaces** (Consumes/Produces), **Test scenarios**, **Verify**. |
| **Ready queue** | Sub-issues that are open + no open blockers + unassigned + `ready-for-agent`. Derived by `gh`, never read from a status label. |
| **Layer** | Sub-issues whose blockers all sit in earlier layers. Layer 0 is the initial ready queue. |
| **Wave** | One concurrent dispatch of 3–5 workers over the current ready queue, one worktree each. |
| **Claim** | Assigning yourself to a sub-issue. Removes it from the ready queue; undone by unclaiming. |
| **Verify block** | The fenced commands in a sub-issue's `## Verify`; green means done. Recorded on the commit as `git notes --ref=sdd-verify`. |
| **Size ladder** | `size:S` → cloud (`claude-code-action`); `size:M`/`L` → local waves; XL → dynamic workflow. |
| **Multi-repo epic** | An epic whose sub-issues live in more than one repo (e.g. a frontend epic with backend tickets). Tickets are identified by URL; each repo gets its own integration branch, worktrees and PRs; cross-repo blockers must be merged **and available** (API deployed, client generated) before the consumer is ready. |
| **Harness dispatch** | The one line of `build-epic` that differs per tool; `references/harness-dispatch.md` holds the concrete calls. |

## Non-goals (this repo)

- Not an application runtime — skills instruct agents; they are not executed as product code.
- No plan files. Specs, plans and progress live in GitHub Issues; the SDD skills never write `docs/plans` or `docs/specs`.
