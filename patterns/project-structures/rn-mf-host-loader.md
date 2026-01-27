# React Native Module Federation: Host Loader Interface

**What:** Minimal host-side loader contract for Metro Module Federation remotes
**Best for:** Bare RN (New Architecture) projects using Zephyr + Metro MF
**Source:** Template for parallel agent teams

## Goals

- Keep host shell thin and stable
- Allow remotes to register screens independently
- Isolate remote loading from navigation setup

## Core Interface (Host)

```ts
import type { RemoteManifest, RemoteModule } from 'packages/contracts'

export type RemoteLoader = {
  loadRemote: (name: string) => Promise<RemoteModule>
}

export async function createRemoteLoader(
  manifest: RemoteManifest,
  runtimeLoad: (entryUrl: string, name: string) => Promise<RemoteModule>
): Promise<RemoteLoader> {
  return {
    loadRemote: async (name: string) => {
      const remote = manifest[name]
      if (!remote) {
        throw new Error(`Unknown remote: ${name}`)
      }
      return runtimeLoad(remote.entryUrl, name)
    },
  }
}
```

## Metro MF Runtime Load (Example)

This uses the Module Federation runtime API. If you already use the Metro build plugin,
you can call `loadRemote` directly. Otherwise, create an instance first.

```ts
import { createInstance } from '@module-federation/enhanced/runtime'
import type { RemoteManifest, RemoteModule } from 'packages/contracts'

export function createRuntimeLoad(manifest: RemoteManifest) {
  const mf = createInstance({
    name: 'host',
    remotes: Object.entries(manifest).map(([name, { entryUrl }]) => ({
      name,
      entry: entryUrl,
    })),
    shareStrategy: 'version-first',
  })

  return async (_entryUrl: string, name: string) => {
    // Use `${name}/module` if your remote exposes "./module"
    const module = await mf.loadRemote(`${name}/module`)
    return module as RemoteModule
  }
}
```

Example manifest (host-side config):

```ts
const manifest = {
  remoteA: { version: '1.0.0', entryUrl: 'http://localhost:8082/mf-manifest.json' },
  remoteB: { version: '1.0.0', entryUrl: 'http://localhost:8083/mf-manifest.json' },
}
```

## Navigation Integration (Host)

```ts
import type { RegisterRoutes, RouteRegistration } from 'packages/contracts'

export async function registerRemoteRoutes(
  loadRemote: (name: string) => Promise<{ registerRoutes: RegisterRoutes }>,
  remotes: string[]
): Promise<RouteRegistration[]> {
  const all = await Promise.all(
    remotes.map(async (name) => {
      const module = await loadRemote(name)
      return module.registerRoutes()
    })
  )
  return all.flat()
}
```

## Remote Export (Remote App)

```ts
import type { RegisterRoutes } from 'packages/contracts'
import RemoteHome from './screens/RemoteHome'

export const registerRoutes: RegisterRoutes = () => [
  {
    name: 'RemoteA/Home',
    component: RemoteHome,
  },
]
```

## Notes

- `runtimeLoad` is the only place that knows about Metro MF runtime.
- Keep a single shared `contracts` package to avoid drift.
- Host should handle errors with a fallback screen if a remote fails to load.
