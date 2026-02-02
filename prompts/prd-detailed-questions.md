# Detailed PRD Questions

Comprehensive requirements elicitation framework for detailed PRD mode. Used by project-orchestrator agent after competitive research completes.

## Purpose

Gather enough information to write a complete PRD by exploring:
1. The problem being solved
2. Who experiences it and how
3. What success looks like
4. Constraints and scope boundaries

## Before Starting

**Prerequisites:**
- Kickoff complete with "Detailed PRD" selected
- `docs/COMPETITIVE-ANALYSIS.md` created (if applicable)
- Basic feature description captured

**Context to have ready:**
- Competitive research findings
- Any constraints from kickoff
- Existing PRD/docs if adding to existing project

## Question Categories

### 1. Problem Space

Start here. Understanding the problem prevents building the wrong thing.

**Core questions:**

> "What problem are you trying to solve?"

Listen for: Pain points, frustrations, unmet needs, inefficiencies.

> "Who experiences this problem?"

Listen for: User types, roles, contexts, frequency.

> "How do they solve it today?"

Listen for: Workarounds, manual processes, competitor products, "they don't."

> "What's painful about the current solution?"

Listen for: Time wasted, errors made, friction points, missing capabilities.

**Follow-ups based on answers:**

- If problem is vague: "Can you give me a specific example?"
- If user-focused: "Are there other stakeholders affected?"
- If solution-focused: "Let's step back — what's the underlying need?"

**Connect to research:**
> "Our competitive research found [X]. Does that match what you're seeing?"

### 2. Target Users

Understand who you're building for.

**Core questions:**

> "Who is the primary user of this feature?"

Listen for: Role, context, frequency of use.

> "Are there secondary users or stakeholders?"

Listen for: Admins, reviewers, downstream consumers.

> "What's their technical sophistication?"

Listen for: Developer, power user, casual user, non-technical.

> "In what environment/context will they use this?"

Listen for: Desktop, mobile, on-the-go, office, embedded in workflow.

**Follow-ups:**

- If multiple users: "Who should we optimize for first?"
- If unclear context: "Walk me through a typical usage scenario."

### 3. Success Criteria

Define what winning looks like.

**Core questions:**

> "How will you know this feature succeeded?"

Listen for: Outcomes, behaviors, metrics, user feedback.

> "What metrics would you track?"

Listen for: Usage, conversion, time saved, errors reduced, satisfaction.

> "What's the minimum viable version?"

Listen for: Core functionality, must-haves for v1, what can wait.

**Follow-ups:**

- If metrics are vague: "What number would make you happy? What would disappoint?"
- If MVP unclear: "If you could only ship one thing, what would it be?"
- If success is fuzzy: "Picture a user after using this — what's different for them?"

**Connect to research:**
> "Competitors measure success by [X]. Is that relevant for us?"

### 4. Constraints

Identify boundaries before they become blockers.

**Core questions:**

> "Any timeline constraints?"

Listen for: Deadlines, dependencies, external commitments.

> "Any technical constraints?"

Listen for: Tech stack requirements, legacy system integration, performance needs.

> "Any budget or resource constraints?"

Listen for: Team size, external services costs, infrastructure limits.

> "Any compliance or policy requirements?"

Listen for: Privacy, security, accessibility, regulatory.

**Follow-ups:**

- If integration mentioned: "What systems does this need to work with?"
- If deadline mentioned: "Is that a hard deadline? What happens if we miss it?"
- If no constraints: "Any stakeholders who might add constraints later?"

### 5. Scope

Define boundaries to prevent scope creep.

**Core questions:**

> "What's explicitly out of scope for this version?"

Listen for: Features to defer, edge cases to ignore, users to exclude.

> "What's a 'must have' versus 'nice to have'?"

Listen for: Prioritization, trade-off willingness.

> "What would you cut if you had to ship in half the time?"

Listen for: True priorities, negotiable features.

**Follow-ups:**

- If scope is broad: "That's a lot — what's the absolute core?"
- If everything is must-have: "If we had to choose between X and Y?"
- If unsure: "What would users complain about if missing?"

**Connect to research:**
> "Competitors include [feature X]. Is that must-have or nice-to-have for us?"

## Adaptive Questioning

### Don't Ask If Already Known

- Skip questions answered in kickoff
- Skip questions answered by previous responses
- Skip questions obvious from context

### Ask Follow-ups When

- Answer is vague or abstract
- Answer contradicts earlier information
- Critical detail is missing
- User seems uncertain

### Probe Deeper When

- "It depends" → "On what specifically?"
- "We need everything" → "If you had to prioritize?"
- "I'm not sure" → "What would help you decide?"
- "The usual" → "What does usual mean in your context?"

### Connect Dots

Reference competitive research throughout:
- "Research showed competitors do X — thoughts?"
- "This gap in competitors could be our differentiator"
- "Users complain about X in reviews — should we address that?"

## Synthesizing into PRD

After questions, map answers to PRD structure:

| Question Category | Maps To |
|------------------|---------|
| Problem Space | Problem/Goal section |
| Target Users | Target Users section |
| Success Criteria | Success Metrics, Acceptance Criteria |
| Constraints | Risks/Dependencies |
| Scope | Requirements (Must/Should/Won't), Non-Goals |
| Research Findings | Competitive Context |

### Draft PRD Flow

1. Present draft PRD in conversation
2. Highlight any gaps or assumptions made
3. Ask for review: "What's missing? What's wrong?"
4. Iterate until approved
5. Write final to `docs/PRD-<feature>.md`

## Red Flags

Watch for these during elicitation:

- **No clear problem** → Probe deeper or suggest more research
- **Everyone is the user** → Push for prioritization
- **No success criteria** → Suggest metrics or outcomes
- **Everything is must-have** → Force trade-off conversations
- **Contradictory requirements** → Surface the conflict explicitly

## Example Dialogue

```
Orchestrator: "What problem are you trying to solve with the shopping list feature?"

User: "I want users to be able to make shopping lists from recipes"

Orchestrator: "What's painful about how they do it today?"

User: "They have to manually write out ingredients, often forgetting things"

Orchestrator: "Our research found that competing apps like Paprika and Mealime
aggregate ingredients and group by store aisle. Is that the direction you're
thinking?"

User: "Yes, aggregation is key. I'm not sure about aisle organization."

Orchestrator: "What about users who cook multiple recipes in a week — should
the list combine ingredients across recipes?"

User: "Definitely, that's core functionality"

Orchestrator: "Got it. What about scaling quantities? If a recipe serves 4 but
they're cooking for 2?"

User: "That's nice to have, not must have for v1"

[continues...]
```
