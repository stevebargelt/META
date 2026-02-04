# Assessment: Per-Group Testing Parallelization

**Date:** 2026-02-04
**Status:** Proposal - Assessment Phase
**Author:** META Architecture Review
**Related:** Wave-Based Parallelization (implemented 2026-02-04)

---

## Executive Summary

**Current State:** Tests are embedded within parallel implementation steps, with sequential build validation and integration testing after groups complete.

**Proposal:** Add dedicated testing agents to each parallel group, enabling group-level testing to run concurrently with implementation, further reducing total pipeline time by 15-25%.

**Assessment:** ✅ **HIGH VALUE** - Significant time savings with clear implementation path and minimal risk.

---

## Problem Statement

### Current Testing Flow

```
Wave 1: backend (steps 2-3) → 40 min
  Step 2: Auth service (includes unit tests)
  Step 3: User service (includes unit tests)

Sequential validation → 10 min
  Step 4: Build validation (npm run build && npm test)

Wave 2: web-features + mobile-features (concurrent) → 40 min
  Steps 7-13: Web features (each includes unit tests)
  Steps 15-21: Mobile features (each includes unit tests)

Sequential validation → 10 min
  Step 14/22: Build validation after each group

Sequential integration testing → 50 min
  Step 23: Integration tests (cross-feature flows)
  Step 24: Frontend tests (Web config)
  Step 25: Frontend tests (Mobile config)

Total: 150 minutes
```

### Bottlenecks Identified

1. **Build validation is sequential** - Waits for all features to complete before validating
2. **Integration tests are sequential** - Runs after all features, not during
3. **Test setup is late-stage** - Vitest/Jest config happens at the end
4. **No incremental validation** - Can't catch issues until group fully completes

### Opportunity

**Your observation is correct:** Each parallel group could have its own testing agent running concurrently with feature implementation, providing:

- **Incremental validation** during group execution
- **Earlier failure detection** (catch issues in step 8, not step 23)
- **Parallel test execution** across groups
- **Reduced total pipeline time** by overlapping testing with implementation

---

## Proposed Architecture

### New Testing Model: Three-Tier Concurrent Testing

#### Tier 1: Within-Step Tests (Unchanged)
**Agent:** base
**Scope:** Feature-level unit tests
**Timing:** During implementation step

```
Step 7 | base | web-features | 35 | Implement features/calendar (UI, state, API, tests)
```

**Tests included:**
- Component unit tests (CalendarGrid, EventForm)
- Hook tests (useEvents, useCalendar)
- Utility function tests
- Basic integration tests within feature boundary

#### Tier 2: Group-Level Testing (NEW)
**Agent:** tester
**Scope:** Group-wide integration and validation
**Timing:** Concurrent with group execution

```
Step 7-13 | base | web-features | [implementation steps]
Step 14   | tester | web-features | 15 | Group validation: Build check, cross-feature integration tests, test coverage verification (runs while group executes)
```

**Tests included:**
- Build validation (npm run build && typecheck)
- Cross-feature integration within group (calendar ↔ tasks ↔ meals)
- Test coverage analysis (ensure minimum coverage %)
- Accessibility tests (a11y within web features)
- Performance tests (bundle size, render time)

**Execution:** Tester starts when group is 50% complete, runs in parallel with remaining features.

#### Tier 3: Final Integration Testing (Enhanced)
**Agent:** tester
**Scope:** Cross-group, full-stack integration
**Timing:** After all groups complete

```
Step 23 | tester | - | 30 | Cross-platform integration tests (web ↔ mobile real-time sync)
Step 24 | tester | - | 20 | E2E critical user flows (Playwright web, Detox mobile)
```

**Tests included:**
- Cross-platform sync verification (web create event → mobile sees it)
- Full user journeys (signup → invite → create constellation → plan meal)
- Edge cases (offline handling, conflict resolution)
- Load/stress tests (100 concurrent users)

---

## Detailed Design

### Parallel Group Structure (Before)

**Current:**
```
Steps 7-13: web-features (parallel group)
  Step 7  | base | web-features | 35 | Relationships (includes unit tests)
  Step 8  | base | web-features | 35 | Constellations (includes unit tests)
  Step 9  | base | web-features | 40 | Calendar (includes unit tests)
  Step 10 | base | web-features | 35 | Meals (includes unit tests)
  Step 11 | base | web-features | 35 | Tasks (includes unit tests)
  Step 12 | base | web-features | 35 | Recipes (includes unit tests)
  Step 13 | base | web-features | 30 | Permissions (includes unit tests)

Step 14: Build validation (sequential, AFTER group)
  Step 14 | base | - | 10 | npm run build && npm test
```

**Timeline:**
```
0-40 min: Steps 7-13 execute in parallel
40-50 min: Step 14 executes sequentially
Total: 50 minutes
```

### Parallel Group Structure (After - Proposed)

