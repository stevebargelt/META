# Handoff Template

Unified format for all handoffs: context resets, model switches, and agent handoffs. One file (`.handoff.md`) in the project root, always overwritten with current state.

## Rules

- `.handoff.md` lives in project root, added to `.gitignore`
- Always overwritten (current state, not history — history is in git)
- Outgoing agent writes it; incoming agent reads it first
- Keep it short — this is a launchpad, not a journal

## Template

```markdown
# Handoff

## Meta
- **Type:** context-reset | model-switch | agent-handoff
- **From:** [agent or model name]
- **To:** [agent or model name, or "same" for context reset]
- **Timestamp:** [ISO 8601]
- **Reason:** [one sentence]

## Project
[One sentence description]
**Stack:** [tech stack]
**AGENTS.md:** [path]

## State
**Working:** [what functions correctly]
**In Progress:** [what's partially done, with file:line references]

## Decisions
1. [Key decision with brief rationale]
2. [Another decision]

## Key Files
- `path/to/file.js` — [one-line explanation]
- `path/to/other.js` — [one-line explanation]
(3-7 files max)

## Next Step
[Single specific action. Not a list — one thing.]

## Context Budget
- **What was loaded:** [files/docs read this session]
- **What should NOT be reloaded:** [things that were irrelevant]
```

## Usage by Type

### Context Reset (type: `context-reset`)
From/To are the same agent or model. Write `.handoff.md` before resetting. New session reads it first, then loads key files on demand.

### Model Switch (type: `model-switch`)
From is outgoing model, To is incoming model. Include model-specific notes in Reason if relevant (e.g., "switching to GPT-4 for debugging stack traces").

### Agent Handoff (type: `agent-handoff`)
From is outgoing agent, To is incoming agent. Next Step should be the specific task for the incoming agent.

## Parallel Workstreams

When running parallel agents, use per-stream files:
- `.handoff-api.md`
- `.handoff-frontend.md`
- `.handoff-database.md`

Consolidate into `.handoff.md` at sync points.
