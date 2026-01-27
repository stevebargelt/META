# META Quick Start (Humans)

Short, practical setup for a new project using META.

## 1) Create a project

```bash
cd ~/code
mkdir my-project && cd my-project
git init
```

## 2) Add the agent config (model-agnostic)

```bash
cp ../META/prompts/project-template.md AGENTS.md
```

Fill in the basics: purpose, stack, commands, structure (feature-first).

## 3) (Recommended) Create a one-page PRD

```bash
mkdir -p docs
cp ../META/prompts/prd-template.md docs/PRD.md
```

## 4) Register the project

Add it to `META/project-registry.md`.

## 5) Build

Start coding. Reference `META/patterns/` and `META/workflows/` as needed.

---

Tip: If your tool requires a specific filename (e.g., `CLAUDE.md`), use that name
but keep the contents the same as `AGENTS.md`.
