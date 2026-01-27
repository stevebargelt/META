# META Quick Start (Humans)

Short, practical setup for a new project using META.

## Fast Start (recommended)

```bash
./META/scripts/new-project.sh my-project --git
```

Open `~/code/my-project/AGENTS.md` and fill in the basics. Done.

## Manual Start (if you prefer)

```bash
cd ~/code
mkdir my-project && cd my-project
git init
cp ../META/prompts/project-template.md AGENTS.md
mkdir -p docs
cp ../META/prompts/prd-template.md docs/PRD.md
```

Add the project to `META/project-registry.md`, then start building.

---

Tip: If your tool requires a specific filename (e.g., `CLAUDE.md`), use that name
but keep the contents the same as `AGENTS.md`.
