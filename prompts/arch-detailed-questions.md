# Detailed Architecture Questions

Comprehensive architecture elicitation framework for detailed Architecture mode. Used by project-orchestrator agent after PRD is complete.

## Purpose

Gather enough information to design a solid architecture by exploring:
1. System context and integrations
2. Data and state management
3. Scale and performance needs
4. Security requirements
5. Trade-offs and priorities

## Before Starting

**Prerequisites:**
- PRD complete and approved (`docs/PRD-<feature>.md`)
- Kickoff complete with "Detailed Architecture" selected

**Context to have ready:**
- PRD requirements (Must/Should/Won't)
- Existing architecture if adding to existing project
- Any technical constraints from kickoff
- Competitive analysis (if created)

## Question Categories

### 1. System Context

Understand what this system touches.

**Core questions:**

> "What external systems does this need to integrate with?"

Listen for: APIs, databases, third-party services, internal systems.

> "What are the external dependencies?"

Listen for: Services that must be available, data sources, auth providers.

> "Where will this run?"

Listen for: Cloud provider, on-prem, edge, hybrid, serverless.

> "What's the deployment model?"

Listen for: Containers, VMs, serverless, static hosting.

**Follow-ups:**

- If integrations mentioned: "What's the interface? REST, GraphQL, events?"
- If cloud mentioned: "Any specific services you want to use or avoid?"
- If existing system: "Show me the current architecture?"

**For existing projects:**
> "How does this feature fit into the existing system?"

Listen for: New service, extension of existing, separate module.

### 2. Data & State

Understand what needs to persist and where.

**Core questions:**

> "What data does this feature need to store?"

Listen for: Entities, relationships, volume, sensitivity.

> "Who owns this data?"

Listen for: User-owned, system-owned, shared, external source.

> "What are the consistency requirements?"

Listen for: Strong consistency, eventual consistency, real-time needs.

> "How long does data need to persist?"

Listen for: Forever, session-scoped, TTL, regulatory requirements.

**Follow-ups:**

- If database mentioned: "Any preference on database type?"
- If real-time needed: "What's the acceptable staleness?"
- If sensitive data: "Any encryption or compliance requirements?"

**Data modeling probe:**
> "Walk me through the main entities and how they relate"

### 3. Scale & Performance

Understand load and growth expectations.

**Core questions:**

> "What's the expected load?"

Listen for: Users, requests/second, data volume, concurrent connections.

> "What are the latency requirements?"

Listen for: Response time targets, p95/p99 expectations, user-facing vs background.

> "What happens during peak load?"

Listen for: Traffic spikes, graceful degradation, scaling behavior.

> "What's the growth expectation?"

Listen for: 10x in a year, stable, seasonal patterns.

**Follow-ups:**

- If high scale: "What's the cost sensitivity vs performance trade-off?"
- If low scale: "Should we optimize for simplicity over scalability?"
- If unsure: "Let's design for [reasonable default] with room to grow"

**Reality check:**
> "What's today's actual load? What's realistic for 6 months out?"

### 4. Security

Understand authentication, authorization, and data protection.

**Core questions:**

> "What's the authentication model?"

Listen for: OAuth, JWT, sessions, API keys, SSO.

> "What's the authorization model?"

Listen for: Roles, permissions, resource-based, attribute-based.

> "Any sensitive data handling requirements?"

Listen for: PII, payment data, health data, encryption needs.

> "Any compliance requirements?"

Listen for: GDPR, HIPAA, SOC2, PCI-DSS.

**Follow-ups:**

- If auth exists: "Using existing auth or new?"
- If sensitive data: "Encryption at rest? In transit? Both?"
- If compliance: "Any specific controls required?"

**For user-facing features:**
> "What can users see/do with each other's data?"

### 5. Trade-offs & Priorities

Understand what to optimize for.

**Core questions:**

> "What should we optimize for?"

Present options:
- **Speed of development** — Ship fast, iterate later
- **Performance** — Low latency, high throughput
- **Simplicity** — Easy to understand and maintain
- **Flexibility** — Easy to change and extend
- **Cost** — Minimize infrastructure spend
- **Reliability** — High availability, fault tolerance

> "What are you willing to sacrifice?"

Listen for: Explicit trade-offs, what's less important.

> "Any technology preferences or constraints?"

Listen for: Team expertise, existing stack, mandates, things to avoid.

**Follow-ups:**

- If "all of the above": "If you had to rank top 2?"
- If speed: "What's acceptable technical debt?"
- If reliability: "What's the uptime target? Cost of downtime?"

## Presenting Options

For significant decisions, present 2-3 options with trade-offs.

### Option Presentation Format

```markdown
## Decision: [Topic]

**Context:** [Why this decision matters]

### Option A: [Name]
- **How it works:** [Brief description]
- **Pros:** [Benefits]
- **Cons:** [Drawbacks]
- **Best when:** [Use case]
- **Example:** [Real-world example if helpful]

### Option B: [Name]
- **How it works:** [Brief description]
- **Pros:** [Benefits]
- **Cons:** [Drawbacks]
- **Best when:** [Use case]
- **Example:** [Real-world example if helpful]

### Option C: [Name] (if applicable)
[Same structure]

**My recommendation:** Option [X]
**Rationale:** [Why this fits our context]

What's your preference?
```

### Common Decision Points

**Database choice:**
- PostgreSQL vs MongoDB vs SQLite
- Managed vs self-hosted
- Single vs replicated

**API style:**
- REST vs GraphQL vs gRPC
- Monolith vs microservices

**State management:**
- Server-side sessions vs JWT
- Redis vs in-memory vs database

**Async processing:**
- Queues vs events vs cron
- Which queue system

**Frontend architecture:**
- SSR vs SPA vs hybrid
- State management approach

## Synthesizing into Architecture

After questions, map answers to architecture document:

| Question Category | Maps To |
|------------------|---------|
| System Context | System Overview, Integrations |
| Data & State | Data Model, Storage decisions |
| Scale & Performance | Constraints & SLOs |
| Security | Security model, Threats & Risks |
| Trade-offs | Key Decisions with rationale |

### Draft Architecture Flow

1. Create system overview with Mermaid diagram
2. Document each component's responsibility
3. Create sequence diagrams for key flows
4. Document data model
5. Record all decisions with rationale
6. Present draft for review
7. Iterate until approved
8. Write final to `docs/ARCHITECTURE.md`

## Red Flags

Watch for these during elicitation:

- **No clear scale requirements** → Assume modest scale, design for growth
- **Everything is critical** → Push for prioritization
- **No security consideration** → Probe for auth/authz needs
- **Overengineering** → Challenge complexity, suggest simpler options
- **Underengineering** → Flag risks, suggest safeguards

## Adaptive Behavior

### Skip Questions When

- Answer is obvious from PRD
- Existing architecture answers it
- Previous response covered it
- Simple feature doesn't need it

### Probe Deeper When

- Answer is vague ("we'll figure it out")
- Risk is glossed over
- Scale assumptions seem unrealistic
- Security is handwaved

### Simplify When

- This is a prototype/MVP
- User prioritizes speed
- Scale is genuinely small
- Team is small

## Example Dialogue

```
Orchestrator: "Looking at the PRD, the shopping list feature needs to persist
user lists and aggregate ingredients. What database does the app currently use?"

User: "SQLite for now, but thinking about migrating"

Orchestrator: "For the shopping list, we have a few options:

Option A: Extend SQLite
- Pros: No migration needed, simple
- Cons: Scaling limits, concurrent write issues

Option B: Add PostgreSQL for new features
- Pros: Better for growth, good query capabilities
- Cons: More infrastructure, migration complexity

Option C: Separate service with its own database
- Pros: Independent scaling, clean boundary
- Cons: More complex, overkill for this feature

Given the PRD scope and current scale, I'd recommend Option A for now with
a clear migration path to B. Thoughts?"

User: "Option A makes sense. We can migrate later if needed."

Orchestrator: "Good. For the ingredient aggregation — that's compute-intensive.
Should it happen:
- On-demand when user views the list (simpler, always fresh)
- Pre-computed when recipes are added (faster reads, stale risk)
- Background job that updates periodically (balanced)

What's your preference?"

[continues...]
```

## Output

After architecture is approved:

1. Update `docs/ARCHITECTURE.md` with:
   - Feature section with diagrams
   - Component descriptions
   - Key decisions with rationale
   - Implementation order

2. Update `.meta/handoff.md` with:
   - Architecture summary
   - Key decisions made
   - Implementation notes for pipeline
