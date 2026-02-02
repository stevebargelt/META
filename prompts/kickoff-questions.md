# Kickoff Questions

Structured questions for project/feature kickoff. Used by project-orchestrator agent.

## Purpose

Gather enough context to:
1. Understand what's being built
2. Help user choose appropriate depth for PRD and Architecture phases
3. Capture constraints and context that inform later work

## Question Flow

### 1. Understanding the Task

**Primary question:**
> "What are we building?"

Capture a 1-2 sentence description. This becomes the feature/project name and drives everything else.

**Follow-up:**
> "Is this a new project or a feature for an existing project?"

- **New project:** Will need project setup, may benefit from more detailed discovery
- **Existing feature:** Reference existing codebase, PRD, architecture

**If existing project:**
> "Can you point me to the existing PRD or architecture docs?"

### 2. PRD Depth Selection

Present both options with clear descriptions:

> "How much detail do you want in the PRD phase?"

**Option: Quick**
> "I have clear requirements, just document them"

- Best when: Requirements are already clear in your head
- What happens: Automated PRD creation from your task description
- No competitive research
- Minimal back-and-forth
- Output: `docs/PRD-<feature>.md`

**Option: Detailed**
> "Help me think through requirements"

- Best when: Idea is fuzzy, want to explore, or entering unfamiliar space
- What happens:
  1. Competitive research (what's out there?)
  2. Interactive requirements questions
  3. Draft PRD with your review
  4. Iterate until you approve
- Output: `docs/COMPETITIVE-ANALYSIS.md` + `docs/PRD-<feature>.md`

### 3. Architecture Depth Selection

Present both options with clear descriptions:

> "How much detail do you want in the Architecture phase?"

**Option: Quick**
> "Standard patterns, minimal design work"

- Best when: Standard CRUD app, familiar patterns, simple feature
- What happens: Automated architecture based on PRD
- Applies standard patterns from META
- Minimal back-and-forth
- Output: Updates to `docs/ARCHITECTURE.md`

**Option: Detailed**
> "Explore options, validate approach with me"

- Best when: Novel problem, multiple valid approaches, want to understand trade-offs
- What happens:
  1. System context questions
  2. Present architectural options with trade-offs
  3. Draft architecture with your review
  4. Iterate until you approve
- Output: Comprehensive `docs/ARCHITECTURE.md` with diagrams

### 4. Context Gathering (Optional)

Only ask if not already clear from previous answers:

**Constraints:**
> "Any known constraints I should be aware of?"

Examples:
- Timeline (needs to ship by X)
- Tech stack requirements (must use React, must integrate with Y)
- Budget/resource limits
- Compliance requirements

**Prior art:**
> "Any prior art or references to consider?"

Examples:
- Competitor products to look at
- Internal tools with similar functionality
- Design mockups or wireframes
- Previous attempts or prototypes

### 5. Confirmation

Summarize before proceeding:

```
"Here's what we'll do:

Feature: [description]
PRD: [Quick/Detailed]
Architecture: [Quick/Detailed]
[Any noted constraints]

[Detailed PRD]: First, I'll research the competitive landscape,
then we'll work through requirements together.

[Detailed Arch]: After the PRD is set, we'll explore architecture
options and I'll present trade-offs for your decisions.

[Quick both]: I'll generate the PRD and architecture, then we'll
move to implementation.

Ready to begin?"
```

## Adaptive Behavior

### Skip Questions When...

- Answer is obvious from context (don't ask "new or existing" if user said "add feature to my app")
- User already provided the information
- Previous answer makes question irrelevant

### Ask Follow-ups When...

- Answer is vague ("a shopping feature" → "what specifically about shopping?")
- Critical information is missing
- User seems uncertain (offer to explain options more)

### Default Recommendations

If user is unsure which depth to choose:

**Recommend Detailed PRD when:**
- "I'm not sure what features to include"
- "I don't know what's out there"
- "This is a new problem space for me"
- New project (vs feature addition)

**Recommend Quick PRD when:**
- "I know exactly what I want"
- "Just need to document for the team"
- Simple feature with clear scope

**Recommend Detailed Architecture when:**
- "I'm not sure how to approach this"
- "There might be multiple ways to do this"
- "This has complex requirements"
- Integration with external systems
- Scale/performance concerns

**Recommend Quick Architecture when:**
- "Standard CRUD is fine"
- "Similar to [existing feature]"
- "I know the patterns I want"

## Output

After kickoff questions, write to `.meta/handoff.md`:

```markdown
## Kickoff Summary

**Feature:** [description]
**Type:** [New project / Feature addition]
**Date:** [date]

### Depth Selections
- PRD: [Quick/Detailed]
- Architecture: [Quick/Detailed]

### Context Captured
- [Any constraints noted]
- [Any prior art mentioned]
- [Any preferences expressed]

### Next Phase
[Competitive research / PRD elicitation / Automated PRD / etc.]
```
