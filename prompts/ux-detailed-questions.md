# Detailed UX Design Questions

Comprehensive UX elicitation framework for detailed UX Design mode. Used by project-orchestrator agent after Architecture is complete.

## Purpose

Gather enough information to design a great user experience by exploring:
1. User context and goals
2. Device and platform considerations
3. Interaction patterns and flows
4. Visual and brand requirements
5. Accessibility needs

## Before Starting

**Prerequisites:**
- PRD complete and approved (`docs/PRD-<feature>.md`)
- Architecture complete and approved (`docs/ARCHITECTURE.md`)
- Kickoff complete with "Detailed UX Design" selected

**Context to have ready:**
- PRD user stories and acceptance criteria
- Architecture's frontend decisions
- Any existing design system or brand guidelines
- Competitive analysis (if created)

## Question Categories

### 1. Users & Context

Understand who we're designing for.

**Core questions:**

> "Who are the primary users of this feature?"

Listen for: Demographics, technical comfort, usage frequency.

> "What context will they be in when using this?"

Listen for: On the go, at desk, distracted, focused, time pressure.

> "Are there secondary users or edge cases to consider?"

Listen for: Admins, power users, occasional users, accessibility needs.

> "What's their current solution? What's frustrating about it?"

Listen for: Pain points to solve, habits to respect, expectations.

**Follow-ups:**

- If multiple user types: "Which is highest priority?"
- If accessibility mentioned: "Any specific needs (vision, motor, cognitive)?"
- If mobile context: "Will they have stable internet?"

### 2. Device & Platform

Understand technical constraints.

**Core questions:**

> "What devices will people use?"

Listen for: Mobile, tablet, desktop, mix, primary vs secondary.

> "Mobile-first or desktop-first?"

Listen for: Where most users will be, which experience to optimize.

> "Any platform-specific requirements?"

Listen for: iOS vs Android patterns, web standards, native features.

> "Offline needs?"

Listen for: Must work offline, graceful degradation, sync behavior.

**Follow-ups:**

- If mobile-first: "What's the minimum viable desktop experience?"
- If desktop-first: "How degraded can mobile be?"
- If both equal: "Same design adapted, or different approaches?"

### 3. Flows & Interactions

Understand how users will move through the feature.

**Core questions:**

> "Walk me through the main user journey"

Listen for: Entry points, key steps, success state, exit points.

> "What are the critical moments in this flow?"

Listen for: Decision points, high-stakes actions, error-prone steps.

> "What happens when things go wrong?"

Listen for: Error states, recovery paths, help/support access.

> "Are there shortcuts power users would want?"

Listen for: Keyboard shortcuts, bulk actions, saved preferences.

**Follow-ups:**

- If complex flow: "Can we break this into steps/wizard?"
- If simple flow: "Any progressive disclosure opportunities?"
- If errors common: "How do we prevent vs recover?"

**Flow mapping probe:**
> "If I'm a new user, how do I get from [start] to [goal]?"

### 4. Visual & Brand

Understand aesthetic constraints.

**Core questions:**

> "Is there an existing design system to follow?"

Listen for: Component libraries, style guides, Figma files.

> "Any brand guidelines?"

Listen for: Colors, typography, voice/tone, logo usage.

> "What's the desired feel?"

Listen for: Playful, professional, minimal, rich, warm, clinical.

> "Any designs you like or want to avoid?"

Listen for: Competitor examples, inspirations, anti-patterns.

**Follow-ups:**

- If existing system: "How strictly should we follow it?"
- If no system: "Should we establish patterns for reuse?"
- If specific feel: "Show me an example that captures that?"

### 5. Accessibility & Inclusion

Understand how to serve all users.

**Core questions:**

> "Any specific accessibility requirements?"

Listen for: WCAG level, screen reader support, motor accommodations.

> "What's the minimum contrast/text size?"

Listen for: WCAG AA (4.5:1), AAA (7:1), large text needs.

> "How will this work with keyboard only?"

Listen for: Tab order, focus management, keyboard shortcuts.

> "Any internationalization needs?"

Listen for: RTL languages, text expansion, date/number formats.

**Follow-ups:**

- If WCAG required: "Level A, AA, or AAA?"
- If unsure: "Let's target WCAG AA as baseline"
- If i18n needed: "Which languages/regions?"

### 6. Trade-offs & Priorities

Understand what to optimize for.

**Core questions:**

> "What should we optimize for?"

Present options:
- **Simplicity** — Fewer options, faster to learn
- **Power** — More features, steeper learning curve
- **Speed** — Fast task completion, minimal steps
- **Delight** — Polish, animations, personality
- **Consistency** — Matches rest of system exactly
- **Innovation** — Novel patterns, differentiation

