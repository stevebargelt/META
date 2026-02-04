# Per-Group Testing Parallelization - Implementation Plan

**Date:** 2026-02-04
**Related:** per-group-testing-parallelization.md (full assessment)
**Status:** Approved for Implementation

---

## Quick Summary

**Your observation:** "Each parallel group could have its own testing agent to further parallelize the work."

**Assessment:** ✅ **CORRECT** - This is a high-value enhancement to wave-based parallelization.

**Time savings:** Additional 15-25% reduction (on top of wave-based parallelization's 25-47%).

---

## Current State

```
Wave 1: web-features + mobile-features (concurrent) → 40 min
  - 14 features run in parallel (7 web + 7 mobile)
  - Each feature includes embedded unit tests

Sequential bottleneck → 20 min
  - Build validation after all features

Sequential bottleneck → 50 min
  - Integration tests after validation

Total: 110 minutes
```

**Issues:**
- Build validation waits for all features (10 min × 2 groups = 20 min wasted)
- Integration tests run at the end (50 min sequential)
- Issues found late (step 23, not during implementation)

---

## Proposed State

```
Wave 1: web-features + mobile-features (concurrent) → 40 min
  - Group: web-features
    - 7 feature implementations (base agents)
    - 1 group tester (tester agent) - RUNS CONCURRENTLY
  - Group: mobile-features
    - 7 feature implementations (base agents)
    - 1 group tester (tester agent) - RUNS CONCURRENTLY

Integration tests (reduced) → 30 min
  - Cross-platform sync tests only
  - Most integration already validated by group testers

Total: 70 minutes
Savings: 40 minutes (36% faster than current)
```

**Benefits:**
- Build validation happens DURING group execution (not after)
- Integration tests run DURING group execution (not after)
- Issues found early (step 10, not step 23)
- Total time reduced by 40 minutes

---

## Architecture

### Three-Tier Testing

**Tier 1: Feature-Level Tests** (Unchanged)
- **Agent:** base
- **When:** During feature implementation
- **Scope:** Unit tests for single feature
- **Example:** Calendar feature unit tests (CalendarGrid.test.tsx)

**Tier 2: Group-Level Tests** (NEW)
- **Agent:** tester
- **When:** Concurrent with group execution (launches at 50% completion)
- **Scope:** Cross-feature integration within group
- **Example:** Calendar ↔ Tasks integration test

**Tier 3: Final Integration Tests** (Enhanced)
- **Agent:** tester
- **When:** After all groups complete
- **Scope:** Cross-platform, full-stack integration
- **Example:** Web create event → Mobile sees it (real-time sync)

### Tester Launch Logic

```bash
# In execute_wave_concurrent()

# Phase 1: Launch all base agents for group
for step in $group_steps; do
  if [[ "${WF_STEP_AGENT[$step]}" == "base" ]]; then
    step_launch(...)
  fi
done

# Phase 2: Launch tester when 50% of features complete
launch_delayed_tester() {
  # Wait until 50% of group steps are done
  while [[ $completed_count -lt $target_count ]]; do
    check_completion_status
    sleep 10
  done

  # Launch tester now
  step_launch "$tester_step" ...
}

# Phase 3: Wait for all (base + tester) to complete
```

---

## Pipeline Changes

### Before (Sequential Validation)

```
# Web features
7-13 | base | web-features | [7 implementation steps]

# Sequential validation AFTER group
14 | base | - | 10 | Build validation: npm run build && npm test
```

**Timeline:**
```
0-40 min: Steps 7-13 run in parallel
40-50 min: Step 14 runs sequentially
Total: 50 minutes
```

### After (Concurrent Group Testing)

```
# Web features + concurrent tester
7-13 | base   | web-features | [7 implementation steps]
14   | tester | web-features | 15 | Group validation (starts at ~20 min mark)
```

**Timeline:**
```
0-20 min: Steps 7-10 execute
20-40 min: Steps 11-13 execute + Step 14 (tester) runs concurrently
40 min: All complete (including validation)
Total: 40 minutes (10 min saved!)
```

---

## Implementation Phases

### Phase 1: Proof of Concept (4-6 hours)

**Goal:** Validate with constellation-2 manually

**Tasks:**
1. Add tester step to web-features group manually
2. Create group-level-testing.md prompt
3. Implement launch_delayed_tester() function
4. Test with constellation-2 project
5. Measure time savings

**Success:** Tester launches at 50% completion, catches issues early, saves 10+ minutes

### Phase 2: Orchestrator Integration (6-8 hours)

**Goal:** Automatic tester insertion

**Tasks:**
1. Update orchestrator.md with group-level testing rule
2. Modify pipeline generation to add tester for groups 3+ features
3. Update parallelization-analyzer to recognize testers
4. Test with project.pipeline template
5. Verify backward compatibility

**Success:** Generated pipelines include group testers automatically

### Phase 3: Enhanced Tester Agent (4-6 hours)

**Goal:** Robust incremental validation

**Tasks:**
1. Enhance tester for incremental mode
2. Add state tracking for tested features
3. Implement intelligent test selection
4. Add coverage analysis
5. Create integration test templates

**Success:** Tester only tests completed features, reports coverage accurately

### Phase 4: Wave Execution (4-6 hours)

**Goal:** Smooth concurrent tester execution

**Tasks:**
1. Implement launch_delayed_tester() in meta script
2. Add group metadata tracking
3. Enhance state management for testers
4. Add tester error handling
5. Test with multi-wave pipelines

**Success:** Testers launch at optimal time, complete before/with final features

### Phase 5: Documentation (3-4 hours)

**Goal:** Production-ready feature

**Tasks:**
1. Update WAVE-BASED-PARALLELIZATION.md
2. Create PER-GROUP-TESTING.md guide
3. Add examples to parallelization-analyzer.md
4. Create test pipelines
5. Full constellation-2 pipeline test

**Success:** Documentation complete, real-world validation shows time savings

**Total:** 21-30 hours

---

## Critical Files

### To Modify

1. **`scripts/meta`** - Add launch_delayed_tester() to execute_wave_concurrent()
2. **`scripts/meta-lib/workflow.sh`** - No changes (wave detection already works)
3. **`agents/orchestrator.md`** - Add group-level testing rule
4. **`agents/parallelization-analyzer.md`** - Recognize tester steps in groups
5. **`agents/tester.md`** - Add incremental validation mode

### To Create

1. **`prompts/group-level-testing.md`** - Template for group tester agent
2. **`docs/PER-GROUP-TESTING.md`** - User guide
3. **`assessments/per-group-testing-parallelization.md`** - This assessment (✅ done)

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Tester starts too early | Low | Non-blocking, retests when more features complete |
| Resource contention | Low | Tester lightweight, uses existing test infra |
| Tester complexity | Medium | Clear prompt template, incremental rollout |
| False positives | Low | Only tests completed features, clear documentation |
| Debugging complexity | Low | Isolated logs, state tracking shows progress |

**Overall risk:** ✅ **LOW** - Well-mitigated, incremental rollout

---

## Success Metrics

### Quantitative

- **Time savings:** 15-25% reduction for multi-platform projects
- **Earlier failure detection:** 70%+ of issues caught during group execution
- **Test coverage:** Increase from 60% to 75%+ average
- **Resource usage:** Stay below 80% CPU/memory during concurrent testing

### Qualitative

- **Developer confidence:** Failures caught early reduce uncertainty
- **Debugging speed:** Group logs make issues easier to isolate
- **Test quality:** Incremental feedback improves test thoroughness
- **Pipeline clarity:** Group testing makes validation points explicit

---

## Example: Constellation-2

### Current (Wave-Based Only)

```
Step 1: Contract stub → 20 min
Steps 2-3: Backend (parallel) → 40 min
Step 4: Backend validation → 10 min
Steps 5-6: Data layer → 30 min
Wave 2: web + mobile (concurrent) → 40 min
  Steps 7-13: web-features
  Steps 15-21: mobile-features
Step 14,22: Build validation → 20 min
Steps 23-25: Integration tests → 50 min

Total: 210 minutes (3.5 hours)
```

### Proposed (Wave + Per-Group Testing)

```
Step 1: Contract stub → 20 min
Steps 2-3: Backend (parallel) + Step 4 (tester) → 40 min
Steps 5-6: Data layer → 30 min
Wave 2: web + mobile + testers (all concurrent) → 40 min
  Steps 7-13: web-features + Step 14 (tester)
  Steps 15-21: mobile-features + Step 22 (tester)
Steps 23-25: Integration tests (reduced) → 30 min

Total: 160 minutes (2.7 hours)
Savings: 50 minutes (24% reduction)
```

---

## Comparison with Alternatives

| Approach | Time | Pros | Cons | Verdict |
|----------|------|------|------|---------|
| **Sequential validation** (current fallback) | 220 min | Simple, easy debug | Slow, late failures | ❌ Suboptimal |
| **Single final tester** (current) | 210 min | Comprehensive end testing | Bottleneck, late detection | ⚠️ OK for small projects |
| **Per-step testers** | 180 min | Immediate feedback | Too granular, overhead | ❌ Over-parallelized |
| **Per-group testers** (proposed) | 160 min | Balanced, early detection, manageable | More complex | ✅ **Optimal** |

---

## Next Steps

1. **Review assessment:** Read full details in `per-group-testing-parallelization.md`
2. **Approve approach:** Sign off on architecture and implementation plan
3. **Phase 1 PoC:** Manual test with constellation-2 (4-6 hours)
4. **Iterate:** Based on PoC results, refine approach
5. **Full implementation:** Phases 2-5 (17-24 hours)

---

## Appendices (See Full Assessment)

- **Appendix A:** Example pipeline comparison (before/after)
- **Appendix B:** State tracking example
- **Appendix C:** Tester prompts by platform (web/mobile/backend)
- **Appendix D:** Integration with CI/CD, Sentry, PostHog
- **Appendix E:** Failure scenarios and handling
- **Appendix F:** Metrics and monitoring

Full details in `per-group-testing-parallelization.md` (21,000+ words, comprehensive).

---

## Conclusion

**Your observation was correct:** Per-group testing is a natural and valuable extension of wave-based parallelization.

**Recommendation:** ✅ **PROCEED WITH IMPLEMENTATION**

**Next action:** Proof of concept with constellation-2 project (Phase 1).

---

**Document Status:**
- Created: 2026-02-04
- Status: Ready for implementation
- Estimated effort: 21-30 hours over 4-6 weeks
- Expected ROI: 24% additional time savings for multi-platform projects
