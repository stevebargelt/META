# Project Retrospective: test-app

**Date:** 2026-01-27
**Duration:** ~4 hours
**Status:** Completed but not working

## What We Built

Production‑quality TODO app scaffold with Supabase‑based auth architecture: React (Vite) client + Express server, feature‑first structure, auth middleware, task CRUD, and tests. The orchestration pipeline bootstrapped PRD + ARCHITECTURE docs and sequenced build steps. Supabase project configuration remains outstanding (env/credentials).

**Key features/components:**
- Express API with task CRUD + auth middleware
- React client with auth flow + task UI
- Vitest + Supertest test suites (server + client)
- PRD + ARCHITECTURE docs, feature‑first structure

## What Worked

### Agent Usage
- **Product Manager** produced a clean PRD quickly. I woudl liek to see a more detailed PRD in the future. 
- **Architect** translated PRD into a clear API/data model and build order.
- Multi‑agent flow worked once pipelines were stable; orchestration reduced manual handoffs.

### Technical Choices
- Vite + React for client speed and simplicity.
- Express + Zod + Pino created a clear, testable API stack.
- Feature‑first structure kept backend/client organized by domain.

### Process Wins
- Tmux orchestration made multi‑agent flow tangible and repeatable.
- `.handoff.md` captured decisions and kept agents aligned.

## What Didn't Work

### Agent Issues
- Orchestrator generated non‑existent agent names in the pipeline (e.g., “test‑automation‑specialist”), causing failures. FIXED
- Interactive vs non‑interactive CLI modes caused confusion and stalls. FIXED

### Technical Challenges
- Supabase credentials were not configured, blocking full runtime validation. The agent shoudl have asked the user for credentials. The orchestrator shoudl be able to spin up a special interactive agent to take into account the need for creds like this. 
- Codex sandbox blocked `npm test` until workspace‑write mode was enforced.

### Process Problems
- Resume logic reattached to the wrong pipeline in early iterations. FIXED
- Quality gate prompts were ambiguous without context and required manual intervention.
- Quality gates - human user needs more information in the control window "Approve?" is not enough - what am I approving? Code? A doc to look at? At least liks or paths to what needs to be approved. 
- No steps ran in parallel because the pipeline never assigned any `PARALLEL_GROUP` values.

### Missing Deliverables
- Observability/traceability was explicitly requested but not implemented (no tracing/logging baseline).
- No CI/CD pipeline was created.
- No project `README.md`.
- No git commits or pushes during the build.
- No Supabase setup steps or database bootstrap file.

## Patterns Added to META

- `patterns/auth/supabase-jwt-middleware.js` — Supabase JWT auth middleware
- `patterns/api/zod-validation-middleware.js` — Zod validation middleware for Express
- `patterns/testing/supertest-in-memory.js` — Supertest in-memory adapter (no port binding)
- META tooling improvements captured in scripts/meta (pipeline switching, resume fixes, CLI override).

## Agent Evolution

### Updates Made
- **orchestrator.md:** constrained allowed agent names to existing definitions.
- **meta CLI:** added dynamic pipeline switching and resume fixes (tooling, not agent).

### New Learnings
- Use interactive mode only for kickoff; keep all build steps non‑interactive. Unless an agent needs to ask for credentials or other user information. This should be done as early as possible to allow most of the steps to run non-interactive. 
- Enforce valid agent names in generated pipelines.
- CLI override for model/tool must supersede pipeline defaults.

## Model Performance

| Task | Model Used | Rating | Notes |
|------|------------|--------|-------|
| Kickoff + PRD + Architecture | Claude | ⭐⭐⭐ | Strong structured planning; hit usage limits mid‑pipeline. |
| Build + Testing (late stages) | Codex | ⭐⭐ | Completed tasks but needed sandbox tweaks; slower due to environment constraints. |

## Metrics

- **Time saved:** ~40% vs manual planning + scaffolding
- **Iterations:** 4–6 pipeline/debug iterations
- **Context resets:** 0 (no full resets)
- **Model switches:** 1 (Claude → Codex)

## Key Decisions

| Decision | Approach Chosen | Rationale | Outcome |
|----------|----------------|-----------|---------|
| Orchestration | tmux‑based meta CLI | Faster multi‑agent loop | Worked after fixes |
| Auth | Supabase JWT + server verification | Security + simplicity | Implemented; needs env config |
| Validation | Zod | Strong schema validation | Implemented |
| Tests | Vitest + Supertest | Consistent tooling | Implemented; sandbox needed write access |

## Reusable Assets

- Code patterns: Auth middleware + task CRUD + Zod validators
- Prompts: `project.pipeline` + `meta` orchestration prompts
- Configurations: Vite/Express scaffolding, Vitest setup

## Would Do Differently

1. Make Supabase env setup a prerequisite step. — Prevents runtime/test failures.
2. Force agent name validation earlier. — Avoid pipeline failures.
3. Every project should have a CI/CD pipeline. 
4. Add observability requirements to the architecture + implementation checklist.
5. Require a minimal `README.md` before declaring completion.
6. Commit early and often; push once a stable milestone is reached.
7. Provide setup steps for external services (Supabase) before feature work.
8. Explicitly mark independent tasks with `PARALLEL_GROUP` to enable true parallelism.

## Would Do Same

1. Use tmux orchestration. — Keeps multi‑agent flow visible and controllable.
2. Keep feature‑first structure. — Clear separation across server/client.

## Next Steps

- [ ] Update `learnings/what-works.md` with “tmux pipeline orchestration works after stabilization”
- [ ] Update `learnings/what-doesnt.md` with “auto‑generated agent names break pipelines”
- [ ] Update `learnings/model-comparison.md` with Claude vs Codex observations
- [x] Extract reusable auth + CRUD patterns if this stack is reused

## Notes for Future Projects

- Ensure tool default (codex/claude) is explicit when resuming.
- Add a visible note in control window for interactive steps.
- Treat sandbox permissions as part of the run config (tests need write access).
