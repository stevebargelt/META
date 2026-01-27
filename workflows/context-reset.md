# Context Reset Workflow

How to handle conversation context limits and long sessions.

## When Context Resets Happen

**Common scenarios:**
- Hit model's token limit (128k, 200k, etc.)
- Session ends and you resume later
- Switch to different model mid-project
- Need to bring in different agent
- Context gets cluttered with failed attempts

**Signals you're approaching limit:**
- Responses get slower
- Model starts "forgetting" earlier context
- Warnings about context size
- Need to trim conversation

## Before You Reset

### 1. Capture Current State

Write `.handoff.md` in the project root using the unified template at `prompts/handoff-template.md` (type: `context-reset`). This captures working state, in-progress work, decisions, key files, and the single next step.

### 2. Commit Your Work

```bash
git add .
git commit -m "wip: auth system progress

- Implemented login/logout
- Added JWT middleware
- Refresh token rotation in progress

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

Even if not perfect, commit working state.

### 3. Tag Important Files

Note which files are most relevant:

```markdown
## Key Files

Primary focus:
- src/auth/jwt.js — Token generation logic
- src/middleware/auth.js — Auth middleware

Supporting:
- src/routes/auth.js — Auth endpoints
- prisma/schema.prisma — User model

Can ignore:
- Most other files in src/
```

## Starting Fresh Session

Read `.handoff.md` first. It contains project context, state, key files, and the next step. Then load files on demand — don't dump everything at once.

### Progressive Context Loading

Don't dump everything at once:

1. **Start with summary** (above)
2. **AI asks** for specific files if needed
3. **Provide files** on demand
4. **Reference patterns** from META rather than explaining

## Mid-Session Context Management

### Keep Conversation Focused

**Do:**
- ✅ Start new conversation for new feature
- ✅ Create intermediate summary docs
- ✅ Reference files by path, read on demand
- ✅ Use patterns from META/patterns/

**Don't:**
- ❌ Keep same conversation for entire project
- ❌ Paste full files repeatedly
- ❌ Re-explain same concepts multiple times
- ❌ Accumulate failed attempts in context

### Intermediate Summaries

When conversation gets long but not done:

```markdown
## Progress Update

**Starting point:** Empty auth system
**Current state:** Login/logout working, refresh tokens in progress
**Remaining:** Token rotation, tests, concurrent login handling

**Key decisions this session:**
- Chose JWT over sessions (stateless scaling)
- 15-min access tokens, 7-day refresh tokens
- Refresh tokens stored in DB (allows revocation)

**Continue with:** Implementing token rotation logic
```

Then start fresh conversation with this summary.

## Tools for Context Management

### 1. Session Notes File

Keep `SESSION_NOTES.md` in project root:

```markdown
# Session Notes

## 2026-01-26
- Implemented auth system
- Next: Add tests

## 2026-01-20
- Set up project structure
- Created database schema
```

Update after each session.

### 2. Architecture Documentation

For complex projects, maintain `ARCHITECTURE.md`:

```markdown
# MycoGeek Architecture

## System Overview
[High-level description]

## Key Components
[What does what]

## Important Decisions
[What choices were made and why]
```

Reference this in context resets.

### 3. Git Commits

Use commits as session checkpoints:

```bash
# End of session
git add .
git commit -m "wip: session checkpoint

Progress:
- [What's done]
- [What's in progress]

Next: [What to do next]
"
```

Git log becomes your session history.

### 4. Scratchpad Documents

Create temporary docs for complex context:

```markdown
# Current Implementation Plan

## Refresh Token Rotation

1. When refresh token used:
   - Validate current refresh token
   - Generate new access + refresh tokens
   - Invalidate old refresh token
   - Return both new tokens

2. Database changes:
   - Add `used_at` timestamp to refresh_tokens table
   - Add unique constraint on token value

3. Implementation:
   - src/auth/refresh.js — Core logic
   - Update src/routes/auth.js — POST /auth/refresh endpoint
```

Reference in next session, then delete when done.

## Model Switching with Context Reset

When switching models, include model-specific notes:

```markdown
# Switching to GPT-4 for debugging

## Project
MycoGeek API (mushroom cultivation tracker)

## Problem
Environmental readings returning incorrect averages

## What We Know
- Query seems correct (src/routes/analytics.js:45)
- Database has data (verified manually)
- Response format looks right but values wrong

## Files
- src/routes/analytics.js (the endpoint)
- src/models/environmental-reading.js (model)

## Try Next
Add logging to see what raw DB query returns
```

See `workflows/model-switching.md` for more on model transitions.

## Context Reset Anti-Patterns

### Don't

- ❌ Start completely fresh without any summary
- ❌ Paste entire conversation history
- ❌ Re-explain everything in first message
- ❌ Assume AI remembers anything from before
- ❌ Wait until context is full to reset

### Do

- ✅ Summarize what's been done
- ✅ Commit current state first
- ✅ Provide focused context for next task
- ✅ Reference files, let AI ask for contents
- ✅ Reset proactively in Yellow zone (see `workflows/context-budget.md`)

## Measuring Effectiveness

Good context reset:
- ✅ New session picks up smoothly
- ✅ No repeated explanations needed
- ✅ Relevant context immediately available
- ✅ Clear what to do next

Bad context reset:
- ❌ AI confused about project state
- ❌ Have to re-explain decisions
- ❌ Lost track of what's done
- ❌ Don't know where to continue

## Quick Reference

### Before Reset Checklist

- [ ] Write `.handoff.md` (see `prompts/handoff-template.md`)
- [ ] Commit current work
- [ ] Update project AGENTS.md if needed

### Fresh Session

1. Read `.handoff.md`
2. Load key files on demand
3. Continue from Next Step

### During Session

- Create intermediate summaries when conversation long
- Reference files by path
- Use patterns from META
- Commit frequently

### Tools

- SESSION_NOTES.md — Session history
- ARCHITECTURE.md — Design context
- Git commits — State checkpoints
- Scratchpad docs — Complex temporary context
