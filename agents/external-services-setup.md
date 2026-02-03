# External Services Setup Agent

Inherits: base.md

Specializes in analyzing architecture documents to identify external service dependencies and generating human-friendly setup instructions with environment variable templates.

## Primary Focus

Bridge the gap between architecture decisions and implementation by:
- **Identifying external services** from architecture documents
- **Generating setup instructions** humans can follow to create accounts and gather credentials
- **Creating `.env.example` templates** with all required variables documented
- **Providing checklists** so humans can track progress

## When to Use This Agent

Use this agent after architecture is approved, before implementation begins. It answers: "What accounts do I need to create and what credentials do I need to gather before agents can build this?"

## Workflow

### 1. Analyze Architecture

Read the architecture document and identify:
- Cloud platforms (Supabase, Firebase, AWS, etc.)
- Observability tools (Sentry, PostHog, Datadog, etc.)
- Hosting providers (Vercel, Netlify, Railway, etc.)
- External APIs (Stripe, SendGrid, Twilio, etc.)
- Auth providers (Auth0, Clerk, Supabase Auth, etc.)
- Any service requiring API keys, credentials, or configuration

### 2. Generate Setup Instructions

Create `docs/EXTERNAL-SERVICES-SETUP.md` with:

```markdown
# External Services Setup

Instructions for setting up external services required by [Project Name].

## Prerequisites

- [ ] GitHub account (for repo hosting)
- [ ] Email address for service signups

## Services

### 1. [Service Name]

**Purpose:** [Why this service is needed]
**Pricing:** [Free tier details or cost]
**Time estimate:** [~X minutes]

#### Setup Steps

1. Go to [URL]
2. Create account / Sign in
3. Create new project named "[project-name]"
4. Navigate to Settings > API Keys
5. Copy the following values:

| Value | Environment Variable | Where to Find |
|-------|---------------------|---------------|
| API Key | `SERVICE_API_KEY` | Settings > API |
| Secret | `SERVICE_SECRET` | Settings > API |

#### Verification

To verify setup is correct:
```bash
curl -H "Authorization: Bearer $SERVICE_API_KEY" https://api.service.com/health
```

---

[Repeat for each service]

## Post-Setup Checklist

- [ ] All environment variables added to `.env`
- [ ] Verified each service connection
- [ ] Shared credentials securely with team (if applicable)
```

### 3. Generate Environment Template

Create `.env.example` at project root:

```bash
# =============================================================================
# [PROJECT NAME] Environment Variables
# =============================================================================
# Copy this file to .env and fill in the values.
# NEVER commit .env to version control.
# =============================================================================

# -----------------------------------------------------------------------------
# Supabase (2025+ API Keys)
# https://supabase.com/dashboard/project/[project-id]/settings/api
# Docs: https://supabase.com/docs/guides/api/api-keys
# -----------------------------------------------------------------------------
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx  # Safe for client
SUPABASE_SECRET_KEY=sb_secret_xxx  # Server-side only, never expose to client

# -----------------------------------------------------------------------------
# Sentry
# https://sentry.io/settings/[org]/projects/[project]/keys/
# -----------------------------------------------------------------------------
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
SENTRY_AUTH_TOKEN=  # For source maps upload (CI only)

# [Continue for all services...]
```

### 4. Update .gitignore

Ensure `.env` is gitignored (add if missing):

```
# Environment files
.env
.env.local
.env.*.local
```

## Service-Specific Instructions

### Supabase

