---
name: nextjs-stripe-subscription
description: Complete guide for implementing Stripe subscription payments in Next.js applications. Includes checkout flows, webhook handling, subscription management, customer portal, pricing tiers, and invoice handling. Use when building SaaS billing, recurring payments, or subscription-based features.
license: Apache 2.0
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
---

# Next.js Stripe Subscription Integration

A comprehensive guide for implementing production-ready Stripe subscription payments in Next.js projects.

## Overview

This skill guides you through implementing:
- ✅ Stripe Checkout for subscriptions
- ✅ Webhook event handling
- ✅ Subscription lifecycle management
- ✅ Customer portal for self-service
- ✅ Multiple pricing tiers
- ✅ Usage-based billing (optional)
- ✅ Invoice and payment handling
- ✅ Test mode and production deployment

---

## Quick Start

Run the automated setup script:

```bash
bash scripts/setup-stripe.sh
```

This will:
1. Install Stripe dependencies
2. Set up environment variables
3. Create webhook handlers
4. Generate API routes
5. Set up TypeScript types
6. Create example pricing page

For manual setup or customization, follow the detailed guide below.

---

## Phase 1: Project Analysis

### 1.1 Detect Project Setup

Check your current stack:

```bash
# Check Next.js version
cat package.json | grep '"next"'

# Detect router type
# App Router: has app/ directory
# Pages Router: has pages/ directory
```

**Decision Points:**
- **Router Type**: App Router vs Pages Router
- **Database**: Needed for storing customer/subscription data
- **Auth System**: Required to link Stripe customers to users

### 1.2 Prerequisites Checklist

- [ ] Next.js project initialized
- [ ] Authentication system in place (or use nextjs-auth-setup skill)
- [ ] Database configured (Prisma recommended)
- [ ] Node.js 18+ installed

---

## Phase 2: Stripe Account Setup

### 2.1 Create Stripe Account

