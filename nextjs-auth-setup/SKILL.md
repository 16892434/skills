---
name: nextjs-auth-setup
description: Complete guide for implementing Auth.js (NextAuth.js) authentication in Next.js projects. Supports both App Router and Pages Router with multiple providers (Google, GitHub, credentials), session management, middleware protection, and database integration. Use when setting up authentication infrastructure for Next.js applications.
license: Apache 2.0
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
---

# Next.js Auth.js (NextAuth.js) Setup

A comprehensive guide for implementing production-ready authentication in Next.js projects using Auth.js (formerly NextAuth.js v5).

## Overview

This skill guides you through implementing authentication with:
- ✅ Multiple authentication providers (OAuth + Credentials)
- ✅ Session management (JWT or Database sessions)
- ✅ Route protection with middleware
- ✅ Database integration (Prisma/Drizzle)
- ✅ Type safety with TypeScript
- ✅ App Router & Pages Router support

---

## Quick Start

Run the initialization script to set up Auth.js:

```bash
bash scripts/setup-auth.sh
```

This will:
1. Detect your Next.js router type (App/Pages)
2. Install required dependencies
3. Create auth configuration files
4. Set up environment variables template
5. Generate provider templates

For manual setup or customization, follow the detailed guide below.

---

## Phase 1: Project Analysis

Before implementing, analyze the current project structure:

### 1.1 Detect Next.js Version and Router Type

```bash
# Check Next.js version
cat package.json | grep '"next"'

# Check router type
# App Router: has app/ directory
# Pages Router: has pages/ directory
```

**Decision Point:**
- **App Router** (Next.js 13+): Modern approach, uses Server Components
- **Pages Router** (Next.js 12 and below): Classic approach, uses API routes

### 1.2 Identify Existing Infrastructure

Check for:
- [ ] Database setup (Prisma, Drizzle, raw SQL)
- [ ] Environment variable management (.env.local)
- [ ] TypeScript configuration
- [ ] Existing user model/schema

---

## Phase 2: Installation

### 2.1 Install Core Dependencies

**For Auth.js v5 (Recommended for new projects):**
```bash
npm install next-auth@beta @auth/prisma-adapter
# or
pnpm add next-auth@beta @auth/prisma-adapter
```

**For NextAuth.js v4 (Stable):**
```bash
npm install next-auth @next-auth/prisma-adapter
```

### 2.2 Install Provider Dependencies

```bash
# For OAuth providers (pick what you need)
npm install @auth/core

# For database sessions with Prisma
npm install @prisma/client
npm install -D prisma

# For credentials provider with bcrypt
npm install bcryptjs
npm install -D @types/bcryptjs
```

### 2.3 Environment Variables

Create or update `.env.local`:

```env
# NextAuth Configuration
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=generate_a_random_secret_here

# Auth.js v5 uses AUTH_SECRET instead
AUTH_SECRET=generate_a_random_secret_here

# Database (if using database sessions)
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"

# OAuth Providers
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# Optional: For production
# NEXTAUTH_URL=https://yourdomain.com
```

**Generate a secure secret:**
```bash
openssl rand -base64 32
```

---

## Phase 3: Database Setup (Optional but Recommended)

### 3.1 Prisma Schema

If using database sessions, add to `prisma/schema.prisma`:

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql" // or "mysql", "sqlite"
  url      = env("DATABASE_URL")
}

model Account {
  id                String  @id @default(cuid())
  userId            String  @map("user_id")
  type              String
  provider          String
  providerAccountId String  @map("provider_account_id")
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
  @@map("accounts")
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique @map("session_token")
  userId       String   @map("user_id")
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@map("sessions")
}

model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime? @map("email_verified")
  image         String?
  password      String?   // Only for credentials provider
  accounts      Account[]
  sessions      Session[]
  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @updatedAt @map("updated_at")

  @@map("users")
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
  @@map("verification_tokens")
}
```

### 3.2 Run Migrations

```bash
npx prisma migrate dev --name add_auth_tables
npx prisma generate
```

---

## Phase 4: Auth Configuration

### 4.1 For App Router (Next.js 13+)

**Create `auth.ts` (or `auth.config.ts`):**

```typescript
// auth.ts
import NextAuth from "next-auth"
import Google from "next-auth/providers/google"
import GitHub from "next-auth/providers/github"
import Credentials from "next-auth/providers/credentials"
import { PrismaAdapter } from "@auth/prisma-adapter"
import { prisma } from "@/lib/prisma"
import bcrypt from "bcryptjs"

