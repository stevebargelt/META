# Plan: `meta` CLI — Tmux-Based Agent Orchestration

## Summary

Add a `meta` CLI tool that automates multi-agent workflows by launching AI coding CLIs (`claude`, `codex`) in tmux windows, sequencing them through pipeline definitions, and pausing at quality gates for user approval.

---

## New Files

### Pipeline Definition Format

Simple line-based format (no YAML parser needed). Extension: `.pipeline`

```
name: feature
description: Full feature development flow
timeout_min: 60

# NUM | AGENT | CLI | GATE | PARALLEL_GROUP | TIMEOUT_MIN | PROMPT
1 | product-manager | claude | auto | - | 30 | Create PRD from task in .handoff.md...
2 | architect       | claude | gate | - | -  | Design architecture from PRD...
3 | tester          | claude | auto | - | -  | Create test plan and skeleton tests...
4 | base            | claude | auto | - | -  | Implement feature, make tests pass...
5 | reviewer        | claude | gate | - | -  | Review all changes for quality...
6 | documenter      | claude | auto | - | -  | Update documentation...
```

Parallel steps share a `PARALLEL_GROUP` value. Pipeline waits for all in group before proceeding.
Notes:
- `timeout_min` sets the pipeline default; `TIMEOUT_MIN` overrides per step (`-` uses default).
- Escape literal pipes in `PROMPT` as `\|`.
- If parallelism is possible, `PARALLEL_GROUP` must be set; otherwise the orchestrator must explain why in `.handoff.md`.
- If parallelism is planned, add a contract stub step first (use `META/prompts/contract-stub.md`). OpenAPI is required unless explicitly justified.
- If `docs/openapi.yaml` exists, add a validation step using `META/prompts/openapi-validation.md`.

### File List

| File | Purpose | ~Lines |
|------|---------|--------|
| `scripts/meta` | Main CLI entry point, arg parsing, orchestration loop | 200 |
| `scripts/meta-lib/workflow.sh` | Parse `.pipeline` files | 40 |
| `scripts/meta-lib/tmux.sh` | Tmux session/window management, completion detection | 60 |
| `scripts/meta-lib/handoff.sh` | Write initial handoff, merge parallel handoffs | 50 |
| `scripts/meta-lib/agent-run.sh` | Build CLI invocation commands for claude/codex | 50 |
| `scripts/meta-lib/gate.sh` | Quality gate prompts in control window | 40 |
| `scripts/meta-lib/status.sh` | State file management, tmux status bar | 30 |
| `workflows/pipelines/feature.pipeline` | Feature development pipeline | 10 |
| `workflows/pipelines/bugfix.pipeline` | Bug fix pipeline | 6 |
| `workflows/pipelines/refactor.pipeline` | Refactor pipeline | 8 |

Total: ~500 lines of bash.

---

## CLI Interface

```bash
meta run <pipeline> --project <path> --task "description" [--cli claude|codex] [--run-id <id>] [--unsafe] [--dry-run]
meta status [--project <path>]        # Show pipeline progress
meta resume [--project <path>]        # Resume from last completed step
meta abort [--project <path>]         # Kill pipeline, clean up
meta list                             # List available pipelines
meta doctor                           # Check tmux + CLI binaries + pipeline validity
```

---

## How It Works

If `--run-id` is not provided, generate one (timestamp + short random suffix) and use it for the tmux session name and `.meta/` paths.

### Tmux Layout

- **Session:** `meta-<project-basename>-<run_id>` (e.g., `meta-my-app-2026-01-27T10-00-00Z-8f3a`)
- **Window 0:** `control` — orchestration status, quality gate prompts
- **Window N:** `step-N-<agent>` — one per pipeline step

User can switch between windows freely (`Ctrl-b <N>`) to watch any agent work.

### Preflight (meta doctor)

- Verify `tmux` is installed and usable
- Verify `claude`/`codex` binaries exist and required flags are supported
- Validate pipeline files parse correctly (including escaped `\|`)

### Agent Invocation

Each agent runs in its own tmux window. By default, run in safe mode. If `--unsafe` is passed, append `--dangerously-skip-permissions` to the `claude` invocation only. The command:

```bash
# claude
cd "$PROJECT" && claude -p "$PROMPT" \
  --system-prompt "$(cat agents/<agent>.md)" \
  --allowedTools "Bash Edit Read Write Glob Grep" ; \
  printf "%s" "$?" > .meta/steps/<run_id>/step-N.exit

# codex
cd "$PROJECT" && codex exec "$PROMPT" ; \
  printf "%s" "$?" > .meta/steps/<run_id>/step-N.exit
```

