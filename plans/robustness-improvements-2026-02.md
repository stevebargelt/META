# Robustness Improvements (2026-02)

Goal: Make META reliably deliver a production‑ready MVP end‑to‑end (PRD → implementation → verification) with minimal manual fixes.

## Prioritized Fixes (5–10)

1. **P0 — User Journey Validation in DoD**
   - Why: Retros show infra is built but user can’t complete core flows (auth UI missing, CRUD not reachable).
   - Change: Add explicit user‑journey checks (auth + primary CRUD) to `prompts/definition-of-done-checklist.md`.
   - Status: **Started**

2. **P0 — Explicit Data Layer Integration Step in Feature Pipeline**
   - Why: “Backend exists” ≠ “frontend uses backend.” Missing data layer is the #1 gap.
   - Change: Add a data layer step between backend and frontend in `workflows/pipelines/feature.pipeline`.
   - Status: **Started**

3. **P0 — Client Observability Initialization Check**
   - Why: Sentry/PostHog deps present, but no `Sentry.init`/`posthog.init` and no error boundary.
   - Change: Extend `scripts/quality-gate.sh` to verify initialization + error boundary usage.
   - Status: **Started**

4. **P1 — Enforce Deferrals with Explicit Approval**
   - Why: MVP items silently deferred (CalDAV, mobile, etc.).
   - Change: Update orchestrator prompt + DoD to require `docs/DEFERRED.md` and explicit approval.
   - Status: Planned

5. **P1 — CD Templates in `patterns/ci-cd/`**
   - Why: CI without CD persists; templates will make CD default.
   - Change: Add Vercel + Netlify + Supabase functions deploy workflows.
   - Status: Planned

6. **P1 — Supabase Realtime Verification**
   - Why: Architecture required realtime; implementation missed it.
   - Change: Add DoD item + optional quality‑gate grep (`supabase.channel` / `postgres_changes`).
   - Status: Planned

7. **P1 — README Completeness Check**
   - Why: Monorepos with mobile apps lack startup docs.
   - Change: Extend quality gate to ensure README references each app and how to run it.
   - Status: Planned

8. **P1 — Per-Group Verification Loops**
   - Why: Parallel streams finish but verification happens only at global gate.
   - Change: Require each parallel group to run its own tests/verification and fix failures before proceeding.
   - Status: **Started**

9. **P2 — Failure Escalation Rules**
   - Why: Repeated retries without strategy shift.
   - Change: Add escalation rules to `agents/orchestrator.md` and `agents/base.md`.
   - Status: Planned

10. **P2 — Verification Manager / Quality PM Agent (tmux‑orchestrator pattern)**
   - Why: Centralized verification enforcement reduces drift.
   - Change: Add new agent definition(s) and insert into pipelines as a gate.
   - Status: Planned

## Notes
- Items 1–3 are immediate blockers observed in Constellation post‑build.
- Items 4–7 address recurring gaps in scope coverage and production readiness.
- Items 8–9 incorporate the best tmux‑orchestrator patterns without adopting its full autonomy model.
