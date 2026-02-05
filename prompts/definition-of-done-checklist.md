# Definition of Done Checklist

Final verification that the project is shippable.

## Goal

Confirm all quality gates pass before marking a pipeline complete.

## Checks

### Scope Verification (CRITICAL)
- [ ] **All platforms implemented** — If PRD specifies web + mobile, BOTH must be built. List each platform and its status.
- [ ] **All major features implemented** — Cross-reference PRD features against actual implementation. No silent scope reductions.
- [ ] **Scope exceptions documented** — If any PRD item was intentionally deferred, document WHY and confirm user approved the deferral.

### Required
- [ ] README exists and matches `META/prompts/readme-template.md`
- [ ] CI pipeline exists (e.g., `.github/workflows/ci.yml`)
- [ ] **CD pipeline exists** — Deployment workflow to Vercel/Netlify/etc. (not just test/build)
- [ ] Observability baseline implemented (`META/prompts/observability-checklist.md`)
- [ ] **Client-side observability** — Sentry and PostHog installed AND initialized in web/mobile app (not just backend)
- [ ] External service setup documented if applicable (`META/prompts/external-service-setup-checklist.md`)
- [ ] Git history exists with at least one milestone commit (`META/prompts/git-hygiene-checklist.md`)
- [ ] Tests pass for core packages
- [ ] OpenAPI validated if `docs/openapi.yaml` exists

### Integration (CRITICAL)
- [ ] **No mock data in production code** — Search for `mock`, `stub`, `fake`, `hardcoded` in non-test files
- [ ] **Backend connected** — API client exists and is used (e.g., `lib/supabase.ts`, `lib/api.ts`)
- [ ] **Database migrations applied** — Run `supabase migration list` or equivalent
- [ ] **Auth wired up** — Login/logout works with real auth provider
- [ ] **CRUD operations work** — Can create, read, update, delete at least one entity type
- [ ] **Environment variables used** — No hardcoded URLs or keys in source code

### E2E Smoke Test (CRITICAL)
Before marking complete, manually verify the app actually works end-to-end:

1. [ ] **Create** — Create a new [primary entity] through the UI
2. [ ] **Read** — Verify it appears in the list/view
3. [ ] **Update** — Modify the entity through the UI
4. [ ] **Persist** — Refresh the page, verify changes persisted
5. [ ] **Delete** — Delete the entity through the UI
6. [ ] **Confirm** — Verify it's removed from the list

**Document results in `.meta/handoff.md`:**
```
## E2E Smoke Test Results
- Entity tested: [e.g., Task, Recipe, Event]
- Create: [pass/fail] - Created "[entity name]" at [timestamp]
- Read: [pass/fail] - Appeared in list
- Update: [pass/fail] - Changed [field] to [value]
- Persist: [pass/fail] - Data survived page refresh
- Delete: [pass/fail] - Entity removed
```

**Why this matters:** Mock data passes visual review. This test proves the frontend actually connects to the backend.

### User Journey Validation (CRITICAL)
Verify that a new user can complete the primary flow without manual intervention.

**Authentication Flow**
- [ ] Unauthenticated user sees a sign-in UI (form or OAuth button)
- [ ] User can sign in and reach the main app
- [ ] Sign-out works and returns user to sign-in state

**Primary Feature Flow**
- [ ] User can reach the primary feature from navigation
- [ ] User can complete the primary action end-to-end (not just view a page)
- [ ] Errors are shown to the user (not only in console/logs)

**Mobile (if applicable)**
- [ ] Mobile app launches without errors
- [ ] README documents how to run the mobile app

### Recommended
- [ ] `.env.example` provided for required env vars
- [ ] Architecture or decisions documented (if non-trivial)
- [ ] Known issues listed in AGENTS.md or README

## How to Verify

Run `META/scripts/quality-gate.sh --project .` and confirm all checks pass. Then verify each checklist item manually.

## Output Template

```markdown
## Definition of Done Check

### Scope Verification
| PRD Item | Status | Implementation |
|----------|--------|----------------|
| Web app | [done/missing] | apps/web/ |
| Mobile app | [done/missing] | apps/mobile/ |
| Feature X | [done/missing] | path/to/implementation |

**Scope exceptions:** [None / List any deferred items with justification]

### Quality Checks
- README: [pass/fail] (path)
- CI pipeline: [pass/fail] (path)
- CD pipeline: [pass/fail] (deployment workflow path)
- Backend observability: [pass/fail] (Sentry/PostHog in API/BFF)
- Frontend observability: [pass/fail] (@sentry/react and posthog-js installed AND initialized)
- External services setup: [pass/fail] (notes)
- Git history: [pass/fail] (summary)
- Tests: [pass/fail] (commands run)
- .env.example: [pass/fail]
- Docs/decisions: [pass/fail]

**Blocking issues:**
- [ ] ...

**Non-blocking issues:**
- [ ] ...
```
