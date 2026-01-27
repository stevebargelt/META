# Project Registry

Track all AI-assisted projects and their configurations.

## Active Projects

| Project | Path | Agent Status |
|---------|------|--------------|
| LED Scoreboard | `~/code/led-scoreboard/` | Needs agent config |
| MeatGeek | `~/code/meatgeek/` | Needs agent config |
| MycoGeek | `~/code/mycogeek/` | Needs agent config |

## Agent Inheritance

All project agent config files should reference the base:

```markdown
# [Project Name]

Inherits: ../META/agents/base.md

## Project Context
[Description]

## Tech Stack
[Languages, frameworks, tools]

## Key Commands
[Build, test, deploy commands]

## Project-Specific Rules
[Anything beyond base agent]
```

## Cross-Model Notes

- Agent config is plain markdown; use a tool-appropriate filename (preferred: `AGENTS.md`)
- Tool-calling schemas vary by provider; translate as needed
- Context windows differ by model

## Adding New Projects

1. Create project folder in `~/code/`
2. Add an agent config file (preferred: `AGENTS.md`) that inherits from META
3. Create a one-page PRD (default: `docs/PRD.md`) using `META/prompts/prd-template.md`
4. Update this registry
5. Add project-specific context as needed
