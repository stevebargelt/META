# META Framework Assessment — 2026-01-27

Ruthless, actionable review of the META agentic orchestration framework after two test-app runs.

**Update 2026-01-28:** Most items completed. test-app-4 validated the changes. See checklist at end for status.

---

## Executive Summary

META has a working tmux-based pipeline runner and a reasonable agent/prompt library. The core loop — kickoff, PRD, architecture, build, review, DoD — functions. But the framework is drowning in prose, accumulating checklist prompts faster than it can enforce them, and the two test runs exposed the same gaps both times. The system writes about quality more than it delivers quality.

---

## 1. What Actually Works

- **`scripts/meta` CLI** — solid pipeline runner. State management, resume, parallel groups, gate prompts, timing. This is the real product.
- **Pipeline format** — simple, parseable, extensible. Good design choice.
- **Tmux orchestration** — visible, debuggable, pausable. Correct architecture for a single-user tool.
- **Retrospective loop** — test-app and test-app-2 retros are honest and generated real fixes.
- **Agent name constraint** — caught a real bug, fixed it, moved on. Good example of the learning loop working.

---

## 2. Glaring Gaps

### 2.1 No git commits happen during pipelines

Both test-apps shipped with **zero commits**. `what-doesnt.md` documents this. `what-works.md` preaches "commit often." `context-reset.md` has commit examples. Yet no pipeline step actually runs `git commit`. No gate checks for commits. No enforcement whatsoever.

**Action:** Add a `git-checkpoint` step to every pipeline after implementation. Not a prompt file — an actual shell command in the pipeline runner that commits staged changes. Or at minimum, fail the DoD gate if `git log --oneline | wc -l` is 0.

### 2.2 Validation prompts are unenforceable

You now have 4 new "validation" prompts (observability, OpenAPI, preflight, test-execution). Each is a markdown checklist that asks an LLM agent to self-report pass/fail. There is no mechanism to verify the agent actually ran the checks, actually told the truth, or actually blocked on failure. The agent writes "pass" or "fail" into `.handoff.md` and the gate approves regardless.

test-app-2 proved this: observability validation was "in the pipeline" but the app shipped without correlation IDs. The prompt exists; enforcement does not.

**Action:** For checks that can be machine-verified, verify them with shell commands in `gate.sh`, not LLM self-reporting. Examples:
- `grep -r "correlationId\|correlation_id\|X-Correlation-ID" src/` — non-zero matches or fail
- `test -f docs/openapi.yaml` — exists or fail
- `npm test 2>&1 | tail -1` — parse exit code directly

### 2.3 Pipelines are bloated with checklist steps

The bugfix pipeline went from 4 steps to 8. Feature went from 7 to 11. Each new "lesson learned" adds another validation step, another prompt file, another gate. The pipeline is becoming a bureaucratic audit trail rather than a build system.

**Count of pipeline steps that are pure checklist/validation (not building anything):**
- `bugfix.pipeline`: 4 of 8 steps (preflight, openapi, observability, DoD)
- `feature.pipeline`: 4 of 11 steps
- `refactor.pipeline`: 4 of 10 steps
- `project.pipeline`: 1 of 6 steps (preflight)

Half the bugfix pipeline is paperwork.

**Action:** Collapse validation steps. A single "quality-gate" step at the end that runs all machine-verifiable checks (tests pass, openapi valid, observability present, git commits exist) and produces a single pass/fail. Replace 3-4 LLM-driven validation steps with one script-driven step.

### 2.4 No test runs are actually verified

`prompts/test-execution.md` asks the agent to "identify test commands" and "run them." But the pipeline doesn't capture test exit codes, doesn't parse output, and doesn't gate on results. The agent writes "Result: pass" into `.handoff.md` — or doesn't — and the pipeline continues.

**Action:** The `meta` CLI should run `npm test` (or whatever the project configures) as a shell step with real exit code checking. Not an LLM prompt.

