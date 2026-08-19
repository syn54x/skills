# syn54x/skills

Public [Agent Skills](https://agentskills.io) for coding agents (Cursor, Claude Code, Codex, and others).

## Skills

| Skill | Description |
|-------|-------------|
| [`coordinate`](coordinate/) | Run a batch of implementation work through sub-agents — research, brief, dispatch, and gate their PRs |
| [`eli5`](eli5/) | Explains a topic like the user is five and has ADD — tiny sentences, one analogy, then stop |
| [`scaffold-python-project`](scaffold-python-project/) | Opinionated Python project bootstrap with uv, prek, ruff, ty, pytest, zensical, GitHub Actions, and optional CLI/API/DB/AI stacks |

## Install

```bash
npx skills add syn54x/skills --skill coordinate
npx skills add syn54x/skills --skill scaffold-python-project
```

Global install (available across projects):

```bash
npx skills add syn54x/skills --skill coordinate -g
```

Install for all detected agents:

```bash
npx skills add syn54x/skills --skill coordinate --agent '*'
```

Skills in this repo follow the [Agent Skills](https://agentskills.io) format (`SKILL.md` with YAML frontmatter).