export const { handlers, signIn, signOut, auth } = NextAuth({
  adapter: PrismaAdapter(prisma),

  session: {
    strategy: "jwt", // or "database"
  },

  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),

    GitHub({
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    }),

    Credentials({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          return null
        }

        const user = await prisma.user.findUnique({
          where: { email: credentials.email as string },
        })

        if (!user || !user.password) {
          return null
        }

        const passwordMatch = await bcrypt.compare(
          credentials.password as string,
          user.password
        )

        if (!passwordMatch) {
          return null
        }

        return {
          id: user.id,
          email: user.email,
          name: user.name,
          image: user.image,
        }
      },
    }),
  ],

  callbacks: {
    async jwt({ token, user, account }) {
      if (user) {
        token.id = user.id
      }
      return token
    },

    async session({ session, token }) {
      if (session.user) {
        session.user.id = token.id as string
      }
      return session
    },
  },

  pages: {
    signIn: "/auth/signin",
    // signOut: "/auth/signout",
    // error: "/auth/error",
    // verifyRequest: "/auth/verify",
  },
})
```

**Create API route handler `app/api/auth/[...nextauth]/route.ts`:**

```typescript
// app/api/auth/[...nextauth]/route.ts
import { handlers } from "@/auth"

export const { GET, POST } = handlers
```

### 4.2 For Pages Router (Next.js 12 and below)

**Create `pages/api/auth/[...nextauth].ts`:**

```typescript
// pages/api/auth/[...nextauth].ts
import NextAuth, { NextAuthOptions } from "next-auth"
import GoogleProvider from "next-auth/providers/google"
import GitHubProvider from "next-auth/providers/github"
import CredentialsProvider from "next-auth/providers/credentials"
import { PrismaAdapter } from "@next-auth/prisma-adapter"
import { prisma } from "@/lib/prisma"
import bcrypt from "bcryptjs"

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),

  session: {
    strategy: "jwt",
  },

  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),

    GitHubProvider({
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    }),

    CredentialsProvider({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          return null
        }

        const user = await prisma.user.findUnique({
          where: { email: credentials.email },
        })

        if (!user || !user.password) {
          return null
        }

        const passwordMatch = await bcrypt.compare(
          credentials.password,
          user.password
        )

        if (!passwordMatch) {
          return null
        }

        return user
      },
    }),
  ],

  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
      }
      return token
    },

    async session({ session, token }) {
      if (session.user) {
        session.user.id = token.id as string
      }
      return session
    },
  },

  pages: {
    signIn: "/auth/signin",
  },
}

export default NextAuth(authOptions)
```

---

## Phase 5: Middleware Protection

### 5.1 App Router Middleware

Create `middleware.ts` in project root:

```typescript
// middleware.ts
import { auth } from "@/auth"
import { NextResponse } from "next/server"

export default auth((req) => {
  const { pathname } = req.nextUrl
  const isAuthenticated = !!req.auth

  // Public routes that don't require authentication
  const publicRoutes = ["/", "/auth/signin", "/auth/signup", "/api/auth"]
  const isPublicRoute = publicRoutes.some(route => pathname.startsWith(route))

  // Redirect unauthenticated users trying to access protected routes
  if (!isAuthenticated && !isPublicRoute) {
    return NextResponse.redirect(new URL("/auth/signin", req.url))
  }

  // Redirect authenticated users away from auth pages
  if (isAuthenticated && pathname.startsWith("/auth/signin")) {
    return NextResponse.redirect(new URL("/dashboard", req.url))
  }

  return NextResponse.next()
})

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|public/).*)",
  ],
}
```

### 5.2 Pages Router Middleware (Next.js 12.2+)

```typescript
// middleware.ts
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"
import { getToken } from "next-auth/jwt"

