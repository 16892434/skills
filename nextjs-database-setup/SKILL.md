---
name: nextjs-database-setup
description: Set up Supabase database operations in Next.js v15 App Router projects without RLS. Includes database schema, queries, mutations, and TypeScript types.
---

# Next.js Database Setup with Supabase (No RLS)

You are an expert at setting up database operations in Next.js v15 applications using Supabase without Row Level Security (RLS).

## Tech Stack Context
- **Next.js**: v15 with App Router
- **Supabase**: Database without RLS (application-level authorization)
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **Form Validation**: zod
- **State Management**: zustand
- **Deployment**: OpenNext compiled to Cloudflare Workers

## Core Database Setup

### 1. Database Schema Definition

Since RLS is disabled, all authorization must be handled in your application code. Create tables with proper foreign keys and constraints:

```sql
-- Example: User profiles table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example: Posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example: Comments table
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 2. TypeScript Types Generation

Generate TypeScript types from your database schema:

```bash
# Install Supabase CLI
npm install -D supabase

# Generate types
npx supabase gen types typescript --project-id <project-id> > types/database.ts
```

Create a typed Supabase client:
```typescript
// lib/supabase/types.ts
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          name: string | null
          avatar_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          email: string
          name?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          email?: string
          name?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      posts: {
        Row: {
          id: string
          user_id: string
          title: string
          content: string | null
          status: 'draft' | 'published' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          content?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          content?: string | null
          status?: 'draft' | 'published' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
      comments: {
        Row: {
          id: string
          post_id: string
          user_id: string
          content: string
          created_at: string
        }
        Insert: {
          id?: string
          post_id: string
          user_id: string
          content: string
          created_at?: string
        }
        Update: {
          id?: string
          post_id?: string
          user_id?: string
          content?: string
          created_at?: string
        }
      }
    }
  }
}
```

Update Supabase client with types:
```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {}
        },
      },
    }
  )
}
```

### 3. Database Operations with Authorization

Create reusable database functions with built-in authorization:

```typescript
// lib/db/posts.ts
'use server'

import { createClient } from '@/lib/supabase/server'
import { getCurrentUser } from '@/lib/auth/get-user'
import { z } from 'zod'

const createPostSchema = z.object({
  title: z.string().min(1, 'Title is required').max(200, 'Title too long'),
  content: z.string().optional(),
  status: z.enum(['draft', 'published', 'archived']).default('draft'),
})

export async function createPost(data: z.infer<typeof createPostSchema>) {
  const user = await getCurrentUser()
  if (!user) {
    throw new Error('Unauthorized')
  }

  const validated = createPostSchema.parse(data)
  const supabase = await createClient()

  const { data: post, error } = await supabase
    .from('posts')
    .insert({
      user_id: user.id,
      title: validated.title,
      content: validated.content,
      status: validated.status,
    })
    .select()
    .single()

  if (error) {
    throw new Error(`Failed to create post: ${error.message}`)
  }

  return post
}

export async function getPost(postId: string) {
  const supabase = await createClient()

  const { data: post, error } = await supabase
    .from('posts')
    .select(`
      *,
      profiles:user_id (
        id,
        name,
        avatar_url
      ),
      comments (
        id,
        content,
        created_at,
        profiles:user_id (
          id,
          name,
          avatar_url
        )
      )
    `)
    .eq('id', postId)
    .single()

  if (error) {
    throw new Error(`Failed to fetch post: ${error.message}`)
  }

  return post
}

export async function updatePost(postId: string, data: Partial<z.infer<typeof createPostSchema>>) {
  const user = await getCurrentUser()
  if (!user) {
    throw new Error('Unauthorized')
  }

  const supabase = await createClient()

  // Authorization check: user can only update their own posts
  const { data: post } = await supabase
    .from('posts')
    .select('user_id')
    .eq('id', postId)
    .single()

  if (!post || post.user_id !== user.id) {
    throw new Error('Forbidden: You can only update your own posts')
  }

  const { data: updatedPost, error } = await supabase
    .from('posts')
    .update(data)
    .eq('id', postId)
    .select()
    .single()

  if (error) {
    throw new Error(`Failed to update post: ${error.message}`)
  }

  return updatedPost
}

