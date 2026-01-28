# Definition of Done Checklist

Use this at the end of a pipeline to verify the project is shippable.

## Required

- [ ] README exists and matches `META/prompts/readme-template.md`
- [ ] CI pipeline exists (e.g., `.github/workflows/ci.yml`)
- [ ] Observability baseline implemented (`META/prompts/observability-checklist.md`)
- [ ] Observability validated (`META/prompts/observability-validation.md`)
- [ ] External service setup documented if applicable (`META/prompts/external-service-setup-checklist.md`)
- [ ] Git history exists with at least one milestone commit (`META/prompts/git-hygiene-checklist.md`)
- [ ] Tests pass for core packages
- [ ] Test execution recorded (`META/prompts/test-execution.md`)
- [ ] OpenAPI validated if `docs/openapi.yaml` exists (`META/prompts/openapi-validation.md`)

## Recommended

- [ ] `.env.example` provided for required env vars
- [ ] Architecture or decisions documented (if non-trivial)
- [ ] Known issues listed in AGENTS.md or README

## Instructions

- Verify each item and report status in `.handoff.md`.
- If something is missing and can be created safely, do it.
- If missing items require user input (credentials, provider setup), list them clearly as TODOs.

## Output format (paste into `.handoff.md`)

```markdown
## Definition of Done Check

- README: [pass/fail] (path)
- CI pipeline: [pass/fail] (path)
- Observability: [pass/fail] (notes)
- External services setup: [pass/fail] (notes)
- Git history: [pass/fail] (summary)
- Tests: [pass/fail] (commands run)
- .env.example: [pass/fail]
- Docs/decisions: [pass/fail]

**Blocking issues:**
- [ ] ...

**Non-blocking issues:**
- [ ] ...
```
