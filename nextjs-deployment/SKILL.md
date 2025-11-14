---
name: nextjs-deployment
description: Deploy Next.js v15 applications to Cloudflare Workers using OpenNext adapter, including configuration, optimization, and CI/CD setup.
---

# Next.js Deployment with OpenNext and Cloudflare Workers

You are an expert at deploying Next.js v15 applications to Cloudflare Workers using the OpenNext adapter.

## Tech Stack Context
- **Next.js**: v15 with App Router
- **Deployment**: OpenNext + Cloudflare Workers
- **Analytics**: Cloudflare Analytics Engine
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **Database**: Supabase without RLS
- **Email**: Resend

## Core Deployment Setup

### 1. Install OpenNext

```bash
npm install -D @opennextjs/cloudflare
```

### 2. Next.js Configuration for Cloudflare

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Output for OpenNext
  output: 'standalone',

  // Image optimization
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**.supabase.co',
      },
    ],
    // Cloudflare Images for optimization
    loader: 'custom',
    loaderFile: './lib/cloudflare-image-loader.ts',
  },

  // Enable experimental features if needed
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },

  // Environment variables available to browser
  env: {
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  },
}

module.exports = nextConfig
```

### 3. Cloudflare Image Loader

```typescript
// lib/cloudflare-image-loader.ts
export default function cloudflareImageLoader({
  src,
  width,
  quality,
}: {
  src: string
  width: number
  quality?: number
}) {
  // If it's an external URL, return as-is
  if (src.startsWith('http')) {
    return src
  }

  // Use Cloudflare Images for optimization
  const params = [`width=${width}`]
  if (quality) {
    params.push(`quality=${quality}`)
  }

  return `/cdn-cgi/image/${params.join(',')}${src}`
}
```

### 4. Wrangler Configuration

```toml
# wrangler.toml
name = "my-nextjs-app"
main = ".open-next/cloudflare-worker.js"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

# KV Namespaces (for caching)
[[kv_namespaces]]
binding = "CACHE_KV"
id = "your-kv-namespace-id"

# Analytics Engine
[[analytics_engine_datasets]]
binding = "ANALYTICS"
dataset = "my_analytics"

# Environment variables
[vars]
NEXT_PUBLIC_APP_URL = "https://yourdomain.com"
NEXT_PUBLIC_SUPABASE_URL = "https://your-project.supabase.co"

# Secrets (use wrangler secret put)
# NEXT_PUBLIC_SUPABASE_ANON_KEY
# SUPABASE_SERVICE_ROLE_KEY
# RESEND_API_KEY

# Routes
routes = [
  { pattern = "yourdomain.com/*", zone_name = "yourdomain.com" }
]

# Workers limits
[limits]
cpu_ms = 50

# Build configuration
[build]
command = "npm run build"

# Bindings for production
[env.production]
name = "my-nextjs-app-production"

[env.production.vars]
NEXT_PUBLIC_APP_URL = "https://yourdomain.com"

# Bindings for staging
[env.staging]
name = "my-nextjs-app-staging"

[env.staging.vars]
NEXT_PUBLIC_APP_URL = "https://staging.yourdomain.com"
```

### 5. Build Script

Update your `package.json`:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build && npx @opennextjs/cloudflare",
    "start": "next start",
    "lint": "next lint",
    "deploy": "npm run build && wrangler deploy",
    "deploy:staging": "npm run build && wrangler deploy --env staging",
    "deploy:production": "npm run build && wrangler deploy --env production"
  }
}
```

### 6. OpenNext Configuration

```javascript
// open-next.config.js
module.exports = {
  default: {
    override: {
      wrapper: 'cloudflare-worker',
      converter: 'edge',
      incrementalCache: 'cloudflare-kv',
      tagCache: 'cloudflare-kv',
      queue: 'cloudflare-queue',
    },
  },
}
```

### 7. Environment Variables Setup

Create `.env.local` for local development:
```env
# App
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Resend
RESEND_API_KEY=re_xxxxxxxxxxxxx
RESEND_FROM_EMAIL=noreply@yourdomain.com
```