**Enhanced:**
```
Steps 7-13: web-features (parallel group - implementation)
  Step 7  | base   | web-features | 35 | Relationships (includes unit tests)
  Step 8  | base   | web-features | 35 | Constellations (includes unit tests)
  Step 9  | base   | web-features | 40 | Calendar (includes unit tests)
  Step 10 | base   | web-features | 35 | Meals (includes unit tests)
  Step 11 | base   | web-features | 35 | Tasks (includes unit tests)
  Step 12 | base   | web-features | 35 | Recipes (includes unit tests)
  Step 13 | base   | web-features | 30 | Permissions (includes unit tests)

Step 14: Group-level testing (NEW - runs IN PARALLEL with steps 7-13)
  Step 14 | tester | web-features | 15 | Group validation: incremental build checks, cross-feature integration, coverage analysis
```

**Timeline:**
```
0-20 min: Steps 7-10 start executing
20-40 min: Steps 11-13 continue + Step 14 (tester) STARTS
  - Tester runs build validation on completed features (7-10)
  - Tests cross-feature integration (relationships ↔ constellations ↔ calendar ↔ meals)
  - Runs coverage analysis
  - Provides feedback to remaining steps if issues found
35-40 min: Final features (12-13) complete
40 min: Tester completes final validation
Total: 40 minutes (10 min saved!)
```

**Key insight:** Tester step is PART OF the parallel group, not after it.

---

## Implementation Strategy

### Phase 1: Modify Pipeline Structure

**orchestrator.md enhancement:**

Add rule for group-level testing:

```markdown
### Rule: Group-Level Testing (New)

After creating a parallel group with 3+ features, add a group-level tester step:

**Pattern:**
```
# Web features group (7 features)
7-13  | base   | web-features | [implementation steps]
14    | tester | web-features | 15 | Group validation

# Mobile features group (7 features)
15-21 | base   | mobile-features | [implementation steps]
22    | tester | mobile-features | 15 | Group validation
```

**Tester responsibilities:**
1. Incremental build validation (npm run build as features complete)
2. Cross-feature integration tests (feature boundaries)
3. Test coverage verification (minimum % threshold)
4. Performance checks (bundle size, memory)

**Timing:** Tester starts when group is ~50% complete, runs concurrently.
```

### Phase 2: Wave Execution Enhancement

**Modify `execute_wave_concurrent()` in `/Users/stevebargelt/code/META/scripts/meta`:**

**Current logic:**
```bash
# Phase 1: Launch all steps in all groups
for group in $wave_groups; do
  for step in $group_steps; do
    if [[ "${WF_STEP_AGENT[$step]}" == "base" ]]; then
      step_launch(...)
    fi
  done
done

# Phase 2: Wait for all steps to complete
```

**Enhanced logic:**
```bash
# Phase 1: Launch all steps in all groups (including testers)
for group in $wave_groups; do
  for step in $group_steps; do
    local agent="${WF_STEP_AGENT[$step]}"

    if [[ "$agent" == "base" ]]; then
      # Launch immediately
      step_launch(...)
    elif [[ "$agent" == "tester" ]]; then
      # Launch tester after 50% of group completes
      launch_delayed_tester "$step" "$group" &
    fi
  done
done

# Phase 2: Wait for all steps (base + tester) to complete
```

**New function: `launch_delayed_tester()`**

```bash
launch_delayed_tester() {
  local step_num="$1"
  local group_name="$2"

  # Find base steps in this group
  local group_base_steps=()
  for ((i=1; i<=WF_STEP_COUNT; i++)); do
    if [[ "${WF_STEP_GROUP[$i]}" == "$group_name" && "${WF_STEP_AGENT[$i]}" == "base" ]]; then
      group_base_steps+=("$i")
    fi
  done

  # Wait for 50% of base steps to complete
  local target_count=$((${#group_base_steps[@]} / 2))
  local completed_count=0

  while [[ $completed_count -lt $target_count ]]; do
    completed_count=0
    for step in "${group_base_steps[@]}"; do
      local status
      status=$(state_get "$state_file" "step_${step}" 2>/dev/null || echo "pending")
      if [[ "$status" == "done" ]]; then
        completed_count=$((completed_count + 1))
      fi
    done
    sleep 10
  done

  # Launch tester now that 50% of features are done
  echo "🧪 Launching group-level tester for $group_name (${completed_count}/${#group_base_steps[@]} features complete)"
  step_launch "$session" "$project" "$run_id" "$step_num" "tester" "$cli" "$prompt" "$handoff_file" "$unsafe_flag"
}
```

### Phase 3: Tester Agent Enhancement

**Create new prompt template: `META/prompts/group-level-testing.md`**

```markdown
# Group-Level Testing Prompt

You are a tester agent running concurrently with feature implementation in a parallel group.

## Context

- **Group:** {GROUP_NAME}
- **Features implemented:** {COMPLETED_FEATURES}
- **Features in progress:** {REMAINING_FEATURES}
- **Platform:** {PLATFORM} (web, mobile, backend)

## Your Responsibilities

### 1. Incremental Build Validation

As features complete, verify they integrate correctly:

```bash
# For web/mobile
npm run build
npm run typecheck

