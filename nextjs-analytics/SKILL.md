---
name: nextjs-analytics
description: Implement comprehensive analytics in Next.js v15 using Cloudflare Analytics Engine for custom events, user tracking, and performance monitoring.
---

# Next.js Analytics with Cloudflare Analytics Engine

You are an expert at implementing analytics in Next.js v15 applications using Cloudflare Analytics Engine for custom event tracking and performance monitoring.

## Tech Stack Context
- **Next.js**: v15 with App Router
- **Analytics**: Cloudflare Analytics Engine
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **State Management**: zustand
- **Database**: Supabase without RLS
- **Deployment**: OpenNext compiled to Cloudflare Workers

## Core Analytics Setup

### 1. Cloudflare Analytics Engine Overview

Cloudflare Analytics Engine allows you to write custom analytics data to Workers and query it later. It's perfect for:
- Page views and user interactions
- Custom event tracking
- Performance metrics
- Error logging
- A/B testing results

### 2. Configure Cloudflare Analytics Engine

First, create an Analytics Engine dataset in your Cloudflare dashboard or via Wrangler:

```bash
# Install Wrangler CLI
npm install -D wrangler

# Create Analytics Engine dataset
npx wrangler analytics create DATASET_NAME
```

Add to your `wrangler.toml`:
```toml
name = "my-nextjs-app"
compatibility_date = "2024-01-01"

[[analytics_engine_datasets]]
binding = "ANALYTICS"
dataset = "my_analytics"
```

### 3. Analytics Types and Interfaces

```typescript
// lib/analytics/types.ts
export interface PageViewEvent {
  type: 'pageview'
  pathname: string
  referrer?: string
  userAgent?: string
  userId?: string
  sessionId: string
  timestamp: number
}

export interface CustomEvent {
  type: 'event'
  category: string
  action: string
  label?: string
  value?: number
  userId?: string
  sessionId: string
  metadata?: Record<string, string | number | boolean>
  timestamp: number
}

export interface PerformanceEvent {
  type: 'performance'
  metric: 'FCP' | 'LCP' | 'FID' | 'CLS' | 'TTFB' | 'INP'
  value: number
  pathname: string
  userId?: string
  sessionId: string
  timestamp: number
}

export interface ErrorEvent {
  type: 'error'
  message: string
  stack?: string
  pathname: string
  userId?: string
  sessionId: string
  severity: 'error' | 'warning' | 'info'
  timestamp: number
}

export type AnalyticsEvent =
  | PageViewEvent
  | CustomEvent
  | PerformanceEvent
  | ErrorEvent
```

### 4. Analytics Client

```typescript
// lib/analytics/client.ts
'use client'

import type { AnalyticsEvent } from './types'

let sessionId: string | null = null

function getSessionId(): string {
  if (sessionId) return sessionId

  // Check localStorage for existing session
  if (typeof window !== 'undefined') {
    const stored = localStorage.getItem('analytics_session_id')
    if (stored) {
      sessionId = stored
      return sessionId
    }
  }

  // Generate new session ID
  sessionId = `${Date.now()}-${Math.random().toString(36).substring(7)}`

  if (typeof window !== 'undefined') {
    localStorage.setItem('analytics_session_id', sessionId)
  }

  return sessionId
}

export async function trackEvent(event: Omit<AnalyticsEvent, 'sessionId' | 'timestamp'>) {
  try {
    const fullEvent: AnalyticsEvent = {
      ...event,
      sessionId: getSessionId(),
      timestamp: Date.now(),
    } as AnalyticsEvent

    await fetch('/api/analytics', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fullEvent),
      // Use keepalive to ensure event is sent even if page is closing
      keepalive: true,
    })
  } catch (error) {
    console.error('Failed to track event:', error)
  }
}

export function trackPageView(pathname: string, userId?: string) {
  trackEvent({
    type: 'pageview',
    pathname,
    referrer: document.referrer,
    userAgent: navigator.userAgent,
    userId,
  })
}

export function trackCustomEvent(
  category: string,
  action: string,
  label?: string,
  value?: number,
  metadata?: Record<string, string | number | boolean>,
  userId?: string
) {
  trackEvent({
    type: 'event',
    category,
    action,
    label,
    value,
    metadata,
    userId,
  })
}

export function trackPerformance(
  metric: 'FCP' | 'LCP' | 'FID' | 'CLS' | 'TTFB' | 'INP',
  value: number,
  pathname: string,
  userId?: string
) {
  trackEvent({
    type: 'performance',
    metric,
    value,
    pathname,
    userId,
  })
}

export function trackError(
  message: string,
  pathname: string,
  severity: 'error' | 'warning' | 'info' = 'error',
  stack?: string,
  userId?: string
) {
  trackEvent({
    type: 'error',
    message,
    stack,
    pathname,
    severity,
    userId,
  })
}
```

