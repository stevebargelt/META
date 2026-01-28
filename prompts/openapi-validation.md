# OpenAPI Validation Prompt

Use this when `docs/openapi.yaml` exists.

## Goal

Validate the OpenAPI spec for syntax/structure issues and report results.

## Steps

1) Check for `docs/openapi.yaml`
   - If missing, note "no OpenAPI spec" in `.handoff.md` and exit.

2) Validate the spec:

Preferred:
```bash
npx @redocly/cli lint docs/openapi.yaml
```

Fallback if Redocly fails:
```bash
npx @apidevtools/swagger-cli validate docs/openapi.yaml
```

3) Update `.handoff.md` with results

Include:
- command(s) run
- pass/fail
- key errors (if any)

## Output template (paste into `.handoff.md`)

```markdown
## OpenAPI Validation

- Spec: docs/openapi.yaml
- Result: [pass/fail/skipped]
- Command: [command used]
- Notes: [errors or "none"]
```
