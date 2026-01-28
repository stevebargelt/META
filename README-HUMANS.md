# META Quick Start (Humans)

Short, practical setup for a new project using META.

## Fast Start (recommended)

```bash
./META/scripts/new-project.sh my-project
```

This will also launch the `meta` orchestrator by default. Use `--no-orchestrate` to skip.

Optional:
```bash
# Preselect tool + auto-launch kickoff (if CLI is installed)
./META/scripts/new-project.sh my-project --tool codex --kickoff
```

The script prints a kickoff prompt. Paste it into chat and answer the questions.
The system will write `AGENTS.md`, create `docs/PRD.md`, then start building.

## Orchestrate with meta (tmux)

```bash
./META/scripts/meta run feature --project ~/code/my-project --task "Add JWT auth"
```

Use `meta list` to see available pipelines, `meta doctor` to verify tmux + CLI setup, and `meta status` / `meta resume` / `meta abort` to manage runs.

## Kickoff (hands-off, human-in-the-loop)

Use the kickoff prompt to answer a short question set and let the system
write `AGENTS.md` (with `CLAUDE.md` symlinked to it), then hand off to the
Product Manager agent for the PRD, and finally to the Orchestrator:

```
Start a project kickoff using META/prompts/kickoff.md
Project path: ~/code/my-project
```

## Manual Start (if you prefer)

```bash
cd ~/code
mkdir my-project && cd my-project
git init
cp ../META/prompts/project-template.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
mkdir -p docs
cp ../META/prompts/prd-template.md docs/PRD.md
```

Then start building.

---

Tip: Always keep `AGENTS.md` as the source of truth and symlink `CLAUDE.md` to it.
