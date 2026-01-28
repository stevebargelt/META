# Code Review Prompt

Structured code review framework for any agent.

## Goal

Identify security, correctness, performance, and maintainability issues. Report findings by severity.

## Checks

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

## Severity Levels

- **Critical** — Security risk, data loss, or crash
- **High** — Bug or significant maintainability issue
- **Medium** — Should improve, not urgent
- **Low** — Nitpick or style preference

## Output Template

```markdown
## Code Review

**Summary:** [One paragraph overview]

**Critical Issues:**
- [Must fix before merge]

**Recommendations:**
- [Should fix, not blocking]

**Nitpicks:**
- [Style/preference, optional]

**What's Good:**
- [Positive patterns worth noting]
```
