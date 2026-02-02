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

## GitHub Issues

Task tracking lives in GitHub Issues: https://github.com/stevebargelt/META/issues

```bash
# List open issues
gh issue list

# View specific issue
gh issue view <number>

# Create new issue
gh issue create --title "Title" --body "Description"

# Close issue
gh issue close <number>
```

**Issue labels:**
- `enhancement` - New features or improvements
- `bug` - Something isn't working
- `documentation` - Documentation updates
- `pipeline` - Related to meta CLI or pipelines

Check open issues before starting work to see current priorities and avoid duplicating effort.

## Recent Test Apps

Check `learnings/` for retrospectives from test-app through test-app-7. These document what worked, what didn't, and improvements made.

## Getting Started

1. Read the files listed in "Read These First"
2. Run `gh issue list` to see current open issues
3. Let me know you're ready to work on the codebase

## Current State

*Last updated: 2026-01-29*

### Recently Completed

- **Gate wait time tracking** - Pipeline now reports execution time vs gate wait time separately
- **Feature pipeline parallelism** - Steps 4-6 (tester, backend, frontend) now run in parallel
- **Feature branch workflow** - Feature pipeline creates `feature/<name>` branch at start
- **Separate feature PRDs** - Creates `docs/PRD-<feature>.md` instead of appending to main PRD
- **Auto-close panes** - Tmux windows close automatically after step completion
- **test-app-7 retrospective** - Documented in `learnings/2026-01-29-test-app-7.md`

### Known Gaps / Open Issues

1. **No E2E testing in pipelines** - Code passes unit/integration tests but can break in browser (e.g., test-app-7 Create Recipe bug). Need to add Playwright smoke tests.

2. **`resume` command doesn't auto-detect next.pipeline** - After project pipeline completes and generates `.meta/next.pipeline`, user must manually run it with `--continue` flag. Could enhance `resume` to auto-detect and offer to run it.

3. **Quality gate monorepo handling** - `quality-gate.sh` assumes single `package.json`. Monorepos with separate server/client need special handling.

### Test App Status

- **test-app-7** (Recipe Manager) - Most recent. Express + SQLite backend, React frontend. Bug fixed (Create Recipe). Local git only, no GitHub remote.
- Previous test apps (1-6) documented in `learnings/` retrospectives

### Next Steps to Consider

- Add Playwright smoke test step to feature.pipeline
- Enhance `resume` to detect and run next.pipeline
- Update quality-gate.sh for monorepo support