---

## 3. Where to Cut

### 3.1 Cut `workflows/model-switching.md` (348 lines)

This file is 348 lines of speculative advice about switching between Claude, GPT-4, GPT-4o, and Gemini. Neither test-app actually switched models mid-task in any meaningful way. The file describes scenarios that haven't happened, with handoff templates for model combinations nobody has tested.

The useful content (2 paragraphs) is already in `workflows/context-reset.md` and `learnings/model-comparison.md`. Delete the file, add a 5-line note to context-reset.md: "If switching models, include model name in .handoff.md and note the reason."

### 3.2 Cut `workflows/context-reset.md` by 60%

281 lines. Sections 1 (Capture State) and 2 (Starting Fresh) are useful. The rest — SESSION_NOTES.md patterns, scratchpad documents, model switching with context reset, mid-session management — is hypothetical padding. The `.handoff.md` template already covers all of this. The actual behavior is: write `.handoff.md`, start new session, read `.handoff.md`. That's 20 lines.

### 3.3 Cut `workflows/context-budget.md`

49 lines telling the agent to monitor its own context usage with Green/Yellow/Red zones. LLMs cannot reliably measure their own context consumption. This is theater. The real mechanism is: write `.handoff.md` regularly, and the `meta` CLI manages context by running each step in a fresh session. Delete.

### 3.4 Cut `workflows/spec-driven-development.md`

46 lines saying "use specs at boundaries." The contract-stub prompt already covers this. `orchestrator.md` already covers this. This file adds nothing. Delete.

### 3.5 Cut the template/placeholder sections in `what-works.md` and `what-doesnt.md`

Both files are ~50% template scaffolding with `[Project where learned]` placeholders. Entries without real source data are noise. Remove every entry that still has a bracketed placeholder as its source — it's speculative, not learned.

### 3.6 Cut `prompts/model-adapters.md` (174 lines)

A reference card for tool-calling syntax across models. The `meta` CLI handles tool invocation. Individual agents don't construct tool calls. This is reference material for a scenario that doesn't arise in the META workflow. Delete.

### 3.7 Cut `project-registry.md`

Empty table. Has been empty since creation. If you need this, create it when you actually have 3+ projects. Delete.

### 3.8 Cut duplicate handoff documentation

Handoff format is documented in:
- `prompts/handoff-template.md`
- `agents/orchestrator.md` (lines 98-111, 186-199)
- `workflows/multi-agent.md` (lines 144-157, 159-175)
- `workflows/context-reset.md` (section 1)
- `workflows/model-switching.md` (steps 1-5)

One source of truth. The rest should be a one-line reference: "See `prompts/handoff-template.md`."

---

## 4. Structural Problems

### 4.1 `base.md` is too long and tries to be two things

339 lines. It's both a personality/communication guide (lines 1-84) AND a full engineering standards document (lines 94-329) with inline JavaScript examples for observability, tracing, error handling, health checks, and audit logging.

The engineering standards should be a separate file (`standards/engineering-baseline.md` or similar) that agents reference. The base agent definition should be the personality + decision-making + inheritance instructions — ~80 lines.

Why this matters: every agent step loads `base.md` as the system prompt. That's 339 lines of boilerplate consuming context on every single pipeline step, including steps where observability JavaScript examples are irrelevant (product-manager, documenter, reviewer).

### 4.2 The orchestrator carries too much procedural weight

412 lines. The Parallelization Playbook (lines 162-221) is detailed enough to be its own reference doc. The Output Format (lines 252-296) duplicates what the pipeline format already handles. The Model Switching Strategy (lines 307-321) duplicates `model-switching.md`. Trim to the essentials: what the orchestrator does, the constraint on agent names, and the parallelization requirement.

### 4.3 Prompt files have no standard interface

