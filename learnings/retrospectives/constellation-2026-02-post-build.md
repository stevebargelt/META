# Post-Build Retrospective: Constellation (Round 2)

**Date:** 2026-02-04
**Context:** After completing wave-based parallelization implementation
**Type:** Interactive assessment of build quality

---

## Executive Summary

Following the completion of the constellation-2 build with the new wave-based parallelization system, this retrospective identifies gaps in user-facing functionality and operational readiness that weren't caught by the DoD checklist.

**Key Finding:** The system is technically complete but has critical UX gaps that make it unusable for end users.

---

## User-Reported Issues

### 1. 🚨 CRITICAL: No Sign-In UI

**Issue:** Web app shows "Please sign in to continue." with no way to actually sign in.

**What We Found:**
```tsx
// apps/web/src/App.tsx (lines 22-26)
{user ? (
  <div>
    <p>Welcome, {user.email}!</p>
    <button onClick={signOut}>Sign Out</button>
  </div>
) : (
  <div>
    <p>Please sign in to continue.</p>
    // ⚠️ NO SIGN-IN BUTTON OR FORM
  </div>
)}
```

**Root Cause:**
- `AuthContext.tsx` provides `signIn` and `signUp` functions
- UI never calls these functions
- No sign-in form component created
- App is a dead-end for unauthenticated users

**Impact:**
- **Severity:** BLOCKER
- App is completely unusable without manual database/auth manipulation
- New users cannot onboard themselves
- Existing users cannot log back in after session expires

**How This Passed DoD:**
- DoD checks for auth *implementation* (context, hooks) ✅
- DoD doesn't check for auth *UI/UX* ❌
- Testing likely done with pre-authenticated session

---

### 2. 📱 MEDIUM: Missing Mobile App Documentation

**Issue:** README.md doesn't explain how to start or run the mobile app.

**What We Found:**
```markdown
## Quick Start
# Start development
pnpm dev  # Starts web only
```

**Missing Information:**
- How to run mobile app (`pnpm dev:mobile`)
- Prerequisites for mobile (Expo CLI, iOS Simulator, Android Studio)
- Expected behavior (what should happen when mobile starts)
- Current mobile app status (placeholder vs working)

**Root Cause:**
- README focused on project structure, not usage
- Mobile app is placeholder (`export const placeholder = true`)
- Documentation reflects planning phase, not current state

**Impact:**
- **Severity:** MEDIUM
- New developers can't run mobile app
- Confusion about whether mobile is implemented
- Wasted time troubleshooting expected functionality

---

### 3. ✅ RESOLVED: Observability & Traceability

**User Request:** Check for observability and traceability.

**What We Found:**

#### ✅ Observability Setup (EXCELLENT)

**Web App:**
```typescript
// apps/web/src/main.tsx (lines 23-47)
Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  environment: import.meta.env.MODE,
  integrations: [
    new Sentry.BrowserTracing({
      tracePropagationTargets: ['localhost', /^https:\/\/.*\.supabase\.co/],
    }),
    new Sentry.Replay({
      maskAllText: false,
      blockAllMedia: false,
    }),
  ],
  tracesSampleRate: 1.0,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  beforeSend(event) {
    // Strip sensitive headers
    if (event.request?.headers) {
      delete event.request.headers['Authorization'];
      delete event.request.headers['Cookie'];
    }
    return event;
  },
});
```

**Mobile App:**
```typescript
// apps/mobile/src/App.tsx (lines 10-26)
Sentry.init({
  dsn: sentryDsn,
  environment: __DEV__ ? 'development' : 'production',
  tracesSampleRate: 1.0,
  beforeSend(event) {
    // Strip sensitive headers
    if (event.request?.headers) {
      delete event.request.headers['Authorization'];
      delete event.request.headers['Cookie'];
    }
    return event;
  },
});
```

**PostHog Analytics:**
- Web: Full autocapture, pageview tracking, person profiles
- Mobile: Basic initialization with API key

**Error Handling:**
- Global React Query mutation error handler captures exceptions
- Sentry ErrorBoundary wraps entire web app
- Mobile app wrapped with `Sentry.wrap(App)`

#### ✅ Traceability (GOOD)

**Sentry Breadcrumbs:**
```typescript
// apps/web/src/contexts/AuthContext.tsx
Sentry.addBreadcrumb({
  category: 'auth',
  message: 'Sign in attempt',
  level: 'info',
});
```

