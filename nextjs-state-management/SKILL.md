---
name: nextjs-state-management
description: Implement client-side state management in Next.js v15 using zustand for global state, with persistence, middleware, and TypeScript support.
---

# Next.js State Management with Zustand

You are an expert at implementing state management in Next.js v15 applications using zustand for global client-side state.

## Tech Stack Context
- **Next.js**: v15 with App Router
- **State Management**: zustand
- **Validation**: zod
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **Database**: Supabase without RLS
- **Deployment**: OpenNext compiled to Cloudflare Workers

## Core Zustand Setup

### 1. Install Dependencies

```bash
npm install zustand
npm install -D @types/node  # For TypeScript support
```

### 2. Basic Store Pattern

```typescript
// stores/use-counter-store.ts
import { create } from 'zustand'

interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
  reset: () => void
}

export const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}))
```

Usage in components:
```typescript
'use client'

import { useCounterStore } from '@/stores/use-counter-store'

export function Counter() {
  const { count, increment, decrement, reset } = useCounterStore()

  return (
    <div className="flex gap-4 items-center">
      <button onClick={decrement}>-</button>
      <span>{count}</span>
      <button onClick={increment}>+</button>
      <button onClick={reset}>Reset</button>
    </div>
  )
}
```

### 3. Advanced Store Patterns

#### User Authentication Store

```typescript
// stores/use-auth-store.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import type { User } from '@supabase/supabase-js'

interface AuthState {
  user: User | null
  isLoading: boolean

  // Actions
  setUser: (user: User | null) => void
  setLoading: (isLoading: boolean) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      isLoading: true,

      setUser: (user) => set({ user, isLoading: false }),
      setLoading: (isLoading) => set({ isLoading }),
      logout: () => set({ user: null }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({ user: state.user }), // Only persist user
    }
  )
)
```

#### UI State Store

```typescript
// stores/use-ui-store.ts
import { create } from 'zustand'

interface UIState {
  // Sidebar
  sidebarOpen: boolean
  toggleSidebar: () => void
  setSidebarOpen: (open: boolean) => void

  // Modal
  modalOpen: boolean
  modalContent: React.ReactNode | null
  openModal: (content: React.ReactNode) => void
  closeModal: () => void

  // Theme
  theme: 'light' | 'dark' | 'system'
  setTheme: (theme: 'light' | 'dark' | 'system') => void

  // Loading
  isLoading: boolean
  setLoading: (loading: boolean) => void
}

export const useUIStore = create<UIState>((set) => ({
  // Sidebar
  sidebarOpen: true,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
  setSidebarOpen: (open) => set({ sidebarOpen: open }),

  // Modal
  modalOpen: false,
  modalContent: null,
  openModal: (content) => set({ modalOpen: true, modalContent: content }),
  closeModal: () => set({ modalOpen: false, modalContent: null }),

  // Theme
  theme: 'system',
  setTheme: (theme) => set({ theme }),

  // Loading
  isLoading: false,
  setLoading: (loading) => set({ isLoading: loading }),
}))
```

#### Shopping Cart Store

```typescript
// stores/use-cart-store.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
  image?: string
}

interface CartState {
  items: CartItem[]

  // Computed
  totalItems: () => number
  totalPrice: () => number

  // Actions
  addItem: (item: Omit<CartItem, 'quantity'>) => void
  removeItem: (id: string) => void
  updateQuantity: (id: string, quantity: number) => void
  clearCart: () => void
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],

      totalItems: () => {
        return get().items.reduce((sum, item) => sum + item.quantity, 0)
      },

      totalPrice: () => {
        return get().items.reduce((sum, item) => sum + item.price * item.quantity, 0)
      },

      addItem: (newItem) =>
        set((state) => {
          const existingItem = state.items.find((item) => item.id === newItem.id)

          if (existingItem) {
            return {
              items: state.items.map((item) =>
                item.id === newItem.id
                  ? { ...item, quantity: item.quantity + 1 }
                  : item
              ),
            }
          }

          return {
            items: [...state.items, { ...newItem, quantity: 1 }],
          }
        }),

      removeItem: (id) =>
        set((state) => ({
          items: state.items.filter((item) => item.id !== id),
        })),

      updateQuantity: (id, quantity) =>
        set((state) => ({
          items: state.items.map((item) =>
            item.id === id ? { ...item, quantity } : item
          ),
        })),

      clearCart: () => set({ items: [] }),
    }),
    {
      name: 'cart-storage',
      storage: createJSONStorage(() => localStorage),
    }
  )
)
```

