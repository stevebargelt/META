# Test Execution Prompt

Use this before final approval to ensure tests are actually run.

## Goal

Run the project’s real test commands and record results.

## Steps

1) Identify test commands from `AGENTS.md` or `package.json`.
2) Run the primary test commands for each package (server/client if applicable).
3) Record pass/fail and any failures.

## Output Template (paste into .handoff.md)

```markdown
## Test Execution

- Command(s) run:
  - [command]
  - [command]
- Result: [pass/fail]
- Notes: [failures or "none"]
```

If tests fail, list blockers and suggested fixes.