# For backend
deno check supabase/functions/**/*.ts
```

**Goal:** Catch compilation errors, type mismatches, missing imports EARLY.

### 2. Cross-Feature Integration Tests

Test feature boundaries:

- **Calendar ↔ Tasks:** Task linked to event appears in calendar
- **Meals ↔ Recipes:** Recipe attached to meal shows ingredients
- **Constellations ↔ Permissions:** Permission changes filter calendar events correctly

Create `tests/integration/{GROUP_NAME}/` with tests for feature interactions.

### 3. Test Coverage Verification

```bash
npm run test -- --coverage
```

**Thresholds:**
- Line coverage: 70% minimum
- Branch coverage: 60% minimum
- Function coverage: 75% minimum

If below threshold, report in `.meta/handoff.md` and request additional tests.

### 4. Performance Checks (Web/Mobile only)

```bash
# Bundle size
npm run build -- --analyze

# Memory leaks
npm run test -- --detectLeaks
```

**Thresholds:**
- Bundle size: < 500KB per feature
- Memory leaks: 0 detected

### 5. Accessibility Tests (Web only)

```bash
npm run test:a11y
```

Using `@axe-core/react` or similar, verify:
- Color contrast ratios
- ARIA labels present
- Keyboard navigation works
- Screen reader compatibility

## Output

Update `.meta/handoff.md` with:

```markdown
## Group-Level Testing: {GROUP_NAME}

**Features tested:** {COMPLETED_FEATURES}

### Build Validation: ✅ PASS
- All features compile without errors
- Type checking passed
- No missing imports

### Integration Tests: ✅ PASS (12/12)
- Calendar ↔ Tasks: ✅
- Meals ↔ Recipes: ✅
- [etc.]

### Coverage: ⚠️ WARNING
- Line: 68% (below 70% threshold)
- Branch: 62%
- Function: 78%
- **Action:** Request additional tests for Calendar feature (only 45% coverage)

### Performance: ✅ PASS
- Bundle size: 420KB (within 500KB limit)
- No memory leaks detected

### Accessibility: ✅ PASS
- All color contrasts > 4.5:1
- ARIA labels present
- Keyboard navigation functional
```

## Failure Handling

If any check fails:

1. **Document failure** in `.meta/handoff.md`
2. **Create TODO** for base agent to fix
3. **Continue other checks** (don't abort on first failure)
4. **Report summary** when complete

## Timing

- **Start:** When 50% of group features are complete
- **Duration:** Continues until all features complete + validation finishes
- **Overlap:** Runs in parallel with remaining features

## Important

You are NOT blocking the pipeline - you're providing incremental feedback. If you find issues:
- Report them clearly
- Provide specific fix recommendations
- Let pipeline continue (issues can be fixed in retry if critical)
```

### Phase 4: parallelization-analyzer Enhancement

**Update parallelization rules:**

When analyzing a pipeline with parallel groups of 3+ features, automatically add group-level tester steps:

```markdown
## Parallelization Strategy Enhancement

### Group-Level Testing

For parallel groups with 3+ features, add a group-level tester step:

**Before:**
```
7-13 | base | web-features | [7 feature implementation steps]
14   | base | -            | 10 | Build validation
```

**After:**
```
7-13 | base   | web-features | [7 feature implementation steps]
14   | tester | web-features | 15 | Group validation: build check, integration tests, coverage
15   | base   | -            | 5  | Final validation (reduced time since group tester caught issues)
```

**Time savings:** 5-10 minutes per group (from earlier issue detection + parallel execution).
```

---

## Expected Outcomes

### Time Savings Analysis

#### Current: Constellation-2 Pipeline

```
Backend group: 40 min
  Steps 2-3: Implementation with embedded tests
  Step 4: Build validation (sequential) → 10 min

Data layer: 30 min

Web features group: 40 min
  Steps 7-13: Implementation with embedded tests
  Step 14: Build validation (sequential) → 10 min

Mobile features group: 40 min
  Steps 15-21: Implementation with embedded tests
  Step 22: Build validation (sequential) → 10 min

Integration tests: 50 min (sequential)
  Step 23: Integration tests → 30 min
  Step 24-25: Frontend test config → 20 min

Total: 220 minutes (3 hours 40 min)
```

#### Proposed: With Per-Group Testing

```
Backend group: 40 min
  Steps 2-3: Implementation (base) | Step 4: Group testing (tester)
  Both run concurrently → 40 min total (tester finishes in 15 min)

Data layer: 30 min

Web features group: 40 min
  Steps 7-13: Implementation (base) | Step 14: Group testing (tester)
  Both run concurrently → 40 min total

Mobile features group: 40 min
  Steps 15-21: Implementation (base) | Step 22: Group testing (tester)
  Both run concurrently → 40 min total

Integration tests: 30 min (reduced - many issues caught earlier)
  Step 23: Cross-platform integration → 20 min
  Step 24-25: Final E2E flows → 10 min

Total: 180 minutes (3 hours)
Savings: 40 minutes (18% reduction)
```

