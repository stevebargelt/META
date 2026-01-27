# Project Kickoff Prompt

Human-in-the-loop kickoff that minimizes manual setup.

## Usage

```
Start a project kickoff using META/prompts/kickoff.md
Project path: [path]
Tool: [codex | claude | other]
```

## Kickoff Flow

1. Ask the questions below (keep it concise).
2. Summarize decisions.
3. Write `AGENTS.md` from the answers and ensure `CLAUDE.md` is a symlink to it.
4. Hand off to Product Manager agent to write `docs/PRD.md`.
5. After PRD is complete, hand off to Orchestrator to start building.

## Questions (Ask, then proceed)

1. What are we building (one sentence)?
2. Who is it for?
3. Must-have outcomes (3–5)?
4. Non-goals (what is out of scope)?
5. Success metric(s)?
6. Deadline or milestone?
7. Tech stack preferences/constraints?
8. Data/storage needs?
9. External integrations?
10. Quality level: prototype or production?

## Output Requirements

- AGENTS.md must include: purpose, stack, key commands, current focus
- Default to feature-first structure
- PRD is written by Product Manager agent using `META/prompts/prd-template.md`
- If answers are missing, ask follow-ups before writing files

## Handoff to Product Manager

After AGENTS.md is created, hand off:
- The answers to kickoff questions
- Project path
- Any open questions

Expected output:
- `docs/PRD.md` (one page)

## Handoff to Orchestrator

After PRD is created, hand off:
- `AGENTS.md` + `docs/PRD.md`
- Any open questions
- Preference for parallel teams (default: enable where possible)

Expected output:
- Orchestration plan
- First build tasks started (or clear next prompts if approvals needed)