### 4. Store with Middleware

#### Logging Middleware

```typescript
// stores/middleware/logger.ts
import type { StateCreator, StoreMutatorIdentifier } from 'zustand'

type Logger = <
  T,
  Mps extends [StoreMutatorIdentifier, unknown][] = [],
  Mcs extends [StoreMutatorIdentifier, unknown][] = []
>(
  f: StateCreator<T, Mps, Mcs>,
  name?: string
) => StateCreator<T, Mps, Mcs>

export const logger: Logger = (f, name) => (set, get, store) => {
  const loggedSet: typeof set = (...a) => {
    set(...a)
    console.log('[Store Update]', name || 'Unknown', get())
  }
  return f(loggedSet, get, store)
}
```

Usage:
```typescript
import { create } from 'zustand'
import { logger } from './middleware/logger'

interface State {
  count: number
  increment: () => void
}

export const useStore = create<State>()(
  logger(
    (set) => ({
      count: 0,
      increment: () => set((state) => ({ count: state.count + 1 })),
    }),
    'CounterStore'
  )
)
```

#### Immer Middleware (for immutable updates)

```bash
npm install immer
```

```typescript
// stores/use-todo-store.ts
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'

interface Todo {
  id: string
  title: string
  completed: boolean
}

interface TodoState {
  todos: Todo[]
  addTodo: (title: string) => void
  toggleTodo: (id: string) => void
  removeTodo: (id: string) => void
}

export const useTodoStore = create<TodoState>()(
  immer((set) => ({
    todos: [],

    addTodo: (title) =>
      set((state) => {
        state.todos.push({
          id: crypto.randomUUID(),
          title,
          completed: false,
        })
      }),

    toggleTodo: (id) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id)
        if (todo) {
          todo.completed = !todo.completed
        }
      }),

    removeTodo: (id) =>
      set((state) => {
        state.todos = state.todos.filter((t) => t.id !== id)
      }),
  }))
)
```

### 5. Async Actions with Zustand

```typescript
// stores/use-posts-store.ts
import { create } from 'zustand'

interface Post {
  id: string
  title: string
  content: string
}

interface PostsState {
  posts: Post[]
  isLoading: boolean
  error: string | null

  // Actions
  fetchPosts: () => Promise<void>
  addPost: (post: Omit<Post, 'id'>) => Promise<void>
  deletePost: (id: string) => Promise<void>
}

export const usePostsStore = create<PostsState>((set, get) => ({
  posts: [],
  isLoading: false,
  error: null,

  fetchPosts: async () => {
    set({ isLoading: true, error: null })
    try {
      const response = await fetch('/api/posts')
      const posts = await response.json()
      set({ posts, isLoading: false })
    } catch (error) {
      set({ error: 'Failed to fetch posts', isLoading: false })
    }
  },

  addPost: async (post) => {
    set({ isLoading: true, error: null })
    try {
      const response = await fetch('/api/posts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(post),
      })
      const newPost = await response.json()
      set((state) => ({
        posts: [...state.posts, newPost],
        isLoading: false,
      }))
    } catch (error) {
      set({ error: 'Failed to add post', isLoading: false })
    }
  },

  deletePost: async (id) => {
    set({ isLoading: true, error: null })
    try {
      await fetch(`/api/posts/${id}`, { method: 'DELETE' })
      set((state) => ({
        posts: state.posts.filter((p) => p.id !== id),
        isLoading: false,
      }))
    } catch (error) {
      set({ error: 'Failed to delete post', isLoading: false })
    }
  },
}))
```

### 6. Slices Pattern (for large stores)

```typescript
// stores/slices/user-slice.ts
import type { StateCreator } from 'zustand'

export interface UserSlice {
  user: {
    id: string
    name: string
    email: string
  } | null
  setUser: (user: UserSlice['user']) => void
  clearUser: () => void
}

export const createUserSlice: StateCreator<UserSlice> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
})
```

