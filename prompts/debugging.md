# Debugging Prompt

Systematic debugging framework for structured problem-solving.

## Goal

Identify root cause through systematic isolation. Fix the cause, not the symptom.

## Steps

### 1. Gather Information
- **Expected behavior** — What should happen?
- **Actual behavior** — What's happening instead?
- **Reproduction steps** — How to trigger it?
- **Environment** — OS, versions, config?
- **Recent changes** — What changed before it broke?

### 2. Reproduce
- Can you consistently reproduce it?
- What's the minimum reproduction case?
- Does it happen in all environments?

### 3. Isolate
- Where in the stack does it fail?
- What's the last known good state?
- Binary search through code/commits if needed

### 4. Hypothesize
- Form a theory about root cause
- What evidence would confirm/deny it?

### 5. Test
- Add logging/breakpoints to verify hypothesis
- Change one thing at a time
- Document what you tried

### 6. Fix
- Address root cause, not symptoms
- Consider similar bugs elsewhere
- Add test to prevent regression

## Common Patterns

- **"It works on my machine"** — Environment, config, dependency, or path differences
- **"It worked yesterday"** — Check git history, dependency updates, infra changes, data changes
- **"It works sometimes"** — Race conditions, resource exhaustion, external flakiness, caching
- **"No error, just wrong"** — Silent failures, wrong data in, wrong assumptions, off-by-one

## Output Template

```markdown
## Debug Report

- **Problem:** [Restate the issue clearly]
- **Root Cause:** [What's actually wrong]
- **Evidence:** [How we know this is the cause]
- **Fix:** [Solution with code if applicable]
- **Prevention:** [How to avoid this in future]
```
