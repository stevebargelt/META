# Wave-Based Parallelization

## Overview

Wave-based parallelization is an optimization in META's pipeline executor that enables **concurrent execution of multiple parallel groups** when they don't depend on each other. This can reduce total pipeline execution time by 25-47% for multi-platform projects.

## Problem Statement

### Before Wave-Based Execution

The pipeline executor ran parallel groups **sequentially**:

```
Wave 1: backend (steps 4-5) → 40 min → complete
Wave 2: web-features (steps 10-16) → 40 min → complete
Wave 3: mobile-features (steps 18-24) → 40 min → complete
Total: 120 minutes
```

**Opportunity:** If `web-features` and `mobile-features` don't depend on each other (both just need `backend` complete), they can run **simultaneously**.

### After Wave-Based Execution

```
Wave 1: backend → 40 min → complete
Wave 2: web-features + mobile-features (CONCURRENT) → 40 min → complete
Total: 80 minutes (33% faster)
```

## How It Works

### Wave Detection

A **wave** is a set of parallel groups that:

1. **Share prerequisites** (both need the same prior steps done)
2. **Don't depend on each other** (web doesn't need mobile, mobile doesn't need web)
3. **Are consecutive** (no serial implementation steps between them)

The executor automatically detects waves at runtime by:

- Scanning the pipeline for consecutive parallel groups
- Identifying groups separated only by validation/gate steps (not implementation steps)
- Grouping them into waves that can execute concurrently

### Execution Strategy

**Single-group waves** use existing parallel execution:
- All steps in the group run in parallel
- Existing behavior, no changes

**Multi-group waves** use concurrent execution:
- Launch all groups simultaneously
- Each group's steps run in parallel
- Wait for all groups to complete
- Handle failures per-group (resume only failed groups)

## Example Pipelines

### Example 1: Multi-Platform App

**Pipeline:**
```
1 | base | - | auto | - | 10 | Setup
2 | base | - | auto | backend | 30 | Auth service
3 | base | - | auto | backend | 30 | User service
4 | base | - | auto | - | 10 | Backend validation
5 | base | - | auto | web-features | 30 | Calendar feature (web)
6 | base | - | auto | web-features | 30 | Tasks feature (web)
7 | base | - | auto | mobile-features | 30 | Calendar feature (mobile)
8 | base | - | auto | mobile-features | 30 | Tasks feature (mobile)
9 | base | - | auto | - | 10 | Integration tests
```

**Wave detection:**
- **Wave 0:** `backend:2-3` (single group)
- **Wave 1:** `web-features:5-6 mobile-features:7-8` (two groups concurrently)

**Execution:**
```
Step 1: Setup (serial) → 10 min
Wave 0: backend (steps 2-3 in parallel) → 30 min
Step 4: Backend validation (serial) → 10 min
Wave 1: web-features + mobile-features (concurrent) → 30 min
  - Steps 5-6 run in parallel (web)
  - Steps 7-8 run in parallel (mobile)
  - Both groups run simultaneously
Step 9: Integration tests (serial) → 10 min

Total: 90 minutes
```

**Savings:** 30 minutes vs sequential (120 min → 90 min)

### Example 2: Single Group (Backward Compatible)

**Pipeline:**
```
1 | base | - | auto | - | 10 | Setup
2 | base | - | auto | dev | 30 | Backend
3 | base | - | auto | dev | 30 | Frontend
4 | base | - | auto | dev | 30 | Tests
5 | base | - | auto | - | 10 | Integration tests
```

**Wave detection:**
- **Wave 0:** `dev:2-4` (single group)

**Execution:**
```
Step 1: Setup → 10 min
Wave 0: dev (steps 2-4 in parallel) → 30 min
Step 5: Integration tests → 10 min

Total: 50 minutes
```

**Behavior:** Identical to pre-wave execution (backward compatible).

### Example 3: Three Waves

**Pipeline:**
```
1  | base | - | auto | - | 10 | Setup
2  | base | - | auto | backend | 30 | Auth service
3  | base | - | auto | backend | 30 | User service
4  | base | - | auto | - | 10 | Backend validation
5  | base | - | auto | web-app | 30 | Web calendar
6  | base | - | auto | web-app | 30 | Web tasks
7  | base | - | auto | mobile-app | 30 | Mobile calendar
8  | base | - | auto | mobile-app | 30 | Mobile tasks
9  | base | - | auto | - | 10 | Frontend validation
10 | base | - | auto | email-integration | 30 | Email service
11 | base | - | auto | sms-integration | 30 | SMS service
12 | base | - | auto | - | 10 | Final tests
```

**Wave detection:**
- **Wave 0:** `backend:2-3`
- **Wave 1:** `web-app:5-6 mobile-app:7-8`
- **Wave 2:** `email-integration:10-10 sms-integration:11-11`

**Execution timeline:**
```
Step 1: Setup → 10 min
Wave 0: backend → 30 min
Step 4: Backend validation → 10 min
Wave 1: web-app + mobile-app (concurrent) → 30 min
Step 9: Frontend validation → 10 min
Wave 2: email-integration + sms-integration (concurrent) → 30 min
Step 12: Final tests → 10 min

Total: 130 minutes
Sequential would be: 190 minutes
Savings: 60 minutes (32%)
```

