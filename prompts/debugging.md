# Debugging Prompt

Cross-model prompt for systematic debugging.

## Usage

```
Help me debug using the approach in META/prompts/debugging.md

[describe the problem]
```

---

## Information Gathering

Before diving in, establish:

1. **Expected behavior** — What should happen?
2. **Actual behavior** — What's happening instead?
3. **Reproduction steps** — How to trigger it?
4. **Environment** — OS, versions, config?
5. **Recent changes** — What changed before it broke?

---

## Systematic Approach

### 1. Reproduce
- Can you consistently reproduce it?
- What's the minimum reproduction case?
- Does it happen in all environments?

### 2. Isolate
- Where in the stack does it fail?
- What's the last known good state?
- Binary search through code/commits if needed

### 3. Hypothesize
- Form a theory about root cause
- What evidence would confirm/deny it?

### 4. Test
- Add logging/breakpoints to verify hypothesis
- Change one thing at a time
- Document what you tried

### 5. Fix
- Address root cause, not symptoms
- Consider similar bugs elsewhere
- Add test to prevent regression

---

## Common Patterns

### "It works on my machine"
- Environment differences
- Config/secrets differences  
- Dependency version mismatches
- File path differences

### "It worked yesterday"
- Check git history
- Check dependency updates
- Check infrastructure changes
- Check data changes

### "It works sometimes"
- Race conditions
- Resource exhaustion
- External service flakiness
- Caching issues

### "No error, just wrong"
- Silent failures being caught
- Wrong data going in
- Correct code, wrong assumptions
- Off-by-one errors

---

## Output Format

```markdown
## Problem Summary
[Restate the issue clearly]

## Root Cause
[What's actually wrong]

## Evidence
[How we know this is the cause]

## Fix
[Solution with code if applicable]

## Prevention
[How to avoid this in future]
```