export async function deletePost(postId: string) {
  const user = await getCurrentUser()
  if (!user) {
    throw new Error('Unauthorized')
  }

  const supabase = await createClient()

  // Authorization check
  const { data: post } = await supabase
    .from('posts')
    .select('user_id')
    .eq('id', postId)
    .single()

  if (!post || post.user_id !== user.id) {
    throw new Error('Forbidden: You can only delete your own posts')
  }

  const { error } = await supabase
    .from('posts')
    .delete()
    .eq('id', postId)

  if (error) {
    throw new Error(`Failed to delete post: ${error.message}`)
  }

  return { success: true }
}

export async function getUserPosts(userId: string) {
  const supabase = await createClient()

  const { data: posts, error } = await supabase
    .from('posts')
    .select(`
      *,
      profiles:user_id (
        id,
        name,
        avatar_url
      )
    `)
    .eq('user_id', userId)
    .order('created_at', { ascending: false })

  if (error) {
    throw new Error(`Failed to fetch posts: ${error.message}`)
  }

  return posts
}

export async function getPublishedPosts(limit = 10, offset = 0) {
  const supabase = await createClient()

  const { data: posts, error, count } = await supabase
    .from('posts')
    .select(`
      *,
      profiles:user_id (
        id,
        name,
        avatar_url
      )
    `, { count: 'exact' })
    .eq('status', 'published')
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1)

  if (error) {
    throw new Error(`Failed to fetch posts: ${error.message}`)
  }

  return { posts, total: count ?? 0 }
}
```

### 4. Real-time Subscriptions

Set up real-time listeners for live updates:

```typescript
// components/posts/post-list-realtime.tsx
'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { Database } from '@/types/database'

type Post = Database['public']['Tables']['posts']['Row']

export function PostListRealtime({ initialPosts }: { initialPosts: Post[] }) {
  const [posts, setPosts] = useState(initialPosts)
  const supabase = createClient()

  useEffect(() => {
    const channel = supabase
      .channel('posts-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'posts',
          filter: 'status=eq.published',
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setPosts((current) => [payload.new as Post, ...current])
          } else if (payload.eventType === 'UPDATE') {
            setPosts((current) =>
              current.map((post) =>
                post.id === payload.new.id ? (payload.new as Post) : post
              )
            )
          } else if (payload.eventType === 'DELETE') {
            setPosts((current) =>
              current.filter((post) => post.id !== payload.old.id)
            )
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase])

  return (
    <div className="space-y-4">
      {posts.map((post) => (
        <div key={post.id} className="border p-4 rounded-lg">
          <h2 className="text-xl font-bold">{post.title}</h2>
          <p className="text-muted-foreground">{post.content}</p>
        </div>
      ))}
    </div>
  )
}
```

### 5. Pagination Helper

```typescript
// lib/db/pagination.ts
export interface PaginationParams {
  page?: number
  limit?: number
}

export interface PaginatedResult<T> {
  data: T[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
    hasNext: boolean
    hasPrev: boolean
  }
}

export function createPaginatedQuery<T>(
  query: any,
  { page = 1, limit = 10 }: PaginationParams
) {
  const offset = (page - 1) * limit
  return query.range(offset, offset + limit - 1)
}

export function createPaginationMeta(
  total: number,
  page: number,
  limit: number
) {
  const totalPages = Math.ceil(total / limit)
  return {
    page,
    limit,
    total,
    totalPages,
    hasNext: page < totalPages,
    hasPrev: page > 1,
  }
}
```

### 6. Database Seeding

```typescript
// scripts/seed.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // Use service role for seeding
)

async function seed() {
  // Seed profiles
  const { data: profiles, error: profilesError } = await supabase
    .from('profiles')
    .insert([
      {
        id: '00000000-0000-0000-0000-000000000001',
        email: 'user1@example.com',
        name: 'John Doe',
      },
      {
        id: '00000000-0000-0000-0000-000000000002',
        email: 'user2@example.com',
        name: 'Jane Smith',
      },
    ])
    .select()

  if (profilesError) {
    console.error('Error seeding profiles:', profilesError)
    return
  }

  // Seed posts
  const { data: posts, error: postsError } = await supabase
    .from('posts')
    .insert([
      {
        user_id: '00000000-0000-0000-0000-000000000001',
        title: 'First Post',
        content: 'This is the first post',
        status: 'published',
      },
      {
        user_id: '00000000-0000-0000-0000-000000000002',
        title: 'Second Post',
        content: 'This is the second post',
        status: 'published',
      },
    ])
    .select()

  if (postsError) {
    console.error('Error seeding posts:', postsError)
    return
  }

  console.log('Database seeded successfully!')
}

