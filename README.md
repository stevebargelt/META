# META

**Knowledge that compounds across AI-assisted projects.**

## Philosophy

Every project should make all projects better. When you solve something well, extract it. When you learn something valuable, document it. Over time, your META system becomes smarter, your projects start faster, and your patterns improve.

This is your central repository for:
- **Agent definitions** that improve with experience
- **Proven patterns** extracted from real projects
- **Learnings** captured and applied
- **Workflows** refined over time

## Structure

```
META/
├── agents/                      # Specialized AI agents
│   ├── base.md                  # Foundation (all agents inherit)
│   ├── product-manager.md       # PRD + scope definition
│   ├── architect.md             # System design & planning
│   ├── tester.md                # Test strategy & design
│   ├── reviewer.md              # Code review specialist
│   ├── debugger.md              # Debug specialist
│   ├── documenter.md            # Documentation writer
│   └── orchestrator.md          # Multi-agent coordinator
│
├── patterns/                    # Reusable code & configs
│   ├── api/                     # API patterns
│   ├── auth/                    # Auth patterns
│   ├── testing/                 # Testing approaches
│   ├── deployment/              # Deploy configs
│   └── project-structures/      # Full templates
│
├── learnings/                   # Knowledge that compounds
│   ├── retrospective-template.md    # Post-project template
│   ├── model-comparison.md          # Which model for what
│   ├── what-works.md                # Proven approaches
│   └── what-doesnt.md               # Anti-patterns
│
├── workflows/                   # Common scenarios
│   ├── new-project.md           # Project setup flow
│   ├── multi-agent.md           # Agent orchestration
│   ├── context-reset.md         # Handling long sessions
│   └── model-switching.md       # Moving between models
│
├── prompts/                     # Task-specific prompts
│   ├── code-review.md
│   ├── debugging.md
│   └── project-template.md
│
├── AGENTS.md                    # Model-agnostic entrypoint
├── CLAUDE.md                    # Legacy redirect to agents/base.md
├── project-registry.md          # Index of all projects
└── README.md                    # This file
```

## Quick Start

### New Project

```bash
cd ~/code
mkdir my-project && cd my-project
git init

# Copy project template
cp ../META/prompts/project-template.md AGENTS.md

# Edit AGENTS.md with:
# - Inherits: ../META/agents/base.md
# - Your project details

# Start coding with AI
# Reference: ../META/workflows/new-project.md
```

### Using Agents

**Simple project:** Use `agents/base.md` only

**Medium complexity:** Use `base.md` + `architect.md` for planning

**Complex/Production:** Use multi-agent workflow
- See `workflows/multi-agent.md`
- Example: Product Manager → Architect → Base → Reviewer → Documenter

### Referencing Patterns

Instead of explaining approaches to AI:

```markdown
❌ "Implement JWT auth with rotating refresh tokens..."

✅ "Use META/patterns/auth/jwt-refresh-rotation.md approach"
```

Patterns are proven code you can reference and adapt.

### Capturing Learnings

After completing a milestone:

```bash
# Copy retrospective template
cp META/learnings/retrospective-template.md \
   META/learnings/2026-01-my-project.md

# Fill it out, extract insights to:
# - learnings/what-works.md
# - learnings/what-doesnt.md
# - learnings/model-comparison.md
```

Your learnings make future projects faster and better.

## Core Concepts

### 1. Specialized Agents

Different tasks benefit from different agent specializations:

- **Base** — Your foundational agent, handles standard development
- **Product Manager** — Defines scope and writes concise PRDs
- **Architect** — Plans systems, makes design decisions, documents trade-offs
- **Tester** — Test strategy, test design, edge case identification
- **Reviewer** — Security and quality checks, finds issues before merge
- **Debugger** — Systematic problem diagnosis, root cause analysis
- **Documenter** — Clear, concise documentation that stays current
- **Orchestrator** — Coordinates multiple agents on complex tasks

Each agent inherits from `base.md` and adds specialized behaviors.

See `agents/` for full definitions.

### 2. Knowledge Compounding

The system gets smarter over time:

**Project 1:**
- Build auth system
- Extract pattern to `patterns/auth/`
- Document what worked in `learnings/what-works.md`

**Project 2:**
- Reference auth pattern from Project 1
- Starts faster, fewer mistakes
- Add improvements back to pattern
- Document new learnings

**Project 3:**
- Inherit improved pattern
- Even faster start
- Focus on new challenges
- Continue to compound

This is exponential improvement.

### 3. Pattern Library

`patterns/` contains code/config you've proven works:

- **API patterns** — Error handling, pagination, validation
- **Auth patterns** — JWT, OAuth, session management
- **Testing patterns** — Setup, fixtures, strategies
- **Deployment patterns** — CI/CD, Docker, infrastructure
- **Project structures** — Full templates for new projects

Only add patterns you've **actually used successfully**.

See `patterns/README.md` for how to add and use patterns.

### 4. Learning System

`learnings/` captures what you discover:

