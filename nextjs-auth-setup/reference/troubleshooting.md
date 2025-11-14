# Auth.js Troubleshooting Guide

Common issues and their solutions when implementing Auth.js in Next.js.

---

## Environment Variables

### Issue: "NEXTAUTH_URL environment variable not set"

**Symptoms:**
- Error on startup or during authentication
- OAuth callbacks fail

**Solutions:**

1. Add to `.env.local`:
```env
NEXTAUTH_URL=http://localhost:3000
```

2. For Auth.js v5, also set:
```env
AUTH_SECRET=your_secret_here
```

3. Generate a secure secret:
```bash
openssl rand -base64 32
```

4. In production, set to your actual domain:
```env
NEXTAUTH_URL=https://yourdomain.com
```

**Why it happens:**
Auth.js needs to know the application URL to construct callback URLs correctly.

---

### Issue: "NEXTAUTH_SECRET is not set"

**Symptoms:**
- Warning in console
- Session signing fails
- Unpredictable authentication behavior

**Solution:**

```env
# For NextAuth.js v4
NEXTAUTH_SECRET=your_generated_secret_here

# For Auth.js v5
AUTH_SECRET=your_generated_secret_here
```

**Generate secure secret:**
```bash
# On macOS/Linux
openssl rand -base64 32

# On Windows (PowerShell)
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))

# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

## OAuth Issues

### Issue: "Redirect URI mismatch" (OAuth error)

**Symptoms:**
- Error page from OAuth provider
- Message about invalid redirect_uri
- Users can't complete sign-in

**Solutions:**

1. **Check exact URL format:**
   ```
   Development: http://localhost:3000/api/auth/callback/google
   Production: https://yourdomain.com/api/auth/callback/google
   ```

2. **Common mistakes:**
   - Using `https` locally (should be `http`)
   - Missing `/api/auth/callback/{provider}`
   - Wrong provider name in URL
   - Trailing slashes

3. **For each provider, verify:**

**Google:**
```
Authorized redirect URIs:
http://localhost:3000/api/auth/callback/google
https://yourdomain.com/api/auth/callback/google
```

**GitHub:**
```
Authorization callback URL:
http://localhost:3000/api/auth/callback/github
```

**Discord:**
```
Redirects:
http://localhost:3000/api/auth/callback/discord
```

4. **Testing with ngrok:**
```bash
npx ngrok http 3000
# Use the ngrok URL in provider config
https://abc123.ngrok.io/api/auth/callback/google
```

---

### Issue: OAuth sign-in works but no session/data

**Symptoms:**
- User completes OAuth flow
- Redirected back to app
- But `useSession()` shows no user
- Or session.user is incomplete

**Solutions:**

1. **Check session strategy:**
```typescript
// In auth config
session: {
  strategy: "jwt", // or "database"
}
```

2. **Verify callbacks:**
```typescript
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
}
```

3. **Check SessionProvider wrapping:**
```typescript
// App Router: app/layout.tsx
import { Providers } from "./providers"

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}

// providers.tsx
"use client"
import { SessionProvider } from "next-auth/react"

export function Providers({ children }) {
  return <SessionProvider>{children}</SessionProvider>
}
```

4. **For database sessions, verify adapter:**
```typescript
import { PrismaAdapter } from "@auth/prisma-adapter"
import { prisma } from "@/lib/prisma"

adapter: PrismaAdapter(prisma),
session: { strategy: "database" },
```

---

## Database Issues

### Issue: Prisma/Database adapter errors

**Symptoms:**
- "Table doesn't exist" errors
- "Invalid `prisma.user.create()` invocation"
- Sessions not persisting

**Solutions:**

1. **Run migrations:**
```bash
npx prisma migrate dev
npx prisma generate
```

2. **Verify schema matches Auth.js requirements:**
```prisma
model User {
  id            String    @id @default(cuid())
  name          String?
  email         String?   @unique
  emailVerified DateTime?
  image         String?
  accounts      Account[]
  sessions      Session[]
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  // ... other fields
  user              User    @relation(fields: [userId], references: [id], onDelete: Cascade)
  @@unique([provider, providerAccountId])
}
```

3. **Check database connection:**
```bash
npx prisma studio
# Should open Prisma Studio if connection works
```

4. **Verify DATABASE_URL:**
```env
# PostgreSQL
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"

