# Model Switching Workflow

How to effectively switch between AI models during a project.

## When to Switch Models

### Good Reasons

**1. Task-Specific Strengths**
- Switch to GPT-4 for debugging stack traces
- Switch to Claude Sonnet for architecture decisions
- Switch to Gemini for massive codebase context

**2. Performance Issues**
- Current model struggling with specific task type
- Need faster iteration (switch to lighter model)
- Need better quality (switch to stronger model)

**3. Availability/Cost**
- Hit rate limits on current model
- Need to reduce costs (switch to cheaper model)
- Current model unavailable

**4. Context Limits**
- Need larger context window
- Gemini for 1M+ token context

### Bad Reasons

**Don't switch because:**
- ❌ Random experimentation mid-task
- ❌ First response wasn't perfect
- ❌ Think grass is greener elsewhere
- ❌ No clear reason, just switching

**Why not:**
- Loses conversation context
- Inconsistent coding style
- Adds overhead without benefit
- Fragments understanding

## Pre-Switch Checklist

Before switching models:

### 1. Commit Current State

```bash
git add .
git commit -m "wip: checkpoint before model switch

Current state:
- [What's working]
- [What's in progress]

Switching to [Model] for [Reason]
"
```

### 2. Identify Clean Breakpoint

**Good breakpoints:**
- ✅ After completing a feature
- ✅ Before starting new component
- ✅ After design phase, before implementation
- ✅ After implementation, before review

**Bad breakpoints:**
- ❌ Mid-implementation
- ❌ In middle of debugging
- ❌ Partial refactor
- ❌ Broken state

### 3. Document Current State

Write `.handoff.md` using the unified template at `prompts/handoff-template.md` with type: `model-switch`. Set From/To to the model names and include the switch reason.

## Switch Execution

### Step 1: Save Context

Write `.handoff.md` in the project root using `prompts/handoff-template.md` (type: `model-switch`). This replaces the previous `HANDOFF_TO_[MODEL].md` convention — one file, always overwritten.

### Step 2: Switch to New Model

**Initial prompt to new model:**

```markdown
I'm switching to you from [previous model]. Please read .handoff.md first.
```

### Step 3: Verify Understanding

New model should:
1. Acknowledge handoff context
2. Summarize their understanding
3. Confirm next action

If understanding is wrong, clarify before proceeding.

### Step 4: Execute Task

Work with new model on specific task.

### Step 5: Handoff Back (if needed)

When task is complete and switching back, overwrite `.handoff.md` with updated state (type: `model-switch`, reversed From/To). Same template, same file.

## Model-Specific Considerations

### Switching TO Claude Sonnet

**Best for:**
- Architecture and design
- Code review (especially security)
- Clean, maintainable implementation
- Concise documentation

**Handoff should include:**
- Design constraints and goals
- Patterns to follow from META/patterns/
- Quality requirements (security, performance)

### Switching TO GPT-4 Turbo

**Best for:**
- Debugging complex issues
- Stack trace analysis
- Broad technical knowledge
- Alternative perspectives

**Handoff should include:**
- Specific problem description
- Error messages and stack traces
- What's been tried already
- Expected vs actual behavior

### Switching TO GPT-4o

**Best for:**
- Quick iterations
- Prototyping
- Simple implementations
- Cost-sensitive tasks

**Handoff should include:**
- Clear, specific task
- Success criteria
- Keep it simple (this is fast model)

### Switching TO Gemini 1.5 Pro

**Best for:**
- Large codebase understanding
- Refactoring across many files
- Long context sessions

**Handoff should include:**
- Pointers to relevant parts of codebase
- Big picture context
- What to focus on vs what to ignore

## Context Management Across Models

### Keep Handoffs Focused

**Include:**
- ✅ Project purpose (1 sentence)
- ✅ Current task
- ✅ Key files (3-5 max)
- ✅ Recent decisions
- ✅ Next specific action

