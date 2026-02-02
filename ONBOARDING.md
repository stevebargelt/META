# META Framework Onboarding Prompt

Use this prompt to onboard a new Claude instance to the META codebase.

---

I need you to understand and work on the META codebase at ~/code/META.

## What META Is

META is an AI-assisted project orchestration framework. Its philosophy: every project should make all future projects better through knowledge compounding.

Core capabilities:
1. **Specialized agents** (agents/*.md) - base, architect, reviewer, tester, etc.
2. **Tmux pipeline orchestration** (scripts/meta) - automated multi-step workflows
3. **Reusable patterns** (patterns/) - battle-tested code snippets
4. **Knowledge capture** (learnings/) - what-works.md, what-doesnt.md, retrospectives

## Key Concepts

- **Contract-first**: OpenAPI spec created before parallel work starts
- **Parallelism**: Steps with same `PARALLEL_GROUP` value run concurrently
- **Build validation**: After parallel merge, run `npm run build && npm test`
- **Two-stage quality gates**: DoD checklist (human judgment) + quality-gate.sh (machine verification)
- **Handoff files**: .meta/handoff.md maintains state between steps/agents
- **Auto-commit**: Each step commits with `meta: step N (agent) complete`

## Pipeline Format

```
# NUM | AGENT | CLI | GATE | PARALLEL_GROUP | TIMEOUT_MIN | PROMPT
1 | base | - | auto | - | 15 | Your task here
2 | base | - | auto | dev | 30 | Backend work
3 | base | - | auto | dev | 30 | Frontend work (runs parallel with step 2)
4 | base | - | auto | - | 10 | Build validation after parallel merge
```

## Read These First

1. `README.md` - Overview
2. `agents/base.md` - Foundation for all agents
3. `agents/orchestrator.md` - How pipelines are generated
4. `workflows/pipelines/feature.pipeline` - Feature development flow with parallelism
5. `learnings/what-works.md` - Proven patterns
6. `learnings/what-doesnt.md` - Anti-patterns to avoid

## Commands

```bash
# Start a new pipeline
./scripts/meta run <pipeline> --project <path> --task "description"

# Run follow-on pipeline (preserves handoff context)
./scripts/meta run <pipeline> --project <path> --continue

# Check pipeline status
./scripts/meta status --project <path>

# Create new project
./scripts/new-project.sh <name> --git

# List available pipelines
./scripts/meta list
```

## Directory Structure

```
META/
├── agents/           # Specialized AI agent definitions
├── workflows/        # Multi-agent coordination + pipelines
│   └── pipelines/    # .pipeline files (project, feature, bugfix, refactor)
├── patterns/         # Reusable code snippets and configs
├── learnings/        # Knowledge capture (retrospectives, what-works/doesnt)
├── scripts/          # meta CLI, new-project.sh, quality-gate.sh
├── prompts/          # Task-specific prompt templates
└── standards/        # Engineering baseline requirements
```

## Recent Test Apps

Check `learnings/` for retrospectives from test-app through test-app-7. These document what worked, what didn't, and improvements made.

## Getting Started

Please start by reading the files listed in "Read These First", then let me know you're ready to work on the codebase.