### Benefit Breakdown

| Benefit | Current | Proposed | Savings |
|---------|---------|----------|---------|
| Backend validation | 10 min (sequential) | 0 min (parallel) | 10 min |
| Web validation | 10 min (sequential) | 0 min (parallel) | 10 min |
| Mobile validation | 10 min (sequential) | 0 min (parallel) | 10 min |
| Integration tests | 50 min (many issues) | 30 min (fewer issues) | 20 min |
| **Total** | **80 min** | **30 min** | **50 min** |

**Additional benefits:**
- Earlier failure detection (catch in step 10, not step 23)
- Better test coverage visibility during execution
- Incremental validation reduces final integration test scope
- Parallel execution better utilizes system resources

---

## Risk Assessment

### Risk 1: Tester Starts Too Early

**Issue:** Tester launches when 50% of features done, but those features have bugs.

**Mitigation:**
- Tester is non-blocking - reports issues but doesn't abort pipeline
- Failed integration tests create TODOs for base agent
- Tester re-runs validation when remaining features complete
- Resume capability allows fixing issues and restarting

**Severity:** Low

### Risk 2: Resource Contention

**Issue:** Running 7 base agents + 1 tester agent (8 total) may exhaust CPU/memory.

**Mitigation:**
- Tester is lightweight (mostly runs existing test suites)
- Tests run in existing npm/deno processes (not additional VMs)
- Wave execution already handles resource management
- User can adjust parallel group sizes if needed

**Severity:** Low

### Risk 3: Tester Complexity

**Issue:** Tester agent needs to handle incremental validation, which is more complex than batch testing.

**Mitigation:**
- Provide clear prompt template (group-level-testing.md)
- Tester uses existing test infrastructure (npm test, deno check)
- Group metadata available in state file (knows which features are done)
- Start with simple validation (build + basic integration), enhance later

**Severity:** Medium

### Risk 4: False Positives

**Issue:** Tester reports failures for features that aren't ready yet.

**Mitigation:**
- Tester only tests completed features (checks state file)
- Integration tests skip features marked as "in progress"
- Clear handoff.md documentation shows which features were tested
- Resume logic allows fixing false positives

**Severity:** Low

### Risk 5: Debugging Complexity

**Issue:** Concurrent base + tester execution makes debugging harder.

**Mitigation:**
- Each step has isolated log file (.meta/steps/RUN_ID/step-N.log)
- Tester log clearly shows which features were tested and results
- State tracking shows which step failed (base vs tester)
- tmux panes visible for both base and tester steps

**Severity:** Low

---

## Implementation Phases

### Phase 1: Proof of Concept (4-6 hours)

**Goal:** Validate per-group testing with single project

**Tasks:**
1. Manually add tester step to web-features group in constellation-2 pipeline
2. Create group-level-testing.md prompt
3. Modify execute_wave_concurrent() to launch tester with delay
4. Test with constellation-2 (web-features only)
5. Measure time savings

**Success criteria:**
- Tester launches when 3-4 features complete
- Tester catches integration issues early
- Total time reduced by 10+ minutes

### Phase 2: Orchestrator Integration (6-8 hours)

**Goal:** Automatic group-level tester insertion

