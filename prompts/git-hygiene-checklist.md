# Git Hygiene Checklist

Use this to prevent "no commits" projects and keep history usable.

## Required

- [ ] `git init` completed
- [ ] `.gitignore` created
- [ ] Initial commit created (project scaffold)
- [ ] Commit after each working milestone
- [ ] Remote added and at least one push completed

## Recommended

- [ ] Use clear commit messages (feat/fix/chore)
- [ ] Tag key milestones (v0.1.0, v0.2.0)
- [ ] Keep `main` green (tests pass before push)

## Verification

```bash
git status
# should be clean at milestones

git log --oneline -n 5
# should show meaningful history
```
