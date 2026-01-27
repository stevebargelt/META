# React Native Module Federation: Contracts Package

**What:** Contract-first types for a React Native host + remote setup
**Best for:** Bare RN (New Architecture) projects using Metro Module Federation
**Source:** Template for parallel agent teams

## Goals

- Enable parallel teams by locking contracts early
- Keep host and remotes decoupled
- Provide stable type boundaries for navigation, events, and API usage

## Package Structure

```
packages/contracts/
├── package.json
├── src/
│   ├── navigation.ts
│   ├── events.ts
│   ├── api.ts
│   ├── remotes.ts
│   └── index.ts
└── README.md
```

## navigation.ts

```ts
export type RemoteRoute =
  | { name: 'RemoteA/Home'; params?: Record<string, never> }
  | { name: 'RemoteB/Profile'; params: { userId: string } }

export type RouteRegistration = {
  name: RemoteRoute['name']
  component: React.ComponentType<any>
  options?: Record<string, unknown>
}

export type RegisterRoutes = () => RouteRegistration[]
```

## events.ts

```ts
export type AppEvent =
  | { type: 'UserLoggedIn'; payload: { userId: string } }
  | { type: 'CheckoutCompleted'; payload: { orderId: string } }

export type EventHandler<T extends AppEvent['type']> = (
  event: Extract<AppEvent, { type: T }>
) => void
```

## api.ts

```ts
export type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string }

export type UserProfile = {
  id: string
  name: string
}

export interface ApiClient {
  getUserProfile(userId: string): Promise<ApiResult<UserProfile>>
}
```

## remotes.ts

```ts
import type { RegisterRoutes } from './navigation'

export type RemoteModule = {
  registerRoutes: RegisterRoutes
  bootstrap?: () => Promise<void>
}

export type RemoteManifest = Record<
  string,
  { version: string; entryUrl: string }
>
```

## index.ts

```ts
export * from './navigation'
export * from './events'
export * from './api'
export * from './remotes'
```

## Notes

- Keep this package small and stable.
- Any breaking change requires a version bump and coordination.
- Use this package as the single source of truth for host/remote integration.

