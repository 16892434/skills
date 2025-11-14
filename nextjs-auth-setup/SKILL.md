---
name: nextjs-auth-setup
description: Set up Supabase authentication in Next.js v15 App Router projects without RLS. Includes login, signup, password reset, and session management.
---

# Next.js Authentication Setup with Supabase (No RLS)

You are an expert at setting up authentication in Next.js v15 applications using Supabase without Row Level Security (RLS).

## Tech Stack Context
- **Next.js**: v15 with App Router
- **Supabase**: Authentication only (no RLS)
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **Form Validation**: zod
- **State Management**: zustand
- **Deployment**: OpenNext compiled to Cloudflare Workers

## Core Authentication Features

### 1. Supabase Client Setup

Create two Supabase clients:
- **Server Component Client** (`@/lib/supabase/server.ts`)
- **Client Component Client** (`@/lib/supabase/client.ts`)

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
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
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    }
  )
}
```

```typescript
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

### 2. Middleware for Session Refresh

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Refresh session if expired
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Protected routes
  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  // Redirect authenticated users away from auth pages
  if (user && ['/login', '/signup'].includes(request.nextUrl.pathname)) {
    const url = request.nextUrl.clone()
    url.pathname = '/dashboard'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### 3. Server Actions for Auth

```typescript
// app/actions/auth.ts
'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { z } from 'zod'

const signUpSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  name: z.string().min(2, 'Name must be at least 2 characters'),
})

const signInSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
})

export async function signUp(formData: FormData) {
  const supabase = await createClient()

  const validatedFields = signUpSchema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
    name: formData.get('name'),
  })

  if (!validatedFields.success) {
    return {
      error: validatedFields.error.flatten().fieldErrors,
    }
  }

  const { email, password, name } = validatedFields.data

  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        name,
      },
    },
  })

  if (error) {
    return {
      error: { message: error.message },
    }
  }

  revalidatePath('/', 'layout')
  redirect('/dashboard')
}

export async function signIn(formData: FormData) {
  const supabase = await createClient()

  const validatedFields = signInSchema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
  })

  if (!validatedFields.success) {
    return {
      error: validatedFields.error.flatten().fieldErrors,
    }
  }

  const { email, password } = validatedFields.data

  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    return {
      error: { message: error.message },
    }
  }

  revalidatePath('/', 'layout')
  redirect('/dashboard')
}

export async function signOut() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  revalidatePath('/', 'layout')
  redirect('/login')
}

export async function resetPassword(formData: FormData) {
  const supabase = await createClient()
  const email = formData.get('email') as string

  const emailSchema = z.string().email()
  const validatedEmail = emailSchema.safeParse(email)

  if (!validatedEmail.success) {
    return {
      error: { message: 'Invalid email address' },
    }
  }

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/reset-password`,
  })

  if (error) {
    return {
      error: { message: error.message },
    }
  }

  return {
    success: true,
    message: 'Password reset email sent',
  }
}
```

### 4. shadcn/ui Auth Components

Install required shadcn components:
```bash
npx shadcn@latest add button input label card form
```

Login Page Component:
```typescript
// app/login/page.tsx
import { signIn } from '@/app/actions/auth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import Link from 'next/link'

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Welcome back</CardTitle>
          <CardDescription>Sign in to your account to continue</CardDescription>
        </CardHeader>
        <CardContent>
          <form action={signIn} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                name="email"
                type="email"
                placeholder="you@example.com"
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                name="password"
                type="password"
                required
              />
            </div>
            <Button type="submit" className="w-full">
              Sign in
            </Button>
          </form>
          <div className="mt-4 text-center text-sm">
            <Link href="/forgot-password" className="text-muted-foreground hover:underline">
              Forgot password?
            </Link>
          </div>
          <div className="mt-4 text-center text-sm">
            Don't have an account?{' '}
            <Link href="/signup" className="font-medium hover:underline">
              Sign up
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
```

### 5. Environment Variables

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 6. Get Current User Helper

```typescript
// lib/auth/get-user.ts
import { createClient } from '@/lib/supabase/server'

export async function getCurrentUser() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  return user
}
```

## Implementation Steps

When implementing authentication:

1. **Install dependencies**:
   ```bash
   npm install @supabase/supabase-js @supabase/ssr zod
   ```

2. **Set up Supabase clients** (server and client)

3. **Create middleware** for session management and route protection

4. **Implement server actions** with zod validation

5. **Build UI components** using shadcn/ui

6. **Configure environment variables**

7. **Add auth callback route** for email verification:
   ```typescript
   // app/auth/callback/route.ts
   import { createClient } from '@/lib/supabase/server'
   import { NextResponse } from 'next/server'

   export async function GET(request: Request) {
     const { searchParams, origin } = new URL(request.url)
     const code = searchParams.get('code')
     const next = searchParams.get('next') ?? '/dashboard'

     if (code) {
       const supabase = await createClient()
       const { error } = await supabase.auth.exchangeCodeForSession(code)
       if (!error) {
         return NextResponse.redirect(`${origin}${next}`)
       }
     }

     return NextResponse.redirect(`${origin}/auth/auth-code-error`)
   }
   ```

## Best Practices

- Always validate form inputs with zod before processing
- Use Server Actions for auth operations (don't expose credentials client-side)
- Implement proper error handling and user feedback
- Set secure cookie options in production
- Use middleware for route protection instead of client-side checks
- Store minimal user data in metadata (name, avatar, etc.)
- Since RLS is disabled, implement authorization checks in your application code
- Always revalidate paths after auth state changes

## Security Considerations (Without RLS)

Since you're not using RLS, security must be handled at the application level:

1. **Authorization checks**: Implement authorization logic in Server Actions and API routes
2. **Data access control**: Manually verify user permissions before data operations
3. **API protection**: Protect all API routes with authentication checks
4. **Input validation**: Always validate and sanitize user inputs with zod
5. **Rate limiting**: Consider implementing rate limiting for auth endpoints

## Common Patterns

### Protected Page
```typescript
// app/dashboard/page.tsx
import { getCurrentUser } from '@/lib/auth/get-user'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const user = await getCurrentUser()

  if (!user) {
    redirect('/login')
  }

  return <div>Welcome, {user.email}</div>
}
```

### User State in Client Component
```typescript
'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { User } from '@supabase/supabase-js'

export function useUser() {
  const [user, setUser] = useState<User | null>(null)
  const supabase = createClient()

  useEffect(() => {
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      setUser(session?.user ?? null)
    })

    return () => subscription.unsubscribe()
  }, [supabase])

  return user
}
```

## Follow-up Tasks

After implementing auth, consider:
- Setting up user profiles in Supabase database
- Adding OAuth providers (Google, GitHub, etc.)
- Implementing role-based access control
- Adding email verification flow
- Setting up password strength requirements
- Adding 2FA support
