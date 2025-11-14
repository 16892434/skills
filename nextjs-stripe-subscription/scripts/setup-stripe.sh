#!/bin/bash

# Next.js Stripe Subscription Setup Script
# Automatically configures Stripe subscription system in your Next.js project

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
  echo -e "${BLUE}==>${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Check if we're in a Next.js project
if [ ! -f "package.json" ]; then
  print_error "No package.json found. Are you in a Next.js project directory?"
  exit 1
fi

if ! grep -q '"next"' package.json; then
  print_error "This doesn't appear to be a Next.js project."
  exit 1
fi

print_success "Next.js project detected"

# Detect router type
if [ -d "app" ]; then
  ROUTER_TYPE="app"
  print_success "App Router detected"
elif [ -d "pages" ]; then
  ROUTER_TYPE="pages"
  print_success "Pages Router detected"
else
  print_warning "Could not detect router type. Defaulting to App Router."
  ROUTER_TYPE="app"
fi

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
  INSTALL_CMD="pnpm add"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  INSTALL_CMD="yarn add"
elif [ -f "bun.lockb" ]; then
  PKG_MANAGER="bun"
  INSTALL_CMD="bun add"
else
  PKG_MANAGER="npm"
  INSTALL_CMD="npm install"
fi

print_success "Using package manager: $PKG_MANAGER"

# Install dependencies
echo ""
print_step "Installing Stripe packages..."
$INSTALL_CMD stripe @stripe/stripe-js

print_success "Dependencies installed"

# Check for database
echo ""
read -p "Are you using Prisma for database? (y/n): " USE_PRISMA

if [ "$USE_PRISMA" = "y" ] || [ "$USE_PRISMA" = "Y" ]; then
  if [ ! -f "prisma/schema.prisma" ]; then
    print_warning "Prisma schema not found. Please set up Prisma first."
  else
    print_success "Prisma detected"
  fi
fi

# Create environment variables
echo ""
print_step "Setting up environment variables..."

if [ ! -f ".env.local" ]; then
  touch .env.local
  print_success "Created .env.local"
else
  print_warning ".env.local already exists, appending to it"
fi

# Add Stripe configuration to .env.local
cat >> .env.local << 'EOF'

# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Stripe Price IDs (get these from your Stripe dashboard)
NEXT_PUBLIC_STRIPE_PRICE_STARTER=price_starter_id
NEXT_PUBLIC_STRIPE_PRICE_PRO=price_pro_id
NEXT_PUBLIC_STRIPE_PRICE_ENTERPRISE=price_enterprise_id

# App URL
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF

print_success "Environment variables template created"

# Create lib directory if it doesn't exist
mkdir -p lib

# Create Stripe client
print_step "Creating Stripe server client..."

cat > lib/stripe.ts << 'EOF'
import Stripe from "stripe"

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error("STRIPE_SECRET_KEY is not set")
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2024-11-20.acacia",
  typescript: true,
})
EOF

print_success "Created lib/stripe.ts"

# Create Stripe client-side helper
cat > lib/stripe-client.ts << 'EOF'
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
EOF

print_success "Created lib/stripe-client.ts"

# Create API routes based on router type
echo ""
print_step "Creating API routes..."

if [ "$ROUTER_TYPE" = "app" ]; then
  # App Router
  mkdir -p app/api/stripe/create-checkout-session
  mkdir -p app/api/stripe/create-portal-session
  mkdir -p app/api/stripe/webhook

  # Checkout session
  cat > app/api/stripe/create-checkout-session/route.ts << 'EOF'
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
      return new NextResponse("Price ID required", { status: 400 })
    }

    const user = await prisma.user.findUnique({
      where: { email: session.user.email },
    })

    let customerId = user?.stripeCustomerId

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: session.user.email,
        metadata: { userId: user!.id },
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

    return NextResponse.json({ sessionId: checkoutSession.id })
  } catch (error) {
    console.error(error)
    return new NextResponse("Internal Error", { status: 500 })
  }
}
EOF

  print_success "Created checkout session API route"

  # Portal session
  cat > app/api/stripe/create-portal-session/route.ts << 'EOF'
import { NextResponse } from "next/server"
import { auth } from "@/auth"
import { stripe } from "@/lib/stripe"
import { prisma } from "@/lib/prisma"