### 5. Analytics API Route

```typescript
// app/api/analytics/route.ts
import { NextRequest, NextResponse } from 'next/server'
import type { AnalyticsEvent } from '@/lib/analytics/types'

export const runtime = 'edge'

export async function POST(request: NextRequest) {
  try {
    const event: AnalyticsEvent = await request.json()

    // Validate event
    if (!event.type || !event.sessionId || !event.timestamp) {
      return NextResponse.json({ error: 'Invalid event' }, { status: 400 })
    }

    // Write to Analytics Engine
    const env = process.env as any
    if (env.ANALYTICS) {
      await env.ANALYTICS.writeDataPoint({
        blobs: [
          event.type,
          event.sessionId,
          (event as any).pathname || '',
          (event as any).userId || '',
        ],
        doubles: [event.timestamp, (event as any).value || 0],
        indexes: [event.type],
      })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Analytics error:', error)
    return NextResponse.json(
      { error: 'Failed to track event' },
      { status: 500 }
    )
  }
}
```

### 6. Analytics Provider Component

```typescript
// components/providers/analytics-provider.tsx
'use client'

import { useEffect } from 'react'
import { usePathname } from 'next/navigation'
import { trackPageView } from '@/lib/analytics/client'
import { useAuthStore } from '@/stores/use-auth-store'

export function AnalyticsProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const user = useAuthStore((state) => state.user)

  useEffect(() => {
    // Track page view on mount and pathname change
    trackPageView(pathname, user?.id)
  }, [pathname, user?.id])

  return <>{children}</>
}
```

Add to your root layout:
```typescript
// app/layout.tsx
import { AnalyticsProvider } from '@/components/providers/analytics-provider'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AnalyticsProvider>
          {children}
        </AnalyticsProvider>
      </body>
    </html>
  )
}
```

### 7. Web Vitals Tracking

```typescript
// lib/analytics/web-vitals.ts
'use client'

import { onCLS, onFCP, onFID, onLCP, onTTFB, onINP } from 'web-vitals'
import { trackPerformance } from './client'

export function initWebVitals(pathname: string, userId?: string) {
  onCLS((metric) => {
    trackPerformance('CLS', metric.value, pathname, userId)
  })

  onFCP((metric) => {
    trackPerformance('FCP', metric.value, pathname, userId)
  })

  onFID((metric) => {
    trackPerformance('FID', metric.value, pathname, userId)
  })

  onLCP((metric) => {
    trackPerformance('LCP', metric.value, pathname, userId)
  })

  onTTFB((metric) => {
    trackPerformance('TTFB', metric.value, pathname, userId)
  })

  onINP((metric) => {
    trackPerformance('INP', metric.value, pathname, userId)
  })
}
```

Install web-vitals:
```bash
npm install web-vitals
```

Update Analytics Provider:
```typescript
// components/providers/analytics-provider.tsx
'use client'

import { useEffect } from 'react'
import { usePathname } from 'next/navigation'
import { trackPageView } from '@/lib/analytics/client'
import { initWebVitals } from '@/lib/analytics/web-vitals'
import { useAuthStore } from '@/stores/use-auth-store'

export function AnalyticsProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const user = useAuthStore((state) => state.user)

  useEffect(() => {
    trackPageView(pathname, user?.id)
    initWebVitals(pathname, user?.id)
  }, [pathname, user?.id])

  return <>{children}</>
}
```

### 8. Event Tracking Hooks

