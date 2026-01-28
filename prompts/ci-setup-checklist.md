# CI Setup Checklist

Verify CI pipeline exists and enforces quality gates.

## Goal

Ensure the project has a working CI pipeline with lint, test, coverage, and security gates.

## Checks

### Setup
- [ ] CI pipeline exists (`.github/workflows/ci.yml` or equivalent)
- [ ] Pipeline runs on push to `main` and on pull requests
- [ ] Pipeline template: `META/patterns/deployment/ci-pipeline-node.md` (Node.js)

### Gates Present
- [ ] Lint step (ESLint or equivalent)
- [ ] Test step with coverage reporting
- [ ] Coverage threshold configured (Jest config or CI step)
- [ ] Build step (if applicable)
- [ ] Security audit (`npm audit` or Dependabot enabled)
- [ ] Type check (TypeScript projects only)

### Thresholds Configured
- [ ] Coverage: statements >= 80% (see `META/patterns/deployment/quality-gates.md`)
- [ ] Coverage: branches >= 70%
- [ ] Coverage: functions >= 80%
- [ ] Security: no critical/high vulnerabilities

### Branch Protection
- [ ] `main` branch protected
- [ ] Status checks required before merge
- [ ] CI workflow selected as required check
- [ ] Branch must be up to date before merge

## How to Verify

- [ ] Push a commit — CI runs and passes
- [ ] Open a PR — CI runs on the PR
- [ ] Intentionally break a test — CI fails
- [ ] Drop coverage below threshold — CI fails
