# What Doesn't Work

Anti-patterns and approaches to avoid, learned from real experience.

**Last Updated:** 2026-01-28

---

## Agent Usage Anti-Patterns

### Over-Orchestration

**What:** Using multiple agents for simple tasks
**Why it fails:** Context handoff overhead exceeds benefit
**Example:** Using architect → base → reviewer for a one-line bug fix
**Instead:** Use base agent directly
**Source:** [Project where learned]

### Parallelizable Work Left Sequential

**What:** Building pipelines without `PARALLEL_GROUP`, even when steps are independent
**Why it fails:** Slower delivery, no concurrency benefit from multi-agent setup
**Example:** All steps in the pipeline have `PARALLEL_GROUP` set to `-`
**Instead:** Group independent steps with a shared `PARALLEL_GROUP` label
**Source:** test-app (2026-01)

### Under-Specified Handoffs

**What:** Passing work to next agent without clear task definition
**Why it fails:** Agent doesn't know what to do, makes assumptions
**Example:** "Now review this" without context on what to look for
**Instead:** Use handoff format from `agents/orchestrator.md`
**Source:** [Project where learned]

### Inventing New Agent Names

**What:** Orchestrator generates agent names that don't exist in `META/agents/`
**Why it fails:** Pipeline crashes when agent definition file is missing
**Example:** `test-automation-specialist` in generated pipeline
**Instead:** Restrict to existing agent names only
**Source:** test-app (2026-01)

---

## Code Patterns

*Add anti-patterns as you discover them. Format:*

### [Anti-Pattern Name]

**What:** [What people try to do]
**Why it fails:** [Actual problems encountered]
**Example:** [Code showing the problem]
**Instead:** [Better approach]
**Source:** [Project where learned]

---

## Communication Anti-Patterns

### Asking Agent to "Make it Better"

**What:** Vague requests like "improve this code"
**Why it fails:** Agent doesn't know what "better" means, makes arbitrary changes
**Example:** "Make this function better" → agent rewrites working code
**Instead:** "Reduce complexity in this function" or "Optimize this for speed"
**Source:** [Project where learned]

### Not Reading AI Output Before Accepting

**What:** Applying AI suggestions without review
**Why it fails:** AI makes mistakes, introduces bugs, misunderstands context
**Example:** [Specific instance]
**Instead:** Always review code changes before applying
**Source:** [Project where learned]

---

## Project Structure

### Deeply Nested Directories

**What:** Creating elaborate folder hierarchies from the start
**Why it fails:** Premature organization, hard to navigate, files move constantly
**Example:** `src/components/features/dashboard/widgets/charts/line/`
**Instead:** Keep flat until clear categories emerge
**Source:** [Project where learned]

### Configuration Sprawl

**What:** Multiple config files for same tool (`.rc`, `.config.js`, `package.json` settings)
**Why it fails:** Hard to find what's configured where, conflicts
**Example:** ESLint settings in 3 different files
**Instead:** One config file per tool, documented location
**Source:** [Project where learned]

---

## Development Workflow

### Committing Broken Code

**What:** Committing code that doesn't run/test
**Why it fails:** Breaks git bisect, confuses history, wastes others' time
**Example:** "WIP commit" that doesn't compile
**Instead:** Commit working states, use git stash for WIP
**Source:** [Project where learned]

### Building Without Commits

**What:** Completing a project with zero local commits or pushes
**Why it fails:** No history, no rollback points, no visibility into progress
**Example:** A full build with no git commits
**Instead:** Commit early/often and push at stable milestones
**Source:** test-app (2026-01)

### Skipping Tests to "Save Time"

**What:** Not writing tests for "simple" code
**Why it fails:** Simple code breaks too, regressions happen
**Example:** [Specific bug that could have been caught]
**Instead:** Write tests, especially for business logic
**Source:** [Project where learned]

### Running Tests in Read-Only Sandboxes

**What:** Running test suites in a sandbox that blocks temp dirs or node_modules writes
**Why it fails:** Tools like Vitest create temp files; tests crash on EPERM
**Example:** `EPERM: operation not permitted, mkdir ... node_modules/.vite-temp`
**Instead:** Use workspace-write or allow temp paths for test runs
**Source:** test-app (2026-01)

---

## Context Management

### Pasting Entire Files Repeatedly

**What:** Including full file contents in every prompt
**Why it fails:** Wastes tokens, hits context limits, slows responses
**Example:** Pasting 500-line file when asking about one function
**Instead:** Reference file paths, paste only relevant sections
**Source:** [Project where learned]

### Not Summarizing After Context Reset

**What:** Starting fresh conversation without context
**Why it fails:** Agent doesn't know what's been done, repeats work
**Example:** [Specific instance]
**Instead:** Use summary template from `workflows/context-reset.md`
**Source:** [Project where learned]

