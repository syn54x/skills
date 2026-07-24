---
name: scaffold-python-project
description: Scaffolds new Python projects with uv, prek, ruff, ty, pytest, zensical, GitHub Actions (CI, docs deploy, release), pydantic, structlog, ferro-orm for databases, and optional cyclopts CLI, FastAPI/Litestar REST API, Pydantic AI, and Logfire. Use when the user asks to create, bootstrap, or scaffold a new Python project, package, library, CLI tool, or API service.
---

# Scaffold Python Project

Opinionated Python project bootstrap. Reference implementations: `syn54x/ttd`, `syn54x/ferro-orm`, `syn54x/mkdocs-typer2`.

## Discovery (ask before scaffolding)

Use `AskQuestion` when available; otherwise ask conversationally. Do not scaffold until answers are clear.

| Question | Options / notes |
|----------|-----------------|
| **Project kind** | `library` (PyPI package), `application` (deployable service), `cli-tool` (installable via `uv tool install`) |
| **Project name** | kebab-case for PyPI; derive `module_name` as snake_case |
| **Python version** | Default `>=3.13`; use `3.14` only when explicitly requested |
| **Target path** | New directory or existing empty directory |
| **CLI?** | If yes → cyclopts + `[project.scripts]` entry point |
| **REST API?** | If yes → ask `fastapi` or `litestar` (Litestar is the successor to Starlite) |
| **AI / agents?** | If yes → add `pydantic-ai` |
| **Database?** | If yes → **ferro-orm** (only ORM; no SQLAlchemy/raw sqlite3 for app persistence) |
| **Logfire telemetry?** | If yes → add `logfire` + observability module (see [reference.md](reference.md)) |
| **Docs site?** | Default yes → zensical with `docs/pages/` + `docs.yml` workflow |
| **PyPI publish?** | Default yes for library/CLI; skip publish jobs for private apps |
| **Commit lockfile?** | `uv.lock` in VCS for apps/CLI; optional for libraries (note in README) |
| **GitHub org/repo** | Needed for release workflow placeholders (`owner`, `repo`, PyPI project URL) |

Collect author name/email if not inferable from git config.

## Scaffolding workflow

Copy this checklist and track progress:

```
- [ ] 1. Discovery complete
- [ ] 2. uv init + src layout
- [ ] 3. .gitignore (GitHub Python.gitignore)
- [ ] 4. pyproject.toml
- [ ] 5. prek.toml + dev deps
- [ ] 6. Tool configs (ruff, ty, pytest, commitizen)
- [ ] 7. zensical.toml + docs/pages/index.md
- [ ] 7b. Agent guidelines: `AGENTS.md` + `docs/agents/design.md`
- [ ] 8. justfile (including `release` → `gh workflow run release.yml`)
- [ ] 9. Optional: settings, observability, CLI, API
- [ ] 10. GitHub workflows: `ci.yml`, `docs.yml`, `release.yml`
- [ ] 11. CHANGELOG.md stub + release secrets documented in README
- [ ] 12. uv sync && prek install
- [ ] 13. Verify: just check && prek run --all-files && uv run pytest
```

### Step 2 — uv init

```bash
cd <target-path>
uv init --name <pypi-name> --python <version>
```

Add flags by project kind:

| Kind | uv init flags | build backend |
|------|---------------|---------------|
| library | `--lib` or `--package` | `uv_build` (simple) or `hatchling` (entry points/plugins) |
| application | `--package` | `uv_build` |
| cli-tool | `--package` | `uv_build` + `[project.scripts]` |

Use **src layout**: `src/<module_name>/`. Move package into `src/` if `uv init` placed it at repo root.

Pin `[tool.uv.build-backend] module-name = "<module_name>"` when using `uv_build`.

### Step 3 — .gitignore

Fetch verbatim from GitHub (do not hand-edit):

```bash
curl -fsSL https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore -o .gitignore
```

Append project-specific lines after the fetch if needed (e.g. `.worktrees/`, `.cache/`).

### Step 4 — Core dependencies

Always add to `[project]`:

```toml
dependencies = [
    "pydantic>=2.0",
    "pydantic-settings>=2.0",
    "structlog>=24",
]
```

Conditional adds:

