# New Project Workflow

End-to-end process for starting a new AI-assisted project.

## Before You Start

### Questions to Answer

1. **What are you building?** — One sentence description
2. **Why are you building it?** — What problem does it solve?
3. **Who is it for?** — You, others, production users?
4. **How complex is it?** — Quick prototype, side project, or serious build?
5. **What's the timeline?** — Weekend hack, ongoing project, or time-boxed?

### Pick Your Agent Approach

**Simple project** (< 1 week, straightforward):
- Use `agents/base.md` only
- Add project-specific context to project AGENTS.md

**Medium project** (1-4 weeks, some complexity):
- Use product manager + architect for planning
- Use reviewer for critical code

**Complex project** (> 1 month, production-bound):
- Use full multi-agent workflow
- See `workflows/multi-agent.md`

## Setup Steps

### 0. Automated Setup (Recommended)

```bash
./META/scripts/new-project.sh my-project --git
```

This scaffolds the project and launches the `meta` pipeline (`project`) by default.
Use `--no-orchestrate` to follow the manual steps below.

### 1. Create Project Directory

```bash
cd ~/code
mkdir project-name
cd project-name
```

### 2. Initialize Version Control

```bash
git init
echo "node_modules/" > .gitignore  # Adjust for your stack
git add .gitignore
git commit -m "Initial commit"
```

### 3. Create Project AGENTS.md

Copy the template:

```bash
cp ../META/prompts/project-template.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
```

Fill in:
- Project name and purpose
- Tech stack
- Key commands (how to run, test, build)
- Project-specific rules
- Project structure (prefer feature-first)

**Default structure:** Use feature-first (vertical slices) unless you have a clear reason not to.  
Reference: `META/patterns/project-structures/feature-first.md`

**Key decision:** Which agent(s) to inherit?

```markdown
# My Project

Inherits: ../META/agents/base.md

<!-- Or for specialized work: -->
<!-- Inherits: ../META/agents/architect.md -->
<!-- See also: ../META/workflows/multi-agent.md -->
```

### 4. Register the Project

Add to `META/project-registry.md`:

```markdown
| Project Name | `~/code/project-name/` | Active | [Status] |
```

### 4b. Create PRD (Recommended)

Create a one-page PRD at `docs/PRD.md` using:
`META/prompts/prd-template.md`

### 4c. Set Up CI Pipeline

Every project gets a CI pipeline from the start — not after "things are working."

1. Copy the pipeline from `META/patterns/deployment/ci-pipeline-node.md`
2. Configure thresholds per `META/patterns/deployment/quality-gates.md`
3. Run through `META/prompts/ci-setup-checklist.md`
4. Enable branch protection on `main`

### 4d. External Service Setup (If Applicable)

If you depend on Supabase or other services, document setup before feature work:

1. Run through `META/prompts/external-service-setup-checklist.md`
2. Add `.env.example` with required variables
3. Add schema/migrations or bootstrap steps
4. Ask early for required external info (API keys, URLs, project refs) and provide instructions on how to find them for external services

### 4e. Observability Baseline

Before building features, ensure a basic observability plan:

1. Run through `META/prompts/observability-checklist.md`
2. Use `META/patterns/api/observability-middleware.js` for correlation IDs + logging
3. Pair with `META/patterns/api/rest-error-handling.ts` to return correlation IDs

### 4f. Preflight Check

Before implementation starts, verify tooling and environment readiness:

1. Run `META/prompts/preflight-checklist.md`
2. Fix missing tools or envs before moving on

### 5. Architecture Phase (if applicable)

For medium/complex projects, start with architect agent:

**Prompt:**
```
I'm starting a new project: [description]

Tech stack considerations: [preferences/constraints]
Target users: [who will use this]
Key requirements: [must-haves]

Please help me design the architecture.
Use META/patterns/project-structures/ARCHITECTURE-template.md as the structure.
Include Mermaid diagrams for system overview and key flows.
```

Architect will create:
- System design with Mermaid diagrams
- Component breakdown
- Key decisions documented
- Implementation order
- Data model (ER diagram)

Save this as `ARCHITECTURE.md` in your project.

**Template available at:**
`META/patterns/project-structures/ARCHITECTURE-template.md`

### 5b. Contract Stub (Required before parallel work)

If you plan to run parallel workstreams, create a minimal contract stub first:

1. Use `META/prompts/contract-stub.md` (OpenAPI required for parallel work)
2. Save to `docs/openapi.yaml` (fallback only with explicit justification)
3. Update `.handoff.md` with the contract stub summary
4. If `docs/openapi.yaml` exists, plan an OpenAPI validation step using `META/prompts/openapi-validation.md`

### 5c. Parallelization Planning (Required for multi-agent runs)

Before implementation starts, decide what can run in parallel and why:

1. Identify independent workstreams (e.g., client vs server)
2. Assign `PARALLEL_GROUP` labels in the pipeline
3. If nothing is parallelizable, document the reason in `.handoff.md`