---

## Model Selection

### Using Opus for Everything

**What:** Defaulting to most expensive model for all tasks
**Why it fails:** Unnecessary cost, no speed benefit for simple tasks
**Example:** Using Opus to fix a typo
**Instead:** Use Sonnet as default, Opus for complex tasks
**Source:** [Project where learned]

### Switching Models Mid-Task

**What:** Changing AI model during implementation
**Why it fails:** Loses context, different coding styles, inconsistency
**Example:** Starting feature with Claude, finishing with GPT
**Instead:** Complete task with same model, switch between tasks
**Source:** [Project where learned]

---

## Quality Practices

### Skipping Security Review on "Internal" Code

**What:** Not reviewing code because it's not public-facing
**Why it fails:** Internal tools have vulnerabilities too, can be exploited
**Example:** [Specific vulnerability found]
**Instead:** Review anything touching sensitive data or auth
**Source:** [Project where learned]

### Ignoring Observability Requirements

**What:** Skipping logging/traceability even when explicitly requested
**Why it fails:** Hard to debug, no audit trail, lower ops confidence
**Example:** App shipped without baseline tracing/logging
**Instead:** Implement observability in the base API stack (correlation IDs, structured logs, tracing hooks)
**Source:** test-app (2026-01)

### Fixing Symptoms, Not Root Cause

**What:** Patching the error without understanding why it happens
**Why it fails:** Bug comes back, or appears elsewhere
**Example:** Adding null check instead of figuring out why value is null
**Instead:** Use debugger agent to find root cause
**Source:** [Project where learned]

---

## Documentation

### Writing Docs Before Code Works

**What:** Documenting API that's still changing
**Why it fails:** Docs immediately outdated, double work
**Example:** [Specific case]
**Instead:** Write docs after implementation stabilizes
**Source:** [Project where learned]

### Skipping README for New Project

**What:** Shipping a project without a `README.md`
**Why it fails:** No onboarding path, unclear run steps, unclear scope
**Example:** App delivered with no README
**Instead:** Require a minimal README (run instructions, env vars, scripts)
**Source:** test-app (2026-01)

### Missing External Service Setup Steps

**What:** Relying on external services without setup instructions or bootstrap files
**Why it fails:** Users cannot run or validate the app
**Example:** Supabase required but no schema/setup steps provided
**Instead:** Provide setup docs and a bootstrap path (SQL, migrations, or CLI steps)
**Source:** test-app (2026-01)

### Documentation That Duplicates Code

**What:** Comments that restate what code does
**Why it fails:** Noise, becomes outdated, doesn't add value
**Example:**
```javascript
// Increment counter
counter++
```
**Instead:** Document why, not what
**Source:** [Project where learned]

---

## Automation

### Over-Automating Early

**What:** Building automation before knowing the workflow
**Why it fails:** Automate the wrong thing, workflow changes, wasted effort
**Example:** [Specific automation that was never used]
**Instead:** Do it manually 3x, then automate
**Source:** [Project where learned]

### Automation Without Error Handling

**What:** Scripts that fail silently or cryptically
**Why it fails:** Can't debug, don't know what went wrong
**Example:** Deploy script that fails without output
**Instead:** Add logging, error messages, exit codes
**Source:** [Project where learned]

### No CI/CD Pipeline

**What:** Shipping a project without any CI/CD automation
**Why it fails:** No repeatable build/test/deploy path, quality gates ignored
**Example:** Manual-only build with no CI workflows
**Instead:** Add at least one CI pipeline for lint/test/build
**Source:** test-app (2026-01)

---

## Learning Capture

### Not Recording Decisions

**What:** Making important choices without documentation
**Why it fails:** Forget rationale, repeat discussions, confusion
**Example:** [Decision that came back to haunt you]
**Instead:** Use decision record format from `agents/architect.md`
**Source:** [Project where learned]

### Waiting to Update META

**What:** Planning to update learnings "at the end"
**Why it fails:** Forget insights, lose details, never get around to it
**Example:** [Learning that was lost]
**Instead:** Update META immediately when you learn something
**Source:** [Project where learned]

---

## Adding to This Document

When you discover something that doesn't work:

1. **Verify it's actually a problem** — Did it fail once or repeatedly?
2. **Document specifics** — What exactly went wrong?
3. **Explain why** — What made this ineffective?
4. **Provide alternative** — What should you do instead?
5. **Add source** — Which project taught you this?

**Format:**
```markdown
### [Anti-Pattern Name]

**What:** [What you tried]
**Why it fails:** [Actual problems]
**Example:** [Specific case]
**Instead:** [Better approach]
**Source:** [Project name, date]
```

If something moves from `what-works.md` to here, note why it stopped working.
