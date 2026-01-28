# Observability Validation Prompt

Validate baseline observability before final approval.

## Goal

Confirm correlation IDs, structured logging, and error correlation are present.

## Checks

- Correlation ID generated per request
- Correlation ID returned in response headers and error bodies
- Structured logs include correlation ID and request details
- Error handler logs errors with correlation ID

## How to Verify

1) Search for correlation ID handling in server code
2) Confirm error responses include correlation ID
3) Confirm logs include correlation ID fields

## Output Template

```markdown
## Observability Validation

- Correlation IDs: [pass/fail]
- Error responses include correlationId: [pass/fail]
- Logs include correlationId: [pass/fail]

**Notes:**
- [If fail, explain what is missing]
```

If any check fails, treat it as **blocking** and list concrete fixes.