```typescript
// lib/analytics/hooks.ts
'use client'

import { useCallback } from 'react'
import { trackCustomEvent } from './client'
import { useAuthStore } from '@/stores/use-auth-store'

export function useAnalytics() {
  const user = useAuthStore((state) => state.user)

  const track = useCallback(
    (
      category: string,
      action: string,
      label?: string,
      value?: number,
      metadata?: Record<string, string | number | boolean>
    ) => {
      trackCustomEvent(category, action, label, value, metadata, user?.id)
    },
    [user?.id]
  )

  return { track }
}

// Specific event hooks
export function useButtonClick() {
  const { track } = useAnalytics()

  return useCallback(
    (buttonName: string, location: string) => {
      track('Button', 'Click', buttonName, undefined, { location })
    },
    [track]
  )
}

export function useFormSubmit() {
  const { track } = useAnalytics()

  return useCallback(
    (formName: string, success: boolean) => {
      track('Form', 'Submit', formName, success ? 1 : 0, { success })
    },
    [track]
  )
}

export function useVideoPlay() {
  const { track } = useAnalytics()

  return useCallback(
    (videoId: string, duration?: number) => {
      track('Video', 'Play', videoId, duration)
    },
    [track]
  )
}

export function useSearch() {
  const { track } = useAnalytics()

  return useCallback(
    (query: string, resultsCount: number) => {
      track('Search', 'Query', query, resultsCount)
    },
    [track]
  )
}
```

### 9. Component Usage Examples

```typescript
// components/example-button.tsx
'use client'

import { Button } from '@/components/ui/button'
import { useButtonClick } from '@/lib/analytics/hooks'

export function ExampleButton() {
  const trackClick = useButtonClick()

  return (
    <Button
      onClick={() => {
        trackClick('Get Started', 'Hero Section')
        // Your button logic here
      }}
    >
      Get Started
    </Button>
  )
}
```

```typescript
// components/example-form.tsx
'use client'

import { useState } from 'react'
import { useFormSubmit } from '@/lib/analytics/hooks'

export function ExampleForm() {
  const trackFormSubmit = useFormSubmit()
  const [status, setStatus] = useState<'idle' | 'success' | 'error'>('idle')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()

    try {
      // Your form logic here
      setStatus('success')
      trackFormSubmit('Contact Form', true)
    } catch (error) {
      setStatus('error')
      trackFormSubmit('Contact Form', false)
    }
  }

  return <form onSubmit={handleSubmit}>{/* Form fields */}</form>
}
```

### 10. Query Analytics Data

Create a Worker or API route to query analytics:

```typescript
// app/api/analytics/query/route.ts
import { NextRequest, NextResponse } from 'next/server'

export const runtime = 'edge'

export async function POST(request: NextRequest) {
  try {
    const { query, startDate, endDate } = await request.json()

    const env = process.env as any
    if (!env.ANALYTICS) {
      return NextResponse.json({ error: 'Analytics not configured' }, { status: 500 })
    }

    // Example: Query page views
    const result = await env.ANALYTICS.query(`
      SELECT
        blob1 AS event_type,
        blob3 AS pathname,
        COUNT() AS count
      FROM my_analytics
      WHERE index1 = 'pageview'
        AND timestamp >= ${startDate}
        AND timestamp <= ${endDate}
      GROUP BY event_type, pathname
      ORDER BY count DESC
      LIMIT 100
    `)

    return NextResponse.json({ data: result })
  } catch (error) {
    console.error('Analytics query error:', error)
    return NextResponse.json(
      { error: 'Failed to query analytics' },
      { status: 500 }
    )
  }
}
```

### 11. Analytics Dashboard Component

```typescript
// components/dashboard/analytics-dashboard.tsx
'use client'

import { useEffect, useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { BarChart, LineChart } from '@/components/ui/charts'

interface AnalyticsData {
  pageViews: number
  uniqueVisitors: number
  avgSessionDuration: number
  topPages: Array<{ pathname: string; views: number }>
}

export function AnalyticsDashboard() {
  const [data, setData] = useState<AnalyticsData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchAnalytics() {
      try {
        const response = await fetch('/api/analytics/query', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            startDate: Date.now() - 30 * 24 * 60 * 60 * 1000, // Last 30 days
            endDate: Date.now(),
          }),
        })

        const result = await response.json()
        setData(result.data)
      } catch (error) {
        console.error('Failed to fetch analytics:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchAnalytics()
  }, [])

  if (loading) return <div>Loading analytics...</div>
  if (!data) return <div>No analytics data available</div>

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader>
          <CardTitle>Page Views</CardTitle>
          <CardDescription>Last 30 days</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{data.pageViews.toLocaleString()}</div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Unique Visitors</CardTitle>
          <CardDescription>Last 30 days</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{data.uniqueVisitors.toLocaleString()}</div>
        </CardContent>
      </Card>

      <Card className="md:col-span-2">
        <CardHeader>
          <CardTitle>Top Pages</CardTitle>
          <CardDescription>Most viewed pages</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {data.topPages.map((page) => (
              <div key={page.pathname} className="flex justify-between">
                <span className="text-sm">{page.pathname}</span>
                <span className="text-sm font-medium">{page.views}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
```