**Tasks:**
1. Update orchestrator.md with group-level testing rule
2. Modify pipeline generation to add tester steps for groups with 3+ features
3. Update parallelization-analyzer to recognize and optimize tester steps
4. Test with project.pipeline template
5. Verify backward compatibility (small groups don't get tester)

**Success criteria:**
- Generated pipelines include group-level testers
- Wave detection includes tester in parallel group
- Backward compatible with existing pipelines

### Phase 3: Enhanced Tester Agent (4-6 hours)

**Goal:** Robust incremental validation

**Tasks:**
1. Enhance tester agent to handle incremental mode
2. Add state tracking for which features are tested
3. Implement intelligent test selection (only test completed features)
4. Add coverage analysis and reporting
5. Create integration test templates for common feature boundaries

**Success criteria:**
- Tester intelligently tests only completed features
- Coverage reports accurate and actionable
- Integration tests catch real cross-feature issues

### Phase 4: Wave Execution Refinement (4-6 hours)

**Goal:** Smooth concurrent tester execution

**Tasks:**
1. Implement launch_delayed_tester() function
2. Add group metadata tracking (completed vs in-progress features)
3. Enhance state management for tester steps
4. Add tester-specific error handling
5. Test with multi-wave pipelines (3+ groups)

**Success criteria:**
- Tester launches at optimal time (50% group completion)
- Tester completes before or with final features
- State tracking shows tester progress clearly

### Phase 5: Documentation & Testing (3-4 hours)

**Goal:** Production-ready feature

**Tasks:**
1. Update WAVE-BASED-PARALLELIZATION.md with per-group testing
2. Create PER-GROUP-TESTING.md guide
3. Add examples to parallelization-analyzer.md
4. Create test pipelines for validation
5. Run full constellation-2 pipeline end-to-end

**Success criteria:**
- Documentation complete and clear
- Examples demonstrate value
- Real-world pipeline (constellation-2) shows time savings
- All edge cases handled

**Total effort:** 21-30 hours

---

## Success Metrics

### Quantitative

- **Time savings:** 15-25% reduction in total pipeline time for multi-platform projects
- **Earlier failure detection:** Catch 70%+ of integration issues during group execution (not after)
- **Test coverage:** Increase from 60% to 75%+ average (incremental feedback drives better testing)
- **Resource utilization:** CPU/memory usage stays below 80% during concurrent testing

### Qualitative

- **Developer confidence:** Failures caught early reduce uncertainty
- **Debugging speed:** Group-level logs make issues easier to isolate
- **Test quality:** Incremental coverage feedback improves test thoroughness
- **Pipeline clarity:** Group testing makes validation points explicit

---

## Comparison with Alternatives

### Alternative 1: Keep Sequential Validation

**Pros:**
- Simpler implementation
- Easier debugging (one thing at a time)
- No resource contention

**Cons:**
- 30-50 minutes longer pipeline time
- Late failure detection (find issues at end, not during)
- Wasted time if early features have bugs

**Verdict:** ❌ Suboptimal for large projects

### Alternative 2: Single Final Tester (Current Approach)

**Pros:**
- Works for small projects
- Comprehensive testing at end
- Simple to understand

**Cons:**
- Doesn't scale to multi-platform projects
- All validation sequential (bottleneck)
- Can't catch issues until everything is done

**Verdict:** ❌ Doesn't leverage parallel group structure

### Alternative 3: Per-Step Testers

**Pros:**
- Immediate feedback per feature
- Maximum parallelization

**Cons:**
- Too granular (7 tester agents for 7 features = overhead)
- Can't test cross-feature integration
- Resource exhaustion likely

**Verdict:** ❌ Over-parallelized, diminishing returns

### Alternative 4: Per-Group Testers (Proposed)

**Pros:**
- Balanced parallelization (3 tester agents for 3 groups)
- Tests feature integration within group
- Runs concurrently with implementation
- Earlier failure detection
- Manageable resource usage

**Cons:**
- More complex than sequential
- Requires delayed tester launch logic

**Verdict:** ✅ **Optimal balance** of speed, validation quality, and complexity

---

## Recommendations

### Immediate Actions

1. **Proof of concept:** Test per-group tester with constellation-2 manually
2. **Measure baseline:** Record current pipeline time for comparison
3. **Create prompt:** Write group-level-testing.md template
4. **Test launch logic:** Implement launch_delayed_tester() and validate timing

### Short-Term (Next Sprint)

1. **Integrate with orchestrator:** Automatic tester insertion for groups with 3+ features
2. **Update wave execution:** Handle tester steps in concurrent groups
3. **Enhance tester agent:** Incremental validation mode
4. **Document:** Update all relevant docs and examples

### Long-Term (Next Quarter)

1. **Advanced features:**
   - Adaptive tester launch (analyze group progress, launch when optimal)
   - Smart test selection (only run affected tests based on changed features)
   - Performance regression detection (compare metrics over time)
   - Visual regression testing (screenshot comparison for UI features)

2. **Integration with CI/CD:**
   - Group-level test results published to GitHub
   - Coverage trends tracked over time
   - Performance metrics visualized

3. **Multi-repository support:**
   - Group testers coordinate across monorepo packages
   - Shared test infrastructure across projects

---

## Open Questions

1. **Tester launch timing:** Is 50% group completion optimal, or should it be configurable?
   - **Hypothesis:** 50% is good default, but 40-60% range might be better for different group sizes
   - **Action:** Collect metrics during PoC, analyze optimal launch time

2. **Failure threshold:** Should tester failures block group completion, or just warn?
   - **Recommendation:** Warn only (non-blocking) in Phase 1, add --strict mode later
   - **Rationale:** Avoid false positive pipeline aborts during rollout

3. **Cross-group testing:** Should tester also test dependencies between groups?
   - **Example:** Web-features tester validates that backend API endpoints exist
   - **Recommendation:** Yes, but only for adjacent groups (web → backend, not web → mobile)
   - **Implementation:** Phase 2 enhancement

4. **Resource limits:** Should there be a max concurrent tester limit?
   - **Recommendation:** Start with 1 tester per group, add limit if resource issues arise
   - **Implementation:** Environment variable `META_MAX_CONCURRENT_TESTERS=3`

---

## Conclusion

**Assessment: ✅ HIGH VALUE - RECOMMENDED FOR IMPLEMENTATION**

Per-group testing parallelization is a natural extension of wave-based parallelization that:

1. **Reduces pipeline time by 15-25%** for multi-platform projects
2. **Catches failures earlier** (during group execution, not after)
3. **Improves test coverage** through incremental feedback
4. **Maintains backward compatibility** (only applies to groups with 3+ features)
5. **Manageable implementation** (21-30 hours over 4-6 weeks)

The proposal aligns perfectly with META's parallelization philosophy:
- **Automatic detection** (orchestrator adds testers, no manual config)
- **Conservative approach** (only for large groups, non-blocking failures)
- **Incremental rollout** (PoC → orchestrator → enhanced tester → production)

**Next step:** Proceed with Phase 1 (Proof of Concept) using constellation-2 project.

---

## Appendix A: Example Pipeline Comparison

### Before: Sequential Validation

```
# Web features group
7  | base | web-features | 35 | Relationships
8  | base | web-features | 35 | Constellations
9  | base | web-features | 40 | Calendar
10 | base | web-features | 35 | Meals
11 | base | web-features | 35 | Tasks
12 | base | web-features | 35 | Recipes
13 | base | web-features | 30 | Permissions

# Sequential validation (AFTER all features)
14 | base | - | 10 | Build validation: npm run build && npm test

Timeline:
0-40 min: Steps 7-13 run in parallel
40-50 min: Step 14 runs sequentially
Total: 50 minutes
```

### After: Concurrent Group Testing

```
# Web features group (implementation + testing concurrently)
7  | base   | web-features | 35 | Relationships
8  | base   | web-features | 35 | Constellations
9  | base   | web-features | 40 | Calendar
10 | base   | web-features | 35 | Meals
11 | base   | web-features | 35 | Tasks
12 | base   | web-features | 35 | Recipes
13 | base   | web-features | 30 | Permissions
14 | tester | web-features | 15 | Group validation (starts at ~20 min mark)

Timeline:
0-20 min: Steps 7-10 execute
20-40 min: Steps 11-13 execute + Step 14 (tester) starts and runs concurrently
40 min: All steps complete (including validation)
Total: 40 minutes (10 min saved!)
```

### Wave View: Before vs After

**Before:**
```
Wave 1: web-features:7-13 + mobile-features:15-21 (concurrent) → 40 min
  THEN: Build validation (sequential) → 20 min
Total: 60 minutes for wave + validation
```

**After:**
```
Wave 1:
  - web-features:7-14 (7 impl + 1 tester, all concurrent) → 40 min
  - mobile-features:15-22 (7 impl + 1 tester, all concurrent) → 40 min
Total: 40 minutes for wave + validation (20 min saved!)
```

---

## Appendix B: State Tracking Example

**State file during concurrent testing:**

```
# Group state
group_web-features=running
group_web-features_time=1770220000

# Individual feature steps
step_7=done     # Relationships complete
step_8=done     # Constellations complete
step_9=done     # Calendar complete
step_10=done    # Meals complete
step_11=running # Tasks in progress
step_12=running # Recipes in progress
step_13=running # Permissions in progress

# Tester step (launched when 4/7 features done)
step_14=running # Group tester running concurrently

# Tester metadata
step_14_launched_at=1770220800  # Launched 20 min after group start
step_14_features_tested=relationships,constellations,calendar,meals
step_14_features_pending=tasks,recipes,permissions
```

**Tester logic:**

```bash
# In tester agent, check which features are complete
completed_features=()
for step in 7 8 9 10 11 12 13; do
  status=$(state_get "$state_file" "step_${step}")
  if [[ "$status" == "done" ]]; then
    completed_features+=("${WF_STEP_PROMPT[$step]}")
  fi
done

# Only test integration between completed features
echo "Testing integration for: ${completed_features[*]}"

# Run incremental validation
npm run build  # Should pass for completed features
npm run test -- --testPathPattern="${completed_features[*]}"

# Update state with test results
state_set "$state_file" "step_14_features_tested" "${completed_features[*]}"
```

---

## Appendix C: Tester Prompts by Platform

### Web Features Group Tester

```markdown
## Web Features Group Testing

**Platform:** React + TypeScript + Vite

### Build Validation
```bash
cd apps/web
npm run build
npm run typecheck
```

### Integration Tests
```bash
npm run test:integration -- features/{completed_features}
```

**Focus areas:**
- Component composition (nested feature components)
- State management (context sharing between features)
- API integration (shared API client, auth context)
- Routing (feature navigation)

### Coverage
```bash
npm run test -- --coverage --coverageDirectory=.meta/coverage/web-features
```

**Thresholds:** 70% line, 60% branch, 75% function

### Performance
```bash
npm run build -- --mode production
npx vite-bundle-visualizer
```

**Check:** Bundle size per feature < 500KB
```

### Mobile Features Group Tester

```markdown
## Mobile Features Group Testing

**Platform:** React Native + TypeScript + Expo

### Build Validation
```bash
cd apps/mobile
npm run typecheck
npx expo export --platform ios
npx expo export --platform android
```

### Integration Tests
```bash
npm run test:integration -- features/{completed_features}
```

**Focus areas:**
- Component composition (RN-specific)
- Navigation (React Navigation integration)
- State management (context sharing)
- API integration (auth, offline sync)
- Platform-specific code (iOS vs Android)

### Coverage
```bash
npm run test -- --coverage --coverageDirectory=.meta/coverage/mobile-features
```

**Thresholds:** 70% line, 60% branch, 75% function

### Performance
```bash
npx expo export --dump-sourcemap
```

**Check:** JS bundle size < 5MB, native binary size < 30MB
```

### Backend Services Group Tester

```markdown
## Backend Services Group Testing

**Platform:** Deno + Supabase Edge Functions

### Build Validation
```bash
cd supabase/functions
deno check web-bff/index.ts
deno check _shared/**/*.ts
```

### Integration Tests
```bash
deno test --allow-all tests/integration/{completed_services}
```

**Focus areas:**
- API contract compliance (OpenAPI spec match)
- Database access (RLS policies correct)
- Auth integration (JWT validation)
- Error handling (consistent error format)

### Coverage
```bash
deno test --coverage=.meta/coverage/backend-services
deno coverage .meta/coverage/backend-services --lcov > .meta/coverage/backend-lcov.info
```

**Thresholds:** 75% line, 65% branch, 80% function

### Performance
```bash
deno bench tests/performance/{completed_services}
```

**Check:** p95 latency < 100ms, throughput > 100 req/s per service
```

---

## Appendix D: Integration with Existing Tools

### CI/CD Integration (GitHub Actions)

```yaml
# .github/workflows/meta-pipeline.yml

name: META Pipeline with Per-Group Testing

on:
  push:
    branches: [main, develop]

jobs:
  meta-pipeline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run META Pipeline
        run: |
          ../META/scripts/meta run project --project . --auto-approve

      - name: Upload Group Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: group-test-results
          path: |
            .meta/coverage/web-features/
            .meta/coverage/mobile-features/
            .meta/coverage/backend-services/

      - name: Comment PR with Group Results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const webCoverage = fs.readFileSync('.meta/coverage/web-features/summary.json');
            const mobileCoverage = fs.readFileSync('.meta/coverage/mobile-features/summary.json');

            const comment = `
            ## Group Test Results

            ### Web Features Group
            - Coverage: ${JSON.parse(webCoverage).total.lines.pct}%
            - Integration Tests: ✅ PASS

            ### Mobile Features Group
            - Coverage: ${JSON.parse(mobileCoverage).total.lines.pct}%
            - Integration Tests: ✅ PASS
            `;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

### Sentry Integration (Error Tracking)

```typescript
// In tester agent, report test results to Sentry
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: 'pipeline-testing',
});

