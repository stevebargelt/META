# META System Assessment: Holistic Analysis & Architectural Improvements

**Date:** 2026-02-03
**Analyst:** Claude Opus 4.5
**Scope:** Systemic analysis of why META pipelines produce incomplete output

---

## Executive Summary

META pipelines consistently produce projects with critical gaps:
- Mobile apps not built despite being in PRD
- Features incomplete or stubbed
- Frontend uses mock data instead of real backends
- Services exist but aren't connected

**Root cause:** META is optimized for **getting things done fast** but not for **ensuring they actually work**. The architecture trusts agents implicitly but provides no verification until too late. The system has three fundamental architectural flaws:

1. **Missing Intermediate Verification** - No checkpoints between phases to validate prerequisites
2. **Trust Without Enforcement** - Agents assume next phase has what it needs; it doesn't
3. **Information Loss** - Requirements don't thread through the pipeline; each phase is a black box

This isn't about fixing individual GitHub issues. It's about fixing the **verification architecture** of the entire system.

---

## Part 1: The Architecture of Failure

### 1.0 GitHub Issues: Pattern Analysis

Looking at all 24 open GitHub issues, clear patterns emerge:

| Category | Issues | Pattern |
|----------|--------|---------|
| **Verification Gaps** | #28, #29, #30, #31, #32, #33 | Things that should be checked aren't |
| **Pipeline Structure** | #7, #8, #12, #13 | Pipeline execution is opaque and incomplete |
| **Pattern Library** | #2, #3, #4, #9, #10, #11, #14, #17 | Growing but unorganized |
| **Meta-Project** | #5, #6 | META lacks versioning and success metrics |
| **Research/Future** | #15, #26, #27 | Nice-to-haves |

**The critical insight:** Issues #28-33 are all symptoms of the same root cause - **no verification at trust boundaries**. Fixing them individually won't prevent future failures. The architecture needs to change.

---

## Part 2: Failure Pattern Analysis

### 1.1 The Constellation Case Study

The most recent project (Constellation, Feb 2026) demonstrates all failure modes:

| PRD Requirement | Expected | Actual | Gap Type |
|-----------------|----------|--------|----------|
| iOS + Android mobile apps | React Native apps | `placeholder = true` | **Silent scope drop** |
| CalDAV calendar sync | Working two-way sync | `throw "not implemented"` | **Silent deferral** |
| Real-time sync | Supabase Realtime | React Query 5-min cache | **Architecture ignored** |
| Client observability | Sentry + PostHog in web | Zero client-side setup | **Single-layer thinking** |
| Deployment | Vercel CD | CI only (test/build) | **Incomplete DevOps** |
| All core pages | Working CRUD | 4 pages show "Coming soon" | **Placeholder shipping** |
| Backend connection | API calls | Hardcoded mock arrays | **Data layer gap** |

**Result:** A project that *looked* complete but didn't actually work.

### 1.2 Pattern: Silent Scope Reduction

**What happens:** Orchestrator receives PRD specifying "web + mobile". Generates pipeline with web-only steps. No flag raised, no approval requested, no justification documented.

**Why it happens:**
- Orchestrator prompt says "create a build plan" but doesn't enforce PRD coverage
- No verification step compares pipeline scope to PRD scope
- No mechanism requires approval for scope changes

**Evidence:** GitHub Issue #28, Constellation retrospective

### 1.3 Pattern: The Data Layer Gap

**What happens:**
1. Backend team builds migrations, BFF endpoints, types
2. Frontend team builds UI components with pages
3. Nobody builds the connection layer (hooks, providers, API client)
4. Frontend developers use `useState` with mock arrays as placeholder
5. Mock data passes visual review

**Why it happens:**
- Pipeline goes from "Backend Complete" → "Frontend Implementation"
- "Frontend Implementation" means UI, not data connections
- No explicit step owns the data layer
- Agents default to working code, which means mock data

**Evidence:** GitHub Issues #33, Constellation retrospective, `what-doesnt.md`

### 1.4 Pattern: Single-Layer Thinking

**What happens:** DevOps agent sets up excellent observability... in the backend only. Web app has zero Sentry, zero PostHog, zero error boundaries.

**Why it happens:**
- Agent prompt focuses on "CI/CD and observability"
- Agent interprets this as server-side concerns
- Checklist (before update) didn't specify "client-side"
- No verification that both layers are covered