seed().catch(console.error)
```

## Implementation Steps

1. **Design database schema** in Supabase dashboard or using SQL migrations

2. **Generate TypeScript types**:
   ```bash
   npx supabase gen types typescript --project-id <id> > types/database.ts
   ```

3. **Create database operation files** in `lib/db/` directory

4. **Implement authorization checks** in every database operation

5. **Set up real-time subscriptions** where needed

6. **Add pagination** for list views

7. **Create seed scripts** for development data

## Best Practices

### Security (Without RLS)
- **Always check user permissions** in Server Actions before database operations
- **Validate all inputs** with zod before database queries
- **Use parameterized queries** to prevent SQL injection
- **Never trust client-side data** - always re-validate on server
- **Implement role-based access control** in application code

### Performance
- **Create indexes** on frequently queried columns
- **Use select() to limit fields** - don't fetch unnecessary data
- **Implement pagination** for large datasets
- **Use database triggers** for auto-updating timestamps
- **Consider caching** frequently accessed data

### Data Integrity
- **Use foreign keys** to maintain relationships
- **Add CHECK constraints** for enum-like fields
- **Set ON DELETE CASCADE** where appropriate
- **Use transactions** for related operations
- **Validate data** before inserting

### Type Safety
- **Generate types** from database schema
- **Create zod schemas** that match database types
- **Use type inference** from zod schemas
- **Keep types in sync** with database changes

## Common Patterns

### Soft Delete
```sql
ALTER TABLE posts ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_posts_deleted_at ON posts(deleted_at);
```

```typescript
export async function softDeletePost(postId: string) {
  const user = await getCurrentUser()
  if (!user) throw new Error('Unauthorized')

  const supabase = await createClient()

  const { error } = await supabase
    .from('posts')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', postId)
    .eq('user_id', user.id)

  if (error) throw new Error(error.message)
}
```

### Full-text Search
```sql
ALTER TABLE posts ADD COLUMN search_vector tsvector;

CREATE INDEX idx_posts_search ON posts USING gin(search_vector);

CREATE FUNCTION posts_search_trigger() RETURNS trigger AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.content, '')), 'B');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER posts_search_update
  BEFORE INSERT OR UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION posts_search_trigger();
```

```typescript
export async function searchPosts(query: string) {
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .textSearch('search_vector', query)
    .eq('status', 'published')
    .limit(20)

  if (error) throw new Error(error.message)
  return data
}
```

## Error Handling

```typescript
// lib/db/errors.ts
export class DatabaseError extends Error {
  constructor(message: string, public code?: string) {
    super(message)
    this.name = 'DatabaseError'
  }
}

export class AuthorizationError extends Error {
  constructor(message: string = 'Unauthorized') {
    super(message)
    this.name = 'AuthorizationError'
  }
}

export class NotFoundError extends Error {
  constructor(resource: string) {
    super(`${resource} not found`)
    this.name = 'NotFoundError'
  }
}

// Usage
export async function getPost(postId: string) {
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('id', postId)
    .single()

  if (error) {
    if (error.code === 'PGRST116') {
      throw new NotFoundError('Post')
    }
    throw new DatabaseError(error.message, error.code)
  }

  return data
}
```

## Testing

```typescript
// __tests__/db/posts.test.ts
import { createPost, getPost } from '@/lib/db/posts'
import { createClient } from '@/lib/supabase/server'

jest.mock('@/lib/supabase/server')
jest.mock('@/lib/auth/get-user')

describe('Post operations', () => {
  it('should create a post', async () => {
    const mockUser = { id: 'user-1', email: 'test@example.com' }
    require('@/lib/auth/get-user').getCurrentUser.mockResolvedValue(mockUser)

    const mockSupabase = {
      from: jest.fn().mockReturnThis(),
      insert: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({
        data: { id: 'post-1', title: 'Test Post' },
        error: null,
      }),
    }

    require('@/lib/supabase/server').createClient.mockResolvedValue(mockSupabase)

    const post = await createPost({ title: 'Test Post' })

    expect(post).toEqual({ id: 'post-1', title: 'Test Post' })
  })
})
```

## Migration Management

Use Supabase CLI for migrations:

```bash
# Create new migration
npx supabase migration new add_posts_table

# Apply migrations
npx supabase db push

# Reset database (dev only)
npx supabase db reset
```

## Follow-up Tasks

- Set up database backups
- Implement audit logging
- Add database monitoring
- Configure connection pooling
- Set up read replicas for scaling
- Implement caching strategy (Redis, etc.)
