# Scripts

Lightweight helpers to start projects and keep workflows consistent.

## new-project.sh

```bash
./scripts/new-project.sh my-project --git
```

Creates a project in `~/code`, copies `AGENTS.md`, and adds `docs/PRD.md`.

Options:
- `--base <path>` set a different base directory
- `--agent-file <name>` use a tool-specific filename
- `--no-prd` skip PRD creation
- `--git` initialize git

## agent.sh

```bash
./scripts/agent.sh architect --project ~/code/my-project
```

Creates `.handoff.md` (or `.handoff-<stream>.md`) for a target agent.

## add-pattern.sh

```bash
./scripts/add-pattern.sh api rest-error-handling
```

Scaffolds a new pattern file under `patterns/<category>/`.

## retrospective.sh

```bash
./scripts/retrospective.sh my-project
```

Creates a dated retrospective file in `learnings/`.