**Don't include:**
- ❌ Full conversation history
- ❌ Entire codebase
- ❌ Unrelated context
- ❌ Long explanations

### Use Shared References

All models can access:
- META/agents/ — Agent definitions
- META/patterns/ — Code patterns
- Project AGENTS.md — Project context
- Git history — What's been done

Reference these instead of re-explaining.

### Maintain Consistency

**Ensure new model:**
- Follows same coding style
- Respects decisions already made
- Uses established patterns
- Doesn't undo previous work

Include in handoff:
```markdown
## Style & Patterns to Maintain

- Auth: Using META/patterns/auth/jwt-refresh.md approach
- Errors: Using META/patterns/api/rest-error-handling.ts
- Tests: Jest, focus on integration tests
- Naming: camelCase for functions, PascalCase for classes
```

## Mid-Task Switching (Emergency)

If you MUST switch mid-task:

1. **Describe exact state**
   ```markdown
   ## Exact Current State

   File: src/auth/refresh.js

   Working:
   - Token validation (lines 1-45)
   - Database lookup (lines 46-60)

   In progress:
   - Token rotation logic (lines 61-75)
   - Currently halfway through implementation
   - Next: Need to invalidate old token

   Not started:
   - Error handling
   - Tests
   ```

2. **Provide partial code**
   Share exactly what's written so far

3. **Clear next step**
   Specific line or function to work on next

**Avoid this when possible** — finish current unit of work first.

## Model Comparison Updates

After switching, update `learnings/model-comparison.md`:

```markdown
## 2026-01-26: MycoGeek Debugging

**Switched:** Claude Sonnet → GPT-4 Turbo

**Task:** Debug environmental data aggregation

**Result:** GPT-4 found bug faster
- Better at analyzing calculation logic
- Clearer trace through the math

**Update:** Confirmed GPT-4 advantage for debugging
```

## Anti-Patterns

### Serial Model Hopping

❌ **Don't:**
```
Claude for 5 min → not perfect → switch to GPT
GPT for 5 min → not perfect → switch to Gemini
Gemini for 5 min → not perfect → switch back to Claude
```

✅ **Do:**
```
Choose right model for task → work through to completion → evaluate
```

### Context Loss

❌ **Don't:**
Switch without handoff document, assume new model knows context

✅ **Do:**
Create explicit handoff with all relevant context

### Style Inconsistency

❌ **Don't:**
Let each model use its own coding style

✅ **Do:**
Specify style/patterns to maintain in handoff

### Premature Switching

❌ **Don't:**
Switch after first non-perfect response

✅ **Do:**
Give model 2-3 attempts, provide clarification

## Quick Reference

### Before Switch

- [ ] Commit current state
- [ ] Find clean breakpoint
- [ ] Create handoff document
- [ ] Identify specific task for new model

### Handoff Document Template

```markdown
# Handoff to [Model]

Reason: [Why switching]
Project: [Brief context]
Done: [Completed work]
Current: [In progress]
Task: [Specific next action]
Files: [Key files]
Patterns: [META references]
```

### After Switch

- [ ] Verify new model understands
- [ ] Complete specific task
- [ ] Document results
- [ ] Update model-comparison.md if learned something
- [ ] Consider switching back or continuing

### Good Switch Points

- ✅ After feature complete
- ✅ Before new component
- ✅ Design → Implementation boundary
- ✅ Implementation → Review boundary

### Model Selection

| Task | Best Model | Why |
|------|-----------|-----|
| Architecture | Claude Sonnet | Trade-off analysis |
| Implementation | Claude Sonnet/GPT-4 | Quality code |
| Debugging | GPT-4 Turbo | Stack traces |
| Review | Claude Sonnet | Security |
| Quick tasks | GPT-4o | Speed/cost |
| Large context | Gemini | 1M+ tokens |

See `learnings/model-comparison.md` for full matrix.