// After running group tests
if (testResults.failed > 0) {
  Sentry.captureEvent({
    message: `Group testing failed: ${groupName}`,
    level: 'warning',
    tags: {
      group: groupName,
      wave: waveNumber,
      platform: platform,
    },
    extra: {
      failedTests: testResults.failures,
      coverage: coverageResults,
      duration: testDuration,
    },
  });
}
```

### PostHog Integration (Analytics)

```typescript
// Track group testing metrics
posthog.capture('group_test_complete', {
  group_name: groupName,
  features_count: featuresCompleted,
  test_duration_ms: duration,
  coverage_pct: coverageResults.total.lines.pct,
  integration_tests_passed: integrationResults.passed,
  integration_tests_failed: integrationResults.failed,
  performance_score: performanceMetrics.score,
});
```

---

## Appendix E: Failure Scenarios and Handling

### Scenario 1: Tester Finds Integration Issue

**Timeline:**
```
0-20 min: Features 1-4 complete
20 min: Tester launches
22 min: Tester finds Calendar ↔ Tasks integration broken
23 min: Tester reports issue in .meta/handoff.md
25-40 min: Features 5-7 continue (independent of issue)
40 min: All features complete, but integration issue documented
```

**Tester report:**
```markdown
## Group Testing: web-features

### Integration Tests: ⚠️ WARNING (11/12 passed, 1 failed)