# MySQL
DATABASE_URL="mysql://user:password@localhost:3306/mydb"

# SQLite (development)
DATABASE_URL="file:./dev.db"
```

---

### Issue: "Cannot read properties of undefined (reading 'findUnique')"

**Symptoms:**
- Error when trying to query database
- `prisma.user` is undefined

**Solution:**

Create proper Prisma client instance:

```typescript
// lib/prisma.ts
import { PrismaClient } from "@prisma/client"

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma
}
```

Then import:
```typescript
import { prisma } from "@/lib/prisma"
```

---

## Session Issues

### Issue: Session not persisting after refresh

**Symptoms:**
- User signs in successfully
- Page refresh loses session
- `useSession()` returns null after reload

**Solutions:**

1. **Check cookies:**
   - Open DevTools → Application → Cookies
   - Look for `next-auth.session-token` (or `__Secure-next-auth.session-token` in production)
   - If missing, cookies are being blocked

2. **Browser cookie settings:**
   - Check if third-party cookies are blocked
   - Check if site data is cleared on browser close
   - Try incognito mode to test

3. **For development with custom domain:**
```env
NEXTAUTH_URL=http://localhost:3000
# Not http://127.0.0.1:3000 or other variants
```

4. **Check CORS (if using different domains):**
```typescript
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: "/api/:path*",
        headers: [
          { key: "Access-Control-Allow-Credentials", value: "true" },
          { key: "Access-Control-Allow-Origin", value: process.env.ALLOWED_ORIGIN },
        ],
      },
    ]
  },
}
```

5. **Session max age:**
```typescript
session: {
  strategy: "jwt",
  maxAge: 30 * 24 * 60 * 60, // 30 days
}
```

---

### Issue: `useSession()` always returns loading state

**Symptoms:**
- `useSession()` never resolves
- `status` stays as "loading"
- App seems stuck

**Solutions:**

1. **Ensure SessionProvider is present:**
```typescript
// Must wrap your app
<SessionProvider>
  <YourApp />
</SessionProvider>
```

2. **Check for multiple SessionProviders:**
   - Only one SessionProvider should wrap your app
   - Check both `_app.tsx` and layout files

3. **Verify API route is working:**
```bash
# Test the API route
curl http://localhost:3000/api/auth/session
# Should return JSON (either empty {} or session data)
```

4. **Check for JavaScript errors:**
   - Open browser console
   - Look for errors that might be blocking execution

---

## TypeScript Issues

### Issue: "Property 'id' does not exist on type 'User'"

**Symptoms:**
- TypeScript error when accessing `session.user.id`
- Type 'AdapterUser' has no property 'role'

**Solution:**

Create type declaration file:

```typescript
// types/next-auth.d.ts
import { DefaultSession } from "next-auth"

declare module "next-auth" {
  interface Session {
    user: {
      id: string
      role?: string
    } & DefaultSession["user"]
  }

  interface User {
    role?: string
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id: string
    role?: string
  }
}
```

---

## Middleware Issues

### Issue: Middleware not running

**Symptoms:**
- Protected routes accessible without auth
- No redirects happening
- Console logs in middleware not appearing

**Solutions:**

1. **Check middleware.ts location:**
   - Must be in project root (not `src/` or `app/`)
   - File must be named exactly `middleware.ts` (or `.js`)

2. **Verify matcher config:**
```typescript
export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|public/).*)",
  ],
}
```

3. **For App Router with Auth.js v5:**
```typescript
// middleware.ts
import { auth } from "@/auth"

