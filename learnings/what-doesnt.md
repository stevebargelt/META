# What Doesn't Work

Anti-patterns and approaches to avoid, learned from real experience.

**Last Updated:** 2026-02-03

---

## Agent Usage Anti-Patterns

### Parallelizable Work Left Sequential

**What:** Building pipelines without `PARALLEL_GROUP`, even when steps are independent
**Why it fails:** Slower delivery, no concurrency benefit from multi-agent setup
**Example:** All steps in the pipeline have `PARALLEL_GROUP` set to `-`
**Instead:** Group independent steps with a shared `PARALLEL_GROUP` label
**Source:** test-app (2026-01)

### Inventing New Agent Names

**What:** Orchestrator generates agent names that don't exist in `META/agents/`
**Why it fails:** Pipeline crashes when agent definition file is missing
**Example:** `test-automation-specialist` in generated pipeline
**Instead:** Restrict to existing agent names only
**Source:** test-app (2026-01)

---

## Development Workflow

### Building Without Commits

**What:** Completing a project with zero local commits or pushes
**Why it fails:** No history, no rollback points, no visibility into progress
**Example:** A full build with no git commits
**Instead:** Commit early/often and push at stable milestones
**Source:** test-app (2026-01)

### Running Tests in Read-Only Sandboxes

**What:** Running test suites in a sandbox that blocks temp dirs or node_modules writes
**Why it fails:** Tools like Vitest create temp files; tests crash on EPERM
**Example:** `EPERM: operation not permitted, mkdir ... node_modules/.vite-temp`
**Instead:** Use workspace-write or allow temp paths for test runs
**Source:** test-app (2026-01)

---

## Quality Practices

### Ignoring Observability Requirements

**What:** Skipping logging/traceability even when explicitly requested
**Why it fails:** Hard to debug, no audit trail, lower ops confidence
**Example:** App shipped without baseline tracing/logging
**Instead:** Implement observability in the base API stack (correlation IDs, structured logs, tracing hooks)
**Source:** test-app (2026-01), test-app-2 (2026-01)

### Backend-Only Observability

**What:** DevOps agent sets up Sentry/PostHog in backend/BFF but not in frontend
**Why it fails:** Frontend errors go completely untracked. No user analytics from client. Can't correlate user actions to backend traces. When users report bugs, you have no visibility into what happened on their end.
**Example:** Constellation had full tracing in Edge Functions (`tracing.ts`, `analytics.ts`) with Sentry + PostHog, but web app had no `@sentry/react` or `posthog-js` installed despite `.env.example` having `VITE_SENTRY_DSN` and `VITE_POSTHOG_API_KEY` ready
**Instead:**
- Observability checklist must verify BOTH backend AND frontend instrumentation
- DevOps agent should install and configure client-side SDKs (Sentry, PostHog) in same step as backend
- Error boundary component with Sentry integration should be standard
- Frontend should generate/propagate trace IDs to backend calls
**Source:** Constellation (2026-02)

### Missing OpenAPI Contract Stub

**What:** Parallel work begins without an OpenAPI (or equivalent) contract stub
**Why it fails:** Teams diverge, unclear expectations, integration friction later
**Example:** No `docs/openapi.yaml` despite preference and parallelization planning
**Instead:** Create a minimal OpenAPI spec before parallel work starts
**Source:** test-app-2 (2026-01)

---

## Documentation

### ASCII Art Diagrams in Architecture Docs

**What:** Using ASCII box diagrams instead of Mermaid for architecture documentation
**Why it fails:** ASCII art doesn't render nicely, is hard to update, and many tools can't interpret it. Mermaid renders in GitHub, VS Code, and most markdown viewers automatically.
**Example:** Constellation ARCHITECTURE.md used ASCII boxes for system overview instead of Mermaid flowcharts
**Instead:** Always use Mermaid syntax for all diagrams (flowchart, sequenceDiagram, erDiagram, stateDiagram-v2)
**Source:** Constellation (2026-02)

### Skipping README for New Project

**What:** Shipping a project without a `README.md`
**Why it fails:** No onboarding path, unclear run steps, unclear scope
**Example:** App delivered with no README
**Instead:** Require a minimal README (run instructions, env vars, scripts)
**Source:** test-app (2026-01)

### Missing External Service Setup Steps

