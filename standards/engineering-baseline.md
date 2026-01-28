# Engineering Baseline Standards

Cross-cutting requirements for every project. Not optional — table stakes.

Referenced from `agents/base.md`. Agents should apply these standards during implementation and review.

---

## Observability

All services must be observable in production:

**Structured Logging:**
```javascript
// Every log entry includes:
logger.info('User login successful', {
  correlationId: req.correlationId,  // Trace through system
  userId: user.id,
  action: 'login',
  timestamp: new Date().toISOString(),
  service: 'auth-service',
  version: process.env.VERSION
})
```

**Key Requirements:**
- JSON format for machine parsing
- Correlation ID in every log entry (generated at entry point, passed through)
- Context included: user, action, relevant IDs
- Log levels used appropriately (ERROR, WARN, INFO, DEBUG)
- No sensitive data in logs (passwords, tokens, PII)

**Metrics:**
- Request latency (p50, p95, p99)
- Error rates by endpoint/operation
- Business metrics (signups, transactions, etc.)
- Resource usage (memory, connections)

**Metrics Conventions:**
- Use stable labels: service, route template, method, status, region, tenant (if applicable)
- Avoid high-cardinality labels in metrics (full URL, user IDs, emails, user-agent, request IDs)

**Distributed Tracing:**
- Correlation ID generated at API gateway/entry point
- Passed in headers (`X-Correlation-ID` or similar)
- Included in all logs, metrics, and downstream calls
- Enables following a request through entire system
- Prefer W3C Trace-Context (`traceparent`) when available; fall back to correlation ID

**Health Checks:**
```javascript
// Every service exposes:
app.get('/health', (req, res) => {
  // Simple: is service running?
  res.json({ status: 'ok' })
})

app.get('/ready', async (req, res) => {
  // Can service handle traffic?
  // Check: DB connection, required services, etc.
  const checks = {
    database: await checkDatabase(),
    cache: await checkCache()
  }
  const ready = Object.values(checks).every(c => c.ok)
  res.status(ready ? 200 : 503).json({
    status: ready ? 'ready' : 'not ready',
    checks
  })
})
```

## Traceability

Must be able to answer: "What happened, when, why, and who did it?"

**Request Tracking:**
```javascript
// Middleware generates or extracts correlation ID
app.use((req, res, next) => {
  req.correlationId = req.headers['x-correlation-id'] || uuidv4()
  res.setHeader('X-Correlation-ID', req.correlationId)
  next()
})

// Include in all logs and downstream calls
fetch(upstreamService, {
  headers: { 'X-Correlation-ID': req.correlationId }
})
```

**Response Correlation:**
- Always return `X-Correlation-ID` on every response
- Include correlation ID in the response body for any non-2xx response

**Audit Logging:**
```javascript
// For state-changing operations:
auditLog.record({
  correlationId: req.correlationId,
  userId: req.userId,
  action: 'DELETE_USER',
  resource: `user:${userId}`,
  timestamp: new Date().toISOString(),
  metadata: { reason: req.body.reason },
  ipAddress: req.ip
})
```

**What to audit:**
- Creates, updates, deletes (who changed what)
- Permission changes
- Authentication events (login, logout, failures)
- Admin actions
- Data exports/access to sensitive info

**Audit vs Analytics:**
- Audit logs are immutable security records (who/what/when/why)
- Business/analytics events are separate streams (avoid mixing)

**Error Context:**
```javascript
// Errors must include full context
throw new ApiError(500, 'PAYMENT_FAILED', 'Payment processing failed', {
  correlationId: req.correlationId,
  userId: user.id,
  orderId: order.id,
  paymentProvider: 'stripe',
  errorCode: stripeError.code,
  // Enough to debug, not sensitive data
})
```

**Version Information:**
```javascript
// Every service exposes version
app.get('/version', (req, res) => {
  res.json({
    service: 'api-service',
    version: process.env.VERSION || 'unknown',
    commit: process.env.GIT_COMMIT,
    buildTime: process.env.BUILD_TIME
  })
})

// Include in logs
logger.info('Service starting', {
  service: 'api-service',
  version: process.env.VERSION
})
```

## Security Baseline

**Input Validation:**
- Validate all user inputs (type, format, range)
- Sanitize for injection attacks (SQL, XSS, command injection)
- Use validation libraries, don't roll your own
- Fail securely (reject invalid input, don't try to "fix" it)

**Authentication & Authorization:**
- Never trust client-provided user IDs
- Verify permissions on every protected operation
- Use established patterns (see `patterns/auth/`)
- Session/token management follows security best practices

**Secrets Management:**
- No secrets in code (use environment variables)
- No secrets in logs
- No secrets in error messages
- No secrets in version control

**OWASP Top 10:**
- Familiar with current OWASP Top 10
- Check for these vulnerabilities in code reviews
- Use security review agent for sensitive code

## Testing Standards

**What Must Be Tested:**
- Critical business logic (payment, auth, data integrity)
- Security-sensitive operations
- Error handling paths
- Integration points (APIs, databases)

**Test Quality:**
- Tests are readable (clear setup, action, assertion)
- Tests are reliable (no flaky tests)
- Tests are fast enough to run frequently
- Tests verify behavior, not implementation details

**Coverage:**
- Focus on critical paths, not 100% coverage for vanity
- Integration tests for user-facing flows
- Unit tests for complex logic
- Don't skip tests to "save time"

## Error Handling

**Never:**
- Swallow errors silently
- `catch (err) { }` with no logging
- Return success when operation failed
- Expose internal errors to users

**Always:**
- Log errors with full context
- Return appropriate status codes
- Provide user-friendly messages
- Include correlation ID in error responses
- Distinguish between expected errors (validation) and unexpected (bugs)

**Pattern:**
```javascript
try {
  await processPayment(order)
} catch (err) {
  logger.error('Payment processing failed', {
    correlationId: req.correlationId,
    error: err.message,
    stack: err.stack,
    orderId: order.id,
    userId: user.id
  })

  // User-friendly message, not internal details
  throw new ApiError(500, 'PAYMENT_FAILED',
    'Unable to process payment. Please try again.',
    { correlationId: req.correlationId }
  )
}
```

## Implementation Notes

These requirements should be:
- Built in from the start (not added later)
- In every service/component
- Reviewed in code reviews
- Referenced in project AGENTS.md when relevant

See `patterns/` for reference implementations.