### 12. Error Boundary with Analytics

```typescript
// components/error-boundary.tsx
'use client'

import { Component, type ReactNode } from 'react'
import { trackError } from '@/lib/analytics/client'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  componentDidCatch(error: Error) {
    trackError(
      error.message,
      window.location.pathname,
      'error',
      error.stack
    )
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || <div>Something went wrong</div>
    }

    return this.props.children
  }
}
```

## Best Practices

### 1. Data Collection
- **Respect privacy**: Only collect necessary data
- **Get consent**: Implement cookie consent if required
- **Anonymize data**: Hash or remove PII
- **Sampling**: Sample high-volume events to reduce costs
- **Deduplication**: Prevent duplicate events

### 2. Performance
- **Async tracking**: Don't block user interactions
- **Batch requests**: Group multiple events
- **Use keepalive**: Ensure events are sent on page unload
- **Error handling**: Fail silently, don't break UX
- **Optimize payload**: Keep event data small

### 3. Event Design
- **Consistent naming**: Use clear, predictable names
- **Structured data**: Use consistent event schema
- **Meaningful values**: Track actionable metrics
- **Context**: Include relevant metadata
- **Time precision**: Use consistent timestamps

### 4. Analysis
- **Define KPIs**: Track metrics that matter
- **Set goals**: Measure conversions and success
- **Segment users**: Analyze by cohorts
- **Monitor trends**: Track changes over time
- **Act on insights**: Use data to improve product

### 5. Security
- **Validate inputs**: Sanitize event data
- **Rate limiting**: Prevent abuse
- **Authentication**: Protect query endpoints
- **Data retention**: Comply with regulations
- **Access control**: Limit who can query data

## Common Tracking Patterns

### Feature Flag Analytics
```typescript
export function trackFeatureFlag(flagName: string, variant: string) {
  trackCustomEvent('Feature Flag', 'Impression', flagName, undefined, { variant })
}
```

### A/B Test Tracking
```typescript
export function trackExperiment(experimentId: string, variant: string) {
  trackCustomEvent('Experiment', 'View', experimentId, undefined, { variant })
}
```

### Purchase Tracking
```typescript
export function trackPurchase(orderId: string, amount: number, currency: string) {
  trackCustomEvent('E-commerce', 'Purchase', orderId, amount, { currency })
}
```

### Engagement Tracking
```typescript
export function trackEngagement(action: string, duration: number) {
  trackCustomEvent('Engagement', action, undefined, duration)
}
```

## Testing

```typescript
// __tests__/analytics/client.test.ts
import { trackPageView } from '@/lib/analytics/client'

global.fetch = jest.fn()

describe('Analytics', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should track page view', async () => {
    await trackPageView('/test', 'user-123')

    expect(fetch).toHaveBeenCalledWith(
      '/api/analytics',
      expect.objectContaining({
        method: 'POST',
        body: expect.stringContaining('pageview'),
      })
    )
  })
})
```

## Privacy Compliance

### GDPR Compliance
```typescript
// lib/analytics/consent.ts
export function hasAnalyticsConsent(): boolean {
  if (typeof window === 'undefined') return false
  return localStorage.getItem('analytics_consent') === 'true'
}

export function setAnalyticsConsent(consent: boolean) {
  localStorage.setItem('analytics_consent', consent.toString())
}

// Update client.ts to check consent
export async function trackEvent(event: Omit<AnalyticsEvent, 'sessionId' | 'timestamp'>) {
  if (!hasAnalyticsConsent()) return

  // ... rest of tracking code
}
```

## Follow-up Tasks

- Set up analytics dashboard visualization
- Implement real-time analytics monitoring
- Add conversion funnel tracking
- Create custom reports and exports
- Set up alerts for anomalies
- Implement cohort analysis
- Add heatmap tracking
- Create attribution modeling