**What:** Relying on external services without setup instructions or bootstrap files
**Why it fails:** Users cannot run or validate the app
**Example:** Supabase required but no schema/setup steps provided
**Instead:** Provide setup docs and a bootstrap path (SQL, migrations, or CLI steps)
**Source:** test-app (2026-01)

### Late Integration Validation

**What:** Waiting until the final DoD step to verify that parallel workstreams compose correctly
**Why it fails:** Blocking issues found late require significant rework; root package.json missing, TS errors across workspaces, config mismatches
**Example:** Step 15 found root package.json missing, TypeScript errors in test files, Vite proxy pointing to wrong port
**Instead:** Add intermediate build validation after parallel merges (`npm run build && npm test` at workspace root before polish/review stages)
**Source:** test-app-5 (2026-01)

### No CI/CD Pipeline

**What:** Shipping a project without any CI/CD automation
**Why it fails:** No repeatable build/test/deploy path, quality gates ignored
**Example:** Manual-only build with no CI workflows
**Instead:** Add at least one CI pipeline for lint/test/build
**Source:** test-app (2026-01)

### CI Without CD (Test Only, No Deploy)

**What:** CI workflow only runs test/lint/build but has no deployment step
**Why it fails:** App can't actually be deployed. "DevOps" incomplete. Manual deployment required every time, prone to errors and inconsistency.
**Example:** Constellation had `.github/workflows/ci.yml` that ran pnpm test/lint/build but no Vercel/Netlify deployment workflow. `.env.example` mentioned `VERCEL_TOKEN` but it was never used.
**Instead:**
- DevOps agent should set up BOTH CI (test/lint/build) AND CD (deploy to Vercel/Netlify/etc.)
- Add deployment workflow that triggers on main branch push
- Include preview deployments for PRs
- Quality gate should verify deployment workflow exists, not just CI
**Source:** Constellation (2026-02)

### Missing Root .gitignore

**What:** Subdirectories have their own .gitignore but root does not
**Why it fails:** node_modules, .env, build artifacts, IDE files can be committed accidentally
**Example:** test-app-5 shipped with no root .gitignore despite monorepo structure
**Instead:** Scaffold .gitignore on project init; quality gate checks for it
**Source:** test-app-5 (2026-01)

### Quality Gate Assumes Single package.json