> "What are you willing to sacrifice?"

Listen for: Explicit trade-offs, what's less important.

> "What's more important: first-time experience or power user efficiency?"

Listen for: Onboarding vs daily use balance.

**Follow-ups:**

- If "all of the above": "If you had to rank top 2?"
- If simplicity: "What features can we cut or hide?"
- If power: "How do we not overwhelm new users?"

## Presenting Design Options

For significant UX decisions, present 2-3 options visually.

### Layout Option Format

```markdown
## Design Decision: [Screen/Component]

**User goal:** [What they're trying to accomplish]

### Option A: [Name]

```
[Text wireframe showing layout]
```

- **Flow:** [How user interacts]
- **Pros:** [Benefits]
- **Cons:** [Drawbacks]
- **Best when:** [Use case]

### Option B: [Name]

```
[Text wireframe showing layout]
```

- **Flow:** [How user interacts]
- **Pros:** [Benefits]
- **Cons:** [Drawbacks]
- **Best when:** [Use case]

**My recommendation:** Option [X]
**Rationale:** [Why this serves users better given stated priorities]

What's your preference?
```

### Common Design Decision Points

**Navigation pattern:**
- Bottom tab bar vs hamburger menu vs sidebar
- Persistent nav vs contextual nav

**Information display:**
- Cards vs list rows vs table
- Dense vs spacious layout

**Form design:**
- Single page vs multi-step wizard
- Inline validation vs submit validation

**Mobile adaptation:**
- Same layout scaled down vs restructured
- Progressive disclosure vs full feature parity

**Data entry:**
- Free text vs structured input
- Autocomplete vs manual

## Synthesizing into UX Design

After questions, map answers to design document:

| Question Category | Maps To |
|------------------|---------|
| Users & Context | User Goals, Flow entry points |
| Device & Platform | Responsive Behavior, Platform patterns |
| Flows & Interactions | User Flows, Screen Inventory |
| Visual & Brand | Design System Decisions |
| Accessibility | Accessibility Requirements |
| Trade-offs | Design Decisions with rationale |

### Draft UX Flow

1. Create user flow diagram in Mermaid
2. Sketch wireframes for key screens
3. Identify component inventory
4. Document responsive behavior
5. Note accessibility requirements
6. Record design decisions
7. Present draft for review
8. Iterate until approved
9. Write final to `docs/UX-DESIGN.md`

## Red Flags

Watch for these during elicitation:

- **No clear primary user** → Push for prioritization
- **"Everyone" is the user** → Probe for specific personas
- **No mobile consideration** → Flag mobile usage likelihood
- **Skipping accessibility** → Include WCAG AA baseline
- **Overcomplicating** → Challenge necessity of complexity
- **"Just make it look nice"** → Probe for specific qualities

## Adaptive Behavior

### Skip Questions When

- Answer is obvious from PRD
- Existing design system covers it
- Previous response answered it
- Simple feature doesn't need it

### Probe Deeper When

- Answer is vague ("make it intuitive")
- User flows have unclear steps
- Accessibility is handwaved
- Mobile is an afterthought

### Simplify When

- This is a prototype/MVP
- User prioritizes speed to ship
- Feature is internal/admin only
- Small user base

## Example Dialogue

```
Orchestrator: "The PRD mentions a calendar view for events.
What devices will people primarily use for this?"

User: "Mostly mobile — people checking schedules on the go"

Orchestrator: "Got it, mobile-first. For the calendar display, we have options:

Option A: Monthly grid (traditional calendar)
- Familiar pattern, good for overview
- Hard to read on small screens, lots of scrolling

Option B: Agenda list (upcoming events)
- Easy to scan, works well on mobile
- Loses monthly context

Option C: Week view with horizontal scroll
- Balance of context and detail
- More complex interaction

For mobile-first with quick schedule checks, I'd recommend
Option B (agenda) as default with Option C (week) as secondary view.
Thoughts?"

User: "Agenda makes sense. Can we add a mini month for context?"

Orchestrator: "Yes — a collapsed month picker at top that expands
when tapped. That gives you quick navigation without sacrificing
screen space. Let me sketch that..."

[continues...]
```

## Output

After UX design is approved:

1. Create `docs/UX-DESIGN.md` (or `docs/UX-DESIGN-<feature>.md`) with:
   - User flow diagrams
   - Screen wireframes
   - Component inventory
   - Responsive behavior
   - Accessibility requirements
   - Design decisions with rationale

2. Update `.meta/handoff.md` with:
   - UX summary
   - Screen list for implementation
   - Component library decisions
   - Any implementation notes