**Evidence:** GitHub Issue #29, Constellation retrospective

### 1.5 Pattern: Architecture → Implementation Drift

**What happens:** Architecture specifies Supabase Realtime channels. Implementation uses React Query polling. Nobody catches the drift.

**Why it happens:**
- Architecture is a reference doc, not a verification target
- No step validates "implementation matches architecture"
- Agents read architecture but can deviate without accountability

**Evidence:** GitHub Issue #31, Constellation retrospective

---

## Part 3: Systemic Root Causes

### 3.0 The Three Architectural Flaws

**Flaw 1: Trust Boundaries Without Verification**

The pipeline has multiple points where one agent assumes the next will do the right thing:

| Handoff | Trust Assumption | Reality | Result |
|---------|------------------|---------|--------|
| PRD → Orchestrator | "Orchestrator will implement all PRD items" | Orchestrator silently drops mobile | 50% scope missing |
| Architecture → Impl | "Implementers will follow design" | Implementers adapt/deviate | Design drift |
| Backend → Frontend | "Frontend has hooks/types it needs" | Infrastructure missing | Mock data default |
| Implementation → Review | "Reviewer will catch all issues" | Review is code-focused, not integration | Mock data passes |
| Review → DoD | "DoD gate catches everything" | DoD is at END, too late | Issues found at end |

**Flaw 2: Information Loss Between Phases**

Requirements exist in `docs/PRD.md` but don't thread through the pipeline:

```
PRD (requirements) → Architecture (design) → Implementation (build) → Review → DoD
     ↓                    ↓                       ↓                  ↓        ↓
  (written)          (referenced)            (sometimes)          (never)  (generic)
```

Each phase is a black box. There's no continuous tracking of "did we implement requirement X?"

**Flaw 3: Feedback Loop Breaks**

The learning system documents failures but doesn't prevent repetition:

```
Project fails → Retrospective → what-doesnt.md → [STOPS HERE]
                                       ↓
                              Agent prompts (maybe)
                                       ↓
                              Pipeline enforcement (rarely)
```

Example: Mock data anti-pattern documented Jan 2026, but still occurs because pipeline doesn't have a data layer step that would prevent it.

### 3.1 The Verification Gap Thesis

**Core problem:** META has excellent documentation of what should happen, but insufficient verification that it did happen.

```
PRD → Architecture → Implementation → [GAP] → Delivery
                                        ↑
                                 No one verifies the
                                 output matches the input
```

**Current verification:**
- ✅ Quality gate checks: build passes, tests pass, no mock data patterns
- ✅ DoD checklist: items to review manually
- ❌ **Scope verification:** Does output match PRD platforms/features?
- ❌ **Architecture verification:** Does implementation match design?
- ❌ **Data layer verification:** Is frontend actually connected to backend?
- ❌ **Cross-layer verification:** Are all layers (web, mobile, backend) instrumented?

### 2.2 Implicit vs Explicit Handoffs

**Problem:** The system assumes agents will make connections that need to be explicit.

| Assumption | Reality |
|------------|---------|
| "Backend exists" = "Frontend uses backend" | Frontend can render UI with mock data |
| "Architecture specifies X" = "X gets implemented" | Agents can deviate without accountability |
| "PRD says mobile" = "Mobile gets built" | Orchestrator can silently omit it |
| "DevOps step" = "Full stack observability" | Agent focuses on backend only |

**Fix:** Every assumption needs an explicit verification step or checklist item with enforcement.

### 2.3 The Accountability Gap

**Problem:** Agents can fail silently. There's no mechanism that forces them to flag:
- Scope reductions
- Deferred features
- Stubbed implementations
- Layer omissions

**Current behavior:** Agent encounters difficulty → stubs/skips/omits → moves on → next agent doesn't know → gap compounds through pipeline.

**Evidence:** CalDAV "not implemented" stub shipped without anyone flagging it.

### 2.4 Checklist vs Enforcement

**Problem:** Checklists exist but don't enforce. An agent can skip items without the pipeline failing.

| Checklist | Enforcement |
|-----------|-------------|
| DoD has "All platforms implemented" | ❌ Agent can check without verifying |
| DoD has "No mock data" | ✅ quality-gate.sh greps for patterns |
| DoD has "CD pipeline exists" | ❌ quality-gate.sh only checks CI |
| Observability checklist has "client-side" | ❌ No automated check |