| Feature | Dependencies |
|---------|--------------|
| CLI | `cyclopts>=4` |
| REST (FastAPI) | `fastapi>=0.111`, `uvicorn[standard]>=0.29` |
| REST (Litestar) | `litestar[standard]>=2` |
| AI | `pydantic-ai>=2,<3` |
| Database | `ferro-orm[alembic]>=0.14,<0.15` |
| Logfire | `logfire>=4,<5` |

Dev group (`[dependency-groups] dev`) — **pytest is always required**:

```toml
dev = [
    "prek>=0.4",
    "ruff>=0.11",
    "ty>=0.0.1a0",
    "pytest>=8",
    "pytest-cov>=6",
    "commitizen>=4",
    "zensical>=0.0.45",
    "mkdocstrings-python>=1.16",
    "pymdown-extensions>=10.7",
]
```

Add `pytest-asyncio>=1.0` when the project uses async code (required for ferro-orm).

Set `[tool.uv] default-groups = ["dev"]`.

### Step 5 — prek (not pre-commit)

Use `prek.toml` (not `.pre-commit-config.yaml`). Prek is a pre-commit-compatible runner preferred over pre-commit itself.

Baseline hooks — see [reference.md](reference.md) for full `prek.toml`. Minimum:

1. `pre-commit-hooks` — trailing-whitespace, eof-fixer, check-yaml, check-toml
2. Local system hooks via `uv run`:
   - `ruff check --fix .`
   - `ruff format .`
   - `ty check src`
3. `commitizen` on `commit-msg` stage

Add when applicable:

- `zensical build --clean` (docs enabled)
- `cli-docs` generator hook (CLI projects with cyclopts)
- `pytest` in prek only if user wants commit-time tests (default: pytest in CI only, like ttd)

Install hooks:

```bash
uv sync
uv run prek install
uv run prek install --hook-type commit-msg  # if using commitizen
```

### Step 6 — Tool configs

Put in `pyproject.toml`:

- `[tool.ruff]` — `target-version`, `line-length = 100`, lint select `E,F,I,UP,B,SIM,RUF,TC,PTH`
- `[tool.ty.environment]` + `[tool.ty.src] include = ["src"]`
- `[tool.pytest.ini_options]` — `testpaths = ["tests"]`, `asyncio_mode = "auto"` if async
- `[tool.commitizen]` — `cz_conventional_commits`, `version_provider = "uv"` for uv-managed versions

### Step 7 — Documentation (zensical)

- Config file: `zensical.toml` at repo root
- Content: `docs/pages/` (not `docs/` root — zensical `docs_dir = "docs/pages"`)
- Start with `docs/pages/index.md` and `docs/pages/getting-started/installation.md`
- Add mkdocstrings handler pointing at `src/`

Serve locally: `uv run zensical serve`

### Step 7b — Agent guidelines

Scaffold on every project. Templates: [agent-guides.md](agent-guides.md).

| File | Content |
|------|---------|
| `AGENTS.md` | **I-1: Build the best solution, not the quickest** (verbatim invariant) + pointer to design guide |
| `docs/agents/design.md` | General software design guide (OOP/functional mix, Pydantic models, error handling, module organization) |

Substitute `<project-name>` in the design guide overview with the actual project name. Do not paraphrase the I-1 invariant text.

Optional later: add domain guides under `docs/agents/` (database, CLI, API, etc.) as the project grows — same pattern as `ferro-orm` (`docs/agents/domain.md`).

### Step 8 — justfile

Provide shortcuts (see [reference.md](reference.md)):

- `setup` — `uv sync` + `uv run prek install`
- `check` — ruff + ty (fast agent feedback loop)
- `test` — `uv run pytest`
- `docs-serve` — `uv run zensical serve`
- `docs-deploy` — `gh workflow run docs.yml --ref main`
- `release-smoke` — `uv build` + install-from-artifact smoke test
- `release` — local gate (`prek run --all-files` + `release-smoke`) then `gh workflow run release.yml --ref main`

Releases are **never** bumped locally — `just release` triggers the workflow; commitizen runs in CI.

### Step 9 — Optional modules

Scaffold only what discovery selected. Templates in [reference.md](reference.md):