export default auth((req) => {
  // Your middleware logic
})
```

4. **Check Next.js version:**
   - Middleware requires Next.js 12.2+
   - Edge runtime must be supported

5. **Test with console.log:**
```typescript
export default auth((req) => {
  console.log("Middleware running for:", req.nextUrl.pathname)
  // ...
})
```

---

## Credentials Provider Issues

### Issue: Credentials login always fails

**Symptoms:**
- Form submits but no login
- No error message
- Returns null from authorize

**Solutions:**

1. **Check password hashing:**
```typescript
// When creating user
import bcrypt from "bcryptjs"
const hashedPassword = await bcrypt.hash(password, 10)

// When verifying
const isValid = await bcrypt.compare(password, user.password)
```

2. **Verify authorize function returns correct format:**
```typescript
async authorize(credentials) {
  // Must return user object or null
  if (valid) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
    }
  }
  return null // Will show error
}
```

3. **Check error handling:**
```typescript
const result = await signIn("credentials", {
  email,
  password,
  redirect: false, // Important for error handling
})

if (result?.error) {
  console.log("Error:", result.error)
}
```

4. **Validate input:**
```typescript
import { z } from "zod"

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
})

const validated = schema.parse(credentials)
```

---

## Production Issues

### Issue: Auth works locally but not in production

**Symptoms:**
- Local development works fine
- Production deployment has auth failures

**Solutions:**

1. **Check environment variables in hosting platform:**
   - Vercel: Project Settings → Environment Variables
   - Netlify: Site Settings → Environment Variables
   - Railway: Project → Variables
   - Ensure all vars are set (NEXTAUTH_URL, NEXTAUTH_SECRET, etc.)

2. **Update NEXTAUTH_URL:**
```env
# Must be production URL
NEXTAUTH_URL=https://yourdomain.com
```

3. **Update OAuth callback URLs:**
   - Add production callback URL to each provider
   - `https://yourdomain.com/api/auth/callback/google`

4. **Check HTTPS:**
   - Production must use HTTPS
   - OAuth providers often require HTTPS

5. **Review cookies in production:**
   - Check if `Secure` flag is set correctly
   - Check SameSite settings

6. **Verify database connection:**
```env
# Check DATABASE_URL points to production DB
DATABASE_URL="postgresql://..."
```

---

## Performance Issues

### Issue: Slow authentication/session checks

**Solutions:**

1. **Use JWT instead of database sessions:**
```typescript
session: { strategy: "jwt" }
```

2. **Optimize database queries:**
```typescript
// Only select needed fields
const user = await prisma.user.findUnique({
  where: { id },
  select: { id: true, email: true, name: true },
})
```

3. **Cache session data:**
```typescript
// In App Router
export const revalidate = 60 // Cache for 60 seconds
```

4. **Use middleware sparingly:**
   - Only protect routes that need it
   - Avoid expensive operations in middleware

---

## Debugging Tips

### Enable debug mode

```typescript
// In auth config
debug: process.env.NODE_ENV === "development",
```

### Check Auth.js version

```bash
npm list next-auth
```

### Test API route directly

```bash
# Session endpoint
curl http://localhost:3000/api/auth/session

# Providers endpoint
curl http://localhost:3000/api/auth/providers
```

### Inspect tokens

```typescript
callbacks: {
  async jwt({ token }) {
    console.log("JWT Token:", token)
    return token
  },
  async session({ session }) {
    console.log("Session:", session)
    return session
  },
}
```

---

## Getting Help

If you're still stuck:

1. **Check Auth.js documentation:** https://authjs.dev
2. **Search GitHub issues:** https://github.com/nextauthjs/next-auth/issues
3. **Ask on Discord:** https://discord.gg/authjs
4. **Stack Overflow:** Tag with `next-auth` or `auth.js`

When asking for help, include:
- Next.js version
- Auth.js/NextAuth.js version
- Router type (App/Pages)
- Code snippets (without secrets!)
- Error messages
- What you've tried
