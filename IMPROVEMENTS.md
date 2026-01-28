# META Framework Improvements

Tracking recommendations from the January 2026 assessment. Update status as items are completed.

**Assessment Date:** 2026-01-26
**Last Updated:** 2026-01-28

---

## Status Legend

- [ ] Not started
- [~] In progress
- [x] Completed

---

## Immediate Priority (High-Value, Low-Effort)

### 1. Validate with One Real Project
- [x] Pick one project (test-app)
- [x] Ensure AGENTS.md inherits from `../META/agents/base.md` and CLAUDE.md is symlinked
- [x] Follow `workflows/new-project.md` end-to-end
- [x] Complete a retrospective using `learnings/retrospective-template.md`
- [x] Extract at least 3 patterns to `patterns/`
- [x] ~~Update `project-registry.md`~~ (removed — recreate when 3+ projects exist)

**Why:** Validates the entire system. Creates the flywheel for compounding.

### 2. Populate Pattern Library from Existing Code
- [x] API error handling pattern → `patterns/api/`
- [x] Testing setup pattern → `patterns/testing/`
- [x] Deployment/CI pattern → `patterns/deployment/` (ci-pipeline-node.md, quality-gates.md, ci-setup-checklist)
- [~] At least 2 more auth patterns → `patterns/auth/` (1/2 done: supabase-jwt-middleware)
- [x] Document React Native patterns properly (rn-mf-contracts, rn-mf-host-loader)

**Target:** 10+ real patterns extracted from existing projects

**Current count:** Proven: 4 (jwt-refresh-rotation, supabase-jwt-middleware, zod-validation-middleware, supertest-in-memory) | Templates: 3 (rn-mf-contracts, rn-mf-host-loader, feature-first)

### 3. Add Tester Agent
- [x] Create `agents/tester.md`
- [x] Define focus: test strategy, coverage analysis, test design
- [x] Define deliverables: test plans, edge case identification, test code
- [x] Add to README.md agent list
- [x] Add to `workflows/multi-agent.md` workflows

**Location:** `agents/tester.md`

### 4. Pipeline Quality Baselines
- [x] Definition-of-done checklist prompt + gated steps in pipelines
- [x] External services setup step early in `project` pipeline
- [x] README template + `.env.example` + CI stub in `new-project.sh`
- [x] Observability checklist prompt
- [x] Observability validation gate
- [x] Git hygiene checklist prompt
- [x] Contract stub prompt (OpenAPI preferred) before parallelization
- [x] Preflight step (tools, permissions, env vars)
- [ ] Gate prompt shows last 20 log lines for faster approvals
- [ ] Artifact checklist step (expected files/paths)
- [ ] Docs completeness check at final gate (README + PRD + ARCHITECTURE)
- [ ] Supabase scaffold when selected (migrations folder + README snippet)

---

## Medium-Term (Structural Improvements)

### 4. Add Simple Tooling
- [x] Create `scripts/` directory
- [x] `scripts/new-project.sh` - bootstrap new project and print kickoff prompt
- [x] `scripts/add-pattern.sh` - scaffold new pattern with header template
- [x] `scripts/retrospective.sh` - create dated retrospective from template
- [x] `scripts/meta` - tmux orchestration CLI for pipelines
- [x] Document scripts in README.md

### 5. Create CHANGELOG.md
- [ ] Create `CHANGELOG.md` at root
- [ ] Define versioning scheme (semantic versioning recommended)
- [ ] Document current state as v1.0.0
- [ ] Establish process for documenting changes

### 6. Define Success Metrics
- [ ] Create `metrics.md` or add section to README
- [ ] Track: projects using META, patterns in library, pattern reuse count
- [ ] Track: average project bootstrap time, learnings captured
- [ ] Set up monthly review cadence

### 7. Simplify Handoff Format
- [x] Review current 7-section handoff template in `workflows/multi-agent.md`
- [x] Create streamlined alternative — unified `.handoff.md` template at `prompts/handoff-template.md`
- [x] Consolidate 4 different handoff templates into one unified spec
- [x] Add context budget system at `workflows/context-budget.md`
- [x] Test simplified format on real handoff (test-app)

### 8. Add Stack-Specific Security Checklists
- [ ] `patterns/security/node-security-checklist.md`
- [ ] `patterns/security/react-security-checklist.md`
- [ ] `patterns/security/api-security-checklist.md`
- [ ] Reference from `agents/reviewer.md`

