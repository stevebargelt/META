# Config Directory Pattern

**What:** Consolidate tool configuration files into a `config/` directory to reduce root clutter
**Best for:** Projects with multiple build tools, linters, and containerization
**Source:** META framework convention

## Problem

A typical JavaScript/TypeScript project accumulates many config files in root:

```
project/
├── .eslintrc.js
├── .prettierrc
├── tsconfig.json
├── jest.config.js
├── vitest.config.ts
├── Dockerfile
├── docker-compose.yml
├── tailwind.config.js
├── postcss.config.js
├── ...
```

This clutters the root and obscures the actual project structure.

## Solution

Move tool configs to `config/`, keep a minimal stub in root where required:

```
project/
├── tsconfig.json                 # Stub: extends config/tsconfig.base.json
├── config/
│   ├── tsconfig.base.json        # Actual TypeScript config
│   ├── eslint.config.js          # ESLint flat config
│   ├── .prettierrc               # Prettier config
│   ├── vitest.config.ts          # Vitest config
│   ├── Dockerfile                # Docker build
│   └── docker-compose.yml        # Docker Compose
└── src/
```

## Configuration by Tool

### TypeScript

Root `tsconfig.json` (stub):
```json
{
  "extends": "./config/tsconfig.base.json"
}
```

`config/tsconfig.base.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "strict": true,
    "outDir": "../dist"
  },
  "include": ["../src/**/*"],
  "exclude": ["../node_modules"]
}
```

### ESLint (Flat Config)

ESLint 9+ supports flat config with explicit path:

`package.json`:
```json
{
  "scripts": {
    "lint": "eslint --config config/eslint.config.js src/"
  }
}
```

`config/eslint.config.js`:
```js
import js from '@eslint/js'
import tseslint from 'typescript-eslint'

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.ts', '**/*.tsx'],
    rules: {
      // project rules
    }
  }
]
```

### Prettier

`package.json`:
```json
{
  "scripts": {
    "format": "prettier --config config/.prettierrc --write src/"
  }
}
```

### Vitest

`package.json`:
```json
{
  "scripts": {
    "test": "vitest --config config/vitest.config.ts"
  }
}
```

`config/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    root: '..',
    include: ['src/**/*.test.ts', 'tests/**/*.test.ts'],
    environment: 'node'
  }
})
```

### Docker

`package.json` or Makefile:
```json
{
  "scripts": {
    "docker:build": "docker build -f config/Dockerfile -t myapp .",
    "docker:up": "docker compose -f config/docker-compose.yml up -d"
  }
}
```

Note: Docker context is still project root (`.`), only the config file location changes.

### Tailwind CSS

`package.json`:
```json
{
  "scripts": {
    "build:css": "tailwindcss -c config/tailwind.config.js -i src/styles/globals.css -o dist/styles.css"
  }
}
```

## Files That Must Stay in Root

Some files cannot be moved due to tool requirements:

| File | Reason |
|------|--------|
| `package.json` | npm requires root |
| `.gitignore` | git requires root |
| `tsconfig.json` | IDE/tools auto-detect in root (use stub with extends) |
| `.env` / `.env.example` | Runtime config, many tools expect root |
| `README.md` | Convention |

## Directory Structure

```
project/
├── README.md                     # Keep in root
├── package.json                  # Keep in root (npm required)
├── tsconfig.json                 # Stub that extends config/
├── .gitignore                    # Keep in root (git required)
├── .env.example                  # Keep in root (convention)
│
├── config/                       # Tool configurations
│   ├── tsconfig.base.json
│   ├── eslint.config.js
│   ├── .prettierrc
│   ├── vitest.config.ts
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── tailwind.config.js
│
├── .meta/                        # META orchestration
│   └── handoff.md
│
├── docs/                         # Documentation
│   ├── ARCHITECTURE.md
│   └── PRD.md
│
├── src/                          # Source code
└── tests/                        # Tests
```

## When to Use

- Projects with 3+ config files in root
- Teams that value clean project structure
- Projects using Docker/containers
- Any project following META conventions

## When Not to Use

- Simple projects with 1-2 config files
- Projects where IDE integration requires specific paths
- Existing projects where migration cost exceeds benefit

## Migration Path

For existing projects:

1. Create `config/` directory
2. Move config files one at a time
3. Update `package.json` scripts with `--config` flags
4. Test that all tools still work
5. For tsconfig, create stub in root

## IDE Considerations

Some IDEs auto-detect config files in root. If moving configs breaks IDE features:

- **TypeScript**: Keep stub `tsconfig.json` in root (extends pattern)
- **ESLint**: Configure IDE to use explicit config path
- **Prettier**: Configure IDE to use explicit config path

Most modern IDEs support explicit config path settings.
