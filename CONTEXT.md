# Domain context — syn54x/skills

Glossary for this skills package. Architecture terms (`module`, `interface`, `seam`, `depth`, …) follow the codebase-design vocabulary; this file names *skill-domain* concepts.

## Terms

| Term | Meaning |
|------|---------|
| **Skill package** | A directory with `SKILL.md` (+ optional supporting files) installable via `npx skills add`. |
| **Orchestrator** | `SKILL.md` — discovery, workflow, feature matrix, and policy. Thin interface over templates. |
| **Template bag** | `reference.md` — sole owner of file bodies agents copy into a new project. |
| **Feature matrix** | Table in the orchestrator: flag → deps / files / prek Δ / workflows / verify. The seam between policy and templates. |
| **Baseline** | Always-on feature row. Python: settings, observability facade, tooling, CI, release. Frontend: Vite/React/Biome/TanStack/shadcn, tooling, CI, tag-driven release. |
| **Feature flag** | Optional matrix row selected in discovery. Python: `cli`, `api`, `database`, `logfire`, `docs`, `pypi`, `mattpocock`. Frontend: `e2e`, `api`, `mattpocock`. |
| **Observability facade** | Python only — always-scaffolded `observability.py`; Logfire is an optional adapter behind the same interface. |
| **Verify** | Baseline gate plus per-flag smoke probes from the matrix `verify` column. |

## Non-goals (this repo)

- Not an application runtime — skills instruct agents; they are not executed as product code.