Add secrets to Cloudflare Workers:
```bash
# Add sensitive environment variables as secrets
wrangler secret put NEXT_PUBLIC_SUPABASE_ANON_KEY
wrangler secret put SUPABASE_SERVICE_ROLE_KEY
wrangler secret put RESEND_API_KEY
wrangler secret put RESEND_FROM_EMAIL
```

### 8. GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloudflare Workers

on:
  push:
    branches:
      - main
      - staging
  pull_request:
    branches:
      - main

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run type check
        run: npx tsc --noEmit

      - name: Run tests
        run: npm test

  deploy-staging:
    name: Deploy to Staging
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/staging'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare Workers (Staging)
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: deploy --env staging

  deploy-production:
    name: Deploy to Production
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare Workers (Production)
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: deploy --env production

      - name: Notify deployment
        if: success()
        run: echo "Deployment successful!"
```

### 9. Performance Optimizations

#### Static Asset Optimization

```javascript
// next.config.js additions
const nextConfig = {
  // ... previous config

  // Optimize bundles
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },

  // Optimize images
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },

  // Optimize fonts
  optimizeFonts: true,

  // Enable SWC minification
  swcMinify: true,

  // Optimize production builds
  productionBrowserSourceMaps: false,
}
```

#### Edge Caching Headers

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const response = NextResponse.next()

  // Static assets
  if (request.nextUrl.pathname.startsWith('/_next/static/')) {
    response.headers.set(
      'Cache-Control',
      'public, max-age=31536000, immutable'
    )
  }

  // Public images
  if (request.nextUrl.pathname.startsWith('/images/')) {
    response.headers.set(
      'Cache-Control',
      'public, max-age=86400, stale-while-revalidate'
    )
  }

  // API routes
  if (request.nextUrl.pathname.startsWith('/api/')) {
    response.headers.set(
      'Cache-Control',
      'private, no-cache, no-store, must-revalidate'
    )
  }

  return response
}
```

### 10. Database Connection Pooling

For Supabase with Cloudflare Workers, use connection pooling:

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
          } catch {}
        },
      },
      global: {
        fetch: (url, options = {}) => {
          return fetch(url, {
            ...options,
            // Use connection pooling for better performance
            cache: 'no-store',
          })
        },
      },
    }
  )
}
```

### 11. Monitoring and Logging

#### Custom Worker Logging

```typescript
// lib/logging/worker-logger.ts
export function logToWorker(
  level: 'info' | 'warn' | 'error',
  message: string,
  data?: any
) {
  const log = {
    level,
    message,
    data,
    timestamp: new Date().toISOString(),
  }

  // Log to console
  console[level](JSON.stringify(log))

  // Optionally send to external logging service
  // await fetch('https://logs.example.com', {
  //   method: 'POST',
  //   body: JSON.stringify(log),
  // })
}
```

#### Error Tracking

```typescript
// app/error.tsx
'use client'

import { useEffect } from 'react'
import { logToWorker } from '@/lib/logging/worker-logger'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    logToWorker('error', error.message, {
      stack: error.stack,
      digest: error.digest,
    })
  }, [error])

  return (
    <div>
      <h2>Something went wrong!</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  )
}
```

### 12. Health Check Endpoint

```typescript
// app/api/health/route.ts
import { NextResponse } from 'next/server'

export const runtime = 'edge'

export async function GET() {
  return NextResponse.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.NEXT_PUBLIC_APP_VERSION || '1.0.0',
  })
}
```

### 13. Custom Domain Setup

1. Add domain to Cloudflare
2. Configure DNS records
3. Update `wrangler.toml` routes:

```toml
routes = [
  { pattern = "yourdomain.com/*", zone_name = "yourdomain.com" },
  { pattern = "www.yourdomain.com/*", zone_name = "yourdomain.com" }
]
```

4. Enable SSL/TLS (Full or Full Strict)
5. Configure redirects (www to non-www or vice versa)

### 14. Preview Deployments

```yaml
# .github/workflows/preview.yml
name: Deploy Preview