- **what-works.md** — Proven approaches to reuse
- **what-doesnt.md** — Anti-patterns to avoid
- **model-comparison.md** — Which AI model for which task
- **Retrospectives** — Post-project reviews (2026-01-project-name.md)

Update immediately when you learn something. Knowledge decays if not captured.

### 5. Multi-Agent Orchestration

Complex tasks benefit from multiple specialized agents:

```
Design Feature:
  Architect → Base → Reviewer → Documenter

Fix Bug:
  Debugger → Base → Reviewer

Refactor:
  Architect → Reviewer (current) + Base (tests) → Base (refactor) → Reviewer
```

See `workflows/multi-agent.md` for orchestration patterns.

### 6. Model Flexibility

Different AI models have different strengths:

- **Claude Sonnet** — Default choice, best balance
- **Claude Opus** — Complex architecture, critical code
- **GPT-4 Turbo** — Debugging, stack traces
- **GPT-4o** — Quick tasks, prototyping
- **Gemini** — Massive context needs

See `learnings/model-comparison.md` and `workflows/model-switching.md`.

## Workflows

### Starting New Project

See `workflows/new-project.md` for full guide.

**Quick version:**
1. Create project directory
2. Copy `prompts/project-template.md` to project `AGENTS.md` (or a tool-specific name)
3. Fill in project details, inherit from `agents/base.md`
4. Add to `project-registry.md`
5. Start building

### Multi-Agent Task

See `workflows/multi-agent.md` for details.

**Pattern:**
1. Choose agents for each phase
2. Create clear handoffs between agents
3. Insert quality gates (reviews)
4. Parallelize when possible

### Handling Context Limits

See `workflows/context-reset.md`.

**Key points:**
- Commit current state before reset
- Create summary document
- Reference files, don't paste everything
- Progressive context loading

### Switching Models

See `workflows/model-switching.md`.

**Process:**
1. Find clean breakpoint
2. Create handoff document
3. Switch to new model with context
4. Complete specific task
5. Update model-comparison.md if learned something

## Recommended Project Layout

```
~/code/
├── META/                         # This directory
├── project-1/
│   ├── AGENTS.md                 # Inherits: ../META/agents/base.md
│   ├── README.md
│   └── src/
├── project-2/
│   ├── AGENTS.md                 # Inherits: ../META/agents/architect.md
│   ├── ARCHITECTURE.md           # From architect agent
│   └── src/
└── project-3/
    └── AGENTS.md
```

Each project references META agents and patterns as needed.

## Evolution & Maintenance

### After Each Project Milestone

1. Fill out retrospective template
2. Extract patterns to `patterns/`
3. Update `learnings/what-works.md` and `what-doesnt.md`
4. Update `learnings/model-comparison.md` if applicable
5. Refine agent definitions if you discovered better approaches

### When a Pattern Improves

1. Update the pattern file
2. Note what changed in pattern comments
3. Consider updating projects using old version
4. Document significant changes in learnings

### When Something Stops Working

1. Move pattern to archive or delete
2. Add to `learnings/what-doesnt.md`
3. Update `learnings/what-works.md` if it was there

### Keep It Current

This system is only valuable if it reflects reality:

**Update:**
- ✅ Immediately when you discover something
- ✅ After each completed project
- ✅ When patterns change
- ✅ When model performance changes

**Don't:**
- ❌ Wait until "the end"
- ❌ Document hypothetical patterns
- ❌ Keep outdated information

## Cross-Model Compatibility

All files are plain markdown — work with any AI model:
- Claude (all versions)
- GPT (all versions)
- Gemini
- Future models

Only tool calling syntax differs between models. The agent definitions, patterns, and learnings transfer.

## Getting Help

**Explore the docs:**
- `agents/` — Read agent definitions
- `workflows/` — Common scenarios
- `learnings/` — See what's worked before
- `patterns/` — Browse reusable code

**Start simple:**
- Use `agents/base.md` only at first
- Add complexity when you need it
- Document what you learn
- Iterate and improve

## Philosophy in Practice

Traditional approach:
```
Project 1: Build from scratch
Project 2: Build from scratch
Project 3: Build from scratch
Result: Repeating same work, same mistakes
```

META approach:
```
Project 1: Build, extract patterns, document learnings
Project 2: Reuse patterns, start faster, add new patterns
Project 3: Inherit everything, focus on new challenges
Result: Exponential improvement
```

**Every project makes all projects better.**

That's the compound effect.

---

## Quick Reference

```bash
# New project
cp META/prompts/project-template.md my-project/AGENTS.md
# Edit with: Inherits: ../META/agents/base.md

# Reference pattern
# Use META/patterns/auth/jwt-refresh-rotation.md

# Multi-agent
# See workflows/multi-agent.md

# After milestone
cp META/learnings/retrospective-template.md \
   META/learnings/2026-01-project.md

# Update META
# Immediately when you learn something
```

## Project Registry

See `project-registry.md` for list of all projects using META.

---

**Start simple. Document what works. Let it compound.**
