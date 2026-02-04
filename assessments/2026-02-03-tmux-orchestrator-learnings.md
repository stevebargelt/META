# Tmux Orchestrator Analysis: Patterns for META

**Date:** 2026-02-03
**Source:** /Users/stevebargelt/code/tmux-orchestrator
**Purpose:** Extract applicable patterns for META's verification architecture and multi-agent coordination

---

## Executive Summary

Tmux Orchestrator is an AI-powered autonomous work system that enables Claude agents to work 24/7 without human intervention through a hierarchical agent structure (Orchestrator → Project Managers → Engineers). Its approach to communication, scheduling, and quality enforcement offers patterns that could significantly enhance META's verification architecture.

**Key insight:** Instead of orchestrating *tasks*, it orchestrates **autonomous agents** that behave like a development team. This is a paradigm shift from META's current task-pipeline approach.

---

## Part 1: What Tmux Orchestrator Does

### Core Capabilities

1. **Persistent Multi-Agent Sessions** - Work continues independently of user presence
2. **Self-Scheduling** - Agents schedule their own check-ins, no external scheduler
3. **Hub-and-Spoke Communication** - Central PM aggregates from engineers, reducing n² complexity
4. **Terminal-Native** - Runs in tmux with no special infrastructure

### Architecture

```
Orchestrator (High-level oversight)
    ├── Project Manager 1 (Team coordination)
    │   ├── Developer/Engineer
    │   ├── QA Engineer
    │   └── DevOps
    └── Project Manager 2 (Team coordination)
        └── Developer/Engineer
```

### Why This Design Works

| Challenge | Solution |
|-----------|----------|
| Context window limitations | Each agent stays focused on specialized role |
| Parallel execution | Multiple engineers work simultaneously |
| n² communication complexity | Hub-and-spoke through PMs |
| Quality enforcement | PM role with non-negotiable standards |

### Key Files (Minimal Codebase)

| File | Purpose | Lines |
|------|---------|-------|
| `send-claude-message.sh` | Reliable agent-to-agent messaging | 25 |
| `schedule_with_note.sh` | Self-scheduling system | 30 |
| `tmux_utils.py` | Python utilities for tmux interaction | 204 |
| `CLAUDE.md` | Complete agent behavior guidelines | 716 |
| `LEARNINGS.md` | Accumulated operational knowledge | 95 |

**Total:** ~256 lines of code, ~1,100+ lines of documentation

---

## Part 2: Patterns Applicable to META

### Pattern 1: Hub-and-Spoke Communication

**Problem in META:** Multi-agent workflows can create communication chaos when many agents need to coordinate.

**Tmux Orchestrator Approach:**
- Engineers report to PM only
- PM aggregates and reports to Orchestrator
- No direct engineer-to-engineer communication required

**META Application:**
- Create "Verification Manager" agent that coordinates verification agents
- Verification results flow through single aggregation point
- Reduces complexity in multi-verification scenarios

```
Current META:
  Agent 1 → Handoff → Agent 2 → Handoff → Agent 3 → ... → DoD

Proposed (Hub-and-Spoke):
  Implementation Agents → Verification Manager → Quality Gate
                              ↓
                    Aggregates all verification results
```

### Pattern 2: Self-Scheduling Check-ins

**Problem in META:** Fixed pipeline steps don't adapt to actual work state.

**Tmux Orchestrator Approach:**
```bash
./schedule_with_note.sh <minutes> "<specific_action>"
```
Agents decide when to check back based on actual progress.

**META Application:**
- Replace rigid verification gates with self-scheduling
- Verification agent runs, schedules follow-up if issues found
- Allows adaptive verification depth

```
Current META:
  Step 8 → [Fixed Build Validation] → Step 9

Proposed (Self-Scheduling):
  Step 8 → [Verification Agent]
              ↓
         Issues found? → Schedule follow-up verification
         Clean? → Proceed to Step 9
```

### Pattern 3: PM as Quality Enforcer

**Problem in META:** Agents can bypass quality standards with "good enough" output.