**What:** Quality gate script only checks root `package.json` for test script
**Why it fails:** Monorepos with separate server/client directories have no root package.json; test check gets skipped
**Example:** test-app-6 skipped test validation despite 156 tests in server/
**Instead:** Update `quality-gate.sh` to detect monorepo structure and check subdirectories (server/, client/, packages/*)
**Source:** test-app-6 (2026-01)

### No Frontend Test Generation

**What:** Pipelines generate backend tests but not frontend (React) tests
**Why it fails:** UI logic, component behavior, and integrations go untested; 156 backend tests but 0 frontend tests
**Example:** test-app-6 has React + TanStack Query + @dnd-kit but no component tests
**Instead:** Add frontend test step to orchestrator template; configure Vitest + Testing Library for client/
**Source:** test-app-6 (2026-01)

---

## Scope and Requirements Anti-Patterns

### Silently Dropping Requirements

**What:** Orchestrator generates a build pipeline that omits major features from the PRD without explanation or approval
**Why it fails:** Stakeholder expects complete delivery per PRD. Discovering missing features at the end wastes the entire pipeline run and erodes trust. The agent made a unilateral decision to reduce scope without consent.
**Example:** Constellation PRD explicitly required React Native mobile app. Orchestrator generated web-only pipeline. Mobile app was never built. No justification provided, no flag raised to user.
**Instead:**
- Orchestrator MUST implement ALL features in PRD unless explicitly told to reduce scope
- If orchestrator believes scope should be reduced, it MUST stop and ask for approval with justification
- DoD checklist must verify: "All platforms/features in PRD have implementations"
- Pipeline gate after orchestrator step should compare pipeline coverage to PRD scope
**Source:** Constellation (2026-02)

---

## Feature Development Anti-Patterns

### Feature PRD Appended to Main PRD

**What:** Product-manager agent appends feature PRD content to existing `docs/PRD.md`
**Why it fails:** Pollutes original project PRD, hard to track feature history, unclear what was original vs added
**Example:** "Feature PRD: Shopping List Generation" appended to Recipe Manager PRD
**Instead:** Create separate file `docs/PRD-<feature-name>.md` for each feature
**Source:** test-app-7 (2026-01)

### Feature Work Without Feature Branch

**What:** Feature development commits directly to main branch
**Why it fails:** No isolation for feature development, harder to review, can't easily revert feature
**Example:** Shopping list feature commits mixed with main branch history
**Instead:** Create `feature/<name>` branch at start of feature pipeline, merge/PR at end
**Source:** test-app-7 (2026-01)

### Sequential Feature Pipeline

**What:** Feature pipeline runs all steps sequentially despite independent workstreams
**Why it fails:** Dramatically slower (11.6 hrs vs expected ~2 hrs), no concurrency benefit
**Example:** Tester, backend impl, frontend impl all sequential when they could be parallel
**Instead:** Use `PARALLEL_GROUP` for tester + backend + frontend, add build validation after merge
**Source:** test-app-7 (2026-01)

### Mock Data in Production Code

**What:** Frontend implementation uses hardcoded mock data instead of connecting to real backend
**Why it fails:** App looks complete but doesn't actually work. No real CRUD, no auth, no data persistence. Users can't use the app.
**Example:** Constellation pages had `const mockTasks = [...]` instead of Supabase queries. Migrations existed, BFFs existed, but frontend never connected to them.
**Instead:**
- Create API client (`lib/supabase.ts`) as first frontend step
- Use React Query with real endpoints
- Wire up auth immediately
- Mock data ONLY in test files, Storybook, or explicit demo modes
- DoD must verify real data flow (create/read/update/delete works)
**Source:** Constellation (2026-02)

### No Data Layer Setup Step

**What:** Pipeline goes directly from "backend complete" to "implement frontend UI" without explicit data layer setup
**Why it fails:** Agents implement UI with local state and mock data because no hooks/providers exist. The connection between backend and frontend is assumed, not built.
**Example:** Constellation had React Query installed but no QueryClientProvider in main.tsx, no data fetching hooks created, no auth context. Each page used `useState` with hardcoded arrays.
**Instead:** Add explicit data layer step before frontend implementation:
1. Generate database types (`supabase gen types typescript`)
2. Set up data fetching library (QueryClientProvider)
3. Create base data hooks (useTasks, useEvents, useMeals, etc.)
4. Wire up auth context (useAuth, auth state management)
5. Create API client with proper typing
**Source:** Constellation (2026-02)

### Database Types Not Generated

**What:** Using Supabase without generating TypeScript types from the schema
**Why it fails:** No autocomplete for table/column names, no type checking on inserts/updates, runtime errors instead of compile-time errors. Queries can reference non-existent columns.
**Example:** Constellation frontend queries were untyped; `supabase.from('tasks').select('*')` returned `any`
**Instead:** Generate types as part of initial setup and after any schema change:
```bash
supabase gen types typescript --project-id <id> > packages/shared-types/src/database.ts
```
Add to README and document in development workflow.
**Source:** Constellation (2026-02)

### React Query Installed But Not Configured

**What:** Data fetching library (React Query, SWR, etc.) added to dependencies but provider never added to app
**Why it fails:** Hooks like `useQuery` won't work without the provider context. Developers resort to `useState` + `useEffect` patterns or mock data.
**Example:** Constellation had `@tanstack/react-query` in package.json but no `QueryClientProvider` in main.tsx
**Instead:** When adding React Query, always add provider setup in same step:
```tsx
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
const queryClient = new QueryClient();
// wrap app in <QueryClientProvider client={queryClient}>
```
**Source:** Constellation (2026-02)

---

---

## Adding to This Document

When you discover something that doesn't work:

1. **Verify it's actually a problem** — Did it fail once or repeatedly?
2. **Document specifics** — What exactly went wrong?
3. **Explain why** — What made this ineffective?
4. **Provide alternative** — What should you do instead?
5. **Add source** — Which project taught you this?

**Format:**
```markdown
### [Anti-Pattern Name]

**What:** [What you tried]
**Why it fails:** [Actual problems]
**Example:** [Specific case]
**Instead:** [Better approach]
**Source:** [Project name, date]
```

If something moves from `what-works.md` to here, note why it stopped working.
