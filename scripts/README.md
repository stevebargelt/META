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
- `meta doctor --project <path>` — also check project readiness (.env, node_modules, tests)
- `meta status` — show current pipeline progress
- `meta resume` — continue last run
- `meta abort` — stop and clean up
- `meta run ... --auto-approve` — auto-approve quality gates (use for test runs only)

Tmux layout:
- Control pane stays on top.
- When steps have `PARALLEL_GROUP`, META creates a tmux window per group with a sub-manager pane on top and workers below.

Optional env:
- `META_GATE_TMUX_SNAPSHOT=1` — include a brief tmux pane snapshot in gate prompts
- `META_GATE_TMUX_SNAPSHOT_LINES=6` — lines per pane (default 6)
- `META_GATE_TMUX_SNAPSHOT_PANES=4` — max panes (default 4)

Pipelines live in `workflows/pipelines/`.

## new-project.sh

```bash
./scripts/new-project.sh my-project
```

Creates a project in `~/code`, writes a `KICKOFF.md`, and prints the kickoff prompt.
Also copies `NO-AGENTS.md` to `AGENTS.md`, creates a `CLAUDE.md` symlink, and scaffolds `docs/`, `config/`, and `.meta/` directories.
The kickoff flow will overwrite `AGENTS.md` and create `docs/PRD.md`.

See `patterns/project-structures/config-directory.md` for config consolidation guidance.

By default, this also launches the `meta` orchestrator pipeline (`project`).
Use `--no-orchestrate` to keep the original manual kickoff flow.

Options:
- `--base <path>` set a different base directory
- `--tool <claude|codex>` set tool defaults
- `--task <desc>` initial task description for orchestration
- `--pipeline <name>` pipeline to run (default: `project`)
- `--unsafe` pass through to `meta` (claude only)
- `--auto-approve` auto-approve quality gates (test runs only)
- `--no-orchestrate` skip auto-orchestration
- `--kickoff` auto-launch kickoff (alias for `--launch`)
- `--launch` start the CLI tool with the kickoff prompt as the initial message
- `--launch-cmd <cmd>` set the CLI command name
- If `--launch` is used without `--tool`, you must provide `--launch-cmd`.
- `--open` open `KICKOFF.md` in `$EDITOR` (or print if unset)
- `--git` initialize git (default)
- `--no-git` skip git init

## agent.sh

```bash
./scripts/agent.sh architect --project ~/code/my-project
```

Creates `.meta/handoff.md` (or `.meta/handoff-<stream>.md`) for a target agent.

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