**User Context Tracking:**
```typescript
// Auth changes update Sentry user
Sentry.setUser({
  id: session.user.id,
  email: session.user.email,
});
```

**Console.log Usage:**
- 29 occurrences across 13 files
- Mostly in development/debug contexts
- 1 intentional warning: PostHog API key not found

**Verdict:**
- **Observability: A+** (Comprehensive setup, security-conscious)
- **Traceability: A** (Good breadcrumbs, user tracking)
- **Improvement area:** Could add more breadcrumbs for critical user flows (create event, invite member, etc.)

---

## Gap Analysis: What Should Have Been Caught

### DoD Checklist Gaps

| What DoD Checks | What DoD Misses | Impact |
|----------------|-----------------|---------|
| Auth context exists | Auth UI/UX exists | User can't log in |
| Sentry installed | Sign-in form rendered | Unusable app |
| README has Quick Start | README has complete usage docs | Developer friction |
| Tests written | App manually tested end-to-end | UX bugs escape |

### Root Cause: Implementation vs Integration Gap

**Pattern observed:**
1. Infrastructure implemented correctly (auth, observability, data layer)
2. Business logic implemented correctly (hooks, API calls, types)
3. **UI never connects to the infrastructure** (missing forms, buttons, flows)

This is the **"last mile" problem** - everything works in isolation, but the user-facing entry points don't exist.

---

## Proposed DoD Enhancements

### Add "User Journey Validation" Section

```markdown
## User Journey Validation

For each primary user flow, verify end-to-end completion:

### Authentication Flow
- [ ] Unauthenticated user sees sign-in form
- [ ] User can enter email/password and submit
- [ ] User can sign up with new account
- [ ] User can reset forgotten password
- [ ] Auth errors display clearly to user

### Core Feature Flows
- [ ] User can create [primary entity]
- [ ] User can view list of [entities]
- [ ] User can edit existing [entity]
- [ ] User can delete [entity]
- [ ] Changes persist after page refresh

### Mobile-Specific (if applicable)
- [ ] Mobile app launches without errors
- [ ] Mobile README documents startup process
- [ ] Mobile has same features as web (or documents differences)
```

### Add "README Completeness" Section

```markdown
## README Completeness

- [ ] All apps in monorepo have startup instructions
- [ ] Prerequisites listed (Node version, package manager, CLI tools)
- [ ] Environment setup documented (copying .env, getting API keys)
- [ ] Expected behavior described ("you should see X")
- [ ] Troubleshooting section for common issues
- [ ] Link to deployment/preview URL (if deployed)
```

---

## Comparison: This Retro vs Previous Retro (2026-02-03)

### What Improved ✅

| Issue (Feb 3) | Status (Feb 4) |
|---------------|----------------|
| Mock data in production | ✅ All real API integration |
| No observability in web app | ✅ Full Sentry + PostHog setup |
| No data layer | ✅ React Query + hooks working |
| Quality gate didn't catch mocks | ✅ No mocks found |

### What Persisted ❌

| Issue (Feb 3) | Status (Feb 4) |
|---------------|----------------|
| Mobile app placeholder | ❌ Still placeholder (`placeholder = true`) |
| DoD didn't catch UX gaps | ❌ Auth UI missing (new manifestation) |
| README incomplete | ❌ Mobile usage not documented |

### New Issues 🆕

| Issue | Type |
|-------|------|
| No sign-in UI | UX blocker (high severity) |
| Auth infrastructure unused | Integration gap |

---

## Recommendations

### Immediate Actions (Blockers)

1. **Create Sign-In UI Component**
   - Build `SignInForm` component with email/password fields
   - Add "Sign Up" link/tab
   - Add "Forgot Password" link
   - Render in `App.tsx` when `!user`
   - Estimated: 2-4 hours

2. **Update README with Mobile Instructions**
   - Document `pnpm dev:mobile` command
   - List prerequisites (Expo, simulators)
   - Note current status (placeholder)
   - Estimated: 30 minutes

### Short-Term Improvements

3. **Add Manual Testing Checklist to DoD**
   - Require testing of auth flow before marking complete
   - Require running each app (web + mobile) and clicking through
   - Estimated: 1 hour to create, 15 min per project

4. **Enhance Quality Gate Script**
   - Add check: "Does unauthenticated user see auth UI?"
   - Add check: "Does README document all apps in monorepo?"
   - Estimated: 2-3 hours

### Long-Term Enhancements