**Failed:** Calendar ↔ Tasks integration
- **Issue:** Task linked to event returns 404
- **Root cause:** Event ID format mismatch (UUID vs integer)
- **Location:** features/calendar/api/events.ts:45, features/tasks/api/tasks.ts:120
- **Fix:** Standardize ID format to UUID in both features
- **Priority:** High (blocks cross-feature workflows)

**Action required:** Base agent should fix before marking group complete.
```

**Resolution:**
- Pipeline continues (non-blocking)
- Issue documented for next iteration
- On resume, base agent fixes and retests
- Tester re-runs integration test to verify fix

### Scenario 2: Tester Launches Too Early

**Timeline:**
```
0-15 min: Features 1-3 complete (faster than expected)
15 min: Tester launches (configured for 50% = 3.5 features)
16 min: Tester tests features 1-3 successfully
18 min: Feature 4 completes
19 min: Tester re-tests with feature 4 included
```

**Handling:**
- Tester is incremental, can test multiple times
- First pass tests features 1-3
- Second pass tests features 1-4
- Final pass tests all features when group completes

### Scenario 3: Resource Exhaustion

**Symptom:**
```
20 min: Tester launches
21 min: System CPU at 95%, memory at 90%
22 min: Tests slow down, timeout warnings
```

**Detection:**
```bash
# In tester agent, check system resources before running tests
cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
if [[ $cpu_usage -gt 85 ]]; then
  echo "⚠️ High CPU usage ($cpu_usage%), pausing tests for 30s"
  sleep 30
