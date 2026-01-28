# External Service Setup Checklist

Use when the project depends on external services (e.g., Supabase, Stripe, S3).

## Goal

Ensure external service dependencies are documented, configured, and testable locally.

## Checks

### Required
- [ ] Document the service in README (what it is used for)
- [ ] Identify required external info (API keys, URLs, project refs) and ask early
- [ ] Record placeholders in `.env.example` (never store real secrets)
- [ ] Provide `.env.example` with required variables
- [ ] Provide setup steps for local dev
- [ ] Provide a verification step (how to test connectivity)
- [ ] Never commit secrets or real credentials

### Data/Schema
- [ ] Schema or migration files included (SQL or migrations)
- [ ] Seed data or fixtures if required
- [ ] Reset/refresh instructions for local dev

### CI/Test Environment
- [ ] Tests run without real credentials (mocks or local service)
- [ ] CI uses safe defaults or test credentials

### Supabase Notes (if applicable)
- [ ] `supabase` CLI usage documented (init/start/reset)
- [ ] Schema in `supabase/migrations` or `supabase/seed.sql`
- [ ] RLS policies documented
- [ ] Service role vs anon key usage explained

## How to Verify

- `.env.example` exists with all required variables
- README has a setup section for the external service
- `docs/SETUP.md` exists with step-by-step instructions
- A verification command is documented (e.g., curl health endpoint)