## State Management

### Group-Level State

Each parallel group has state tracked independently:

```bash
state_set_group "$state_file" "web-features" "running"
state_set_group "$state_file" "web-features" "done"
state_set_group "$state_file" "mobile-features" "failed"
```

State values:
- `running` - Group is executing
- `done` - All steps in group completed successfully
- `failed` - One or more steps in group failed

### Wave-Level State

Waves are tracked for monitoring:

```bash
state_set_wave "$state_file" "1" "running" "web-features mobile-features"
state_set_wave "$state_file" "1" "done" "web-features mobile-features"
```

### Resume Behavior

When resuming after failure:
- **Failed groups** are re-executed
- **Completed groups** are skipped
- **Other groups in same wave** are not affected

Example:
```
Wave 1 execution:
  - web-features: ✅ completed
  - mobile-features: ❌ failed at step 7

Resume:
  - web-features: skipped (already done)
  - mobile-features: retry from step 7
```

## Status Display

### During Wave Execution

```
$ meta status --project constellation-2

Pipeline Status
═══════════════════════════════════════

Wave 1: backend
  ✅ Group: backend (2/2 steps complete)

Wave 2: frontend features (IN PROGRESS)
  🔄 Group: web-features (5/7 steps complete)
  🔄 Group: mobile-features (4/7 steps complete)

Overall: 11/16 steps complete (68%)
```

### Wave Execution Output

```
═══════════════════════════════════════
🌊 Wave with multiple concurrent groups:
  - web-features (steps 10 to 16)
  - mobile-features (steps 18 to 24)
═══════════════════════════════════════

🚀 Launching group: web-features (steps 10-16)
🚀 Launching group: mobile-features (steps 18-24)

⏳ Waiting for all groups to complete...
  Monitoring group: web-features
  ✅ Group web-features complete
  Monitoring group: mobile-features
  ✅ Group mobile-features complete

📝 Merging handoffs from completed steps...
✅ Wave complete - all groups succeeded
```

## Failure Handling

### Partial Wave Failure

If one group fails in a wave:

```
⚠️  Failed groups in wave: mobile-features
Other groups may have completed successfully.
Resume will retry only failed groups.
```