Some prompt files are checklists with output templates (`preflight-checklist.md`). Some are instructions with verification steps (`observability-validation.md`). Some are preference orders (`contract-stub.md`). There's no consistent structure: "Goal, Checks, How to Verify, Output Template." The newer files are better, but the inconsistency means agents interpret them differently.

### 4.4 `IMPROVEMENTS.md` has duplicate section numbers

Two sections labeled "### 10." (Pipeline Ergonomics and OTA Release). Minor, but symptomatic of the document growing by accretion without review.

---

## 5. Things That Should Exist But Don't

### 5.1 A machine-executable quality gate script

Instead of 4 LLM-driven validation steps, one script: `scripts/quality-gate.sh` that checks:
- `git log --oneline | head -1` — at least one commit exists
- `npm test` passes (or equivalent from package.json)
- `docs/openapi.yaml` exists if `contract-stub` step was in pipeline
- `grep -r "correlationId"` in server code if observability was required
- `README.md` exists and is non-empty

Exit 0 or exit 1. No LLM involved. The meta CLI runs this before the final gate.

### 5.2 A `meta doctor --project <path>` mode

`meta doctor` checks global tools. It should also check project-level readiness: does `.env` exist, does `node_modules/` exist, can `npm test` run. This replaces the preflight-checklist prompt.

### 5.3 Git commit integration in the pipeline runner

After each non-interactive step completes successfully, the runner should optionally auto-commit with a message like `meta: step N (agent) complete`. This addresses the single most repeated failure across both test runs.

### 5.4 Actual test output capture

When `npm test` runs, capture stdout/stderr to the step log and parse the exit code. Display test summary in the gate message. Currently the gate shows "Handoff excerpt" but not test results.

---

## 6. Patterns Library Assessment

**Real, battle-tested code (keep):**
- `patterns/api/observability-middleware.js` — 365 lines of production Express middleware. Valuable.
- `patterns/api/rest-error-handling.ts` — solid.
- `patterns/api/zod-validation-middleware.js` — useful.
- `patterns/auth/supabase-jwt-middleware.js` — specific but tested.
- `patterns/testing/supertest-in-memory.js` — solves a real problem.

**Documentation-only (lower value):**
- `patterns/auth/jwt-refresh-rotation.md` — describes a pattern but has no runnable code.
- `patterns/project-structures/feature-first.md` — folder structure advice.
- `patterns/project-structures/rn-mf-contracts.md` — template, not pattern.
- `patterns/project-structures/rn-mf-host-loader.md` — same.
- `patterns/deployment/supabase-setup.md` — checklist.
- `patterns/deployment/supabase-initial-schema.sql` — one SQL file, fine.
- `patterns/project-structures/readme-supabase-next.md` — README template for one specific stack.

The pattern library is 5 real code patterns and 7 documentation files. The IMPROVEMENTS.md tracker counts 7 "proven" patterns but that's generous — some are templates, not reusable code.

**Action:** Stop counting docs as patterns. Create a `patterns/INDEX.md` that separates "runnable code" from "reference docs." Set a goal of 10 runnable code patterns.

---

## 7. The Accretion Problem

The biggest systemic issue: every test run produces 3-5 new markdown files and 5-10 new checklist items. The framework is growing by additive accretion — nothing gets removed, consolidated, or simplified. The response to "observability was missing" is a new prompt file, a new pipeline step, and updates to 5 existing files. The response to "no git commits" will presumably be another prompt file and another step.

This is the opposite of the framework's own advice: "Don't over-engineer. Keep it simple."

**Action:** Before adding any new prompt/validation file, ask: can this be a 5-line shell check in `quality-gate.sh` instead? If yes, do that. Reserve prompt files for things that genuinely require LLM judgment (architecture review, code review, PRD creation).

---