Template for `.handoff.md`:

```markdown
## Parallelization Decision

**Parallel groups:** [list or "none"]
**Reason:** [Why parallelism is unsafe or not applicable]
**Revisit point:** [When to re-evaluate parallelism]
```

### 6. Initial Implementation

**Simple project:**
Start coding with base agent, reference patterns from `META/patterns/` as needed.

**Medium/Complex project:**
Follow implementation order from architecture, use base agent for each component.

### 7. Quality Gates

At key points, use reviewer agent:

- After auth implementation
- After API endpoints defined
- After data handling logic
- Before any "done" declaration

### 8. Documentation

Use documenter agent or base agent to create:

- **README.md** — Quick start guide (use `META/prompts/readme-template.md`)
- **API docs** — If applicable
- **Architecture docs** — For complex projects

## Project Structure Template

Start simple, add as needed:

```
project-name/
├── AGENTS.md           # Agent definition
├── CLAUDE.md           # Symlink to AGENTS.md (tool compatibility)
├── README.md           # Quick start
├── ARCHITECTURE.md     # System design (if applicable)
├── src/                # Source code
├── tests/              # Tests
└── docs/               # Extended documentation (if needed)
```

Don't create elaborate structures upfront.

## First Commit

After basic structure is in place:

```bash
git add .
git commit -m "chore: project setup

- Add AGENTS.md with project context
- Add README with quick start
- Initialize project structure

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

For ongoing work, use `META/prompts/git-hygiene-checklist.md`.

## Development Workflow

### Daily Pattern

1. **Start session** — Review what's done, what's next
2. **Implement** — Use appropriate agent(s)
3. **Test** — Verify it works
4. **Commit** — Save working state
5. **Update AGENTS.md** — If you learned something about the project

### When to Use Which Agent

**Base Agent:**
- Standard implementation
- Bug fixes
- Refactoring existing code

**Architect Agent:**
- Planning new features
- Significant structural changes
- Technical decisions

**Reviewer Agent:**
- Security-sensitive code
- Before merging significant changes
- When you want a second opinion

**Debugger Agent:**
- Complex bugs
- Performance issues
- Mysterious failures

**Documenter Agent:**
- API documentation
- Major features needing docs
- Architecture documentation

See `workflows/multi-agent.md` for coordination.

## Context Management

### Keep AGENTS.md Lean

Include:
- ✅ Project purpose and tech stack
- ✅ How to run/test/build
- ✅ Current focus area
- ✅ Project-specific rules

Don't include:
- ❌ Full codebase documentation
- ❌ Implementation details
- ❌ Temporary notes

### Use Git for History

Don't maintain long "what we did" lists in AGENTS.md. Use:
- Git commits for what changed
- Git tags for milestones
- ARCHITECTURE.md for design decisions

## Milestones

### After Each Significant Milestone

1. **Tag the release**
   ```bash
   git tag v0.1.0 -m "First working version"
   ```

2. **Create retrospective**
   Copy `META/learnings/retrospective-template.md` and fill it out.

3. **Update META**
   - Add patterns to `META/patterns/` if you found reusable code
   - Update `META/learnings/what-works.md` or `what-doesnt.md`
   - Update `META/learnings/model-comparison.md` if you learned about models

4. **Update project AGENTS.md**
   - Move completed items from "Current Focus"
   - Add new focus areas
   - Update "Known Issues" if applicable

## Project Completion

When project is done (or paused):

### 1. Final Documentation
- Ensure README is current
- Document deployment if applicable
- Note any known limitations

### 2. Final Retrospective
Create detailed retrospective in `META/learnings/YYYY-MM-project-name.md`

### 3. Extract Value
- Move reusable code to `META/patterns/`
- Update agent definitions if you discovered better approaches
- Update `META/learnings/` files

### 4. Update Registry
Mark project as complete/paused in `META/project-registry.md`

### 5. Archive or Deploy
- Push to GitHub if applicable
- Deploy if production
- Archive if learning project

## Common Pitfalls

### Starting Too Big
Don't create elaborate folder structures, configs, and tooling before writing code.

Start with: `src/main.js` and `README.md`

Add structure when needed.

### Not Using Patterns
Don't reinvent auth, error handling, testing setup. Check `META/patterns/` first.

### Skipping Documentation
Write README early. Future you will thank present you.

### Not Updating META
When you learn something useful, update META immediately. Don't wait until project ends.

## Quick Reference

```bash
# Start new project
cd ~/code && mkdir project && cd project
git init
cp ../META/prompts/project-template.md AGENTS.md
ln -s AGENTS.md CLAUDE.md
# Edit AGENTS.md
# Add to META/project-registry.md

# During development
# - Use appropriate agents
# - Reference META/patterns/
# - Commit working states
# - Update AGENTS.md when you learn

# At milestones
git tag v0.x.0
# Fill retrospective
# Update META

# When complete
# Final retrospective
# Extract patterns
# Update registry
```

See `workflows/multi-agent.md` for agent coordination.
