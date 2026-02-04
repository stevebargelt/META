# Requirements Tracking Template

Track PRD requirements through the pipeline to ensure nothing gets lost.

## Purpose

This document threads requirements from PRD through implementation. Each agent phase updates it. DoD gate verifies all items are DONE or explicitly DEFERRED.

## How to Use

1. **Product Manager creates initial list** from PRD Must-Have items
2. **Each agent updates status** after their step completes
3. **DoD step verifies** no items are MISSING
4. **Quality gate checks** for DEFERRED.md if deferrals exist

## Template

Create this file as `docs/REQUIREMENTS_TRACKING.md` in your project:

```markdown
# Requirements Tracking

**Project:** [Project name]
**PRD:** docs/PRD.md
**Last Updated:** [Date]

## Platforms

| Platform | Status | Implementation | Verified Step |
|----------|--------|----------------|---------------|
| Web app | ✅ DONE | apps/web/ | Step 8 |
| Mobile app | 🚫 DEFERRED | - | - |

## Must-Have Features

| Feature | Status | Implementation | Verified Step |
|---------|--------|----------------|---------------|
| User authentication | ✅ DONE | hooks/useAuth.ts | Step 7 |
| Task CRUD | ✅ DONE | pages/Tasks.tsx + hooks/useTasks.ts | Step 8 |
| Calendar sync | ⏳ PARTIAL | CalendarPage.tsx (view only) | Step 8 |
| Real-time updates | ❌ MISSING | - | - |

## Status Legend

| Status | Meaning |
|--------|---------|
| ✅ DONE | Fully implemented and tested |
| ⏳ PARTIAL | Partially implemented, notes below |
| ❌ MISSING | Not implemented, blocks DoD |
| 🚫 DEFERRED | Explicitly deferred (see docs/DEFERRED.md) |

## Partial Implementation Notes

### Calendar sync
- View implemented, two-way sync deferred to Phase 2
- See docs/DEFERRED.md for justification

## Deferred Items

If any items are DEFERRED, they MUST be documented in `docs/DEFERRED.md` with:
- What was deferred
- Why it was deferred
- When it will be implemented
- User approval date

## Verification

At DoD step, verify:
- [ ] All platforms are DONE or DEFERRED (none MISSING)
- [ ] All Must-Have features are DONE or DEFERRED (none MISSING)
- [ ] All DEFERRED items have entries in docs/DEFERRED.md
- [ ] PARTIAL items have notes explaining what's missing
```

## Agent Responsibilities

### Product Manager (Step 3)
- Create initial `docs/REQUIREMENTS_TRACKING.md`
- List all platforms from PRD
- List all Must-Have features from PRD
- Set initial status to ❌ MISSING for all items

### Orchestrator (Step 6)
- Review tracking document
- Verify pipeline covers all items
- Update status to ⏳ PARTIAL for items with planned steps
- Flag any items without coverage

### Implementation Agents (various steps)
- Update status to ✅ DONE when feature is complete
- Add implementation path (file/component)
- Add step number for verification

### DoD Agent (final steps)
- Verify no items are ❌ MISSING
- Verify all 🚫 DEFERRED items have docs/DEFERRED.md entries
- Verify all ⏳ PARTIAL items have notes
- Include tracking summary in DoD report
