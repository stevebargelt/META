# Project Kickoff Prompt

Human-in-the-loop kickoff that minimizes manual setup.

## Goal

Gather project requirements, write AGENTS.md, and hand off to Product Manager for PRD creation.

## Steps

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

## How to Verify

- AGENTS.md exists with: purpose, stack, key commands, current focus
- CLAUDE.md is a symlink to AGENTS.md
- Default to feature-first structure
- PRD is written by Product Manager agent using `META/prompts/prd-template.md`
- If answers are missing, ask follow-ups before writing files

## Output Template

After AGENTS.md is created, hand off with:
- The answers to kickoff questions
- Project path
- Any open questions

After PRD is created, hand off with:
- `AGENTS.md` + `docs/PRD.md`
- Any open questions
- Preference for parallel teams (default: enable where possible)
