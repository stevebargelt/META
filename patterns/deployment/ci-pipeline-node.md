# CI Pipeline: Node.js (GitHub Actions)

Standard CI pipeline for Node.js projects. Copy, configure the variables at the top, commit.

## Pipeline

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '20'           # Adjust per project
  COVERAGE_THRESHOLD: 80       # Minimum coverage %
  WORKING_DIRECTORY: '.'       # Monorepo? Set to subdir

jobs:
  ci:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIRECTORY }}

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: ${{ env.WORKING_DIRECTORY }}/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run typecheck
        # Remove if not using TypeScript

      - name: Unit tests
        run: npm test -- --coverage --coverageReporters=text --coverageReporters=lcov

      - name: Coverage gate
        run: |
          COVERAGE=$(npx coverage-summary total statements)
          echo "Coverage: ${COVERAGE}%"
          if (( $(echo "$COVERAGE < ${{ env.COVERAGE_THRESHOLD }}" | bc -l) )); then
            echo "::error::Coverage ${COVERAGE}% is below threshold ${{ env.COVERAGE_THRESHOLD }}%"
            exit 1
          fi
        # Alternative: use jest's coverageThreshold in jest.config.js (simpler)

      - name: Build
        run: npm run build
        # Remove if no build step
```

## Simpler Coverage Gate (Preferred)

Instead of the shell-based gate above, configure Jest directly:

```jsonc
// jest.config.js (or package.json "jest" key)
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

Then the `npm test -- --coverage` step fails automatically if thresholds aren't met. Remove the separate "Coverage gate" step.

## Required package.json Scripts

```jsonc
{
  "scripts": {
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",    // TypeScript only
    "test": "jest",
    "build": "tsc"                  // or your build command
  }
}
```

## Adapting This Pipeline

**No TypeScript?** Remove the `typecheck` step.

**Monorepo?** Set `WORKING_DIRECTORY` to the package path.

**Integration tests needing a database?** Add a service container:

```yaml
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

**Multiple Node versions?** Use a matrix:

```yaml
    strategy:
      matrix:
        node-version: [18, 20, 22]
```

## What This Pipeline Enforces

| Gate | Fails when |
|------|-----------|
| Lint | ESLint errors (not warnings) |
| Type check | TypeScript errors |
| Tests | Any test fails |
| Coverage | Below configured threshold |
| Build | Build errors |

Every PR must pass all gates before merge. Configure branch protection in GitHub to require this workflow.
