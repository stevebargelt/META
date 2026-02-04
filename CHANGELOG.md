# META Changelog

## [Unreleased]

### Added

#### Wave-Based Parallelization (2026-02-04)

META pipelines now support **wave-based parallelization**, enabling concurrent execution of multiple independent parallel groups. This can reduce total pipeline execution time by 25-47% for multi-platform projects.

**Key Features:**
- **Automatic wave detection** - No pipeline format changes required
- **Concurrent group execution** - Multiple parallel groups run simultaneously
- **Group-level state tracking** - Better resume and status reporting
- **100% backward compatible** - Existing pipelines work unchanged

**Example:**
```
Before: backend (40m) → web-features (40m) → mobile-features (40m) = 120m
After:  backend (40m) → [web-features + mobile-features] (40m) = 80m
Savings: 40 minutes (33%)
```

**How it works:**
- Pipeline executor detects groups that don't depend on each other
- Groups separated only by validation steps can run in same wave
- Multi-group waves execute all groups concurrently
- Single-group waves use existing behavior (backward compatible)

**Benefits:**
- Multi-platform projects see 25-47% time reduction
- Better resource utilization (CPU/memory)
- Clearer status reporting with group-level progress
- Fault-tolerant (one group can fail, others continue)

**New Functions:**
- `detect_waves()` in `workflow.sh` - Automatic wave detection
- `execute_wave_concurrent()` in `meta` - Concurrent wave execution
- `state_set_group()`, `state_get_group()` in `status.sh` - Group state
- `state_set_wave()`, `state_get_wave()` in `status.sh` - Wave state

**Modified:**
- `control_run()` in `meta` - Wave-based execution logic
- `parallelization-analyzer.md` - Wave plan output section

**Documentation:**
- `/docs/WAVE-BASED-PARALLELIZATION.md` - Comprehensive guide
- Includes examples, testing, troubleshooting

**Testing:**
- Unit tests for wave detection (single/multi/three waves)
- Backward compatibility verified
- Integration test ready for constellation-2

**See:** `/docs/WAVE-BASED-PARALLELIZATION.md` for complete documentation.

---

## Previous Changes

(Previous changelog entries would go here)
