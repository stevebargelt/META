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

### Client-Side Observability (REQUIRED for web/mobile apps)
- [ ] Error tracking SDK installed (@sentry/react, @sentry/react-native, or equivalent)
- [ ] Error boundary component wraps app with error reporting
- [ ] Sentry DSN configured via environment variable (VITE_SENTRY_DSN)
- [ ] User identification on auth (Sentry.setUser)
- [ ] Analytics SDK installed (posthog-js or equivalent)
- [ ] PostHog configured with project key (VITE_POSTHOG_API_KEY)
- [ ] Page views tracked automatically
- [ ] Key user actions tracked (signup, login, feature usage)
- [ ] Trace ID generated client-side and passed to API calls via x-trace-id header

### Optional (If Needed)
- [ ] OpenTelemetry tracing configured
- [ ] Metrics exported (latency, error rate, request count)
- [ ] Source maps uploaded to Sentry for readable stack traces
- [ ] Session replay configured (PostHog/Sentry)

## How to Verify

### Backend
- Search server code for correlation ID middleware
- Confirm error responses include correlationId field
- Confirm log output includes correlationId in JSON structure
- Hit health endpoint and verify 200 response

### Frontend (Web/Mobile)
- Verify `@sentry/react` or equivalent in package.json dependencies
- Search for `Sentry.init` in app entry point (main.tsx, App.tsx)
- Verify ErrorBoundary component wraps the app
- Verify `posthog-js` or equivalent in package.json dependencies
- Search for `posthog.init` in app entry point
- Verify API client adds trace headers to requests

## References

- `META/patterns/api/observability-middleware.js`
- `META/patterns/api/rest-error-handling.ts`