```typescript
// stores/slices/settings-slice.ts
import type { StateCreator } from 'zustand'

export interface SettingsSlice {
  settings: {
    theme: 'light' | 'dark'
    language: string
    notifications: boolean
  }
  updateSettings: (settings: Partial<SettingsSlice['settings']>) => void
}

export const createSettingsSlice: StateCreator<SettingsSlice> = (set) => ({
  settings: {
    theme: 'light',
    language: 'en',
    notifications: true,
  },
  updateSettings: (newSettings) =>
    set((state) => ({
      settings: { ...state.settings, ...newSettings },
    })),
})
```

```typescript
// stores/use-app-store.ts
import { create } from 'zustand'
import { createUserSlice, type UserSlice } from './slices/user-slice'
import { createSettingsSlice, type SettingsSlice } from './slices/settings-slice'

type AppStore = UserSlice & SettingsSlice

export const useAppStore = create<AppStore>()((...a) => ({
  ...createUserSlice(...a),
  ...createSettingsSlice(...a),
}))
```

### 7. Selectors (Performance Optimization)

```typescript
// Bad: Re-renders on any state change
function Component() {
  const store = useStore()
  return <div>{store.user.name}</div>
}

// Good: Only re-renders when user.name changes
function Component() {
  const userName = useStore((state) => state.user.name)
  return <div>{userName}</div>
}

// Good: Multiple selectors
function Component() {
  const userName = useStore((state) => state.user.name)
  const userEmail = useStore((state) => state.user.email)
  return (
    <div>
      {userName} - {userEmail}
    </div>
  )
}
```

Create reusable selectors:
```typescript
// stores/selectors.ts
import { useCartStore } from './use-cart-store'

export const useCartTotal = () => useCartStore((state) => state.totalPrice())
export const useCartItemCount = () => useCartStore((state) => state.totalItems())
export const useCartItem = (id: string) =>
  useCartStore((state) => state.items.find((item) => item.id === id))
```

### 8. Zustand with Server Components

Create a provider to initialize state from server:

```typescript
// providers/store-provider.tsx
'use client'

import { useEffect, useRef } from 'react'
import { useAuthStore } from '@/stores/use-auth-store'
import type { User } from '@supabase/supabase-js'

interface StoreProviderProps {
  user: User | null
  children: React.ReactNode
}

export function StoreProvider({ user, children }: StoreProviderProps) {
  const initialized = useRef(false)

  useEffect(() => {
    if (!initialized.current) {
      useAuthStore.setState({ user, isLoading: false })
      initialized.current = true
    }
  }, [user])

  return <>{children}</>
}
```

```typescript
// app/layout.tsx
import { StoreProvider } from '@/providers/store-provider'
import { getCurrentUser } from '@/lib/auth/get-user'

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const user = await getCurrentUser()

  return (
    <html lang="en">
      <body>
        <StoreProvider user={user}>{children}</StoreProvider>
      </body>
    </html>
  )
}
```

### 9. DevTools Integration

```bash
npm install -D @redux-devtools/extension
```

```typescript
// stores/use-counter-store.ts
import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

interface CounterState {
  count: number
  increment: () => void
  decrement: () => void
}

export const useCounterStore = create<CounterState>()(
  devtools(
    (set) => ({
      count: 0,
      increment: () => set((state) => ({ count: state.count + 1 }), undefined, 'increment'),
      decrement: () => set((state) => ({ count: state.count - 1 }), undefined, 'decrement'),
    }),
    { name: 'CounterStore' }
  )
)
```

### 10. Testing Stores