1. Go to [stripe.com](https://stripe.com) and create an account
2. Complete business verification (for production)
3. Navigate to the Dashboard

### 2.2 Get API Keys

**Development (Test Mode):**
1. Go to Developers → API keys
2. Copy **Publishable key** (starts with `pk_test_`)
3. Reveal and copy **Secret key** (starts with `sk_test_`)

**Production:**
1. Toggle to "Live mode"
2. Copy **Publishable key** (starts with `pk_live_`)
3. Reveal and copy **Secret key** (starts with `sk_live_`)

### 2.3 Create Products and Prices

**Via Dashboard:**
1. Go to Products → Add product
2. Create your pricing tiers:
   - **Starter**: $9/month
   - **Pro**: $29/month
   - **Enterprise**: $99/month

3. For each product:
   - Set name and description
   - Choose "Recurring" payment
   - Set billing period (monthly/yearly)
   - Note the **Price ID** (starts with `price_`)

**Via API (Recommended for automation):**
```typescript
// See templates/create-products.ts
```

---

## Phase 3: Installation

### 3.1 Install Dependencies

```bash
npm install stripe @stripe/stripe-js
# or
pnpm add stripe @stripe/stripe-js
```

**Optional (for enhanced features):**
```bash
# For Stripe webhook signature verification
npm install micro

# For React hooks
npm install @stripe/react-stripe-js
```

### 3.2 Environment Variables

Create or update `.env.local`:

```env
# Stripe API Keys
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here

# Stripe Webhook Secret (get this after creating webhook)
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Price IDs (from your Stripe dashboard)
NEXT_PUBLIC_STRIPE_PRICE_STARTER=price_starter_id
NEXT_PUBLIC_STRIPE_PRICE_PRO=price_pro_id
NEXT_PUBLIC_STRIPE_PRICE_ENTERPRISE=price_enterprise_id

# App URL
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Database (if not already set)
DATABASE_URL="postgresql://user:password@localhost:5432/mydb"
```

**Security Note:** Never commit `.env.local` to version control!

---

## Phase 4: Database Schema

### 4.1 Prisma Schema Updates

Add to your `prisma/schema.prisma`:

```prisma
model User {
  id                 String    @id @default(cuid())
  email              String    @unique
  name               String?

  // Stripe fields
  stripeCustomerId   String?   @unique @map("stripe_customer_id")
  stripeSubscriptionId String? @unique @map("stripe_subscription_id")
  stripePriceId      String?   @map("stripe_price_id")
  stripeCurrentPeriodEnd DateTime? @map("stripe_current_period_end")

  // ... other user fields

  @@map("users")
}

// Optional: Store subscription history
model Subscription {
  id                    String   @id @default(cuid())
  userId                String   @map("user_id")
  stripeSubscriptionId  String   @unique @map("stripe_subscription_id")
  stripeCustomerId      String   @map("stripe_customer_id")
  stripePriceId         String   @map("stripe_price_id")
  stripeProductId       String?  @map("stripe_product_id")
  status                String   // active, canceled, incomplete, etc.
  currentPeriodStart    DateTime @map("current_period_start")
  currentPeriodEnd      DateTime @map("current_period_end")
  cancelAtPeriodEnd     Boolean  @default(false) @map("cancel_at_period_end")

  createdAt             DateTime @default(now()) @map("created_at")
  updatedAt             DateTime @updatedAt @map("updated_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([stripeCustomerId])
  @@map("subscriptions")
}

// Optional: Store invoices
model Invoice {
  id                String   @id @default(cuid())
  userId            String   @map("user_id")
  stripeInvoiceId   String   @unique @map("stripe_invoice_id")
  stripeCustomerId  String   @map("stripe_customer_id")
  amount            Int      // in cents
  currency          String
  status            String
  hostedInvoiceUrl  String?  @map("hosted_invoice_url")
  invoicePdf        String?  @map("invoice_pdf")

  createdAt         DateTime @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id])

  @@index([userId])
  @@map("invoices")
}
```

### 4.2 Run Migrations

```bash
npx prisma migrate dev --name add_stripe_fields
npx prisma generate
```

---

## Phase 5: Stripe Client Setup

### 5.1 Server-Side Stripe Client

Create `lib/stripe.ts`:

```typescript
import Stripe from "stripe"

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error("STRIPE_SECRET_KEY is not set")
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2024-11-20.acacia",
  typescript: true,
})
```

### 5.2 Client-Side Stripe

Create `lib/stripe-client.ts`:

```typescript
import { loadStripe, Stripe } from "@stripe/stripe-js"

let stripePromise: Promise<Stripe | null>

export const getStripe = () => {
  if (!stripePromise) {
    stripePromise = loadStripe(
      process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!
    )
  }
  return stripePromise
}
```

---

## Phase 6: Checkout Flow

### 6.1 Create Checkout Session API (App Router)

Create `app/api/stripe/create-checkout-session/route.ts`:

```typescript
import { NextResponse } from "next/server"
import { auth } from "@/auth"
import { stripe } from "@/lib/stripe"
import { prisma } from "@/lib/prisma"

export async function POST(req: Request) {
  try {
    const session = await auth()

    if (!session?.user?.email) {
      return new NextResponse("Unauthorized", { status: 401 })
    }

    const { priceId } = await req.json()

    if (!priceId) {
      return new NextResponse("Price ID is required", { status: 400 })
    }

    // Get or create Stripe customer
    const user = await prisma.user.findUnique({
      where: { email: session.user.email },
    })

    let customerId = user?.stripeCustomerId

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: session.user.email,
        metadata: {
          userId: user!.id,
        },
      })

      customerId = customer.id

      await prisma.user.update({
        where: { id: user!.id },
        data: { stripeCustomerId: customerId },
      })
    }

    // Create checkout session
    const checkoutSession = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard?success=true`,
      cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing?canceled=true`,
      metadata: {
        userId: user!.id,
      },
    })

    return NextResponse.json({ sessionId: checkoutSession.id })
  } catch (error) {
    console.error("Error creating checkout session:", error)
    return new NextResponse("Internal Server Error", { status: 500 })
  }
}
```

### 6.2 Create Checkout Session API (Pages Router)

Create `pages/api/stripe/create-checkout-session.ts`:

```typescript
import { NextApiRequest, NextApiResponse } from "next"
import { getServerSession } from "next-auth"
import { authOptions } from "@/pages/api/auth/[...nextauth]"
import { stripe } from "@/lib/stripe"
import { prisma } from "@/lib/prisma"

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" })
  }

  try {
    const session = await getServerSession(req, res, authOptions)

    if (!session?.user?.email) {
      return res.status(401).json({ error: "Unauthorized" })
    }

    const { priceId } = req.body

    if (!priceId) {
      return res.status(400).json({ error: "Price ID is required" })
    }

    // Similar logic as App Router version...
    const user = await prisma.user.findUnique({
      where: { email: session.user.email },
    })

    let customerId = user?.stripeCustomerId

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: session.user.email,
        metadata: {
          userId: user!.id,
        },
      })

      customerId = customer.id

      await prisma.user.update({
        where: { id: user!.id },
        data: { stripeCustomerId: customerId },
      })
    }

    const checkoutSession = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard?success=true`,
      cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing?canceled=true`,
      metadata: { userId: user!.id },
    })

    return res.status(200).json({ sessionId: checkoutSession.id })
  } catch (error) {
    console.error(error)
    return res.status(500).json({ error: "Internal server error" })
  }
}
```

### 6.3 Client-Side Checkout Button

Create `components/subscribe-button.tsx`:

```typescript
"use client"

import { useState } from "react"
import { getStripe } from "@/lib/stripe-client"

interface SubscribeButtonProps {
  priceId: string
  planName: string
}

export function SubscribeButton({ priceId, planName }: SubscribeButtonProps) {
  const [loading, setLoading] = useState(false)

  const handleSubscribe = async () => {
    setLoading(true)

    try {
      const response = await fetch("/api/stripe/create-checkout-session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ priceId }),
      })

      const { sessionId } = await response.json()

      const stripe = await getStripe()
      await stripe?.redirectToCheckout({ sessionId })
    } catch (error) {
      console.error("Error:", error)
      alert("Something went wrong. Please try again.")
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={handleSubscribe}
      disabled={loading}
      className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50"
    >
      {loading ? "Loading..." : `Subscribe to ${planName}`}
    </button>
  )
}
```

---

## Phase 7: Webhook Handling

### 7.1 Create Webhook Handler (App Router)

Create `app/api/stripe/webhook/route.ts`:

```typescript
import { headers } from "next/headers"
import { NextResponse } from "next/server"
import { stripe } from "@/lib/stripe"
import { prisma } from "@/lib/prisma"
import Stripe from "stripe"

export async function POST(req: Request) {
  const body = await req.text()
  const signature = headers().get("stripe-signature")!

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (error) {
    console.error("Webhook signature verification failed:", error)
    return new NextResponse("Webhook Error", { status: 400 })
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session
        await handleCheckoutSessionCompleted(session)
        break
      }

      case "customer.subscription.created":
      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription
        await handleSubscriptionChange(subscription)
        break
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription
        await handleSubscriptionDeleted(subscription)
        break
      }

      case "invoice.payment_succeeded": {
        const invoice = event.data.object as Stripe.Invoice
        await handleInvoicePaymentSucceeded(invoice)
        break
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice
        await handleInvoicePaymentFailed(invoice)
        break
      }

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return NextResponse.json({ received: true })
  } catch (error) {
    console.error("Error processing webhook:", error)
    return new NextResponse("Webhook handler failed", { status: 500 })
  }
}

// Webhook event handlers
async function handleCheckoutSessionCompleted(
  session: Stripe.Checkout.Session
) {
  const subscriptionId = session.subscription as string
  const customerId = session.customer as string

  // Retrieve subscription details
  const subscription = await stripe.subscriptions.retrieve(subscriptionId)

  // Update user with subscription info
  await prisma.user.update({
    where: { stripeCustomerId: customerId },
    data: {
      stripeSubscriptionId: subscription.id,
      stripePriceId: subscription.items.data[0].price.id,
      stripeCurrentPeriodEnd: new Date(
        subscription.current_period_end * 1000
      ),
    },
  })
}

async function handleSubscriptionChange(subscription: Stripe.Subscription) {
  await prisma.user.update({
    where: { stripeCustomerId: subscription.customer as string },
    data: {
      stripeSubscriptionId: subscription.id,
      stripePriceId: subscription.items.data[0].price.id,
      stripeCurrentPeriodEnd: new Date(
        subscription.current_period_end * 1000
      ),
    },
  })
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  await prisma.user.update({
    where: { stripeCustomerId: subscription.customer as string },
    data: {
      stripeSubscriptionId: null,
      stripePriceId: null,
      stripeCurrentPeriodEnd: null,
    },
  })
}

async function handleInvoicePaymentSucceeded(invoice: Stripe.Invoice) {
  // Store invoice in database
  const user = await prisma.user.findUnique({
    where: { stripeCustomerId: invoice.customer as string },
  })

  if (user) {
    await prisma.invoice.create({
      data: {
        userId: user.id,
        stripeInvoiceId: invoice.id,
        stripeCustomerId: invoice.customer as string,
        amount: invoice.amount_paid,
        currency: invoice.currency,
        status: invoice.status!,
        hostedInvoiceUrl: invoice.hosted_invoice_url,
        invoicePdf: invoice.invoice_pdf,
      },
    })
  }
}

async function handleInvoicePaymentFailed(invoice: Stripe.Invoice) {
  // Handle failed payment (e.g., send email notification)
  console.log(`Payment failed for invoice ${invoice.id}`)
  // TODO: Send notification email to user
}

// Disable body parsing for webhook
export const config = {
  api: {
    bodyParser: false,
  },
}
```

### 7.2 Configure Webhook in Stripe Dashboard

**For Development (using Stripe CLI):**

1. Install Stripe CLI:
```bash
# macOS
brew install stripe/stripe-cli/stripe

# Other platforms: https://stripe.com/docs/stripe-cli
```

2. Login and forward webhooks:
```bash
stripe login
stripe listen --forward-to localhost:3000/api/stripe/webhook
```

3. Copy the webhook signing secret (starts with `whsec_`)
4. Add to `.env.local`:
```env
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

**For Production:**

1. Go to Stripe Dashboard → Developers → Webhooks
2. Click "Add endpoint"
3. Set endpoint URL: `https://yourdomain.com/api/stripe/webhook`
4. Select events to listen to:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Copy the signing secret
6. Add to production environment variables

---

## Phase 8: Customer Portal

### 8.1 Create Portal Session API

Create `app/api/stripe/create-portal-session/route.ts`:

```typescript
import { NextResponse } from "next/server"
import { auth } from "@/auth"
import { stripe } from "@/lib/stripe"
import { prisma } from "@/lib/prisma"

export async function POST(req: Request) {
  try {
    const session = await auth()

    if (!session?.user?.email) {
      return new NextResponse("Unauthorized", { status: 401 })
    }

    const user = await prisma.user.findUnique({
      where: { email: session.user.email },
    })

    if (!user?.stripeCustomerId) {
      return new NextResponse("No Stripe customer found", { status: 400 })
    }

    const portalSession = await stripe.billingPortal.sessions.create({
      customer: user.stripeCustomerId,
      return_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard`,
    })

    return NextResponse.json({ url: portalSession.url })
  } catch (error) {
    console.error("Error creating portal session:", error)
    return new NextResponse("Internal Server Error", { status: 500 })
  }
}
```

### 8.2 Manage Subscription Button

```typescript
"use client"

