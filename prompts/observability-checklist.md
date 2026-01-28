# Observability Checklist

Use this to verify baseline observability (logs + traceability) is in place.

## Required

- [ ] Correlation/request ID generated per request
- [ ] Correlation ID returned in response headers and error bodies
- [ ] Structured logs (JSON) include: requestId, method, path, status, duration
- [ ] Error handler logs error with stack trace and correlation ID
- [ ] Authenticated requests log userId (or anonymized equivalent)
- [ ] Health endpoint exists and returns status

## Recommended

- [ ] Request logging includes latency and response size
- [ ] Logs redact secrets and tokens
- [ ] Log levels configurable via env
- [ ] Service name + version included in logs
- [ ] Downstream calls (DB/external APIs) include correlation ID

## Optional (If Needed)

- [ ] OpenTelemetry tracing configured
- [ ] Metrics exported (latency, error rate, request count)

## References

- `META/patterns/api/observability-middleware.js`
- `META/patterns/api/rest-error-handling.ts`
