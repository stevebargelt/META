# Quality Gates

Standard gates every project must pass. These are non-negotiable — configure thresholds per project, but every gate must exist.

## Required Gates

| Gate | What it checks | Default threshold | Where enforced |
|------|---------------|-------------------|----------------|
| Lint | Code style, common errors | Zero errors | CI pipeline |
| Tests | All tests pass | 100% pass rate | CI pipeline |
| Coverage | Code covered by tests | 80% statements | CI pipeline (Jest config or CI step) |
| Build | Code compiles/bundles | Builds without error | CI pipeline |
| Security | Known vulnerabilities | No critical/high | `npm audit` or Dependabot |

## Optional Gates (Add When Relevant)

| Gate | What it checks | When to add |
|------|---------------|-------------|
| Type check | TypeScript errors | TypeScript projects |
| Bundle size | JS bundle too large | Frontend apps |
| Integration tests | End-to-end flows | APIs with databases |
| License check | Dependency licenses | Production/commercial projects |

## Coverage Thresholds

Start here, adjust per project:

| Metric | Minimum | Notes |
|--------|---------|-------|
| Statements | 80% | Overall code execution |
| Branches | 70% | Lower — conditional paths are hard to exhaust |
| Functions | 80% | Every function should be called by some test |
| Lines | 80% | Same as statements in most cases |

**When to adjust:**

- **Raise** thresholds when stabilizing a mature project
- **Lower** branch coverage for config-heavy code (lots of conditionals that are environment-specific)
- **Never** set thresholds to 0 or remove them to "fix" CI

## Configuring in Jest

```jsonc
// jest.config.js
{
  "coverageThreshold": {
    "global": {
      "statements": 80,
      "branches": 70,
      "functions": 80,
      "lines": 80
    }
  }
}
```

## Branch Protection (GitHub)

After CI pipeline is set up, enable branch protection on `main`:

1. Settings > Branches > Add rule for `main`
2. Enable "Require status checks to pass before merging"
3. Select the CI workflow
4. Enable "Require branches to be up to date before merging"
5. Optionally: "Require approvals" (1 reviewer for solo projects is fine if using reviewer agent)

## Security Gate

Add to CI pipeline or run separately:

```yaml
      - name: Security audit
        run: npm audit --audit-level=high
```

Or use GitHub's Dependabot (zero-config, runs automatically).

## When Gates Fail

**Lint fails:** Fix the lint errors. Don't disable rules to make CI pass.

**Tests fail:** Fix the test or the code. Don't skip tests.

**Coverage drops:** You added code without tests. Write tests for the new code.

**Build fails:** Fix the build error. Don't merge broken builds.

**Security audit fails:** Update the vulnerable dependency. If no fix exists, document the risk and suppress with `npm audit fix` or `.nsprc`.

The point of gates is to catch problems before they reach `main`. Bypassing them defeats the purpose.
