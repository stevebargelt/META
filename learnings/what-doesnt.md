# What Doesn't Work

Anti-patterns and approaches to avoid, learned from real experience.

**Last Updated:** 2026-01-28

---

## Agent Usage Anti-Patterns

### Parallelizable Work Left Sequential

**What:** Building pipelines without `PARALLEL_GROUP`, even when steps are independent
**Why it fails:** Slower delivery, no concurrency benefit from multi-agent setup
**Example:** All steps in the pipeline have `PARALLEL_GROUP` set to `-`
**Instead:** Group independent steps with a shared `PARALLEL_GROUP` label
**Source:** test-app (2026-01)

### Inventing New Agent Names

**What:** Orchestrator generates agent names that don't exist in `META/agents/`
**Why it fails:** Pipeline crashes when agent definition file is missing
**Example:** `test-automation-specialist` in generated pipeline
**Instead:** Restrict to existing agent names only
**Source:** test-app (2026-01)

---

## Development Workflow

### Building Without Commits

**What:** Completing a project with zero local commits or pushes
**Why it fails:** No history, no rollback points, no visibility into progress
**Example:** A full build with no git commits
**Instead:** Commit early/often and push at stable milestones
**Source:** test-app (2026-01)

### Running Tests in Read-Only Sandboxes

**What:** Running test suites in a sandbox that blocks temp dirs or node_modules writes
**Why it fails:** Tools like Vitest create temp files; tests crash on EPERM
**Example:** `EPERM: operation not permitted, mkdir ... node_modules/.vite-temp`
**Instead:** Use workspace-write or allow temp paths for test runs
**Source:** test-app (2026-01)

---

## Quality Practices

### Ignoring Observability Requirements

**What:** Skipping logging/traceability even when explicitly requested
**Why it fails:** Hard to debug, no audit trail, lower ops confidence
**Example:** App shipped without baseline tracing/logging
**Instead:** Implement observability in the base API stack (correlation IDs, structured logs, tracing hooks)
**Source:** test-app (2026-01), test-app-2 (2026-01)

### Missing OpenAPI Contract Stub

**What:** Parallel work begins without an OpenAPI (or equivalent) contract stub
**Why it fails:** Teams diverge, unclear expectations, integration friction later
**Example:** No `docs/openapi.yaml` despite preference and parallelization planning
**Instead:** Create a minimal OpenAPI spec before parallel work starts
**Source:** test-app-2 (2026-01)

---

## Documentation

### Skipping README for New Project

**What:** Shipping a project without a `README.md`
**Why it fails:** No onboarding path, unclear run steps, unclear scope
**Example:** App delivered with no README
**Instead:** Require a minimal README (run instructions, env vars, scripts)
**Source:** test-app (2026-01)

### Missing External Service Setup Steps

**What:** Relying on external services without setup instructions or bootstrap files
**Why it fails:** Users cannot run or validate the app
**Example:** Supabase required but no schema/setup steps provided
**Instead:** Provide setup docs and a bootstrap path (SQL, migrations, or CLI steps)
**Source:** test-app (2026-01)

### Late Integration Validation

**What:** Waiting until the final DoD step to verify that parallel workstreams compose correctly
**Why it fails:** Blocking issues found late require significant rework; root package.json missing, TS errors across workspaces, config mismatches
**Example:** Step 15 found root package.json missing, TypeScript errors in test files, Vite proxy pointing to wrong port
**Instead:** Add intermediate build validation after parallel merges (`npm run build && npm test` at workspace root before polish/review stages)
**Source:** test-app-5 (2026-01)

### No CI/CD Pipeline

**What:** Shipping a project without any CI/CD automation
**Why it fails:** No repeatable build/test/deploy path, quality gates ignored
**Example:** Manual-only build with no CI workflows
**Instead:** Add at least one CI pipeline for lint/test/build
**Source:** test-app (2026-01)

### Missing Root .gitignore

**What:** Subdirectories have their own .gitignore but root does not
**Why it fails:** node_modules, .env, build artifacts, IDE files can be committed accidentally
**Example:** test-app-5 shipped with no root .gitignore despite monorepo structure
**Instead:** Scaffold .gitignore on project init; quality gate checks for it
**Source:** test-app-5 (2026-01)

---

---

## Adding to This Document

When you discover something that doesn't work:

1. **Verify it's actually a problem** — Did it fail once or repeatedly?
2. **Document specifics** — What exactly went wrong?
3. **Explain why** — What made this ineffective?
4. **Provide alternative** — What should you do instead?
5. **Add source** — Which project taught you this?

**Format:**
```markdown
### [Anti-Pattern Name]

**What:** [What you tried]
**Why it fails:** [Actual problems]
**Example:** [Specific case]
**Instead:** [Better approach]
**Source:** [Project name, date]
```

If something moves from `what-works.md` to here, note why it stopped working.
