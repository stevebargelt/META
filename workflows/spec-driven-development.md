# Spec-Driven Development (Boundary-Only)

Use SDD only at cross-team boundaries to enable parallel work without slowing down delivery.

## Where SDD is Required

- API contracts (OpenAPI/GraphQL/JSON Schema)
- Event schemas (pub/sub payloads)
- Module/remote interfaces (e.g., MF remotes)
- Critical workflows (auth, payments, onboarding)

Skip SDD for internal helpers, early UI drafts, or single-owner code.

## Minimal SDD Checklist

1. **Spec first**
   - Define the contract (schema, types, interface)
   - Version it (even if just a semver in a file header)

2. **Stub the boundary**
   - Provide a mock implementation or sample payloads
   - Ensure consumers can build against it

3. **Contract tests**
   - Add a simple test that validates the contract shape
   - Run in CI on every merge

4. **Integration gate**
   - Block merge if contract tests fail
   - Review any contract change with affected owners

## Outputs (Minimum)

- Contract spec file(s)
- Mock payloads or stub
- Contract test(s)
- CI step that runs contract tests

## Anti-Patterns

- Spec everything (slows down parallel work)
- Spec after implementation (defeats the point)
- Change contracts without versioning
- No contract tests (specs drift)

