# Patterns Index

Separates runnable code patterns from reference documentation.

## Runnable Code (5)

| Pattern | File | Language |
|---------|------|----------|
| Observability middleware | `api/observability-middleware.js` | JavaScript |
| REST error handling | `api/rest-error-handling.ts` | TypeScript |
| Zod validation middleware | `api/zod-validation-middleware.js` | JavaScript |
| Supabase JWT middleware | `auth/supabase-jwt-middleware.js` | JavaScript |
| Supertest in-memory testing | `testing/supertest-in-memory.js` | JavaScript |

## Reference Docs (7)

| Document | File | Type |
|----------|------|------|
| JWT refresh token rotation | `auth/jwt-refresh-rotation.md` | Design pattern |
| Feature-first project structure | `project-structures/feature-first.md` | Structure guide |
| RN micro-frontend contracts | `project-structures/rn-mf-contracts.md` | Template |
| RN micro-frontend host loader | `project-structures/rn-mf-host-loader.md` | Template |
| CI pipeline (Node) | `deployment/ci-pipeline-node.md` | CI template |
| Quality gates | `deployment/quality-gates.md` | Checklist |
| Supabase setup | `deployment/supabase-setup.md` | Setup guide |

## Other Files

| File | Type |
|------|------|
| `deployment/supabase-initial-schema.sql` | SQL seed file |
| `project-structures/ARCHITECTURE-template.md` | Template |
| `project-structures/readme-supabase-next.md` | README template |
| Category READMEs (`api/`, `auth/`, `testing/`, `deployment/`, `project-structures/`) | Directory indexes |

## Goal

Target: 10 runnable code patterns. Currently at 5.

Candidates for next patterns:
- Authentication flow (login/logout/session management)
- Database migration setup
- WebSocket connection handling
- Rate limiting middleware
- File upload handling
