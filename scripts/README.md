# Scripts

Lightweight helpers to start projects and keep workflows consistent.

## meta

```bash
./scripts/meta run feature --project ~/code/my-project --task "Add JWT auth"
```

Tmux-based orchestrator for multi-agent pipelines.

Common commands:
- `meta list` — list available pipelines
- `meta doctor` — check tmux/CLI/pipeline health
- `meta status` — show current pipeline progress
- `meta resume` — continue last run
- `meta abort` — stop and clean up

Pipelines live in `workflows/pipelines/`.

## new-project.sh

```bash
./scripts/new-project.sh my-project --git
```

Creates a project in `~/code`, writes a `KICKOFF.md`, and prints the kickoff prompt.
Also creates `AGENTS.md` (placeholder) and a `CLAUDE.md` symlink.
The kickoff flow will overwrite `AGENTS.md` and create `docs/PRD.md`.

Options:
- `--base <path>` set a different base directory
- `--tool <claude|codex>` set tool defaults
- `--kickoff` auto-launch kickoff (alias for `--launch`)
- `--launch` start the CLI tool with the kickoff prompt as the initial message
- `--launch-cmd <cmd>` set the CLI command name
- If `--launch` is used without `--tool`, you must provide `--launch-cmd`.
- `--open` open `KICKOFF.md` in `$EDITOR` (or print if unset)
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
