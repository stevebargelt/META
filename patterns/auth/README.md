# Authentication & Authorization Patterns

Reusable patterns for auth systems.

## Patterns in This Category

### JWT Authentication

- **`jwt-refresh-rotation.md`** — JWT with rotating refresh tokens
  - Prevents token replay attacks
  - Secure token rotation on each use
  - Database schema and implementation notes

### OAuth/Social Login
*(Add patterns here as you create them)*

- OAuth 2.0 flow
- Social provider integration
- Account linking

### Session Management
*(Add patterns here as you create them)*

- Redis session store
- Cookie configuration
- Session expiration

### Authorization
*(Add patterns here as you create them)*

- Role-based access control (RBAC)
- Permission middleware
- Resource ownership checks

## Usage

Reference these patterns for auth implementation:

```markdown
# In agent prompt

Implement authentication using the approach in:
META/patterns/auth/jwt-refresh-rotation.md
```

## Security Note

Auth patterns require careful review:
- Always use reviewer agent for auth code
- Don't skip security checks
- Keep secrets out of code
- Use environment variables

## When to Add Auth Patterns

Add patterns for:
- Auth flows you've implemented and tested
- Security patterns that worked well
- Common auth middleware
- Token management approaches

Must be **proven in real project** before adding here.