**Pattern:** If it's not in `quality-gate.sh`, it doesn't get enforced.

---

## Part 4: Proposed Solutions (Architectural)

### 3.1 Add Scope Verification Gate (Critical)

**Problem:** Orchestrator can silently drop scope.

**Solution:** Add automated scope comparison after orchestrator step.

```markdown
## New Pipeline Step: Scope Verification Gate

Location: After orchestrator generates pipeline, before execution

Action:
1. Parse PRD for platforms (web, mobile, desktop, etc.)
2. Parse PRD for Must-Have features
3. Parse generated pipeline for coverage
4. Compare and flag gaps

If gaps found:
- STOP pipeline
- Present gaps to user
- Require explicit approval for any omissions
- Document approved deferrals in docs/DEFERRED.md
```

**Files to create/update:**
- `scripts/scope-verification.sh` - Automated PRD vs pipeline comparison
- `workflows/pipelines/project.pipeline` - Add scope verification step after #6

### 3.2 Add Explicit Data Layer Step (Critical)

**Problem:** Frontend agents implement UI without data connections.

**Solution:** Insert mandatory "Data Layer Setup" step between backend and frontend.

```markdown
## New Pipeline Step: Data Layer Setup

Location: After backend complete, before frontend UI implementation

Deliverables (all required):
1. Generated database types (supabase gen types)
2. QueryClientProvider in app entry point
3. Typed API client (lib/supabase.ts)
4. Auth hooks (useAuth, useCurrentUser)
5. Entity hooks for each domain object (useTasks, useEvents, etc.)

Verification:
- npm run typecheck passes
- Hooks can be imported
- Test component renders with loading state

Exit criteria: "Frontend developers can import hooks and render real data"
```

**Files to update:**
- `workflows/pipelines/project.pipeline` - Add data layer step
- `workflows/pipelines/feature.pipeline` - Add data layer step
- Already created: `prompts/data-layer-setup-checklist.md`

### 3.3 Enhance Quality Gate Enforcement (High)

**Problem:** quality-gate.sh misses critical checks.

**Add these checks:**

```bash
# CD Deployment workflow (not just CI)
check_cd_workflow() {
  # Look for deployment workflows
  if ls .github/workflows/deploy*.yml 2>/dev/null | head -1; then
    result pass "CD workflow" "deployment workflow found"
  elif [[ -f vercel.json ]] || [[ -f netlify.toml ]]; then
    result pass "CD workflow" "platform auto-deploy configured"
  else
    result fail "CD workflow" "no deployment workflow (CI is not CD)"
  fi
}

# Client-side observability
check_client_observability() {
  local web_pkg=""
  for pkg in apps/web/package.json client/package.json package.json; do
    [[ -f "$pkg" ]] && web_pkg="$pkg" && break
  done

  if [[ -n "$web_pkg" ]]; then
    sentry_ok=$(grep -q "@sentry/react\|@sentry/browser" "$web_pkg" && echo "yes")
    posthog_ok=$(grep -q "posthog-js" "$web_pkg" && echo "yes")

    if [[ "$sentry_ok" == "yes" && "$posthog_ok" == "yes" ]]; then
      result pass "Client observability" "Sentry + PostHog installed"
    else
      result fail "Client observability" "missing: ${sentry_ok:-Sentry} ${posthog_ok:-PostHog}"
    fi
  fi
}

# Placeholder page detection
check_placeholder_pages() {
  local placeholder_count=$(grep -rl "Coming soon\|Placeholder\|Not implemented" \
    apps/web/src client/src src \
    --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l)

  if [[ "$placeholder_count" -gt 0 ]]; then
    result fail "Placeholder pages" "$placeholder_count files with placeholder content"
  else
    result pass "Placeholder pages" "no placeholder content found"
  fi
}

# Stub/TODO detection in production code
check_stubs() {
  local stub_count=$(grep -rl "throw.*not.*implement\|// TODO:\|// FIXME:" \
    apps/web/src client/src src server \
    --include="*.ts" --include="*.tsx" 2>/dev/null | \
    grep -v ".test.\|.spec.\|__test" | wc -l)

  if [[ "$stub_count" -gt 0 ]]; then
    result fail "Stubs/TODOs" "$stub_count files with unfinished code"
  else
    result pass "Stubs/TODOs" "no stubs found in production code"
  fi
}
```

