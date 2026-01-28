# README Template — Next.js + Supabase App

**What:** A production-ready README structure for a Next.js + Supabase app.
**Best for:** Full‑stack web apps using Supabase Auth + Postgres.
**Tech stack:** Next.js (App Router), Supabase, TypeScript, Tailwind, Vitest.
**Source:** test-app-2 (2026-01)

---

# [Project Name]

One‑sentence summary of what the app does and who it is for.

## Features

- [Feature 1]
- [Feature 2]
- [Feature 3]

## Requirements

- Node.js 20+
- Supabase CLI + Docker (local dev)
- npm

## Quick Start

```bash
npm install
supabase start
cp .env.example .env
supabase db reset
npm run dev
```

## Configuration

Create `.env` from `.env.example`:

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

See `docs/SETUP.md` for hosted Supabase setup.

## Scripts

```bash
npm run dev
npm run build
npm run start
npm run lint
npm test
```

## Project Structure

```
src/
  app/          # Routes (Next.js App Router)
  features/     # Feature slices
  lib/          # Supabase client + shared utils
supabase/
  migrations/   # DB schema + RLS policies
```

## Tech Stack

- Next.js (App Router, TypeScript)
- Supabase (Postgres + Auth + RLS)
- Tailwind CSS
- Zod (validation)
- Vitest (testing)

## Testing

```bash
npm test
```

## Deployment

1. Push to GitHub
2. Connect to Vercel (or similar)
3. Set env vars
4. Push migrations: `supabase link --project-ref <ref> && supabase db push`

## Troubleshooting

- **Supabase connection error** → run `supabase status` / `supabase start`
- **Auth not working** → check `.env` values match `supabase status`
- **Migrations out of sync** → run `supabase db reset`

## Learn More

- `docs/SETUP.md`
- `docs/ARCHITECTURE.md`
- `docs/PRD.md`