export async function middleware(request: NextRequest) {
  const token = await getToken({
    req: request,
    secret: process.env.NEXTAUTH_SECRET,
  })

  const { pathname } = request.nextUrl

  // Public routes
  const publicRoutes = ["/", "/auth/signin", "/auth/signup"]
  const isPublicRoute = publicRoutes.includes(pathname)

  if (!token && !isPublicRoute) {
    return NextResponse.redirect(new URL("/auth/signin", request.url))
  }

  if (token && pathname.startsWith("/auth/signin")) {
    return NextResponse.redirect(new URL("/dashboard", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico).*)",
  ],
}
```

---

## Phase 6: Type Definitions

### 6.1 Extend NextAuth Types

Create `types/next-auth.d.ts`:

```typescript
// types/next-auth.d.ts
import { DefaultSession } from "next-auth"

declare module "next-auth" {
  interface Session {
    user: {
      id: string
    } & DefaultSession["user"]
  }

  interface User {
    id: string
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id: string
  }
}
```

---

## Phase 7: Client Components and Pages

### 7.1 Sign In Page (App Router)

```typescript
// app/auth/signin/page.tsx
"use client"

import { signIn } from "next-auth/react"
import { useState } from "react"
import { useRouter } from "next/navigation"

export default function SignInPage() {
  const router = useRouter()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [error, setError] = useState("")

  const handleCredentialsSignIn = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    const result = await signIn("credentials", {
      email,
      password,
      redirect: false,
    })

    if (result?.error) {
      setError("Invalid credentials")
    } else {
      router.push("/dashboard")
      router.refresh()
    }
  }

  const handleOAuthSignIn = (provider: string) => {
    signIn(provider, { callbackUrl: "/dashboard" })
  }

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md space-y-8 p-8">
        <h1 className="text-2xl font-bold text-center">Sign In</h1>

        {error && (
          <div className="bg-red-50 text-red-600 p-3 rounded">
            {error}
          </div>
        )}

        {/* OAuth Providers */}
        <div className="space-y-3">
          <button
            onClick={() => handleOAuthSignIn("google")}
            className="w-full flex items-center justify-center gap-3 px-4 py-2 border rounded-lg hover:bg-gray-50"
          >
            Continue with Google
          </button>

          <button
            onClick={() => handleOAuthSignIn("github")}
            className="w-full flex items-center justify-center gap-3 px-4 py-2 border rounded-lg hover:bg-gray-50"
          >
            Continue with GitHub
          </button>
        </div>

        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t" />
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="bg-white px-2 text-gray-500">Or continue with email</span>
          </div>
        </div>

        {/* Credentials Form */}
        <form onSubmit={handleCredentialsSignIn} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="mt-1 block w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="mt-1 block w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700"
          >
            Sign In
          </button>
        </form>
      </div>
    </div>
  )
}
```

### 7.2 Session Provider Wrapper (App Router)

```typescript
// app/providers.tsx
"use client"

import { SessionProvider } from "next-auth/react"

