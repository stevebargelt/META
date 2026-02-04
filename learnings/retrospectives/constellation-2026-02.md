# Project Retrospective: Constellation

**Date:** 2026-02-03
**Duration:** ~1 week (initial MVP pipeline + manual fixes)
**Status:** MVP Complete (with manual data layer fixes)

## What We Built

A polyamorous relationship coordination app with calendar, meal planning, task management, and recipe storage. Monorepo with React web app, React Native mobile (placeholder), Supabase backend with Edge Functions as BFF layer.

**Key features/components:**
- Today dashboard with calendar, meals, and tasks summary
- Task management with assignee tracking and task balance visualization
- Meal planning with weekly calendar view
- Calendar with day/week/month views
- Recipe library with search and tags
- Supabase migrations for all domain tables with RLS policies
- BFF layer (Edge Functions) for web and mobile clients

## What Worked

### Agent Usage
- **Architect** produced excellent system design with clear component boundaries
- **UX Designer** created comprehensive wireframes and user flows
- **DevOps Engineer** (new) successfully set up CI/CD and observability baseline
- Multi-agent pipeline executed all steps without crashes

### Technical Choices
- Supabase with RLS policies worked well for multi-tenant data isolation
- React Query for data fetching (once configured) provides excellent caching
- Tailwind CSS v4 for styling was straightforward
- Edge Functions as BFF layer cleanly separates client concerns

### Process Wins
- UX design docs being referenced by downstream agents improved UI consistency
- External services setup checklist ensured all third-party services were configured
- Auto-commit per step created clean git history

## What Didn't Work

### Agent Issues
- **Frontend implementation** produced mock data instead of real API integration
- No agent explicitly owned the "data layer" (hooks, providers, type generation)
- Pipeline assumed frontend would connect to backend automatically
- **CRITICAL: Mobile app was completely skipped** despite being explicitly in PRD requirements

### Technical Challenges
- React Query installed but `QueryClientProvider` never added to app
- No data fetching hooks created despite React Query being available
- Database types never generated (`supabase gen types`)
- Auth hooks not created; auth flow not wired up
- Pages used `useState` with hardcoded mock arrays

### Observability Gap (BFF vs Web App)
- **Sentry:** Fully implemented in Edge Functions (`tracing.ts`), but NOT in web app (no `@sentry/react` installed)
- **PostHog:** Fully implemented in Edge Functions (`analytics.ts`), but NOT in web app (no `posthog-js` installed)
- **Vercel:** No deployment workflow configured; CI only runs test/lint/build
- `.env.example` has all the right variables (`VITE_SENTRY_DSN`, `VITE_POSTHOG_API_KEY`) but web app never uses them
- **Impact:** Frontend errors go completely untracked; no user analytics from client; can't correlate user actions to backend traces

### Process Problems
- DoD checklist didn't catch mock data until manual review
- No explicit "data layer setup" step in pipeline
- Gap between "backend exists" and "frontend uses backend"
- **Orchestrator silently dropped mobile app from build plan** - PRD specified React Native mobile app, but orchestrator generated pipeline with web-only implementation. No justification given, no flag raised, requirement simply ignored.

## Patterns Added to META

- `agents/base.md` — Added "No Mock Data in Production Code" standard
- `agents/reviewer.md` — Added mock data detection to review checklist
- `prompts/definition-of-done-checklist.md` — Added Integration (CRITICAL) section
- `workflows/pipelines/project.pipeline` — Added note about real backend connection
- `workflows/pipelines/feature.pipeline` — Updated frontend step to require real API connection

## Agent Evolution

### Updates Made
- **base.md:** Added Implementation Standards section with explicit "No Mock Data" rule
- **reviewer.md:** Added integration checklist (mock data, API client, migrations, auth, CRUD)
- **devops-engineer.md:** Created new agent for CI/CD, deployment, observability

### New Learnings
- Frontend agents need explicit instructions to create data layer, not just UI
- "Connect to real backend" must be an explicit, verifiable requirement
- Database type generation should be a pipeline step, not assumed

