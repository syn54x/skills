# syn54x/skills

Public [Agent Skills](https://agentskills.io) for coding agents (Cursor, Claude Code, Codex, and others).

## Skills

| Skill | Description |
|-------|-------------|
| [`coordinate`](coordinate/) | Run a batch of implementation work through sub-agents — research, brief, dispatch, and gate their PRs |
| [`adhd`](adhd/) | Explains a topic in the shortest possible form — tiny sentences, lead with the point, then stop |
| [`eli5`](eli5/) | Explains a complex topic in plain language with one concrete analogy |
| [`prepare-release-notes`](prepare-release-notes/) | Drafts bloggy GitHub Release highlights from the delta since the last tag and prints the release command — never cuts the release |
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