```typescript
// __tests__/stores/use-cart-store.test.ts
import { renderHook, act } from '@testing-library/react'
import { useCartStore } from '@/stores/use-cart-store'

describe('useCartStore', () => {
  beforeEach(() => {
    // Reset store before each test
    useCartStore.setState({ items: [] })
  })

  it('should add item to cart', () => {
    const { result } = renderHook(() => useCartStore())

    act(() => {
      result.current.addItem({
        id: '1',
        name: 'Product 1',
        price: 10,
      })
    })

    expect(result.current.items).toHaveLength(1)
    expect(result.current.items[0].name).toBe('Product 1')
  })

  it('should increment quantity if item already exists', () => {
    const { result } = renderHook(() => useCartStore())

    act(() => {
      result.current.addItem({ id: '1', name: 'Product 1', price: 10 })
      result.current.addItem({ id: '1', name: 'Product 1', price: 10 })
    })

    expect(result.current.items).toHaveLength(1)
    expect(result.current.items[0].quantity).toBe(2)
  })

  it('should calculate total price correctly', () => {
    const { result } = renderHook(() => useCartStore())

    act(() => {
      result.current.addItem({ id: '1', name: 'Product 1', price: 10 })
      result.current.addItem({ id: '2', name: 'Product 2', price: 20 })
    })

    expect(result.current.totalPrice()).toBe(30)
  })
})
```

## Best Practices

### 1. Store Organization
- **Single responsibility**: Each store handles one domain
- **Flat structure**: Avoid deeply nested state
- **Computed values**: Use getter functions for derived state
- **Action naming**: Use descriptive verb names (addItem, removeItem)

### 2. Performance
- **Use selectors**: Only subscribe to needed state slices
- **Avoid large objects**: Break into multiple stores if needed
- **Memoize selectors**: Use shallow equality for objects
- **Lazy initialization**: Don't compute on every render

### 3. Type Safety
- **Define interfaces**: Always type your store state
- **Infer types**: Use `z.infer<typeof schema>` from zod
- **Export types**: Make types available for components
- **Strict mode**: Enable TypeScript strict mode

### 4. Persistence
- **Selective persistence**: Only persist necessary state
- **Security**: Don't persist sensitive data in localStorage
- **Version migrations**: Handle schema changes gracefully
- **Hydration**: Initialize from server when possible

### 5. Testing
- **Reset state**: Clear store before each test
- **Mock async**: Use mock functions for API calls
- **Test actions**: Verify state changes after actions
- **Integration tests**: Test store + component together

## Common Patterns

### Optimistic Updates

```typescript
export const usePostsStore = create<PostsState>((set, get) => ({
  posts: [],

  deletePost: async (id) => {
    // Save current state for rollback
    const previousPosts = get().posts

    // Optimistically remove post
    set((state) => ({
      posts: state.posts.filter((p) => p.id !== id),
    }))

    try {
      await fetch(`/api/posts/${id}`, { method: 'DELETE' })
    } catch (error) {
      // Rollback on error
      set({ posts: previousPosts })
      throw error
    }
  },
}))
```

### Computed Properties with Memoization

```typescript
import { create } from 'zustand'
import { useMemo } from 'react'

export const useStore = create((set, get) => ({
  items: [],
  // ... other state
}))

// Use in component
function Component() {
  const items = useStore((state) => state.items)

  const expensiveComputation = useMemo(() => {
    return items.reduce((sum, item) => sum + item.value, 0)
  }, [items])

  return <div>{expensiveComputation}</div>
}
```

### Store Reset

```typescript
const initialState = {
  user: null,
  isLoading: false,
  error: null,
}

export const useAuthStore = create<AuthState>((set) => ({
  ...initialState,

  reset: () => set(initialState),
}))
```

## Integration with Next.js Features

### Server Actions Integration

```typescript
// app/actions/posts.ts
'use server'

import { revalidatePath } from 'next/cache'

export async function createPost(data: any) {
  // Create post in database
  const post = await db.posts.create(data)

  revalidatePath('/posts')
  return post
}
```

```typescript
// components/create-post-button.tsx
'use client'

import { createPost } from '@/app/actions/posts'
import { usePostsStore } from '@/stores/use-posts-store'

export function CreatePostButton() {
  const addPost = usePostsStore((state) => state.addPost)

  async function handleCreate() {
    const post = await createPost({ title: 'New Post' })
    addPost(post) // Update client state
  }

  return <button onClick={handleCreate}>Create Post</button>
}
```

## Follow-up Tasks

- Add state persistence with IndexedDB for larger data
- Implement undo/redo functionality
- Set up state synchronization across tabs
- Add state migration utilities
- Implement state versioning
- Create custom middleware for analytics tracking