5. **Create "Last Mile" Checklist Template**
   - User journey validation per feature
   - Entry point verification (can user access this?)
   - Error state coverage (what if X fails?)
   - Estimated: 4-6 hours

6. **Add Breadcrumbs to Critical Flows**
   - Calendar: event creation, editing, deletion
   - Meals: meal planning, recipe attachment
   - Tasks: task assignment, completion
   - Constellations: member invitation, permission changes
   - Estimated: 3-4 hours

---

## Learnings for META Framework

### New Anti-Pattern: "Invisible Infrastructure"

**Description:** Backend and infrastructure are fully implemented and working, but the user-facing UI never calls them.

**Examples:**
- Auth context provides `signIn()`, but no sign-in form exists
- API endpoints exist, but no buttons/forms to trigger them
- Mobile app setup complete, but no documentation to run it

**Detection:**
- Search codebase for exported functions that are never imported
- Check if README commands match package.json scripts
- Manually test: "Can a new user complete the primary flow?"

**Prevention:**
- Add "User Journey Validation" to DoD
- Require manual testing of unauthenticated flow
- Check for orphaned infrastructure (unused exports)

### Pattern: Observability as First-Class Citizen ✅

**What Worked:**
- Sentry + PostHog initialized in `main.tsx` immediately
- Breadcrumbs added to auth flows proactively
- Security considerations (strip auth headers) built-in
- Global error handlers catch mutation failures

**This is the correct approach.** Observability should be set up at app initialization, not bolted on later.

### Pattern: README as Living Document ⚠️

**Issue:** README reflects planning phase, not current state.

**Better approach:**
- Update README when app structure changes
- Document "how to run X" when X is built
- Add troubleshooting sections as issues arise
- Include "Current Status" section for incomplete features

---

## Metrics

### Time to Identify Issues
- **Sign-in UI gap:** 2 minutes (user opens app, sees dead-end)
- **Mobile docs gap:** 5 minutes (developer tries to run mobile, unsure how)
- **Observability check:** 15 minutes (grep + read source files)

### Estimated Fix Time
- **Sign-in UI:** 2-4 hours (component + form + validation + error states)
- **Mobile docs:** 30 minutes (update README with usage section)
- **DoD enhancement:** 1 hour (add user journey checklist)

**Total:** 3.5-5.5 hours to resolve all identified issues.

---

## Next Steps

### High Priority
- [ ] Create issue: "Add sign-in/sign-up UI to web app" (blocker)
- [ ] Update constellation-2 README with mobile app instructions
- [ ] Add "User Journey Validation" section to `prompts/definition-of-done-checklist.md`

### Medium Priority
- [ ] Update `learnings/what-doesnt.md` with "Invisible Infrastructure" anti-pattern
- [ ] Update `learnings/what-works.md` with observability setup pattern
- [ ] Add auth UI templates to `patterns/react/auth-ui.md`

### Low Priority
- [ ] Enhance quality gate to detect missing auth UI
- [ ] Create "Last Mile Checklist" template
- [ ] Add more Sentry breadcrumbs to critical user flows

---

## Questions for User

1. **Sign-In UI Priority:** Should we build a full sign-in/sign-up UI, or is there a temporary workaround (e.g., Supabase Auth UI component)?

2. **Mobile App Status:** Is the mobile app intentionally a placeholder, or should it be implemented? (Previous retro noted it was dropped from scope silently)

3. **Deployment:** Should we add deployment workflow now, or focus on local development experience first?

4. **Additional Flows to Test:** Besides auth, which user journeys are most critical to validate? (Calendar, Meals, Tasks, Constellations?)

---

## Status

**Build Quality:** 🟡 **YELLOW** (Technically sound, UX blockers present)

**Observability:** 🟢 **GREEN** (Excellent setup)

**Documentation:** 🟡 **YELLOW** (Incomplete for end-to-end usage)

**User Readiness:** 🔴 **RED** (Cannot onboard new users)

---

## Conclusion

This build represents a **significant improvement** over the 2026-02-03 iteration:
- Real API integration throughout
- Full observability instrumentation
- Clean data layer with React Query

However, it reveals a new class of issue: **the last mile gap**. Infrastructure is correct, but entry points are missing.

**Key takeaway:** A technically correct implementation isn't user-ready until someone can actually *use* it. DoD must validate user journeys, not just component existence.

---

**Next Review:** After sign-in UI is implemented and tested.