on:
  pull_request:
    branches:
      - main

jobs:
  deploy-preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Deploy Preview
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: deploy --env preview-${{ github.event.pull_request.number }}

      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ Preview deployed to https://preview-${{ github.event.pull_request.number }}.yourdomain.workers.dev'
            })
```

## Deployment Checklist

### Pre-Deployment
- [ ] Run tests and linting
- [ ] Verify environment variables
- [ ] Check database migrations
- [ ] Review security headers
- [ ] Test build locally
- [ ] Verify external API connections

### Deployment
- [ ] Build passes successfully
- [ ] Deploy to staging first
- [ ] Run smoke tests on staging
- [ ] Monitor error rates
- [ ] Deploy to production
- [ ] Verify production deployment

### Post-Deployment
- [ ] Check application health
- [ ] Monitor performance metrics
- [ ] Verify analytics tracking
- [ ] Test critical user flows
- [ ] Monitor error logs
- [ ] Check database connections

## Best Practices

### 1. Build Optimization
- Use `next/dynamic` for code splitting
- Optimize images with Cloudflare Images
- Enable SWC minification
- Remove unused dependencies
- Use tree-shaking

### 2. Edge Performance
- Minimize cold start time
- Use edge caching strategically
- Optimize database queries
- Implement request coalescing
- Use streaming SSR where possible

### 3. Security
- Set security headers in middleware
- Validate environment variables
- Use secrets for sensitive data
- Implement rate limiting
- Enable CORS properly

### 4. Monitoring
- Set up uptime monitoring
- Track performance metrics
- Monitor error rates
- Log important events
- Set up alerts

### 5. Cost Optimization
- Use caching effectively
- Optimize API calls
- Implement request batching
- Monitor Workers usage
- Use appropriate cache TTLs

## Common Issues and Solutions

### Issue: Cold Starts
**Solution**: Keep worker warm with scheduled pings

```toml
# wrangler.toml
[triggers]
crons = ["*/5 * * * *"]  # Ping every 5 minutes
```

### Issue: Bundle Size Too Large
**Solution**: Code splitting and dynamic imports

```typescript
import dynamic from 'next/dynamic'

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <p>Loading...</p>,
  ssr: false,
})
```

### Issue: Database Connection Timeouts
**Solution**: Use Supabase connection pooling and retry logic

```typescript
async function queryWithRetry(query: () => Promise<any>, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await query()
    } catch (error) {
      if (i === retries - 1) throw error
      await new Promise((resolve) => setTimeout(resolve, 1000 * (i + 1)))
    }
  }
}
```

## Performance Benchmarks

Target metrics for Cloudflare Workers:
- **Cold start**: < 100ms
- **Response time**: < 200ms (p95)
- **TTFB**: < 100ms
- **LCP**: < 2.5s
- **CLS**: < 0.1

## Rollback Strategy

```bash
# Rollback to previous version
wrangler rollback --env production

# Or deploy specific version
git checkout <previous-commit>
npm run deploy:production
```

## Testing Production

```typescript
// scripts/smoke-test.ts
async function smokeTest() {
  const tests = [
    { name: 'Health Check', url: '/api/health' },
    { name: 'Home Page', url: '/' },
    { name: 'Dashboard', url: '/dashboard' },
  ]

  for (const test of tests) {
    const response = await fetch(`https://yourdomain.com${test.url}`)
    if (!response.ok) {
      throw new Error(`${test.name} failed: ${response.status}`)
    }
    console.log(`✅ ${test.name} passed`)
  }
}

smokeTest().catch(console.error)
```

## Follow-up Tasks

- Set up CDN caching rules
- Configure DDoS protection
- Implement blue-green deployments
- Add canary releases
- Set up A/B testing infrastructure
- Configure WAF rules
- Implement graceful degradation
- Add feature flags
- Set up rollback automation
- Configure backup strategy
