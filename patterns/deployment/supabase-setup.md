# Supabase Setup Guide (Local + Hosted)

**What:** Repeatable setup steps for Supabase projects (local dev + hosted).
**When to use:** Any project that uses Supabase for Auth/DB.
**Source:** test-app-2 (2026-01), updated 2026-02 for new API keys

## API Key Format (2025+)

> **Important:** Supabase now uses publishable/secret keys instead of legacy anon/service_role JWT keys. New projects only have the new format. See [API Keys Documentation](https://supabase.com/docs/guides/api/api-keys).

| Old Key | New Key | Format |
|---------|---------|--------|
| `anon` / `public` | `publishable` | `sb_publishable_xxx` |
| `service_role` | `secret` | `sb_secret_xxx` |

**Key differences:**
- New keys are opaque tokens, NOT JWTs
- Cannot use in `Authorization: Bearer` header (use user JWT instead)
- Edge Functions may need `--no-verify-jwt` flag
- Supabase Client libraries work without code changes

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
# fill SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, SUPABASE_SECRET_KEY
# (or VITE_SUPABASE_* / NEXT_PUBLIC_SUPABASE_* depending on framework)
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
| `SUPABASE_PUBLISHABLE_KEY` | Client | Public operations under RLS |
| `SUPABASE_SECRET_KEY` | Server only | Admin/server operations, bypasses RLS |

Never expose the secret key to the client.

## Environment Variable Naming

Adjust prefix based on your framework:

| Framework | Client Key | Server Key |
|-----------|------------|------------|
| Vite | `VITE_SUPABASE_PUBLISHABLE_KEY` | `SUPABASE_SECRET_KEY` |
| Next.js | `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `SUPABASE_SECRET_KEY` |
| Expo | `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `SUPABASE_SECRET_KEY` |

## Edge Functions

If calling Edge Functions with publishable/secret keys (not user JWTs):

```bash
# Deploy with --no-verify-jwt if needed
supabase functions deploy my-function --no-verify-jwt
```

Or extract the key from the `apikey` header in your function code.

## CI / Testing

Tests should run without real Supabase credentials (use mocks or a local Supabase instance in CI).