export function Providers({ children }: { children: React.ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>
}
```

Update `app/layout.tsx`:

```typescript
// app/layout.tsx
import { Providers } from "./providers"

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

### 7.3 Protected Page Example

```typescript
// app/dashboard/page.tsx
import { auth } from "@/auth"
import { redirect } from "next/navigation"

export default async function DashboardPage() {
  const session = await auth()

  if (!session) {
    redirect("/auth/signin")
  }

  return (
    <div>
      <h1>Welcome, {session.user?.name}</h1>
      <p>Email: {session.user?.email}</p>
    </div>
  )
}
```

---

## Phase 8: Server Actions (App Router)

### 8.1 Sign Out Action

```typescript
// app/actions/auth.ts
"use server"

import { signOut } from "@/auth"

export async function handleSignOut() {
  await signOut({ redirectTo: "/" })
}
```

### 8.2 Sign Out Button Component

```typescript
// components/sign-out-button.tsx
"use client"

import { handleSignOut } from "@/app/actions/auth"

export function SignOutButton() {
  return (
    <button
      onClick={() => handleSignOut()}
      className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
    >
      Sign Out
    </button>
  )
}
```

---

## Phase 9: Testing Checklist

After implementation, verify:

- [ ] **OAuth Sign In**: Test Google/GitHub sign in flow
- [ ] **Credentials Sign In**: Test email/password login
- [ ] **Session Persistence**: Refresh page, session should persist
- [ ] **Protected Routes**: Unauthenticated users redirected to sign in
- [ ] **Middleware**: Routes properly protected
- [ ] **Sign Out**: User can sign out and session is cleared
- [ ] **Database**: User records created in database (if using adapter)
- [ ] **TypeScript**: No type errors, autocomplete works
- [ ] **Error Handling**: Invalid credentials show error message
- [ ] **Callback URLs**: Users redirected to correct page after auth

---

## Common Issues and Solutions

### Issue 1: "NEXTAUTH_URL" environment variable not set

**Solution:**
```env
# Add to .env.local
NEXTAUTH_URL=http://localhost:3000
```

### Issue 2: OAuth redirect URI mismatch

**Solution:**
Configure OAuth provider callback URL:
```
http://localhost:3000/api/auth/callback/google
http://localhost:3000/api/auth/callback/github
```

### Issue 3: Session not persisting

**Solutions:**
- Check if `SessionProvider` wraps your app
- Verify `NEXTAUTH_SECRET` is set
- Check browser cookies are enabled
- For database sessions, verify database connection

### Issue 4: TypeScript errors with session.user.id

**Solution:**
Create `types/next-auth.d.ts` with extended types (see Phase 6.1)

### Issue 5: Middleware not protecting routes

**Solution:**
- Ensure `middleware.ts` is in project root
- Check `matcher` config includes your routes
- Verify middleware is being called (add console.log)

---

## Best Practices

### Security

1. **Always use environment variables** for secrets
2. **Use database sessions** for production (more secure than JWT)
3. **Implement CSRF protection** (built-in with Auth.js)
4. **Hash passwords** with bcrypt (cost factor >= 10)
5. **Use HTTPS** in production
6. **Implement rate limiting** for credentials provider

### Performance

1. **Use JWT sessions** for better performance (trade-off: less secure)
2. **Cache user data** where appropriate
3. **Lazy load auth components** that aren't immediately needed

### User Experience

1. **Show loading states** during authentication
2. **Provide clear error messages**
3. **Remember me functionality** (adjust session max age)
4. **Social login buttons** should be prominent
5. **Implement password reset flow**

---

## Advanced Features

### Email Verification

```typescript
// Add to auth config
providers: [
  EmailProvider({
    server: process.env.EMAIL_SERVER,
    from: process.env.EMAIL_FROM,
  }),
]
```

### Two-Factor Authentication

Requires additional setup:
1. Install `@node-rs/bcrypt` and `speakeasy`
2. Add `twoFactorSecret` to User model
3. Implement verification flow in callbacks

### Role-Based Access Control (RBAC)

```typescript
// Add to User model
enum Role {
  USER
  ADMIN
  MODERATOR
}

model User {
  // ... other fields
  role Role @default(USER)
}

// Extend session callback
callbacks: {
  async session({ session, token }) {
    if (session.user) {
      session.user.id = token.id as string
      session.user.role = token.role as Role
    }
    return session
  },
}
```

---

## Reference Files

See the `templates/` directory for complete reference implementations:
- `templates/auth-app-router.ts` - Complete App Router setup
- `templates/auth-pages-router.ts` - Complete Pages Router setup
- `templates/middleware-advanced.ts` - Advanced middleware patterns
- `templates/prisma-schema.prisma` - Complete database schema

See the `reference/` directory for:
- `oauth-setup-guides.md` - Step-by-step OAuth provider setup
- `migration-guide.md` - Migrating from v4 to v5
- `troubleshooting.md` - Common issues and solutions

---

## Resources

- [Auth.js Documentation](https://authjs.dev/)
- [NextAuth.js v4 Docs](https://next-auth.js.org/)
- [Next.js Authentication Patterns](https://nextjs.org/docs/authentication)
- [OAuth Provider Setup Guides](https://authjs.dev/getting-started/providers)

---

## Version Support

This skill supports:
- ✅ Next.js 13+ (App Router) with Auth.js v5
- ✅ Next.js 12+ (Pages Router) with NextAuth.js v4
- ✅ TypeScript & JavaScript
- ✅ Prisma, Drizzle, or any database adapter

Last updated: 2025-01