fi
```

**Mitigation:**
- Tester detects high resource usage
- Pauses and retries
- If persistent, skips performance tests (focus on build + integration)
- Reports resource constraint in handoff.md

### Scenario 4: Tester Never Launches (No Features Complete)

**Timeline:**
```
0-40 min: All 7 features in progress, none complete
40 min: Features start completing rapidly
40-42 min: Tester should launch but never did
```

**Detection:**
```bash
# In execute_wave_concurrent, check if tester launched
if [[ "$agent" == "tester" ]]; then
  local tester_launched=$(state_get "$state_file" "step_${step}_launched")
  if [[ -z "$tester_launched" ]]; then
    # Tester never launched, start it now
    echo "⚠️ Tester step $step never launched, starting now"
    step_launch(...)
  fi
fi
```

**Fallback:**
- Check at wave completion if tester ran
- If not, launch tester in emergency mode (all features complete)
- Tester runs full validation before group marked done

---

## Appendix F: Metrics and Monitoring

### Tester Performance Metrics

**Collect per group:**

```json
{
  "group_name": "web-features",
  "wave_number": 1,
  "tester_launch_time": "2026-02-04T20:15:00Z",
  "features_at_launch": 4,
  "total_features": 7,
  "tester_duration_ms": 900000,
  "tests_run": 156,
  "tests_passed": 154,
  "tests_failed": 2,
  "coverage": {
    "lines": 72.5,
    "branches": 65.3,
    "functions": 78.2
  },
  "performance": {
    "bundle_size_kb": 420,
    "build_time_ms": 45000,
    "test_time_ms": 180000
  },
  "issues_found": [
    {
      "type": "integration",
      "severity": "high",
      "feature_a": "calendar",
      "feature_b": "tasks",
      "description": "Event ID format mismatch"
    }
  ]
}
```

**Aggregate metrics across pipelines:**

```sql
-- Average time savings from per-group testing
SELECT
  AVG(sequential_time - concurrent_time) as avg_time_saved_min,
  AVG((sequential_time - concurrent_time) / sequential_time * 100) as avg_pct_saved
FROM pipeline_runs
WHERE per_group_testing_enabled = true;

-- Issue detection rate (how many issues caught by group tester vs final tester)
SELECT
  COUNT(*) FILTER (WHERE found_by = 'group_tester') as group_tester_issues,
  COUNT(*) FILTER (WHERE found_by = 'final_tester') as final_tester_issues,
  COUNT(*) FILTER (WHERE found_by = 'group_tester') * 100.0 / COUNT(*) as pct_caught_early
FROM test_failures
WHERE pipeline_run_date > '2026-01-01';
```

### Alerting Rules

**Slack notification triggers:**

1. **Group tester failure rate > 20%**
   ```
   Alert: web-features group tester failing frequently
   - Last 10 runs: 3 failures
   - Common issue: Calendar ↔ Tasks integration
   - Action: Investigate test flakiness or feature coupling
   ```

2. **Tester launch delay > 10 minutes**
   ```
   Alert: Tester not launching on time
   - Expected launch: 50% group completion (~20 min)
   - Actual launch: 32 min (12 min late)
   - Possible cause: All features slower than expected
   - Action: Review timeout settings or feature complexity
   ```

3. **Coverage drop > 10%**
   ```
   Alert: Coverage decreased significantly
   - Previous: 75%
   - Current: 62%
   - Delta: -13%
   - Group: web-features
   - Action: Review recent commits for untested code
   ```

---

## Document Status

**Version:** 1.0
**Last Updated:** 2026-02-04
**Status:** Assessment Complete - Awaiting Approval
**Next Review:** After Phase 1 PoC completion

**Reviewers:**
- [ ] Architecture Team
- [ ] Platform Engineering
- [ ] QA Team
- [ ] DevOps Team

**Approvals Required:**
- [ ] Technical Lead
- [ ] Product Owner
- [ ] Engineering Manager

**Once approved, proceed to:**
- Implementation Plan: `/Users/stevebargelt/code/META/plans/per-group-testing-implementation.md`
- Tracking Issue: Create GitHub issue in META repository
- Project Board: Add to "Pipeline Optimization" milestone