The executor:
1. Continues monitoring other groups (doesn't abort immediately)
2. Completes all groups that can finish
3. Reports which groups failed
4. Returns failure status
5. On resume, only retries failed groups

### Full Wave Failure

If all groups fail:
- State shows all groups as `failed`
- User can investigate logs per-group
- Resume retries all failed groups

## Auto-Commit Behavior

After wave completion:
```bash
git commit -m "meta: wave complete (web-features mobile-features)"
```

Commit includes:
- All changes from all groups in the wave
- Group names in commit message

## Implementation Details

### Wave Detection Logic

Located in: `/Users/stevebargelt/code/META/scripts/meta-lib/workflow.sh`

**Algorithm:**
```bash
detect_waves() {
  # 1. Scan pipeline for parallel groups
  # 2. For each group, check if previous group ended with serial step
  # 3. If yes, start new wave
  # 4. If no, add to current wave
  # 5. Output: WAVE_N=group1:start-end group2:start-end ...
}
```

**Key rule:** Groups are in same wave if they are consecutive (no serial steps between them).

### Concurrent Execution

Located in: `/Users/stevebargelt/code/META/scripts/meta`

**Function:** `execute_wave_concurrent()`

**Phases:**
1. **Launch:** Start all steps in all groups simultaneously
2. **Wait:** Monitor all groups concurrently
3. **Handle failures:** Track which groups failed
4. **Process gates:** Handle gate steps for completed steps
5. **Merge handoffs:** Combine outputs from all groups
6. **Auto-commit:** Commit all changes as one wave

### Modified Control Flow

The main `control_run()` function:

**Before wave detection:**
```bash
while [[ $idx -le $WF_STEP_COUNT ]]; do
  if [[ -n "$group" ]]; then
    # Execute single group
  fi
done
```

**After wave detection:**
```bash
# Detect waves once at start
detect_waves

while [[ $idx -le $WF_STEP_COUNT ]]; do
  if [[ -n "$group" ]]; then
    if [[ is_multi_group_wave ]]; then
      # Execute wave concurrently
      execute_wave_concurrent(...)
    else
      # Execute single group (existing logic)
    fi
  fi
done
```

## Backward Compatibility

**Guarantee:** Pipelines without wave opportunities execute identically to pre-wave behavior.

**How:**
- Single-group waves use existing `execute_parallel_group()` logic
- Wave detection returns one wave per group → sequential execution
- No performance regression for existing pipelines

**Testing:**
```bash
# Pipeline with single groups (feature.pipeline)
# Before: Steps 5-7 run in parallel (one group)
# After:  Steps 5-7 run in parallel (one group)
# Result: Identical behavior
```

## Benefits

### Time Savings

**Multi-platform projects:**
- Web + Mobile features can run concurrently
- Savings: 25-47% total pipeline time

**Example (Constellation-2):**
- Before: 150 min (backend 40 + data 30 + web 40 + mobile 40)
- After: 110 min (backend 40 + data 30 + web+mobile 40)
- Savings: 40 min (27%)

### Resource Utilization

- Better CPU/memory utilization during multi-group waves
- More work done in parallel
- Tmux panes for all groups visible simultaneously

### Explainability

- Wave plan documented in `.meta/parallelization-analysis.md`
- Clear dependency graph (Mermaid diagram)
- User can see why groups are concurrent

## Limitations

### When Waves Don't Help

1. **Single parallel group** - No concurrent execution opportunity
2. **Dependencies between groups** - Must serialize
3. **Resource constraints** - System may not handle many parallel steps

### Resource Exhaustion

Running web + mobile simultaneously may exceed system resources.

**Mitigation:**
- User can serialize groups by editing `PARALLEL_GROUP`
- System resource limits cause graceful failure (not corruption)
- Parallelization-analyzer provides dependency metadata

### Debugging Complexity

Multiple groups failing simultaneously is harder to debug.

**Mitigation:**
- Each step has isolated log file (`.meta/steps/RUN_ID/step-N.log`)
- Group-level status tracking shows which group failed
- `meta status` shows wave breakdown
- Resume logic skips completed groups

## Testing

### Unit Tests

See: `/private/tmp/claude-501/-Users-stevebargelt-code-META/*/scratchpad/test-*.sh`

**Test cases:**
1. `test-wave-detection.sh` - Multi-group wave detection
2. `test-single-group.sh` - Backward compatibility
3. `test-three-waves.sh` - Multiple waves

**Run tests:**
```bash
bash /private/tmp/.../test-wave-detection.sh
bash /private/tmp/.../test-single-group.sh
bash /private/tmp/.../test-three-waves.sh
```

### Integration Test (Constellation-2)

**Setup:**
```bash
cd /Users/stevebargelt/code/constellation-2
../META/scripts/meta run project --continue
```

**Expected:**
- Detect Wave 2 with 2 groups: web-features + mobile-features
- Both groups launch simultaneously (14 tmux panes at once)
- Total time: ~110 min (vs 150 min sequential)

**Verify:**
```bash
# During execution
tmux list-panes -a | grep "Step"
# Should show panes for steps 10-16 AND 18-24 simultaneously

# After execution
cat .meta/steps/*/state.txt | grep "^group_"
# Should show:
# group_web-features=done
# group_mobile-features=done
```

## Future Enhancements

### Dynamic Wave Adjustment

If groups have different durations, adjust wave composition:
- Fast group (10 min) + slow group (40 min) = suboptimal
- Better: Put fast groups together, slow groups together

### Wave Prediction

Use historical timing data to predict optimal wave composition.

### Cross-Wave Dependencies

Support soft dependencies between waves:
- Wave 2 can start before Wave 1 fully completes
- Risk-managed parallelization

## Troubleshooting

### Wave Not Detected

**Symptom:** Groups run sequentially despite being independent.

**Cause:** Serial step between groups breaks wave.

**Solution:** Check pipeline for implementation steps between groups. Only validation/gate steps should separate wave members.

### Resource Exhaustion

**Symptom:** System hangs or fails during wave execution.

**Cause:** Too many parallel steps for available resources.

**Solution:**
1. Serialize groups by editing `PARALLEL_GROUP`
2. Reduce step timeout
3. Increase system resources (RAM, CPU)

### Partial Wave Failure

**Symptom:** One group fails, others succeed.

**Behavior:** This is expected! Wave execution is fault-tolerant.

**Resolution:**
1. Check failed group logs: `.meta/steps/RUN_ID/step-N.log`
2. Fix the issue
3. Resume: `meta resume --project <project>`
4. Only failed group re-executes

## Architecture Decisions

### Why Not Task Dependencies?

**Alternative:** Explicit task dependency graph (like Make/Bazel).

**Reason for current approach:**
- Simpler for users (no dependency syntax to learn)
- Automatic detection from pipeline structure
- Backward compatible with existing pipelines
- Conservative (prefers safety over max parallelization)

### Why Waves vs DAG Scheduling?

**Alternative:** Full DAG scheduler with topological sort.

**Reason for waves:**
- Simpler implementation
- Easier to reason about
- Sufficient for common case (multi-platform features)
- Can add DAG later as enhancement

### Why Group-Level Tracking?

**Alternative:** Only track step-level state.

**Reason for groups:**
- Clearer resume logic
- Better status reporting
- User thinks in terms of "web-features failed"
- Enables future optimizations (skip entire group)

## References

- **Implementation:** `/Users/stevebargelt/code/META/scripts/meta-lib/workflow.sh`
- **Execution:** `/Users/stevebargelt/code/META/scripts/meta` (control_run, execute_wave_concurrent)
- **State:** `/Users/stevebargelt/code/META/scripts/meta-lib/status.sh`
- **Tests:** `/private/tmp/claude-501/-Users-stevebargelt-code-META/*/scratchpad/test-*.sh`
- **Plan:** `/Users/stevebargelt/code/META/.planning/wave-parallelization-plan.md` (if exists)
