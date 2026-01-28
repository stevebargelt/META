# Git Hygiene Checklist

Prevent "no commits" projects and keep history usable.

## Goal

Ensure the project has a meaningful git history with regular commits and a remote.

## Checks

### Required
- [ ] `git init` completed
- [ ] `.gitignore` created
- [ ] Initial commit created (project scaffold)
- [ ] Commit after each working milestone
- [ ] Remote added and at least one push completed

### Recommended
- [ ] Use clear commit messages (feat/fix/chore)
- [ ] Tag key milestones (v0.1.0, v0.2.0)
- [ ] Keep `main` green (tests pass before push)

## How to Verify

```bash
git status          # should be clean at milestones
git log --oneline -n 5  # should show meaningful history
git remote -v       # should have an origin
```