## Model Performance

| Task | Model Used | Rating | Notes |
|------|------------|--------|-------|
| Architecture | Sonnet | ⭐⭐⭐⭐⭐ | Excellent system design |
| UX Design | Sonnet | ⭐⭐⭐⭐⭐ | Comprehensive wireframes |
| Frontend UI | Sonnet | ⭐⭐⭐ | Good UI, but used mock data |
| Database migrations | Sonnet | ⭐⭐⭐⭐⭐ | Clean RLS policies |
| Manual fixes | Opus | ⭐⭐⭐⭐⭐ | Quickly fixed data layer |

## Metrics

- **Time saved:** ~70% (architecture, migrations, UI would take weeks manually)
- **Iterations:** 1 major revision (adding data layer manually)
- **Context resets:** 1 (for data layer fix session)
- **Model switches:** 1 (Sonnet for pipeline, Opus for fixes)

## Key Decisions

| Decision | Approach Chosen | Rationale | Outcome |
|----------|----------------|-----------|---------|
| BFF pattern | Edge Functions per client type | Clean separation, client-specific optimizations | Good |
| Data fetching | React Query | Industry standard, good caching | Good (once configured) |
| Auth | Supabase Auth | Integrated with database, built-in RLS | Good |
| Database types | Generate from schema | Type safety for queries | Excellent |

## Reusable Assets

- **Code patterns:**
  - `lib/supabase.ts` - Typed Supabase client setup
  - `hooks/use{Entity}.ts` - Pattern for CRUD hooks with React Query
  - `hooks/useAuth.ts` - Auth state management pattern
  - `hooks/useConstellation.ts` - Multi-tenant context pattern

- **Prompts:**
  - Explicit data layer requirements for frontend steps
  - Integration verification checklist

- **Configurations:**
  - Vite + React Query + Supabase monorepo setup

## Would Do Differently

1. **Require orchestrator to justify scope reductions** — If PRD says "web + mobile" and pipeline only has web, orchestrator MUST explicitly document why and get approval. Silent scope reduction is unacceptable.

2. **Add explicit "Data Layer Setup" pipeline step** — Between backend completion and frontend implementation, have a step that:
   - Generates database types
   - Sets up React Query provider
   - Creates base data hooks
   - Wires up auth context

3. **Frontend step must reference backend** — Change prompt from "implement UI" to "implement UI connected to real API endpoints"

4. **Quality gate should search for mock data** — Add `grep -r "mock\|Mock\|MOCK" src/ --include="*.tsx"` to quality gate script

5. **Generate database types early** — Make this part of the initial setup, not an afterthought

6. **DoD must verify ALL platforms in PRD are implemented** — Checklist item: "All platforms specified in PRD have working implementations"

7. **Require observability in ALL layers, not just backend** — DevOps agent set up Sentry/PostHog in Edge Functions but NOT in web app. Observability checklist must verify client-side error tracking and analytics are wired up, not just backend.

8. **Add deployment workflow, not just CI** — CI workflow only runs test/lint/build. No Vercel/Netlify deployment step. "DevOps" should mean deployment, not just testing.

## Would Do Same

1. **BFF layer with Edge Functions** — Clean separation worked well
2. **Comprehensive UX docs** — Improved UI consistency across pages
3. **Supabase RLS policies** — Security built into data layer
4. **DevOps agent for CI/CD** — Good to have deployment pipeline from start

## Next Steps

- [x] Update `learnings/what-works.md` with database type generation pattern
- [x] Update `learnings/what-doesnt.md` with data layer anti-patterns
- [x] Add `scripts/quality-gate.sh` check for mock data patterns
- [x] Update `prompts/definition-of-done-checklist.md` with scope verification
- [x] Update `workflows/pipelines/project.pipeline` with scope enforcement
- [ ] Update `workflows/pipelines/project.pipeline` with explicit data layer step
- [ ] Create `patterns/react/data-layer-setup.md` template
- [x] Update `prompts/observability-checklist.md` to require client-side instrumentation
- [x] Update `agents/devops-engineer.md` checklist and anti-patterns
- [x] Update `prompts/definition-of-done-checklist.md` with CD and frontend observability checks
- [x] Update `learnings/what-doesnt.md` with observability gap anti-pattern

