# Project Structure Patterns

Full project templates and structure patterns.

## Patterns in This Category

### Language/Framework Templates
*(Add patterns here as you create them)*

- Node.js/Express API structure
- React application structure
- Python/FastAPI structure
- Go service structure
- Full-stack monorepo
 - Feature-first structure (vertical slices)

### Specialized Structures
*(Add patterns here as you create them)*

- Microservices organization
- Monorepo setup
- CLI tool structure
- Library/package structure

## Usage

Use these when starting new projects:

```bash
# Copy structure
cp -r META/patterns/project-structures/node-api-template my-new-api

# Or reference in planning
# See META/patterns/project-structures/react-app.md for structure
```

## When to Add Project Structures

Add structure patterns when you've:
- Built a project with a structure that worked well
- Refined the organization over time
- Want to replicate it for new projects

Include:
- Directory structure
- Key configuration files
- README template
- Initial dependencies
- Common scripts

## Templates in This Category

### Architecture Documentation

- **`ARCHITECTURE-template.md`** — Complete architecture document template
  - Uses Mermaid diagrams throughout
  - System architecture, sequence diagrams, data models
  - Decision records, security, observability sections
  - Production-ready structure with examples

### React Native + Module Federation

- **`rn-mf-contracts.md`** — Contract-first package template for host/remotes
- **`rn-mf-host-loader.md`** — Minimal host loader interface for MF remotes
 - **`feature-first.md`** — Feature-based folder structure (preferred)

## Format

```markdown
# [Project Type] Structure

**What:** Brief description
**Best for:** Type of projects
**Tech stack:** Languages/frameworks
**Source:** Project where refined

## Structure

\`\`\`
project/
├── src/
│   ├── [structure]
├── tests/
├── docs/
├── package.json
└── README.md
\`\`\`

## Key Files

Explain important files and their purpose

## Getting Started

How to use this structure for new project
```