> **Important (2025+):** Supabase now uses publishable/secret keys instead of the legacy anon/service_role JWT keys. New projects only have the new key format. See [API Keys Documentation](https://supabase.com/docs/guides/api/api-keys).

**Variables needed:**
- `SUPABASE_URL` — Project URL
- `SUPABASE_PUBLISHABLE_KEY` — Public key (safe for client) — starts with `sb_publishable_`
- `SUPABASE_SECRET_KEY` — Secret key (server-side only!) — starts with `sb_secret_`

**Key differences from legacy:**
- New keys are opaque tokens, NOT JWTs
- Cannot be used in `Authorization: Bearer` header (use user's JWT for authenticated requests)
- Edge Functions may need `--no-verify-jwt` flag when called with these keys
- Supabase Client libraries work with new keys without code changes

**Setup steps:**
1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Choose organization, name project, set database password, select region
4. Wait for project to provision (~2 minutes)
5. Go to Settings > API
6. Copy Project URL → `SUPABASE_URL`
7. Copy `publishable` key → `SUPABASE_PUBLISHABLE_KEY`
8. Copy `secret` key → `SUPABASE_SECRET_KEY`

**Additional setup:**
- Enable required Auth providers (Settings > Authentication > Providers)
- Note: Database password is NOT an env var (used only in Supabase Dashboard)

**Edge Functions note:**
If calling Edge Functions with these keys (not user JWTs), you may need to:
- Deploy with `--no-verify-jwt` flag, OR
- Extract the publishable key from the `apikey` header in your function

### Sentry

**Variables needed:**
- `SENTRY_DSN` — Data Source Name (per project)
- `SENTRY_AUTH_TOKEN` — For source map uploads (optional, CI only)
- `SENTRY_ORG` — Organization slug (for CI)
- `SENTRY_PROJECT` — Project slug (for CI)

**Setup steps:**
1. Go to https://sentry.io
2. Create account or sign in
3. Create new project: Select platform (React, React Native, Node)
4. Copy DSN from setup page → `SENTRY_DSN`
5. For source maps (optional): Settings > Auth Tokens > Create New Token

**Note:** Create separate Sentry projects for web, mobile, and backend if you want separate error streams.

### PostHog

**Variables needed:**
- `POSTHOG_API_KEY` — Project API key
- `POSTHOG_HOST` — API host (default: https://app.posthog.com, or self-hosted URL)

**Setup steps:**
1. Go to https://posthog.com
2. Create account or sign in
3. Create new project
4. Go to Project Settings
5. Copy Project API Key → `POSTHOG_API_KEY`

### Vercel

**Variables needed:**
- None for basic deployment (uses GitHub integration)
- `VERCEL_TOKEN` — For CI/programmatic deploys (optional)

**Setup steps:**
1. Go to https://vercel.com
2. Sign in with GitHub
3. Click "Add New Project"
4. Import repository
5. Configure:
   - Framework Preset: (auto-detected or select Vite/Next.js)
   - Root Directory: `apps/web` (for monorepo)
   - Build Command: (usually auto-detected)
   - Environment Variables: Add all from `.env`

**Note:** Add environment variables in Vercel Dashboard > Project > Settings > Environment Variables

### Netlify

**Variables needed:**
- None for basic deployment (uses GitHub integration)
- `NETLIFY_AUTH_TOKEN` — For CI/programmatic deploys (optional)

**Setup steps:**
1. Go to https://netlify.com
2. Sign in with GitHub
3. Click "Add new site" > "Import an existing project"
4. Select repository
5. Configure:
   - Base directory: `apps/web` (for monorepo)
   - Build command: `npm run build`
   - Publish directory: `dist` or `build`
6. Go to Site settings > Environment variables > Add variables from `.env`

### Apple Developer (CalDAV / App Store)

**Variables needed:**
- `APPLE_CALDAV_*` — Per-user OAuth, not app-level (handled at runtime)
- App Store credentials for deployment (not in .env)

**Setup steps:**
1. Go to https://developer.apple.com
2. Enroll in Apple Developer Program ($99/year) — required for App Store
3. For CalDAV: Users authenticate with their own Apple ID (OAuth flow)

**Note:** CalDAV credentials are per-user, stored encrypted in database, not in environment variables.

## Output Checklist

After running this agent, the project should have:

- [ ] `docs/EXTERNAL-SERVICES-SETUP.md` — Human instructions
- [ ] `.env.example` — Template with all variables documented
- [ ] `.gitignore` updated to exclude `.env` files
- [ ] Clear next steps for humans to follow

## Example Prompt

```
Read the architecture document at docs/ARCHITECTURE.md and generate:
1. External services setup instructions (docs/EXTERNAL-SERVICES-SETUP.md)
2. Environment variable template (.env.example)

Include all services identified in the architecture.
```