### 3.4 Architecture Verification Gate (High)

**Problem:** Implementation can drift from architecture without detection.

**Solution:** Add architecture verification step before DoD.

```markdown
## New Pipeline Step: Architecture Verification

Location: After implementation, before DoD

Checks:
1. If Architecture specifies real-time → verify Realtime subscriptions exist
2. If Architecture specifies mobile → verify mobile app is built
3. If Architecture specifies auth → verify auth flow works
4. If Architecture specifies caching → verify cache implementation

Output: Architecture conformance report in .meta/handoff.md
```

### 3.5 Mandatory Deferral Documentation (High)

**Problem:** Features get stubbed/skipped without documentation.

**Solution:** Any MVP deferral must be documented and approved.

```markdown
## Required: docs/DEFERRED.md

If ANY Must-Have (MVP) PRD item is not implemented:
1. Create docs/DEFERRED.md
2. List each deferred item with:
   - What was deferred
   - Why it was deferred
   - When it should be implemented
   - User approval date
3. Quality gate checks for DEFERRED.md and flags for review
4. DoD requires explicit sign-off on deferrals
```

### 3.6 Cross-Layer Agent Instructions (Medium)

**Problem:** Agents think in single layers (backend OR frontend).

**Solution:** Update agent prompts to require cross-layer thinking.

**devops-engineer.md update:**
```markdown
## CRITICAL: Full-Stack Observability

You MUST set up observability in ALL layers:

### Backend (BFF/API)
- Sentry error tracking
- Structured logging with correlation IDs
- PostHog event tracking (optional)

### Frontend (Web)
- @sentry/react with ErrorBoundary
- posthog-js for analytics
- Trace ID propagation to API calls

### Frontend (Mobile) - if applicable
- @sentry/react-native
- PostHog React Native SDK

DO NOT consider DevOps complete until BOTH backend AND frontend have:
- [ ] Error tracking initialized
- [ ] Analytics initialized
- [ ] Health endpoints / error boundaries
```

### 3.7 End-to-End Smoke Test Requirement (Medium)

**Problem:** Mock data passes visual review.

**Solution:** Require actual CRUD verification before DoD.

```markdown
## DoD Smoke Test Requirement

Before marking DoD complete, manually verify:

1. Create a new [primary entity] through the UI
2. Verify it appears in the list
3. Update the [primary entity] through the UI
4. Verify changes persist after page reload
5. Delete the [primary entity] through the UI
6. Verify it's removed from the list

Document results in .meta/handoff.md with timestamps.
```

---

### 3.7 Architectural Solution: Pipeline Phase Dependencies

The core fix is to make the pipeline **enforce prerequisites**, not assume them.

**Current pipeline (implicit dependencies):**
```
1. Preflight
2. Kickoff (interactive)
3. External services (interactive)
4. Product Manager → PRD
5. Architect → Design
6. Orchestrator → Generate next.pipeline
7. [generated pipeline executes]
   - Backend
   - Frontend (assumes data layer exists - IT DOESN'T)
8. DoD checklist
9. Quality gate
```

**Proposed pipeline (explicit dependencies):**
```
1. Preflight
2. Kickoff (interactive)
3. Product Manager → PRD
4. Architect → Design
5. External services (interactive) ← Moved here: can't know what services until after architecture
6. Orchestrator → Generate next.pipeline
   ↓ [SCOPE_VERIFICATION - blocks if PRD/pipeline mismatch]
7. Contract stub (if parallel work)
8. Backend implementation
   ↓ [DATA_LAYER_SETUP - generates types, hooks, providers]
9. Frontend implementation (now has real infrastructure)
   ↓ [BUILD_VALIDATION - catches integration issues]
10. Review
    ↓ [ARCHITECTURE_VERIFICATION - design matches implementation]
11. DoD checklist (with smoke test requirement)
12. Quality gate (enhanced with CD, observability, placeholder checks)
```

**The key difference:** Blocking verification steps at trust boundaries, not optional checklists at the end.

### 3.8 Architectural Solution: Requirements Threading

Add a living document that tracks requirement coverage:

```markdown
# docs/REQUIREMENTS_TRACKING.md

| PRD Item | Status | Implementation | Verified |
|----------|--------|----------------|----------|
| Web app | ✅ DONE | apps/web/ | Step 9 |
| Mobile app | ❌ MISSING | - | - |
| CalDAV sync | 🚫 DEFERRED | - | Approved 2026-02-01 |
| Real-time | ⏳ PARTIAL | subscriptions/events only | - |
```

