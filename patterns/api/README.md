# API Patterns

Reusable patterns for building APIs (REST, GraphQL, error handling, etc.)

## Patterns in This Category

### Error Handling

- **`rest-error-handling.ts`** — Consistent error responses for REST APIs
  - Status codes, error format, logging
  - Handles validation, auth, server errors
  - Example included

### Observability

- **`observability-middleware.js`** — Complete observability setup for Express
  - Correlation ID tracking
  - Structured request logging
  - Metrics label conventions (stable labels, avoid high-cardinality)
  - Audit logging helper
  - Downstream service call tracking
  - Health check patterns
  - Implements base.md observability requirements
  - Pair with `rest-error-handling.ts` to return correlationId in error responses

### Response Formatting
*(Add patterns here as you create them)*

- Response pagination
- HATEOAS links
- API versioning

### Middleware
*(Add patterns here as you create them)*

- Rate limiting
- Request logging
- CORS configuration

### Validation
*(Add patterns here as you create them)*

- Request body validation
- Query parameter validation
- File upload validation

## Usage

Reference these patterns when building APIs:

```markdown
# In project AGENTS.md

## API Patterns

Using META/patterns/api/ approaches:
- Error handling: rest-error-handling.ts
- [Other patterns as you adopt them]
```

## When to Add API Patterns

Add to this category when you've built:
- Error handling approach you'll reuse
- Pagination logic that works well
- Validation pattern that's clean
- Middleware that solves common problem
- Response format that's consistent

Focus on patterns you've **actually used successfully**, not theoretical best practices.