### 9. Add Contract Tests Template
- [ ] Create a minimal contract test template for host/remotes
- [ ] Require contract tests in parallel workstreams

### 10. Pipeline Ergonomics
- [ ] Auto-commit checkpoints option for key steps
- [x] Contract validation step (OpenAPI lint) when `docs/openapi.yaml` exists
- [ ] Model budget guard (warn when step exceeds expected duration)
- [x] Test execution enforcement step

### 11. Add OTA Release + Rollback Checklist
- [ ] Document host/remote compatibility checks
- [ ] Add rollback path for failed OTA

---

## Long-Term (Scale Considerations)

### 11. Pattern Discovery/Search
- [ ] Add tags/categories to pattern headers (standardize format)
- [ ] Create `patterns/INDEX.md` with descriptions and tags
- [ ] Consider future: RAG/vector search integration for 50+ patterns

### 12. Multi-User/Team Considerations
- [ ] Document pattern approval process (if needed)
- [ ] Define how conflicting learnings are resolved
- [ ] Consider branch/PR workflow for pattern changes

### 13. Automated Pattern Extraction
- [ ] Research feasibility of AI-assisted pattern detection
- [ ] Design prompt for reviewing commits and suggesting extractions
- [ ] Prototype integration with git hooks or CI

---

## Completed Items

*Move items here when done, with completion date and any notes.*

| Item | Completed | Notes |
|------|-----------|-------|
| Initial assessment | 2026-01-26 | Created this tracking document |
| Tester agent created | 2026-01-26 | `agents/tester.md` — test strategy, design, edge cases, coverage analysis |
| Unified handoff & context budget | 2026-01-26 | `prompts/handoff-template.md`, `workflows/context-budget.md` — consolidated 4 templates into one |
| Model-agnostic AGENTS.md | 2026-01-27 | Added `AGENTS.md`, updated docs to prefer model-agnostic config |
| Product manager agent + PRD | 2026-01-27 | `agents/product-manager.md`, `prompts/prd-template.md` |
| Feature-first structure | 2026-01-27 | `patterns/project-structures/feature-first.md` |
| RN MF templates | 2026-01-27 | `rn-mf-contracts.md`, `rn-mf-host-loader.md` |
| Meta CLI orchestration | 2026-01-27 | `scripts/meta`, `workflows/pipelines/*` |
| Definition-of-done baseline | 2026-01-28 | `prompts/definition-of-done-checklist.md`, gates added to pipelines |
| External service setup step | 2026-01-28 | `workflows/pipelines/project.pipeline` step 2 |
| Contract stub prompt (OpenAPI) | 2026-01-28 | `prompts/contract-stub.md`, orchestrator + workflow requirements |
| New-project scaffolding baselines | 2026-01-28 | README template, `.env.example`, CI stub in `scripts/new-project.sh` |
| Pipeline timing logs | 2026-01-28 | step + pipeline timestamps and durations in `scripts/meta*` |
| OpenAPI validation step | 2026-01-28 | `prompts/openapi-validation.md`, pipeline steps added |
| Preflight checklist step | 2026-01-28 | `prompts/preflight-checklist.md`, inserted into pipelines |
| Observability validation gate | 2026-01-28 | `prompts/observability-validation.md`, gate added to pipelines |
| Test execution enforcement | 2026-01-28 | `prompts/test-execution.md`, pipeline steps added |

---

## Assessment Summary Reference

### Current Scores (2026-01-26)

| Aspect | Score | Target |
|--------|-------|--------|
| Philosophy/Vision | 5/5 | Maintain |
| Agent Definitions | 4/5 | Add Tester agent |
| Pattern Library | 2/5 | Target: 4/5 (10+ patterns) |
| Learnings Capture | 2/5 | Target: 4/5 (real retrospectives) |
| Workflows | 4/5 | Maintain |
| Documentation | 4/5 | Maintain |
| Tooling | 1/5 | Target: 3/5 (basic scripts) |
| Validation | 1/5 | Target: 4/5 (1+ active project) |
| Maintainability | 3/5 | Target: 4/5 (add versioning) |

### Key Insight

> The single most valuable thing: Take one existing project, retrofit it with META properly, document the learnings, and extract 5-10 real patterns. This creates the flywheel that makes the compounding philosophy actually work.

---

## Review Schedule

- [ ] Weekly: Check immediate priority items
- [ ] Monthly: Review metrics, update scores
- [ ] Quarterly: Reassess priorities, add new recommendations

---

## Notes

*Add notes, blockers, or decisions here as work progresses.*
