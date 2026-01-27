# Code Review Prompt

Cross-model prompt for structured code review.

## Usage

Include this in your request when you want a thorough code review:

```
Review this code using the structure in META/prompts/code-review.md

[paste code or reference file]
```

---

## Review Structure

### 1. Security
- Input validation
- Authentication/authorization
- Data exposure risks
- Injection vulnerabilities
- Secrets handling

### 2. Correctness
- Logic errors
- Edge cases
- Error handling
- Race conditions
- Null/undefined handling

### 3. Performance
- Algorithmic complexity
- Memory usage
- Unnecessary operations
- Caching opportunities
- Database query efficiency

### 4. Maintainability
- Code clarity
- Naming conventions
- Function/module size
- DRY violations
- Documentation needs

### 5. Testing
- Test coverage gaps
- Testability concerns
- Missing edge case tests

---

## Output Format

```markdown
## Summary
[One paragraph overview]

## Critical Issues
[Must fix before merge]

## Recommendations  
[Should fix, not blocking]

## Nitpicks
[Style/preference, optional]

## What's Good
[Positive patterns worth noting]
```

---

## Severity Levels

- 🔴 **Critical** — Security risk, data loss, or crash
- 🟠 **High** — Bug or significant maintainability issue
- 🟡 **Medium** — Should improve, not urgent
- 🟢 **Low** — Nitpick or style preference
