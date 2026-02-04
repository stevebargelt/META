# Feature-First Project Structure

**What:** Organize code by feature (vertical slices), not by technical layers
**Best for:** Products with multiple features and parallel teams/agents
**Source:** Preferred default structure

## Principles

- Each feature owns its UI, state, data access, and tests
- Keep shared code minimal and explicit
- Prefer vertical slices over horizontal layers (no global `models/`, `ui/`, `services/` at top level)

## Example Structure (Generic)

```
src/
├── app/                       # App bootstrap, navigation, providers
├── features/
│   ├── home/
│   │   ├── screens/
│   │   ├── components/
│   │   ├── state/
│   │   ├── api/
│   │   ├── types.ts
│   │   └── index.ts
│   ├── profile/
│   │   ├── screens/
│   │   ├── components/
│   │   ├── state/
│   │   ├── api/
│   │   ├── types.ts
│   │   └── index.ts
│   └── checkout/
│       ├── screens/
│       ├── components/
│       ├── state/
│       ├── api/
│       ├── types.ts
│       └── index.ts
├── shared/                    # Cross-feature, minimal
│   ├── ui/
│   ├── hooks/
│   ├── utils/
│   └── types/
└── index.ts
```

## Rules of Thumb

- If a file is used by one feature, it stays in that feature.
- If two features share it, promote to `shared/` **only after** duplication hurts.
- Shared modules must be stable and owned; avoid becoming a new “layered” dump.

## Feature Index Pattern

Each feature exposes only its public surface:

```
features/home/index.ts
```

```ts
export { HomeScreen } from './screens/HomeScreen'
export { useHomeState } from './state/useHomeState'
export type { HomeParams } from './types'
```

## Testing

Tests live with the feature:

```
features/home/__tests__/
```

Integration tests can live in:

```
tests/integration/
```

## Parallel Development (CRITICAL)

**The PRIMARY reason for feature-first structure is parallel development.**

When features are self-contained:
- Multiple agents/teams can work simultaneously
- No file conflicts or merge hell
- Linear time reduction: 4 features = 4x speedup

**Pipeline Pattern:**
```
8 | base | - | auto | features | 30 | Implement features/calendar
9 | base | - | auto | features | 30 | Implement features/tasks
10 | base | - | auto | features | 30 | Implement features/meals
11 | base | - | auto | features | 30 | Implement features/recipes
```
All run in parallel with group "features" → completes in 30 minutes instead of 120 minutes.

**If you're not parallelizing features, you're wasting 75% of your time.**

## When to Break the Rule

- Domain libraries that are truly shared across many features
- Core infrastructure: routing, auth bootstrap, logging, analytics
- Design system (if used across all features)

If you find yourself creating `models/`, `ui/`, `services/` at the top level,
re-evaluate — it usually means features are underspecified or over-shared.

