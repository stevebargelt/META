# Multi-Agent Workflow

How to coordinate multiple specialized agents on complex tasks.

## When to Use Multi-Agent Approach

**Use multiple agents when:**
- Task spans multiple domains (design + code + review + docs)
- Quality gates are important (review before merge)
- Different perspectives add value (architect vs implementer view)
- Work can be parallelized
- Task is complex enough that specialization helps

**Don't use multiple agents for:**
- Simple, single-domain tasks
- Quick bug fixes
- Exploration or prototyping
- When context handoff overhead exceeds benefit

## Core Principles

1. **Clear handoffs** — Each agent gets specific task and context
2. **Minimal context** — Pass only what next agent needs
3. **Quality gates** — Review at logical checkpoints
4. **Proper sequencing** — Understand dependencies
5. **Parallel when possible** — Run independent tasks simultaneously

## Standard Workflows

### Feature Development (Full Flow)

```
┌─────────────┐
│ Product Mgr │  Define PRD + scope
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Architect  │  Design approach, identify components
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Tester    │  Test plan + edge cases (optional: test-first)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Base     │  Implement core logic + tests
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Reviewer   │  Security & quality check
└──────┬──────┘
       │
       ├─── Issues? ───► Back to Base for fixes
       │
       ▼
┌─────────────┐
│ Documenter  │  API docs & README updates
└─────────────┘
```

**Handoff:** Use `.meta/handoff.md` (see `prompts/handoff-template.md`, type: `agent-handoff`). Outgoing agent writes it; incoming agent reads it first.

## Automated Execution

For tmux-based orchestration, use the `meta` CLI:

```bash
./scripts/meta run feature --project ~/code/my-project --task "Your task"
```

Pipelines live in `workflows/pipelines/`. See `scripts/README.md` for available commands.

### Bug Fix (Focused Flow)

```
┌─────────────┐
│  Debugger   │  Root cause analysis
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Base     │  Implement fix + regression test
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Reviewer   │  Quick security/correctness check
└─────────────┘
```

**When to skip reviewer:** Trivial fixes (typos, obvious issues)

### Refactor (Design-Heavy Flow)

```
┌─────────────┐
│  Architect  │  Plan refactor approach
└──────┬──────┘
       │
       ├──────────┬──────────────┐
       ▼          ▼              ▼
  ┌─────────┐ ┌─────────┐  ┌──────────┐
  │Reviewer │ │  Base   │  │  Base    │ (Parallel)
  │(Current)│ │(Tests)  │  │(Refactor)│
  └────┬────┘ └────┬────┘  └─────┬────┘
       │           │              │
       └───────────┴──────────────┘
                   │
                   ▼
            ┌─────────────┐
            │  Reviewer   │  Verify refactor
            └─────────────┘
```

**Note:** Can parallelize review of current code, writing tests, and refactoring if clear separation.

### Research to Implementation

```
┌─────────────┐
│    Base     │  Explore codebase, understand system
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Architect  │  Design solution based on findings
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Base     │  Implement solution
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Reviewer   │  Quality check
└─────────────┘
```

## Handoff Format

Use the unified handoff template at `prompts/handoff-template.md`. Agents share state through `.meta/handoff.md` in the project root.

## Parallel Execution

When tasks are independent:

```markdown
## Parallel Work

### Task A → Base Agent (API Implementation)
**Task:** Implement REST endpoints
[Handoff details]

### Task B → Base Agent (Database Schema)
**Task:** Create database migrations
[Handoff details]

### Task C → Documenter (API Docs)
**Task:** Document API spec (can start from design)
[Handoff details]

**Sync point:** All three complete before integration testing
```

**When to parallelize:**
- Tasks have no dependencies
- Different parts of codebase
- Different agents with different focus

**When NOT to parallelize:**
- Tasks depend on each other
- Same codebase area (merge conflicts)
- Benefits don't justify coordination overhead

**Requirement:** If tasks can run in parallel, assign `PARALLEL_GROUP` labels in the pipeline. If you plan parallel workstreams, create a contract stub first (use `META/prompts/contract-stub.md`). OpenAPI (`docs/openapi.yaml`) is required unless explicitly justified. OpenAPI validation is automatic via `META/scripts/quality-gate.sh`. If no OpenAPI, explicitly justify why in `.meta/handoff.md`.

## Quality Gates

Insert review checkpoints at these points:

### 1. After Architecture Design
**Reviewer question:** Is this design sound before we build it?

- Check for security issues in design
- Verify approach is reasonable
- Identify risks early

### 2. After Implementation
**Reviewer question:** Is this code safe and correct?

- Security vulnerabilities
- Logic errors
- Edge case handling
- Code quality

### 3. Before Merge/Deploy
**Reviewer question:** Is this production-ready?

- Final security check
- Performance review
- Documentation complete
- Tests adequate

### 4. After Documentation
**Reviewer question:** Are docs accurate and complete?

- Examples work
- No outdated information
- Clear and understandable

## Definition of Done (Baseline)

Use these as minimum ship criteria for new projects:

- README exists and follows `META/prompts/readme-template.md`
- CI pipeline exists and passes (`META/prompts/ci-setup-checklist.md`)
- Observability baseline implemented (`META/prompts/observability-checklist.md`)
- External service setup documented if applicable (`META/prompts/external-service-setup-checklist.md`)
- Git history exists with at least one milestone commit (`META/prompts/git-hygiene-checklist.md`)

## Context Management in Multi-Agent Workflows

### Keep Context Lean

Each agent should receive:
- ✅ Their specific task
- ✅ Directly relevant context
- ✅ References to files/patterns (not full content)
- ✅ Key decisions made by previous agents

Don't pass:
- ❌ Entire conversation history
- ❌ Irrelevant background
- ❌ Full file contents when path reference would work

### Use Files for State

Instead of long context:

1. **Create intermediate docs**
   ```
   docs/ARCHITECTURE.md — Architect's design
   REVIEW.md — Reviewer's findings
   DECISIONS.md — Key choices
   ```

2. **Reference them in handoffs**
   ```markdown
   See docs/ARCHITECTURE.md section "Database Design"
   ```

3. **Update as you go**
   Keep these docs current for next agent.

## Model Switching in Multi-Agent Flows

Different agents might benefit from different models:

```markdown
## Agent → Model Mapping

- **Architect:** Claude Sonnet (great at trade-offs)
- **Base (Implementation):** Claude Sonnet or GPT-4
- **Reviewer:** Claude Sonnet (thorough security review)
- **Debugger:** GPT-4 (good at stack traces)
- **Documenter:** Claude Sonnet (concise writing)
```

See `learnings/model-comparison.md` for latest findings.

**How to switch:**
1. Summarize previous agent's output
2. Create clear handoff for new model
3. Reference files rather than pasting content
4. Include specific task for this agent

If switching models, include model name and reason in `.meta/handoff.md`.

## Orchestrator Role

For very complex tasks, use orchestrator agent (or human) to:

1. **Break down work** into agent-sized tasks
2. **Sequence tasks** (what depends on what)
3. **Create handoffs** between agents
4. **Monitor progress** and adjust plan
5. **Consolidate outputs** into final deliverable

See `agents/orchestrator.md` for orchestration patterns.

## Spec-Driven Development (Boundary-Only)

When parallel teams work on shared boundaries, require specs at the contract level:
- API contracts (see `prompts/contract-stub.md`)
- Event schemas
- Remote/module interfaces

## Progress Tracking

For multi-phase work:

```markdown
## Progress

- [x] Phase 1: Architecture (Architect) — Complete
- [x] Phase 2: Implementation (Base) — Complete
- [ ] Phase 3: Review (Reviewer) — In Progress ← Current
- [ ] Phase 4: Fixes (Base) — Not Started
- [ ] Phase 5: Documentation (Documenter) — Not Started

**Current status:** Reviewer found 2 issues to address
**Blockers:** None
**Next:** Base agent to fix review items
```

## Common Patterns

### Design → Build → Review Loop

Most common pattern:

1. Architect designs
2. Base implements
3. Reviewer checks
4. Base fixes issues
5. Repeat 3-4 until clean
6. Documenter updates docs

### Parallel Build, Sequential Review

When multiple components:

1. Architect designs all components
2. Base builds component A, B, C in parallel
3. Reviewer checks all components
4. Base fixes all issues
5. Documenter writes docs

### Research → Spike → Production

For uncertain work:

1. Base explores/researches
2. Architect designs based on findings
3. Base implements quick spike/prototype
4. Reviewer evaluates approach
5. Base builds production version
6. Reviewer final check
7. Documenter writes docs

## Anti-Patterns

### Over-Orchestration
Using 5 agents for a 10-line change. Keep it proportional.

### Under-Specified Handoffs
"Now review this" without context on what to look for.

### Skipping Quality Gates
Going straight from code to production without review.

### Sequential When Could Parallel
Building component A, waiting, then building B when they're independent.

### Parallel When Should Sequential
Two agents editing same file simultaneously.

## Measuring Effectiveness

Multi-agent workflow is working when:

- ✅ Better quality than single agent
- ✅ Faster than doing sequentially
- ✅ Each agent adds clear value
- ✅ Handoffs are smooth

It's not working when:

- ❌ Context handoff takes longer than task
- ❌ Agents contradict each other
- ❌ Same work done multiple times
- ❌ More coordination than value

## Quick Reference

```markdown
# Standard Feature Flow
Architect → Tester (plan) → Base → Reviewer → [Base fixes] → Documenter

# Test-First Feature Flow
Architect → Tester (plan + skeleton tests) → Base (implement to pass) → Reviewer

# Quick Bug Fix
Debugger → Base → [Reviewer if security-related]

# Complex Refactor
Architect → [Reviewer (current) + Tester (coverage analysis) parallel] → Base (refactor) → Reviewer

# Research Task
Base (explore) → Architect (design) → Tester (test plan) → Base (implement) → Reviewer

# Coverage Gap Analysis
Tester (analyze) → Base (add tests) → Reviewer

# Handoff Format
Task + Context + Inputs + Expected Output + Success Criteria
```

See individual agent files in `agents/` for agent-specific guidance.
