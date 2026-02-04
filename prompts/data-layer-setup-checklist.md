# Data Layer Setup Checklist

Setup checklist for connecting frontend to backend. Run BEFORE frontend UI implementation.

## Goal

Ensure the frontend has all infrastructure needed to fetch real data from the backend. After this step, frontend developers can import hooks and start building UI with real data.

## Prerequisites

- Database migrations applied
- Backend/BFF layer deployed or running locally
- Auth configured in backend

## Checklist

### 1. Generate Database Types

For Supabase projects:
```bash
supabase gen types typescript --project-id <project-id> > packages/shared-types/src/database.ts
cd packages/shared-types && npm run build
```

Verify types are exported:
```typescript
// packages/shared-types/src/index.ts
export * from './database';
```

### 2. Create Typed API Client

Create `apps/web/src/lib/supabase.ts` (or equivalent):

```typescript
import { createClient } from '@supabase/supabase-js';
import type { Database } from '@myapp/shared-types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient<Database>(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
});
```

### 3. Setup Data Fetching Provider

Add QueryClientProvider to app entry point (`main.tsx` or `App.tsx`):

```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
});

// Wrap app
<QueryClientProvider client={queryClient}>
  <App />
</QueryClientProvider>
```

### 4. Create Auth Hook

Create `hooks/useAuth.ts`:

```typescript
import { useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setSession(session);
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null);
        setSession(session);
        setLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  return { user, session, loading };
}
```

### 5. Create Entity Hooks

For each domain entity, create a hook file. Example for tasks:

```typescript
// hooks/useTasks.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuth } from './useAuth';

export function useTasks() {
  const { user } = useAuth();

  return useQuery({
    queryKey: ['tasks'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data;
    },
    enabled: !!user,
  });
}

export function useCreateTask() {
  const queryClient = useQueryClient();
  const { user } = useAuth();

  return useMutation({
    mutationFn: async (input: { title: string; description?: string }) => {
      if (!user) throw new Error('Not authenticated');

      const { data, error } = await supabase
        .from('tasks')
        .insert({ ...input, created_by: user.id })
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
    },
  });
}

// Add useUpdateTask, useDeleteTask similarly
```

### 6. Export Hooks

Update `hooks/index.ts`:

```typescript
export * from './useAuth';
export * from './useTasks';
export * from './useEvents';
export * from './useMeals';
// etc.
```

## Verification

Before marking complete, verify:

- [ ] `npm run typecheck` passes
- [ ] `npm run build` passes
- [ ] Can import hooks in a test component
- [ ] Hooks return loading/error states correctly
- [ ] Auth hook detects logged-in user

## Output

Update `.meta/handoff.md` with:
- List of hooks created
- Any auth considerations for frontend
- Notes on data relationships or special queries needed

## Common Issues

**"Module not found" for database types:**
- Rebuild shared-types package after generating types
- Check tsconfig paths are correct

**React Query errors:**
- Ensure QueryClientProvider wraps entire app
- Check that hooks are called inside React components

**Auth not working:**
- Verify environment variables are set
- Check Supabase project auth settings
