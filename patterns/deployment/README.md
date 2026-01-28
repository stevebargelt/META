# Deployment Patterns

Reusable patterns for deployment, CI/CD, and infrastructure.

## Patterns in This Category

### CI/CD

- `ci-pipeline-node.md` — Standard GitHub Actions pipeline for Node.js (lint, test, coverage, build)
- `quality-gates.md` — Required gates, thresholds, and branch protection setup

### Infrastructure
*(Add patterns here as you create them)*

- Docker configurations
- Docker Compose setups
- Kubernetes manifests
- Cloud infrastructure (Terraform, etc.)

### Deployment Scripts
*(Add patterns here as you create them)*

- Zero-downtime deployment
- Database migration strategies
- Environment configuration
- Health checks

### External Services

- `supabase-setup.md` — Local + hosted Supabase setup checklist
- `supabase-initial-schema.sql` — Profiles + todos schema with RLS policies

## Usage

Reference deployment patterns:

```markdown
# In project AGENTS.md

CI/CD: META/patterns/deployment/ci-pipeline-node.md
Quality gates: META/patterns/deployment/quality-gates.md
Setup checklist: META/prompts/ci-setup-checklist.md
```

## When to Add Deployment Patterns

Add patterns for:
- CI/CD configs that work reliably
- Deployment scripts you'll reuse
- Infrastructure setups that are solid
- Automation that saves time

Must be **tested and working** before adding.