The prompt includes:
1. Agent role and agent definition file path
2. Instruction to read `.handoff.md` first
3. The step's specific task
4. Instruction to update `.handoff.md` when done

### Completion Detection

Sentinel file approach: each step wrapper writes `.meta/steps/<run_id>/step-N.exit` with the CLI exit code. The orchestrator polls for this file every 5 seconds and treats exit code `0` as success, anything else as failure. Timeout default: 60 minutes per step (configurable).

### Handoff Flow

1. `meta run` writes initial `.handoff.md` with user's task
2. Each agent reads `.handoff.md`, does work, updates `.handoff.md`
3. For parallel steps: each writes `.handoff-step-N.md`, orchestrator merges at sync point into `.handoff.md` using deterministic, sectioned append:
   - Adds a header `## Parallel Step <N> (<agent>) — <timestamp>` for each step
   - Appends the full contents of `.handoff-step-N.md` under that header
   - Keeps original `.handoff-step-N.md` files for traceability
4. Quality gates: orchestrator pauses, user reviews in control window, approves/retries/aborts

### State Persistence

Directory: `$PROJECT/.meta/`

File: `$PROJECT/.meta/state.<run_id>`

```
pipeline=feature
session=meta-my-app-2026-01-27T10-00-00Z-8f3a
started=2026-01-27T10:00:00Z
run_id=2026-01-27T10-00-00Z-8f3a
current_step=3
step_1=done
step_2=done
step_3=running
```

Enables `meta resume` after disconnection or abort (default to most recent `state.*` unless `--run-id` is provided).

### Quality Gates

When a step has `gate`, after completion:
1. Control window shows: "QUALITY GATE after step N (agent)"
2. Prompts: `Approve? [y/n/r(retry)/s(skip)]`
3. `y` continues, `r` re-runs the step, `s` skips the step, `n` aborts

### Error Handling

- Step timeout → pause, ask user: retry/skip/abort
- CLI crash or non-zero exit → same prompt
- Main script traps `SIGINT`/`SIGTERM` to persist state before exit
- `meta abort` → kill tmux session, clean up `.meta/steps/<run_id>/` and `.meta/state.<run_id>`
- `meta resume` → read `.meta/state.<run_id>` (default to latest), continue from last completed step

---

## Files to Modify

| File | Change |
|------|--------|
| `workflows/multi-agent.md` | Add section: "Automated Execution" referencing `scripts/meta` and `workflows/pipelines/` |
| `scripts/README.md` | Add `meta` documentation |
| `README.md` | Add `meta` to scripts section |
| `IMPROVEMENTS.md` | Mark tooling item as in-progress/complete |

No changes needed to agent definition files — they're read as-is by the CLI.

---

## Implementation Order

1. `scripts/meta-lib/` directory and all library files (workflow, tmux, handoff, agent-run, gate, status)
2. `scripts/meta` main entry point
3. `workflows/pipelines/feature.pipeline` (first pipeline, validates the format)
4. `workflows/pipelines/bugfix.pipeline` and `refactor.pipeline`
5. Update `scripts/README.md`, `workflows/multi-agent.md`, `README.md`
6. Update `IMPROVEMENTS.md`

---

## End-to-End Example

```bash
$ meta run feature --project ~/code/my-app --task "Add JWT authentication with refresh tokens"

# Creates tmux session "meta-my-app-<run_id>"
# Window 0: control (shows progress)
#
# Step 1: product-manager → window "step-1-product-manager"
#   claude runs, creates docs/PRD.md, updates .handoff.md
#   Completes → orchestrator proceeds
#
# Step 2: architect → window "step-2-architect"
#   claude runs, creates ARCHITECTURE.md, updates .handoff.md
#   Completes → QUALITY GATE in control window
#   User reviews, types "y"
#
# Step 3: tester → creates test plan + skeleton tests
# Step 4: base → implements feature, passes tests
# Step 5: reviewer → QUALITY GATE, user approves
# Step 6: documenter → updates docs
#
# Control window: "Pipeline complete!"
```

---

## Verification

- Run `meta doctor` — verify tmux/CLI availability and pipeline parsing
- Run `meta list` — shows available pipelines
- Run `meta run feature --project /tmp/test-project --task "test" --dry-run` — prints what would happen without launching
- Run full pipeline on a test project — verify each tmux window launches, sentinel files created, gates pause correctly
- Test `meta abort` — verify cleanup of tmux session and temp files
- Test `meta resume` — verify continuation from last completed step
- Verify `.handoff.md` is updated between each step
