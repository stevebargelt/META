# Pre-Assessment: test-app-6 (Project & Task Manager)

**Date:** 2026-01-28
**Project:** test-app-6
**Type:** Pre-mortem / Planning Assessment
**Purpose:** Set expectations, hypotheses, and success criteria before running

---

## What We're Testing

### New META Features (First Real Test)

| Feature | Added | What to Watch |
|---------|-------|---------------|
| Split pane for interactive steps | Today | Does it stay visible? Does pane close cleanly on exit? |
| Gate prompt with log summary | Today | Are last 20 lines useful for approval decisions? |
| Build validation after parallel merge | Today | Does it catch integration issues early? |
| .gitignore quality gate | Today | Should pass (new-project.sh scaffolds it now) |
| Auto-retry | Yesterday | Still working? Any edge cases? |
| Auto-commit | Earlier | Clean commit history? |

### The Application

**Project & Task Manager** — More complex than test-app-5's Expense Tracker:

| Aspect | test-app-5 (Expense Tracker) | test-app-6 (Task Manager) |
|--------|------------------------------|---------------------------|
| Entities | 3 (expenses, categories, budgets) | 4+ (projects, tasks, subtasks, tags) |
| Relationships | Simple FK (expense→category) | Nested (task→subtask) + M:M (task↔tag) |
| Views | List + Dashboard | List + **Kanban** (drag-drop) |
| API complexity | Standard CRUD | CRUD + reordering + status transitions |

**Risk areas:**
1. **Kanban view** — Drag-and-drop is complex; may need react-beautiful-dnd or similar
2. **Subtasks** — Nested resources in API design
3. **Tags M:M** — Junction table, separate endpoints
4. **Task reordering** — Position/order field management

---

## Expected Pipeline Structure

Based on test-app-5 patterns, the orchestrator should generate something like:

```
Phase 1: Foundation
  1. Contract stub (OpenAPI) — all endpoints defined

Phase 2: Infrastructure (parallel)
  2. Database setup + migrations (projects, tasks, subtasks, tags, task_tags)
  3. Frontend scaffold (Vite/React/Tailwind/React Query)
  → BUILD VALIDATION (new)

Phase 3: Backend (parallel, 5 streams)
  4. Projects API (CRUD)
  5. Tasks API (CRUD + filtering + status)
  6. Subtasks API (nested under tasks)
  7. Tags API (CRUD + task association)
  8. Board API (positions, reorder, Kanban state)
  → BUILD VALIDATION (new)

Phase 4: Frontend (parallel, 4 streams)
  9. Project list/form
  10. Task list/form
  11. Kanban board
  12. Tag management
  → BUILD VALIDATION (new)

Phase 5: Polish & Quality
  13. Polish (error handling, loading states, observability)
  14. Testing (unit + integration)
  15. Review
  16. Documentation
  17. Definition of Done
  18. Final quality gate
```

**Estimated steps:** 18-20 (vs 16 for test-app-5)
**Estimated duration:** 90-120 min (vs 85 min for test-app-5)

---

## Hypotheses

### H1: Build Validation Catches Early Issues
**Prediction:** The new build validation steps after parallel merges will catch at least 1 integration issue (missing types, import errors, config mismatch) that would have reached the final DoD step in test-app-5.

**How to verify:** Check step logs for build validation steps. Did they fail and trigger fixes? Compare to test-app-5 where issues were found at step 15.

### H2: Split Pane Improves Interactive UX
**Prediction:** Seeing the control window during interactive steps 1-2 will make it clearer when the step is waiting vs. complete.

**How to verify:** Subjective assessment. Did you lose track of pipeline state? Did the pane close cleanly?

### H3: Gate Log Summary Speeds Approvals
**Prediction:** Seeing last 20 lines will let you approve/reject without opening the full log file in most cases.

**How to verify:** Track how many times you needed to read the full log vs. approving from summary.

### H4: More Parallel Streams = More Time Savings
**Prediction:** With 5 backend + 4 frontend parallel streams (vs 4+3 in test-app-5), we'll see proportionally better parallelization benefit.

**How to verify:** Compare actual parallel group durations to theoretical sequential time.

### H5: Kanban Complexity May Require Retry
**Prediction:** The Kanban view step has higher failure probability due to drag-drop complexity. May need retry or manual intervention.

**How to verify:** Did the Kanban step complete first try? What was the retry count?

---

## Success Criteria

### Must Pass
- [ ] All quality gate checks pass (git, README, .gitignore, tests, OpenAPI, observability)
- [ ] Build validation steps run after each parallel merge
- [ ] Split pane works for interactive steps
- [ ] Gate prompts show log summary
- [ ] Final app has working: project CRUD, task CRUD, subtasks, tags, Kanban view

### Should Pass
- [ ] No more than 2 retries total
- [ ] Duration under 120 minutes
- [ ] Test count ≥ 250
- [ ] At least 1 issue caught by build validation (not final gate)

### Nice to Have
- [ ] Kanban drag-drop works smoothly
- [ ] Duration under 100 minutes
- [ ] Zero manual interventions needed

---

## Comparison Metrics

| Metric | test-app-5 | test-app-6 Target | test-app-6 Actual |
|--------|------------|-------------------|-------------------|
| Total duration | 85 min | < 120 min | _TBD_ |
| Steps | 16 | 18-20 | _TBD_ |
| Parallel groups | 3 | 4-5 | _TBD_ |
| Max parallelism | 4 | 5 | _TBD_ |
| Tests | 315 | ≥ 250 | _TBD_ |
| Retries | 1 | ≤ 2 | _TBD_ |
| Issues at DoD | 3 | < 3 | _TBD_ |
| Issues at build validation | N/A | ≥ 1 | _TBD_ |

---

## Risk Mitigation

### If Kanban Step Fails
The drag-drop implementation is the highest risk. If it fails repeatedly:
1. Let auto-retry attempt (up to 3)
2. If still failing, consider simplifying to sortable list without drag-drop
3. Document in retrospective as pattern limitation

### If Build Validation Blocks Progress
The new validation steps might fail on legitimate work-in-progress (e.g., types not yet exported). If this causes friction:
1. Consider making validation a warning instead of blocker
2. Or add `--skip-validation` flag for development runs

### If Split Pane Causes Issues
If the split pane interferes with the pipeline:
1. Note the specific issue
2. Can revert to window-switch behavior via quick code change
3. Consider making it configurable

---

## Questions to Answer Post-Run

1. Did build validation catch issues early? What kind?
2. Was the split pane helpful or distracting?
3. Was the log summary sufficient for gate approvals?
4. How did the orchestrator handle the increased complexity?
5. Any new anti-patterns discovered?
6. What should we change before test-app-7?

---

## Command to Run

```bash
./scripts/new-project.sh test-app-6 \
  --task "Build a Project & Task Manager. Features: projects with names/descriptions, tasks with title/description/status/priority/due date, subtasks, tags, list and Kanban views. Node/Express backend, React frontend with Tailwind, SQLite database." \
  --tool claude \
  --unsafe \
  --auto-approve
```

---

*Fill in "test-app-6 Actual" column and answer questions after run completes.*