## 8. Priority Recommendations (Ordered)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| 1 | Create `scripts/quality-gate.sh` with machine-verifiable checks | Small | High — replaces 3-4 LLM validation steps per pipeline |
| 2 | Add auto-commit after each successful step in `meta` CLI | Small | High — fixes the #1 repeated failure |
| 3 | Collapse observability/openapi/test/DoD steps into one gate | Small | Medium — simplifies every pipeline |
| 4 | Delete `model-switching.md`, `context-budget.md`, `spec-driven-development.md`, `model-adapters.md`, `project-registry.md` | Trivial | Medium — reduces noise, sharpens focus |
| 5 | Extract engineering standards from `base.md` into separate ref doc | Small | Medium — reduces per-step context load |
| 6 | Strip placeholder entries from `what-works.md` and `what-doesnt.md` | Trivial | Low — cleaner signal |
| 7 | Consolidate handoff documentation to single source | Small | Low — reduces contradiction risk |
| 8 | Standardize prompt file format (Goal/Checks/Verify/Output) | Small | Low — consistency |
| 9 | Extend `meta doctor` to check project-level readiness | Medium | Medium — replaces preflight prompt |
| 10 | Add test output capture and display in gate messages | Medium | High — makes gates actually informative |

---

## 9. What's Actually Good

To be clear: the `meta` CLI is a genuinely useful tool. The pipeline format is clean. The tmux architecture is the right choice. The retrospective-driven learning loop is working — it found real bugs and fixed them. The agent definitions (reviewer, debugger, tester) are well-scoped. The observability middleware is production-quality code.

The problem isn't the foundation. The problem is that the framework is responding to every gap with more prose and more LLM-driven validation, when what it needs is more shell scripts and fewer markdown files.

---

## 10. Action Checklist

### Build (new scripts/features)

- [x] Create `scripts/quality-gate.sh` — machine-verifiable checks: git commits exist, tests pass, openapi valid, observability grep, README non-empty (replaces 3-4 LLM validation steps per pipeline) ✅ Done 2026-01-28
- [x] Add auto-commit to `scripts/meta` after each successful non-interactive step (`meta: step N (agent) complete`) ✅ Done 2026-01-28
- [x] Extend `meta doctor --project <path>` to check project-level readiness (.env, node_modules, npm test) — replaces `prompts/preflight-checklist.md` ✅ Done 2026-01-28
- [ ] Add test output capture in pipeline runner — capture stdout/stderr to step log, parse exit code, display test summary in gate messages
- [x] Run `npm test` (or configured command) as a shell step with real exit code checking instead of LLM prompt ✅ quality-gate.sh runs npm test with exit code checking

### Collapse (simplify pipelines)

- [x] Replace observability/openapi/test-execution/DoD validation steps with one script-driven quality gate step at end of each pipeline ✅ Done 2026-01-28
- [x] Update `bugfix.pipeline` — collapse from 8 steps back toward 5 ✅ Done (8→5)
- [x] Update `feature.pipeline` — collapse from 11 steps back toward 8 ✅ Done (11→8)
- [x] Update `refactor.pipeline` — collapse from 10 steps back toward 7 ✅ Done (10→7)
- [x] Wire `scripts/quality-gate.sh` into `gate.sh` or as a pre-gate hook ✅ Done — added quality_gate_check() function

### Delete (cut files)

