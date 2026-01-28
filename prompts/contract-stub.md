# Contract Stub Prompt (Prefer OpenAPI)

Create a minimal API/UI contract before parallelizing workstreams.

## Goal

Define shared contracts so parallel teams can build independently without integration surprises.

## Steps

### 1. Choose contract type (preference order)

1. **OpenAPI spec** (required when parallelizing): `docs/openapi.yaml`
2. **Route list** (only if OpenAPI is explicitly not feasible): `docs/api-routes.md`
3. **Shared types/interfaces**: `src/shared/contracts.ts` (or similar)

### 2. Create minimum output

**OpenAPI (preferred):** Create `docs/openapi.yaml` with title, version, auth scheme, base paths, endpoints with request/response schemas, error response shape.

**Route list (if OpenAPI is too heavy):** Create `docs/api-routes.md` with method+path, auth requirements, request body fields, response shape, error codes.

**Shared types:** Create a shared types file with request/response interfaces, error envelope type, shared enums.

### 3. Follow these rules

- Keep it minimal and accurate to the current plan.
- Do not guess complex schemas; stub with placeholders if needed.
- If parallel workstreams exist, OpenAPI is required unless you document a clear exception.
- If you create `docs/openapi.yaml`, ensure the pipeline includes a validation step.

## Output Template

```markdown
## Contract Stub

**Type:** [OpenAPI | Route list | Shared types]
**Files:**
- [path]

**Notes:**
- [Key assumptions]
- [Open questions]
```