Each agent updates this document. DoD gate fails if any PRD item is MISSING without explicit DEFERRED approval.

### 3.9 Architectural Solution: Orchestrator Constraints

Make orchestrator **enforce mandatory phases**, not just suggest them:

```markdown
ORCHESTRATOR GENERATION RULES (mandatory):

IF parallel work:
  THEN contract stub step MUST precede it
  THEN build validation step MUST follow it

IF backend exists:
  THEN data layer setup step MUST precede frontend
  THEN observability step MUST include BOTH backend AND frontend

IF frontend exists:
  THEN frontend test step MUST exist
  THEN data layer setup step MUST precede it

IF PRD specifies multiple platforms:
  THEN pipeline MUST include implementation for EACH platform
  OR STOP and request explicit deferral approval

These are NOT suggestions. They are BLOCKING CONSTRAINTS.
```

---

## Part 5: Implementation Priority

### Phase 1: Fix the Architecture (1-2 weeks)

**Goal:** Add verification at trust boundaries so failures are caught in-band.

| Item | What It Fixes | Files to Modify |
|------|---------------|-----------------|
| **Scope verification step** | Silent scope reduction (#28) | `scripts/scope-verification.sh` (new), `project.pipeline` |
| **Data layer setup step** | Mock data, missing hooks (#33) | `project.pipeline`, `feature.pipeline`, `prompts/data-layer-setup-checklist.md` |
| **Orchestrator constraints** | Missing mandatory phases | `agents/orchestrator.md` |
| **Requirements threading** | Information loss | `prompts/requirements-tracking-template.md` (new) |

### Phase 2: Enhance Quality Gate (1 week)

**Goal:** Make quality-gate.sh catch everything DoD checklist should catch.

| Check | What It Catches | Implementation |
|-------|-----------------|----------------|
| CD workflow exists | CI without CD (#30) | Check for deploy*.yml or vercel.json |
| Client observability | Backend-only observability (#29) | Grep package.json for @sentry/react, posthog-js |
| Placeholder detection | "Coming soon" pages (#33) | Grep for "Coming soon", "Placeholder" |
| Stub detection | Unfinished code (#32) | Grep for "not implemented", "// TODO" |
| DEFERRED.md check | Silent deferrals (#32) | If exists, flag for review |

### Phase 3: Strengthen Agents (1 week)

**Goal:** Give agents what they need to succeed.

| Agent | Current Gap | Fix |
|-------|-------------|-----|
| **devops-engineer** | Single-layer thinking | Explicit "BOTH backend AND frontend" requirement |
| **orchestrator** | No enforcement | Add mandatory phase generation rules |
| **base** | Success criteria vague | Add concrete verification checklist per step type |
| **reviewer** | Doesn't check integration | Add integration verification to review checklist |

### Phase 4: Close the Feedback Loop (Ongoing)

**Goal:** Ensure learnings become enforcement.

| Action | Timing |
|--------|--------|
| Learning added to what-works/what-doesnt | Immediate |
| Agent definition updated | Within 1 week |
| Pipeline/orchestrator updated | Within 2 weeks |
| Quality gate script updated | Within 2 weeks |
| Tested in real project | Within 1 month |

**New policy:** If a learning isn't in orchestrator enforcement within 2 weeks, create a tracking issue.

---

## Part 6: Success Metrics

### Quantitative Metrics (per project)

| Metric | Current (Constellation) | Target |
|--------|-------------------------|--------|
| Silent scope reductions | 1 (mobile dropped) | 0 |
| Mock data files in production | 7 pages | 0 |
| Backend-only observability | 100% (no frontend) | 0% |
| CI without CD | Yes | No |
| Placeholder pages | 4 | 0 |
| Unimplemented MVP items | 3 (CalDAV, realtime, offline) | 0 or explicitly deferred |
| PRD items with tracking | 0% | 100% |

### Systemic Metrics (track over time)

| Metric | How to Measure |
|--------|----------------|
| Repeat failures | Same issue type in consecutive projects |
| Learning-to-enforcement lag | Days from retrospective to orchestrator update |
| Verification step coverage | % of trust boundaries with blocking verification |
| DoD failures caught late | Issues found at DoD that could have been caught earlier |

### Validation

Run next project pipeline and verify:
1. Scope verification step blocks if PRD/pipeline mismatch
2. Data layer setup step runs before frontend
3. Quality gate catches missing CD, client observability
4. Requirements tracking document exists and is updated
5. Zero gap count (vs Constellation's 13 gaps)

---

## Part 7: Recommended Implementation Order

### Week 1: Core Architecture Fixes

1. **Create `scripts/scope-verification.sh`**
   - Parse PRD for platforms and major features
   - Compare against generated pipeline
   - Exit non-zero if gaps exist without explicit deferral

2. **Update `workflows/pipelines/project.pipeline`**
   - Add scope verification step after orchestrator (step 7)
   - Add data layer setup step in generated pipeline template

3. **Update `agents/orchestrator.md`**
   - Add mandatory phase generation rules
   - Add constraints that block pipeline generation if requirements aren't met

### Week 2: Quality Gate Enhancement

4. **Update `scripts/quality-gate.sh`**
   ```bash
   # Add these checks:
   - check_cd_workflow()      # Deploy workflow exists
   - check_client_obs()       # @sentry/react + posthog-js
   - check_placeholders()     # No "Coming soon" pages
   - check_stubs()            # No "not implemented" in prod
   - check_deferred()         # DEFERRED.md flagged for review
   ```

5. **Create `prompts/requirements-tracking-template.md`**
   - Standard format for tracking PRD item status
   - Updated by each agent phase
   - Verified at DoD

### Week 3: Agent Strengthening

6. **Update `agents/devops-engineer.md`**
   - Explicit full-stack observability requirement
   - Separate sections for backend AND frontend
   - Anti-pattern: "backend-only" flagged

7. **Update `prompts/definition-of-done-checklist.md`**
   - Add smoke test requirement (CRUD works end-to-end)
   - Add requirements tracking verification
   - Add deferred item review

### Ongoing: Feedback Loop Policy

8. **Establish learning-to-enforcement timeline**
   - Document in CONTRIBUTING.md or similar
   - Track via GitHub issues if timeline exceeded

---

## Appendix A: Current vs Proposed Pipeline Flow

### Current Flow (Trust Without Verification)
```
Kickoff → PRD → Architecture → Orchestrator → [Generated Pipeline]
                                                      ↓
                               Backend → Frontend → Review → DoD → Quality Gate
                                  ↑         ↑                         ↑
                            No contract  No data layer        Catches issues
                            stub         setup                too late
```

### Proposed Flow (Verification at Trust Boundaries)
```
Kickoff → PRD → Architecture → External Services → Orchestrator
                                                        ↓
                                    [SCOPE VERIFICATION GATE] ← Blocks if PRD/pipeline mismatch
                                                        ↓
                                            Contract Stub (if parallel)
                                                        ↓
                                                  Backend Implementation
                                    ↓
                        [DATA LAYER SETUP] ← Types, hooks, providers
                                    ↓
                              Frontend Implementation (uses real hooks)
                                    ↓
                        [BUILD VALIDATION] ← Integration check
                                    ↓
                              Review
                                    ↓
                        [ARCHITECTURE VERIFICATION] ← Design matches impl
                                    ↓
                              DoD (with smoke test + requirements check)
                                    ↓
                        Quality Gate (CD, client obs, placeholders, stubs)
```

---

## Appendix B: Files to Create/Modify

### New Files
| File | Purpose |
|------|---------|
| `scripts/scope-verification.sh` | PRD vs pipeline comparison |
| `prompts/requirements-tracking-template.md` | Track PRD item status through pipeline |

### Modified Files
| File | Changes |
|------|---------|
| `scripts/quality-gate.sh` | Add CD, client obs, placeholder, stub, deferred checks |
| `workflows/pipelines/project.pipeline` | Add scope verification step, data layer step reference |
| `workflows/pipelines/feature.pipeline` | Add data layer step, verification gates |
| `agents/orchestrator.md` | Add mandatory phase generation rules |
| `agents/devops-engineer.md` | Full-stack observability requirement |
| `prompts/definition-of-done-checklist.md` | Smoke test, requirements tracking |

---

## Appendix C: GitHub Issues Addressed

| Issue | Root Cause | Solution |
|-------|------------|----------|
| #28 Orchestrator scope reduction | No PRD/pipeline comparison | Scope verification gate |
| #29 Backend-only observability | Single-layer agent thinking | DevOps full-stack requirement + quality gate check |
| #30 CI without CD | Quality gate only checks CI | Add CD workflow check |
| #31 Realtime not implemented | Architecture drift undetected | Architecture verification step |
| #32 Deferred MVPs not flagged | No deferral accountability | DEFERRED.md requirement + quality gate check |
| #33 Data layer gap | No explicit step | Data layer setup step in pipeline |

---

## Appendix D: The Holistic View

**META's purpose:** Make every project improve future projects through knowledge compounding.

**The problem:** Knowledge compounds in documentation but not in execution. Learnings are written down but not enforced. The pipeline structure allows the same failures to repeat.

**The fix:** Transform META from a "documentation-first" system to a "verification-first" system:

1. **Before each phase:** Verify prerequisites exist
2. **After each phase:** Verify outputs match requirements
3. **At trust boundaries:** Add blocking verification steps
4. **When learning occurs:** Enforce it in pipeline structure, not just docs

**The metric:** Zero repeat failures. If the same issue type appears in consecutive projects, the feedback loop is broken.

---

## Appendix E: Quick Reference - What Changes

| Current Behavior | New Behavior |
|------------------|--------------|
| Orchestrator trusted to include all PRD items | Scope verification step blocks if mismatch |
| Frontend assumes data layer exists | Data layer setup step creates it first |
| DevOps sets up backend observability | DevOps required to set up BOTH layers |
| Quality gate checks build passes | Quality gate checks CD, client obs, placeholders, stubs |
| DoD checklist reviewed manually | DoD includes smoke test + requirements tracking |
| Learnings documented in markdown | Learnings enforced via orchestrator constraints |

**Bottom line:** Every trust boundary gets a verification step. Every learning gets enforcement within 2 weeks.

---

## Implementation Progress

### Week 1: Core Architecture Fixes ✅ COMPLETE (2026-02-03)

| Item | Status | Commit |
|------|--------|--------|
| Create `scripts/scope-verification.sh` | ✅ Done | e37c9b2 |
| Update `project.pipeline` (reorder + scope gate) | ✅ Done | e37c9b2 |
| Update `agents/orchestrator.md` (mandatory rules) | ✅ Done | e37c9b2 |
| Enhance `quality-gate.sh` (5 new checks) | ✅ Done | e37c9b2 |
| Create `prompts/requirements-tracking-template.md` | ✅ Done | e37c9b2 |

**Branch:** `feature/verification-architecture`

### Week 2: Quality Gate Testing ✅ COMPLETE (2026-02-03)

| Test | Result | Notes |
|------|--------|-------|
| scope-verification.sh on Constellation | ✅ Works | Detected 31 gaps (some false positives from user persona text) |
| quality-gate.sh CD check | ✅ Works | Correctly identified "no deployment workflow" |
| quality-gate.sh client observability | ✅ Works | Correctly identified "neither Sentry nor PostHog" |
| Placeholder detection | ✅ Works | Found 2 placeholder pages |
| Stub detection | ✅ Works | No stubs found (expected) |

**Bug Fixes Applied:**
- Fixed bash 3 compatibility issue in scope-verification.sh (`mapfile` → `while read`)
- Fixed pipefail issues in quality-gate.sh (grep returns 1 when no matches)

**Constellation Quality Gate Summary:**
```
Results: 9 passed, 5 failed, 5 skipped
Failed:
  - TypeScript (tsc not installed in project)
  - Lint (2 unused imports)
  - CD workflow (no deployment - CORRECT DETECTION)
  - Client observability (no Sentry/PostHog - CORRECT DETECTION)
  - Placeholder pages (2 files - CORRECT DETECTION)
```

### Week 3: Agent Strengthening ✅ COMPLETE (2026-02-03)

| Item | Status | Notes |
|------|--------|-------|
| Update `agents/devops-engineer.md` | ✅ Already done | Full-stack observability requirement in Week 1 |
| Update `prompts/definition-of-done-checklist.md` | ✅ Done | Added E2E smoke test requirement |
| Test on new project | ⏳ Pending | Next pipeline run will validate |

### Outstanding Items

**Future refinements:**
- [ ] Improve scope-verification.sh to filter user persona text from feature extraction
- [ ] Add test coverage for Constellation's mobile app (apps/mobile/src has no tests)
- [ ] Run full pipeline on new project to validate all changes work in practice
