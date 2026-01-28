# Observability Checklist

Verify baseline observability (logs + traceability) is in place.

## Goal

Confirm correlation IDs, structured logging, and error tracing exist and work correctly.

## Checks

### Required
- [ ] Correlation/request ID generated per request
- [ ] Correlation ID returned in response headers and error bodies
- [ ] Structured logs (JSON) include: requestId, method, path, status, duration
- [ ] Error handler logs error with stack trace and correlation ID
- [ ] Authenticated requests log userId (or anonymized equivalent)
- [ ] Health endpoint exists and returns status

### Recommended
- [ ] Request logging includes latency and response size
- [ ] Logs redact secrets and tokens
- [ ] Log levels configurable via env
- [ ] Service name + version included in logs
- [ ] Downstream calls (DB/external APIs) include correlation ID

### Optional (If Needed)
- [ ] OpenTelemetry tracing configured
- [ ] Metrics exported (latency, error rate, request count)

## How to Verify

- Search server code for correlation ID middleware
- Confirm error responses include correlationId field
- Confirm log output includes correlationId in JSON structure
- Hit health endpoint and verify 200 response

## References

- `META/patterns/api/observability-middleware.js`
- `META/patterns/api/rest-error-handling.ts`