**Tmux Orchestrator Approach:**
PM role enforces non-negotiable standards:
- Meticulous testing before merging
- Git discipline (30-minute commits)
- Technical debt tracking
- Quality standards cannot be skipped

**META Application:**
- Create "Quality PM" agent that reviews all outputs
- Cannot be bypassed by implementation agents
- Has authority to block progression

```markdown
## Quality PM Agent Responsibilities

1. Review all implementation outputs before DoD
2. Verify scope coverage against PRD
3. Enforce data layer connectivity (no mock data)
4. Validate architecture conformance
5. Cannot be overridden by implementation agents
```

### Pattern 4: Research Escalation Rule

**Problem in META:** Agents can spin on problems without seeking help.

**Tmux Orchestrator Learning:**
> "Suggest web research after 10 minutes of failure (not lazy debugging)"

**META Application:**
- After N verification failures → suggest alternative approach
- After M failed fixes → escalate to architect review
- Embed failure counters in agent prompts

```markdown
## Verification Agent Escalation Rules

- 2 failed verification attempts → document specific failures
- 3 failed verification attempts → suggest architectural review
- 5 failed verification attempts → STOP and request human input
```

### Pattern 5: Git as Atomic Verification Unit

**Problem in META:** Verification can be on uncommitted/unstable code.

**Tmux Orchestrator Rule:**
> "Auto-commit every 30 minutes (never > 1 hour uncommitted)"

**META Application:**
- Require commit before verification gates
- Tag verification states alongside code states
- Use commits as verification checkpoints

```markdown
## Git-Verification Integration

1. Before verification gate → require clean commit
2. After successful verification → tag with verification result
3. On verification failure → preserve commit for debugging
4. Never verify uncommitted code
```

### Pattern 6: Cross-Window Monitoring

**Problem in META:** Agents work in isolation, miss context from related processes.

**Tmux Orchestrator Approach:**
> "Monitor related windows (logs, servers) while coordinating"

**META Application:**
- Verification agents should check logs during verification
- Monitor build output, not just exit codes
- Watch for warnings, not just errors

### Pattern 7: Documentation-First When Stuck

**Problem in META:** Failures don't always capture learnings.

**Tmux Orchestrator Rule:**
> "Enforce doc creation when stuck"

**META Application:**
- On verification failure → require documentation of:
  - What was tried
  - What failed
  - Proposed next steps
- Feeds into `learnings/what-doesnt.md`

---

## Part 3: Proposed META Enhancements

### Enhancement 1: Verification Manager Agent

Create new agent type: `agents/verification-manager.md`

```markdown
# Verification Manager Agent

Inherits: base.md

Coordinates all verification activities across the pipeline.

## Primary Focus

- Aggregate verification results from multiple sources
- Enforce verification standards across all agents
- Schedule follow-up verifications when needed
- Block progression on verification failures

## Cannot Be Bypassed

Implementation agents cannot mark tasks complete without
Verification Manager approval.

## Escalation Authority

After repeated failures:
- 2 failures: Document and retry
- 3 failures: Escalate to architect
- 5 failures: Stop pipeline, request human input
```

### Enhancement 2: Self-Scheduling Verification

Modify pipeline to support adaptive verification:

```
# Current (fixed)
8 | base | auto | - | 10 | Build validation

# Proposed (adaptive)
8 | verification-manager | auto | - | 15 | Verify build. Schedule follow-up if issues. Proceed if clean.
```

### Enhancement 3: Git-Verification Protocol

Add to `agents/base.md`:

```markdown
## Git-Verification Protocol

Before any verification gate:
1. Commit all changes with descriptive message
2. Ensure working tree is clean
3. Tag commit if verification is critical checkpoint

After verification:
1. If passed: Tag with `verified-step-N`
2. If failed: Preserve commit, document failure
3. Never verify uncommitted code
```

### Enhancement 4: Failure Escalation Rules

Add to `agents/orchestrator.md`:

```markdown
## Failure Escalation Protocol

When an agent reports repeated failures:

| Failure Count | Action |
|---------------|--------|
| 1 | Normal retry |
| 2 | Document specific failure, different approach |
| 3 | Suggest web research or architectural review |
| 5 | STOP pipeline, request human input |

Embed in agent prompts:
"If you've tried 3 approaches without success, STOP and document what you've tried. Suggest an alternative strategy or request help."
```

### Enhancement 5: Quality PM Review Step

Add mandatory review step in pipelines:

```
# Before DoD
N-1 | quality-pm | gate | - | 20 | Review all implementation. Verify: scope coverage, no mock data, architecture conformance, test coverage. Cannot be skipped.
N   | base | gate | - | 10 | Final quality gate
```

---

## Part 4: Implementation Plan

### Phase 1: Documentation Updates (Low effort, high value)

| Task | Effort | Impact |
|------|--------|--------|
| Add failure escalation rules to orchestrator.md | Small | High |
| Add git-verification protocol to base.md | Small | High |
| Add research escalation rule to agent prompts | Small | Medium |
| Document cross-window monitoring pattern | Small | Medium |

### Phase 2: New Agent Types (Medium effort)

| Task | Effort | Impact |
|------|--------|--------|
| Create verification-manager.md agent | Medium | High |
| Create quality-pm.md agent | Medium | High |
| Update pipeline templates to include new agents | Medium | High |

### Phase 3: Infrastructure Changes (Higher effort)

| Task | Effort | Impact |
|------|--------|--------|
| Implement self-scheduling verification | Large | High |
| Add git-verification enforcement to quality-gate.sh | Medium | High |
| Create verification aggregation reporting | Medium | Medium |

---

## Part 5: Comparison Summary

| Aspect | Tmux Orchestrator | Current META | Proposed META |
|--------|-------------------|--------------|---------------|
| Communication | Hub-and-spoke | Linear handoff | Hub-and-spoke via Verification Manager |
| Scheduling | Self-scheduling | Fixed pipeline | Adaptive verification |
| Quality enforcement | PM role (non-bypassable) | DoD checklist (bypassable) | Quality PM (non-bypassable) |
| Failure handling | Escalation rules | Retry or fail | Escalation rules with documentation |
| Git discipline | 30-min commits, mandatory | Suggested | Mandatory before verification |
| Learning capture | LEARNINGS.md | what-works/what-doesnt | Same + failure documentation requirement |

---

## Part 6: Key Quotes from Tmux Orchestrator

From LEARNINGS.md:

> "Suggest research after 10 minutes of failure (not lazy debugging)"

> "Always verify ACTUAL error before solving"

> "If 3 approaches fail, change strategy immediately"

> "Timely positive feedback when progress detected"

From CLAUDE.md:

> "Quality standards are non-negotiable"

> "Auto-commit every 30 minutes (never > 1 hour uncommitted)"

> "Tag working versions before major changes"

---

## Appendix: Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `agents/verification-manager.md` | Coordinates all verification |
| `agents/quality-pm.md` | Reviews and enforces quality |

### Modified Files

| File | Changes |
|------|---------|
| `agents/base.md` | Add git-verification protocol |
| `agents/orchestrator.md` | Add failure escalation rules, research escalation |
| `workflows/pipelines/project.pipeline` | Add quality-pm step |
| `workflows/pipelines/feature.pipeline` | Add verification-manager coordination |
| `scripts/quality-gate.sh` | Add git cleanliness check before verification |

---

## Conclusion

Tmux Orchestrator demonstrates that **autonomous agent coordination** can work effectively with minimal infrastructure and maximum documentation. Its patterns for communication, scheduling, and quality enforcement directly address META's verification gaps.

The key paradigm shift: **Treat verification as an autonomous agent responsibility, not a fixed pipeline step.**

This means:
1. Agents own their verification outcomes
2. Verification can self-schedule follow-ups
3. Quality enforcement is a role, not a checklist
4. Failure escalation is systematic, not ad-hoc

Implementing these patterns would transform META from "trust with late verification" to "continuous autonomous verification."