export function ManageSubscriptionButton() {
  const handleManage = async () => {
    try {
      const response = await fetch("/api/stripe/create-portal-session", {
        method: "POST",
      })

      const { url } = await response.json()
      window.location.href = url
    } catch (error) {
      console.error("Error:", error)
    }
  }

  return (
    <button
      onClick={handleManage}
      className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
    >
      Manage Subscription
    </button>
  )
}
```

---

## Phase 9: Subscription Status Checks

### 9.1 Helper Functions

Create `lib/subscription.ts`:

```typescript
import { prisma } from "./prisma"

export async function getUserSubscription(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      stripeSubscriptionId: true,
      stripePriceId: true,
      stripeCurrentPeriodEnd: true,
    },
  })

  if (!user) return null

  const isActive =
    user.stripeSubscriptionId &&
    user.stripeCurrentPeriodEnd &&
    user.stripeCurrentPeriodEnd.getTime() > Date.now()

  return {
    ...user,
    isActive: !!isActive,
    isCanceled: !isActive && !!user.stripeSubscriptionId,
  }
}

export async function checkSubscription(userId: string, requiredPriceId?: string) {
  const subscription = await getUserSubscription(userId)

  if (!subscription?.isActive) return false

  if (requiredPriceId) {
    return subscription.stripePriceId === requiredPriceId
  }

  return true
}
```

### 9.2 Server Component Usage

```typescript
// app/dashboard/page.tsx
import { auth } from "@/auth"
import { getUserSubscription } from "@/lib/subscription"
import { redirect } from "next/navigation"