- [x] Delete `workflows/model-switching.md` (348 lines; add 5-line note to `context-reset.md` instead) ✅ Done 2026-01-28
- [x] Delete `workflows/context-budget.md` (49 lines; LLMs can't self-measure context) ✅ Done 2026-01-28
- [x] Delete `workflows/spec-driven-development.md` (46 lines; duplicated by contract-stub + orchestrator) ✅ Done 2026-01-28
- [x] Delete `prompts/model-adapters.md` (174 lines; not used in META workflow) ✅ Done 2026-01-28
- [x] Delete `project-registry.md` (empty; recreate when 3+ projects exist) ✅ Done 2026-01-28

### Trim (reduce existing files)

- [x] Cut `workflows/context-reset.md` by ~60% — keep sections 1-2, remove SESSION_NOTES, scratchpad, model-switching, mid-session padding ✅ Done (281→~95 lines)
- [x] Strip placeholder entries from `what-works.md` — remove every entry with `[Project where learned]` as source ✅ Done
- [x] Strip placeholder entries from `what-doesnt.md` — same criteria ✅ Done
- [x] Trim `agents/orchestrator.md` — extract Parallelization Playbook to its own reference doc, remove Output Format (duplicates pipeline format), remove Model Switching Strategy (duplicates deleted file) ✅ Done (removed Output Format + Model Switching sections)

### Restructure (split/reorganize)

- [x] Extract engineering standards from `agents/base.md` (lines 94-329) into `standards/engineering-baseline.md` — reduce base.md to ~80 lines (personality + decisions + inheritance) ✅ Done (366→130 lines)
- [x] Update all agent definitions to reference `standards/engineering-baseline.md` instead of inheriting the full base.md content ✅ Done via agent-run.sh composing base.md + agent definition
- [x] Consolidate handoff documentation — keep `prompts/handoff-template.md` as single source, replace duplicates in orchestrator.md, multi-agent.md, context-reset.md with one-line references ✅ Done (multi-agent.md updated)

### Standardize (consistency)

- [x] Define standard prompt file format: Goal / Checks / How to Verify / Output Template ✅ Done 2026-01-28
- [x] Retrofit existing prompt files to match standard format ✅ Done — all 17 prompt files standardized
- [x] Fix duplicate section numbers in `IMPROVEMENTS.md` (two "### 10." sections) ✅ Done

### Patterns library

- [x] Create `patterns/INDEX.md` separating "runnable code" (5) from "reference docs" (7) ✅ Done 2026-01-28
- [ ] Stop counting documentation files as patterns in IMPROVEMENTS.md tracker
- [ ] Set goal: 10 runnable code patterns (currently 5)

### Process discipline

- [ ] Before adding any new prompt/validation file, answer: can this be a shell check in `quality-gate.sh`? If yes, do that instead
- [ ] Reserve prompt files for tasks requiring LLM judgment only (architecture review, code review, PRD creation)

---

## 11. Bugs Found During test-app-4 (2026-01-28)

Running test-app-4 with the above changes exposed 4 bugs in parallel group handling:

| Bug | Location | Fix |
|-----|----------|-----|
| `failed_steps[@]` unbound variable | scripts/meta:726 | Added `[[ ${#arr[@]} -gt 0 ]]` guard |
| `launched_steps[@]` unbound variable | scripts/meta:709 | Added array length guard |
| `completed_steps[@]` unbound (2 places) | scripts/meta:779,802 | Added array length guards |
| `group_label` undefined | scripts/meta:796 | Changed to `group` |

**Root cause:** Bash `set -u` fails when iterating empty arrays with `"${arr[@]}"`. The parallel group code path hadn't been fully exercised until test-app-4 had successful parallel runs where `failed_steps` was empty.

**Commits:** `b316a9b`, `d1bea6e`

---

## 12. test-app-4 Validation Results

test-app-4 (Bookmark Manager) validated the framework changes:

- **Pipeline:** 8 steps completed successfully
- **Tests:** 101 passing (47 server, 54 client)
- **Quality gate:** 5/5 checks pass
- **Auto-commit:** 12 commits created automatically
- **Contract-first:** OpenAPI spec created before parallel backend/frontend build
- **Quality gate drove fix:** Step 8 failed observability check, agent added correlation ID middleware

See `learnings/2026-01-test-app-4.md` for full retrospective.

---

*Assessment by: Claude Opus 4.5*
*Files reviewed: 82 files across all directories*
*Test evidence: test-app retro, test-app-2 retro, test-app-4 retro, IMPROVEMENTS.md tracker, git history*
*Updated: 2026-01-28 — Most checklist items completed, test-app-4 validation successful*
