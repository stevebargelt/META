# Definition of Done Checklist

Final verification that the project is shippable.

## Goal

Confirm all quality gates pass before marking a pipeline complete.

## Checks

### Required
- [ ] README exists and matches `META/prompts/readme-template.md`
- [ ] CI pipeline exists (e.g., `.github/workflows/ci.yml`)
- [ ] Observability baseline implemented (`META/prompts/observability-checklist.md`)
- [ ] External service setup documented if applicable (`META/prompts/external-service-setup-checklist.md`)
- [ ] Git history exists with at least one milestone commit (`META/prompts/git-hygiene-checklist.md`)
- [ ] Tests pass for core packages
- [ ] OpenAPI validated if `docs/openapi.yaml` exists

### Recommended
- [ ] `.env.example` provided for required env vars
- [ ] Architecture or decisions documented (if non-trivial)
- [ ] Known issues listed in AGENTS.md or README

## How to Verify

Run `META/scripts/quality-gate.sh --project .` and confirm all checks pass. Then verify each checklist item manually.

## Output Template

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
