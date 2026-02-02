# Pipeline Modules

Composable pipeline step templates used by project-orchestrator to generate custom pipelines.

## Concept

Instead of one-size-fits-all pipelines, the project-orchestrator composes a custom pipeline based on:
- Which phases completed interactively (Detailed mode)
- Which phases should run automated (Quick mode)
- Project-specific context

## Module Types

### Executable Modules (`.steps`)

Contain actual pipeline steps that get copied into the generated pipeline:
- `prd-quick.steps` — Automated PRD creation
- `arch-quick.steps` — Automated architecture design
- `impl-parallel.steps` — Implementation (tester + backend + frontend)
- `review.steps` — Code review and fixes
- `finalize.steps` — DoD checklist and quality gate

### Reference Modules (`.steps`)

Document interactive flows that run before the pipeline (not copied into pipeline):
- `prd-detailed.steps` — Interactive PRD process description
- `arch-detailed.steps` — Interactive architecture process description

These exist for documentation and so the orchestrator knows what artifacts to expect.

## File Format

Each `.steps` file uses the standard pipeline format:

```
# [Module Name]
# [Description]
# [Prerequisites or notes]

# NUM | AGENT | CLI | GATE | PARALLEL_GROUP | TIMEOUT_MIN | PROMPT
N | agent | - | gate | group | mins | Task description
```

**Note:** Step numbers (`N`, `N+1`) are placeholders. The orchestrator renumbers when composing.

## Composition Model

The project-orchestrator:

1. Reads user's depth selections from kickoff
2. Determines which modules to include
3. Copies steps from relevant modules
4. Renumbers steps sequentially
5. Adjusts prompts to reference existing artifacts
6. Writes to `.meta/composed.pipeline`

### Example Composition

**User selections:** PRD=Detailed, Architecture=Quick

**Orchestrator actions:**
1. Run detailed PRD interactively (creates `docs/PRD-<feature>.md`)
2. Skip `prd-quick.steps` (PRD already exists)
3. Include `arch-quick.steps` (references existing PRD)
4. Include `impl-parallel.steps`
5. Include `review.steps`
6. Include `finalize.steps`

**Generated pipeline:**
```
# Steps 1: Branch creation (always)
# Steps 2: Architecture (from arch-quick.steps, PRD skipped)
# Steps 3-5: Implementation (from impl-parallel.steps)
# Steps 6-8: Review (from review.steps)
# Steps 9-10: Finalize (from finalize.steps)
```

## Module Descriptions

### prd-quick.steps
Single automated step. Product-manager creates PRD from task description.
- Input: Task description from kickoff
- Output: `docs/PRD-<feature>.md`

### prd-detailed.steps (Reference)
Interactive flow run by project-orchestrator before pipeline.
- Research phase (product-researcher)
- Requirements elicitation
- Draft PRD with review loop
- Output: `docs/COMPETITIVE-ANALYSIS.md`, `docs/PRD-<feature>.md`

### arch-quick.steps
Single automated step. Architect designs based on PRD.
- Input: PRD
- Output: Updated `docs/ARCHITECTURE.md`

### arch-detailed.steps (Reference)
Interactive flow run by project-orchestrator before pipeline.
- Architecture elicitation
- Options exploration with trade-offs
- Draft architecture with review loop
- Output: Updated `docs/ARCHITECTURE.md` with diagrams

### impl-parallel.steps
Three parallel steps for implementation.
- Tester: Test plan and skeleton tests
- Backend: API, services, repositories
- Frontend: UI components, hooks, pages
- Build validation after parallel merge

### review.steps
Review and fix cycle.
- Reviewer checks quality, security, architecture adherence
- Base agent fixes flagged issues

### finalize.steps
Final quality checks.
- DoD checklist
- Quality gate script

## Adding New Modules

When adding a new phase that can be Quick or Detailed:

1. Create `<phase>-quick.steps` with automated step(s)
2. Create `<phase>-detailed.steps` documenting interactive flow
3. Create `prompts/<phase>-detailed-questions.md` for elicitation
4. Update `agents/project-orchestrator.md` with new depth option
5. Update composition logic in project-orchestrator

## Customization

Projects can override modules by creating local versions:
```
my-project/.meta/modules/impl-parallel.steps
```

The orchestrator checks for local overrides before using META defaults.

## Related Files

- `agents/project-orchestrator.md` — Agent that composes pipelines
- `prompts/kickoff-questions.md` — Depth selection questions
- `workflows/pipelines/feature.pipeline` — Original monolithic pipeline (still works)
