# Preflight Checklist

Run this before heavy implementation to avoid late blockers.

## Checks

### Project Basics
- [ ] Project directory exists and is writable
- [ ] `AGENTS.md` present and readable
- [ ] `README.md` exists (or note missing)
- [ ] `.env.example` exists (or note missing)

### Tooling
- [ ] `node` available
- [ ] `npm` available
- [ ] `git` available

### Supabase (if project uses it)
Trigger if any are true: `supabase/` directory exists, `.env.example` contains SUPABASE, or docs mention Supabase.

- [ ] `supabase` CLI available
- [ ] `docker` available (Supabase local)
- [ ] `supabase start` instructions present in `docs/SETUP.md`

### Environment
- [ ] `.env` exists (or explicitly note missing)
- [ ] Required env vars listed in `.env.example`

## How to Run

Use shell commands to verify:

```bash
command -v node
command -v npm
command -v git
```

For Supabase:

```bash
command -v supabase
command -v docker
```

## Output Template (paste into .handoff.md)

```markdown
## Preflight Check

- Project writable: [pass/fail]
- README: [pass/fail]
- .env.example: [pass/fail]
- node/npm/git: [pass/fail]
- Supabase CLI: [pass/fail/not-applicable]
- Docker: [pass/fail/not-applicable]
- .env present: [pass/fail]

**Missing or blocking items:**
- [ ] ...

**Notes:**
- ...
```
