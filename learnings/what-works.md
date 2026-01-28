# What Works

Proven patterns and approaches from real projects. Add to this when you discover something that actually saves time or improves quality.

**Last Updated:** 2026-01-28

---

## Agent Usage Patterns

### Tmux Pipeline Orchestration

**Pattern:** Use `meta` CLI to run multi-agent workflows in tmux
**Why it works:** Clear visibility into each agent, repeatable flow, easy to pause at gates
**When to use:** Multi-step builds, PRD → architecture → implementation sequences
**Source:** test-app (2026-01)

---

## Communication Patterns

### Start with Code, Not Explanation

**What:** Show code examples before explaining in prose
**Why it works:** Faster to understand, easier to verify
**Example:**
```markdown
❌ "We should implement a factory pattern that creates..."
✅ "Use this approach:
    ```javascript
    const factory = createFactory(...)
    ```
    This handles [specific case]"
```

### Ask Questions Early

**What:** Clarify requirements before building
**Why it works:** Saves rebuilding, gets better results
**When:** Any time there are multiple valid approaches

---

## Development Workflow

### Commit Often, Push Later

**What:** Small commits locally, push after feature works
**Why it works:** Easy to revert, clear history, not cluttered remote
**Pattern:**
```bash
git commit -m "wip: component structure"
git commit -m "wip: add logic"
git commit -m "feat: complete feature"
# Now push
```

### Test-Then-Implement for Complex Logic

**What:** Write test cases before implementation
**Why it works:** Clarifies requirements, catches edge cases early
**When:** Complex algorithms, business logic, anything with edge cases

---

## Context Management

### Use Patterns Over Repetition

**What:** Extract repeated code/config to `patterns/`, reference it
**Why it works:** Reduces context size, maintains consistency
**Example:** Instead of pasting auth middleware each time, reference `patterns/auth/jwt-middleware.ts`

### Summarize Long Sessions

**What:** When hitting context limits, summarize what's done and what's next
**Why it works:** Maintains continuity, reduces token usage
**Template:** See `workflows/context-reset.md`

### Interactive Kickoff Only

**What:** Make kickoff step interactive; keep build steps non-interactive
**Why it works:** Collects requirements once; avoids stalled pipelines later
**When:** Automated multi-agent orchestration
**Source:** test-app (2026-01)

### Contract-First Development

**What:** Create OpenAPI (or equivalent) contract stub before parallel workstreams begin
**Why it works:** Zero integration issues at merge time; response envelopes, error formats, data shapes all match
**When:** Any project with parallel backend/frontend development
**Example:** Step 1 creates `docs/openapi.yaml`, then infra/backend/frontend groups work against shared contract
**Source:** test-app-5 (2026-01)

### Auto-Commit Per Step

**What:** Pipeline auto-commits after each successful step with `meta: step N (agent) complete`
**Why it works:** Clean history showing exactly what each step produced; easy to bisect; each step's changes isolated
**When:** Multi-step automated pipelines
**Pattern:** `--no-auto-commit` flag available for edge cases
**Source:** test-app-5 (2026-01)

### Two-Stage Quality Gate

**What:** DoD checklist (human-readable) followed by quality gate script (machine-verifiable)
**Why it works:** Checklist catches nuanced issues; script enforces hard gates. Redundant but effective.
**When:** Final stages of any build pipeline
**Pattern:** Step N-1 runs checklist, Step N runs `quality-gate.sh`
**Source:** test-app-5 (2026-01)

---

## Model Selection

### Default to Claude Sonnet

**What:** Use Claude Sonnet 4.5 unless specific reason not to
**Why it works:** Best balance of quality, speed, cost for most tasks
**When to switch:** See `learnings/model-comparison.md`

---

## Quality Practices

### Security Review Before Merge

**What:** Run reviewer agent on all code touching auth, data, external APIs
**Why it works:** Catches vulnerabilities early
**Checklist:** See `agents/reviewer.md`

### One Change at a Time

**What:** When debugging or refactoring, change one thing, test, repeat
**Why it works:** Easy to identify what broke, easy to revert
**Anti-pattern:** Changing multiple things then figuring out which broke it

---

## Documentation

### README-Driven Development

**What:** Write README first for new projects
**Why it works:** Clarifies what you're building, API design emerges naturally
**Template:** See `prompts/project-template.md`

### Decision Records for Architecture

**What:** Document significant technical decisions
**Why it works:** Future you remembers why, others understand rationale
**Format:** See `agents/architect.md` decision format

---

## Learning Capture

### Retrospectives After Milestones

**What:** Fill out retrospective template after each major milestone
**Why it works:** Compounds knowledge, improves future projects
**Template:** `learnings/retrospective-template.md`

### Update META Immediately

**What:** When you discover a good pattern, add it to META right away
**Why it works:** Don't lose the insight, available for next project
**Process:**
1. Add to relevant `learnings/` or `patterns/` file
2. Update agent definitions if applicable
3. Commit with clear message

---

## Adding to This Document

When you discover something that works:

1. **Verify it's repeatable** — Did it work once or consistently?
2. **Document specifics** — What exactly did you do?
3. **Explain why** — What made this effective?
4. **Add source** — Which project taught you this?
5. **Update relevant files** — Add to patterns/ or agents/ if needed

**Format:**
```markdown
### [Pattern Name]

**What:** [Clear description]
**Why it works:** [Actual benefits]
**When to use:** [Specific scenarios]
**Example/Location:** [Code or reference]
**Source:** [Project name, date]
```

Keep this document current — patterns that no longer work should move to `what-doesnt.md` with explanation.