export default async function DashboardPage() {
  const session = await auth()

  if (!session) {
    redirect("/auth/signin")
  }

  const subscription = await getUserSubscription(session.user.id)

  if (!subscription?.isActive) {
    redirect("/pricing")
  }

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Plan: {subscription.stripePriceId}</p>
      <p>
        Renews:{" "}
        {subscription.stripeCurrentPeriodEnd?.toLocaleDateString()}
      </p>
    </div>
  )
}
```

---

## Phase 10: Pricing Page

See `components/pricing-table.tsx` for a complete pricing page component.

---

## Phase 11: Testing

### 11.1 Test Mode Cards

Use these test card numbers in Stripe test mode:

| Card Number | Result |
|------------|--------|
| 4242 4242 4242 4242 | Success |
| 4000 0000 0000 0002 | Decline |
| 4000 0025 0000 3155 | Requires authentication (3D Secure) |

- Any future expiration date
- Any 3-digit CVC
- Any ZIP code

### 11.2 Testing Checklist

- [ ] **Subscription creation**: User can subscribe to a plan
- [ ] **Checkout flow**: Redirects work correctly
- [ ] **Webhook processing**: Events are received and processed
- [ ] **Database updates**: User subscription data is stored
- [ ] **Customer portal**: Users can manage their subscription
- [ ] **Subscription upgrade**: Users can upgrade plans
- [ ] **Subscription downgrade**: Users can downgrade plans
- [ ] **Cancellation**: Users can cancel subscription
- [ ] **Payment failure**: Failed payments are handled gracefully
- [ ] **Invoice creation**: Invoices are stored in database

---

## Phase 12: Production Deployment

### 12.1 Pre-deployment Checklist

- [ ] Switch to live Stripe keys
- [ ] Configure production webhook endpoint
- [ ] Test webhook with Stripe CLI in production
- [ ] Enable 3D Secure (SCA compliance)
- [ ] Set up tax collection (Stripe Tax)
- [ ] Configure email receipts
- [ ] Test full subscription flow in production
- [ ] Set up monitoring and alerts

### 12.2 Environment Variables (Production)

```env
STRIPE_SECRET_KEY=sk_live_your_live_key
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_your_live_key
STRIPE_WEBHOOK_SECRET=whsec_your_production_webhook_secret
NEXT_PUBLIC_APP_URL=https://yourdomain.com
```

---

## Advanced Features

### Usage-Based Billing

```typescript
// Track usage
await stripe.subscriptionItems.createUsageRecord(
  subscriptionItemId,
  {
    quantity: 100, // API calls, storage, etc.
    timestamp: Math.floor(Date.now() / 1000),
  }
)
```

### Prorations

Handled automatically by Stripe when changing plans.

### Coupons and Discounts

```typescript
const checkoutSession = await stripe.checkout.sessions.create({
  // ... other options
  discounts: [{
    coupon: 'SUMMER2024',
  }],
})
```

### Trial Periods

```typescript
const checkoutSession = await stripe.checkout.sessions.create({
  // ... other options
  subscription_data: {
    trial_period_days: 14,
  },
})
```

---

## Best Practices

### Security

1. **Verify webhook signatures**: Always verify Stripe webhook signatures
2. **Use HTTPS**: Required for webhooks in production
3. **Secure API keys**: Never expose secret keys to client
4. **Idempotency**: Handle webhook events idempotently
5. **Validate inputs**: Always validate price IDs and amounts

### Performance

1. **Cache subscription status**: Cache user subscription data
2. **Use webhook events**: Don't poll Stripe API
3. **Batch database updates**: Update multiple records efficiently
4. **Optimize queries**: Use appropriate database indexes

### User Experience

1. **Clear pricing**: Display all costs upfront
2. **Easy cancellation**: Make it simple to cancel
3. **Email notifications**: Send receipts and updates
4. **Error messages**: Provide clear, actionable error messages
5. **Loading states**: Show loading indicators during checkout

---

## Common Issues and Solutions

### Issue 1: Webhook not receiving events

**Solutions:**
- Check webhook URL is publicly accessible
- Verify webhook secret is correct
- Check webhook event selections in dashboard
- Review Stripe logs in dashboard

### Issue 2: Customer created twice

**Solution:**
Check for existing customer before creating:
```typescript
const customer = await stripe.customers.list({
  email: user.email,
  limit: 1,
})

const customerId = customer.data[0]?.id || (await stripe.customers.create({
  email: user.email,
})).id
```

### Issue 3: Subscription status out of sync

**Solution:**
Use webhooks (not polling) and handle all subscription events.

### Issue 4: Payment fails silently

**Solution:**
Handle `invoice.payment_failed` webhook event and notify user.

---

## Resources

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe API Reference](https://stripe.com/docs/api)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)
- [SCA/3D Secure](https://stripe.com/docs/strong-customer-authentication)
- [Testing](https://stripe.com/docs/testing)

---

## Reference Files

- `templates/create-checkout-session.ts` - Complete checkout API
- `templates/webhook-handler.ts` - Production webhook handler
- `components/pricing-table.tsx` - Pricing page component
- `reference/stripe-setup-guide.md` - Detailed Stripe configuration
- `reference/webhook-events.md` - All webhook event types

---

Last updated: 2025-01
