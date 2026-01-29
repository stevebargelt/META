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

Write `.meta/handoff.md` in the project root using the unified template at `prompts/handoff-template.md` (type: `context-reset`). This captures working state, in-progress work, decisions, key files, and the single next step.

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

Read `.meta/handoff.md` first. It contains project context, state, key files, and the next step. Then load files on demand — don't dump everything at once.

### Progressive Context Loading

Don't dump everything at once:

1. **Start with summary** (above)
2. **AI asks** for specific files if needed
3. **Provide files** on demand
4. **Reference patterns** from META rather than explaining

## Model Switching

If switching models mid-project, include the model name and reason in `.meta/handoff.md`. Keep the same handoff format — it works across all models.

## Quick Reference

### Before Reset Checklist

- [ ] Write `.meta/handoff.md` (see `prompts/handoff-template.md`)
- [ ] Commit current work
- [ ] Update project AGENTS.md if needed

### Fresh Session

1. Read `.meta/handoff.md`
2. Load key files on demand
3. Continue from Next Step

### During Session

- Create intermediate summaries when conversation long
- Reference files by path
- Use patterns from META
- Commit frequently

### Tools

- `.meta/handoff.md` — State capture (see `prompts/handoff-template.md`)
- Git commits — State checkpoints
- docs/ARCHITECTURE.md — Design context
