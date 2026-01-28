# Supabase Setup Guide (Local + Hosted)

**What:** Repeatable setup steps for Supabase projects (local dev + hosted).
**When to use:** Any project that uses Supabase for Auth/DB.
**Source:** test-app-2 (2026-01)

## Prerequisites

- Node.js 20+
- Supabase CLI (requires Docker)
- Docker running locally

## Local Development

1) Install dependencies

```bash
npm install
```

2) Initialize + start Supabase (first time only)

```bash
supabase init
supabase start
```

3) Copy env and fill values from `supabase status`

```bash
cp .env.example .env
# fill NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
```

4) Apply migrations

```bash
supabase db reset
```

5) Run the app

```bash
npm run dev
```

## Hosted Supabase (Staging/Production)

1) Create a Supabase project
2) Copy project URL and keys from **Settings → API**
3) Set env vars in hosting platform
4) Push migrations:

```bash
supabase link --project-ref <project-ref>
supabase db push
```

## Key Usage

| Key | Where | Purpose |
|-----|-------|---------|
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Client | Public operations under RLS |
| `SUPABASE_SERVICE_ROLE_KEY` | Server only | Admin/server operations |

Never expose the service role key to the client.

## CI / Testing

Tests should run without real Supabase credentials (use mocks or a local Supabase instance in CI).