| Module | When |
|--------|------|
| `src/<pkg>/settings.py` | Always (pydantic-settings `BaseSettings`) |
| `src/<pkg>/observability.py` | Logfire enabled |
| `src/<pkg>/cli/app.py` | CLI enabled (cyclopts root `App`) |
| `src/<pkg>/api/app.py` | REST API enabled |
| `src/<pkg>/storage/db.py` + `storage/models/` | Database enabled (**ferro-orm only**) |
| `tests/conftest.py` with async `db` fixture | Database enabled |
| `tests/test_health.py` | Always (smoke import test) |

**Database rules:** use ferro-orm for all app persistence. Pin `ferro-orm[alembic]`. Use `connect(..., migrate_updates=True)` for bootstrap; Alembic bridge when migration history is needed. Register models via side-effect import before `connect`. Reference: `syn54x/ttd`.

### Step 10 — GitHub workflows

Scaffold three workflows under `.github/workflows/`. Full templates: [reference.md](reference.md). Pattern follows `syn54x/ttd`.

#### `ci.yml` — PRs and pushes to main

| Job | Runs |
|-----|------|
| `lint` | `prek run --all-files` |
| `test` | `pytest` (matrix: ubuntu + macos × python versions) |
| `pr-title` | `amannn/action-semantic-pull-request` (PRs only) |

#### `docs.yml` — standalone docs deploy

- Trigger: `workflow_dispatch` only (not on every push)
- Also expose `workflow_call` so `release.yml` can invoke it
- Build with `uv run zensical build --clean`, deploy to GitHub Pages
- Requires repo Settings → Pages → GitHub Actions

#### `release.yml` — version bump, tag, PyPI, GitHub Release, docs

Triggered by `workflow_dispatch` (from `just release`). Job order:

1. **`gate`** — `prek run --all-files` + `pytest` (same bar as CI)
2. **`release`** — `cz bump --yes --check-consistency --changelog`; push commit + tag
3. **`publish`** — `uv build` → PyPI via trusted publishing (`pypi` environment)
4. **`github-release`** — attach wheels/sdist + changelog body to GitHub Release
5. **`docs`** — `workflow_call` to `docs.yml` at `main` post-release

Release workflow needs org/repo variables (document in README):

| Name | Kind | Purpose |
|------|------|---------|
| `RELEASE_APP_ID` | variable | GitHub App ID for push + release creation |
| `RELEASE_APP_PRIVATE_KEY` | secret | App private key |
| PyPI trusted publisher | environment | `pypi` environment on `release.yml` `publish` job |

Substitute `<github_owner>`, `<github_repo>`, `<pypi-package-name>` in workflow templates.

Skip `publish` / `github-release` jobs when discovery says no PyPI (private apps).

### Step 11 — CHANGELOG.md

Seed with commitizen header only — versions are added by `cz bump` at release:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

This file is generated by [commitizen](https://github.com/commitizen-tools/commitizen) at release time.
```

### Step 12 — README stub

Include:

```markdown
## Development

uv sync
uv run prek install
prek run --all-files   # full CI parity
just check             # fast lint + types
uv run pytest

## Release

just release           # local gate + trigger release workflow
just docs-deploy       # deploy docs without releasing
```

## Recommended prek extras (offer during discovery)

| Hook | Purpose |
|------|---------|
| commitizen | Conventional commits on commit-msg |
| zensical build | Catch broken docs before push |
| pytest | Commit-time tests (slower; usually CI-only) |
| custom `cli-docs` | Regenerate cyclopts reference pages |

## Anti-patterns

- Do not bump versions locally — use `just release` → release workflow
- Do not use SQLAlchemy, raw `sqlite3`, or another ORM for app persistence — use ferro-orm
- Do not combine docs deploy into `ci.yml` — keep `docs.yml` separate
- Do not omit pytest from dev dependencies
- Do not use `.pre-commit-config.yaml` when `prek.toml` suffices
- Do not put docs content at `docs/` root — use `docs/pages/`
- Do not use `mypy` — use `ty`
- Do not hand-write `.gitignore` — fetch GitHub Python.gitignore
- Do not import `structlog` or `logfire` outside the observability facade
- Do not skip `pydantic-settings` for configuration

## Additional resources

- Full file templates: [reference.md](reference.md)
- Agent guideline templates: [agent-guides.md](agent-guides.md)
- Example repos: https://github.com/syn54x/ttd, https://github.com/syn54x/ferro-orm, https://github.com/syn54x/mkdocs-typer2