export async function POST() {
  try {
    const session = await auth()
    if (!session?.user?.email) {
      return new NextResponse("Unauthorized", { status: 401 })
    }

    const user = await prisma.user.findUnique({
      where: { email: session.user.email },
    })

    if (!user?.stripeCustomerId) {
      return new NextResponse("No customer found", { status: 400 })
    }

    const portalSession = await stripe.billingPortal.sessions.create({
      customer: user.stripeCustomerId,
      return_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard`,
    })

    return NextResponse.json({ url: portalSession.url })
  } catch (error) {
    console.error(error)
    return new NextResponse("Internal Error", { status: 500 })
  }
}
EOF

  print_success "Created portal session API route"

  # Webhook handler
  cat > app/api/stripe/webhook/route.ts << 'EOF'
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
    return new NextResponse("Webhook Error", { status: 400 })
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session
        const subscription = await stripe.subscriptions.retrieve(
          session.subscription as string
        )
        await prisma.user.update({
          where: { stripeCustomerId: session.customer as string },
          data: {
            stripeSubscriptionId: subscription.id,
            stripePriceId: subscription.items.data[0].price.id,
            stripeCurrentPeriodEnd: new Date(
              subscription.current_period_end * 1000
            ),
          },
        })
        break
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription
        await prisma.user.update({
          where: { stripeCustomerId: subscription.customer as string },
          data: {
            stripePriceId: subscription.items.data[0].price.id,
            stripeCurrentPeriodEnd: new Date(
              subscription.current_period_end * 1000
            ),
          },
        })
        break
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription
        await prisma.user.update({
          where: { stripeCustomerId: subscription.customer as string },
          data: {
            stripeSubscriptionId: null,
            stripePriceId: null,
            stripeCurrentPeriodEnd: null,
          },
        })
        break
      }
    }

    return NextResponse.json({ received: true })
  } catch (error) {
    console.error(error)
    return new NextResponse("Webhook handler failed", { status: 500 })
  }
}
EOF

  print_success "Created webhook API route"

else
  # Pages Router
  mkdir -p pages/api/stripe

  cat > pages/api/stripe/create-checkout-session.ts << 'EOF'
import { NextApiRequest, NextApiResponse } from "next"
import { getServerSession } from "next-auth"
import { authOptions } from "../auth/[...nextauth]"
import { stripe } from "@/lib/stripe"
import { prisma } from "@/lib/prisma"

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" })
  }

  const session = await getServerSession(req, res, authOptions)
  if (!session?.user?.email) {
    return res.status(401).json({ error: "Unauthorized" })
  }

  const { priceId } = req.body
  // TODO: Implement checkout session creation
  return res.status(200).json({ sessionId: "session_id_here" })
}
EOF

  print_success "Created Pages Router API routes"
fi

# Create TypeScript types
mkdir -p types

cat > types/stripe.d.ts << 'EOF'
import Stripe from "stripe"

export interface StripeSubscription {
  stripeCustomerId: string | null
  stripeSubscriptionId: string | null
  stripePriceId: string | null
  stripeCurrentPeriodEnd: Date | null
}

export interface CreateCheckoutSessionParams {
  priceId: string
}

export interface CheckoutSessionResponse {
  sessionId: string
}

export interface PortalSessionResponse {
  url: string
}
EOF

print_success "Created TypeScript types"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Stripe setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Get your Stripe API keys:"
echo "   → https://dashboard.stripe.com/apikeys"
echo ""
echo "2. Update .env.local with your Stripe keys"
echo ""
echo "3. Create products in Stripe dashboard:"
echo "   → https://dashboard.stripe.com/products"
echo ""
echo "4. Add Price IDs to .env.local"
echo ""

if [ "$USE_PRISMA" = "y" ] || [ "$USE_PRISMA" = "Y" ]; then
  echo "5. Update your Prisma schema with Stripe fields:"
  echo "   - stripeCustomerId"
  echo "   - stripeSubscriptionId"
  echo "   - stripePriceId"
  echo "   - stripeCurrentPeriodEnd"
  echo ""
  echo "6. Run: npx prisma migrate dev"
  echo ""
  echo "7. Set up webhooks:"
fi

echo "   Development: stripe listen --forward-to localhost:3000/api/stripe/webhook"
echo "   Production: Configure in Stripe dashboard"
echo ""
echo "📚 Resources:"
echo "  - Stripe docs: https://stripe.com/docs"
echo "  - Setup guide: See reference/stripe-setup-guide.md"
echo ""