## Notes for Future Projects

The gap between "backend exists" and "frontend uses backend" is significant. Don't assume AI agents will connect them automatically. Explicit instructions and verification are required.

Key question to ask at DoD: "Can I create, read, update, and delete a record through the UI?"

---

## PRD vs Implementation Gap Analysis

Comprehensive audit performed 2026-02-03 comparing PRD and Architecture documents against actual implementation.

### CRITICAL GAPS (Scope Violations)

| # | Gap | PRD/Arch Requirement | Reality | Impact |
|---|-----|---------------------|---------|--------|
| 1 | **Mobile App Missing** | iOS + Android React Native apps | `apps/mobile/` has only `export const placeholder = true`. No RN code, no ios/, no android/ | 50% of platform requirement missing |
| 2 | **CalDAV Not Implemented** | Two-way Apple Calendar sync within 30 seconds | `caldav.ts` throws "not yet implemented". No protocol, no credentials, no polling | Core calendar value prop missing |
| 3 | **Real-time Missing** | Supabase Realtime subscriptions | No `.on('postgres_changes')` code. React Query 5-min stale cache only | Not collaborative for simultaneous use |
| 4 | **Client Observability Missing** | Sentry + PostHog in web & mobile | Backend has full implementation; web app has ZERO (no packages installed) | Frontend errors untracked |
| 5 | **Offline Support Missing** | IndexedDB queue, background sync | No offline queue, no service worker, no local storage | App unusable without network |
| 6 | **Deployment Missing** | Vercel deployment, App Store builds | CI only (test/build). No CD workflow | No automated deployment |

### HIGH GAPS (Feature Incomplete)

| # | Gap | PRD Requirement | Reality |
|---|-----|-----------------|---------|
| 7 | **Task Recurrence** | Auto-generate next occurrence | `recurrence_rule` field exists, no processing logic |
| 8 | **Relationship UI** | Create/view relationships | Routes return "Coming soon..." placeholder |
| 9 | **Permission UI** | Per-person permissions | Routes return "Coming soon..." placeholder |

### MEDIUM GAPS

| Gap | Reality |
|-----|---------|
| Auth Route Protection | Routes publicly accessible, page-level guards only |
| Recipe URL Import | Backend exists, not wired to UI |
| Settings Functionality | UI toggles exist, no backend logic |
| Test Implementation | 100% `.todo()` stubs |

### Implemented Pages (7 working)
- TodayPage, CalendarPage, MealsPage, TasksPage, RecipesPage, SettingsPage, MorePage

### Placeholder Pages (4 not implemented)
- Profile, Relationships, Permissions, Help (all show "Coming soon...")

### Backend Status (Fully Implemented)
- Web-BFF: Complete (all endpoints)
- Mobile-BFF: Complete (all endpoints, ready for mobile client that doesn't exist)
- Database: 13 migrations, full RLS policies
- Tracing: Full Sentry integration in Edge Functions
- Analytics: Full PostHog integration in Edge Functions
- OpenAPI: Complete spec at `docs/api/openapi.yaml`

### Root Causes (META Framework Gaps)

1. **Orchestrator silently dropped mobile** — Generated web-only pipeline despite PRD requiring mobile. No justification, no approval request.
2. **CalDAV silently deferred** — Listed as MVP must-have, stubbed without flagging.
3. **Observability checklist backend-only** — Didn't require client-side instrumentation.
4. **Quality gate didn't verify CD** — Passed with CI-only (test/build), no deployment.
5. **No real-time verification** — Architecture specified, never verified.
6. **DoD didn't catch placeholder pages** — 4 core features show "Coming soon..."
