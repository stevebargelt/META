# Testing Patterns

Reusable patterns for testing strategies, fixtures, and test setup.

## Patterns in This Category

### Test Setup
*(Add patterns here as you create them)*

- Integration test configuration
- Test database setup/teardown
- Mock service setup
- Test fixtures and factories
- **`supertest-in-memory.js`** — Supertest adapter without binding to a port
  - Routes requests directly to an Express handler
  - Useful for sandboxed or fast unit-style API tests

### Testing Strategies
*(Add patterns here as you create them)*

- API endpoint testing
- Database testing patterns
- Auth testing helpers
- Error case testing

### Tools & Configuration
*(Add patterns here as you create them)*

- Jest configuration
- Testing library setup
- Code coverage settings

## Usage

Reference testing patterns when setting up tests:

```markdown
# In project

See META/patterns/testing/ for:
- Test setup approach
- Fixture patterns
- Mock strategies
```

## When to Add Testing Patterns

Add patterns for:
- Test setup that works well
- Fixture/factory patterns you reuse
- Mock strategies that are clean
- Testing utilities that help

Focus on patterns that **reduce boilerplate** and **improve test clarity**.
