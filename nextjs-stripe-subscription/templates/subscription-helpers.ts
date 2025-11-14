// lib/subscription.ts
// Helper functions for subscription management

import { prisma } from "./prisma"
import { stripe } from "./stripe"

/**
 * Get user's current subscription status
 */
export async function getUserSubscription(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      stripeCustomerId: true,
      stripeSubscriptionId: true,
      stripePriceId: true,
      stripeCurrentPeriodEnd: true,
    },
  })

  if (!user) {
    return null
  }

  const isPro =
    user.stripePriceId &&
    user.stripeCurrentPeriodEnd &&
    user.stripeCurrentPeriodEnd.getTime() + 86_400_000 > Date.now()

  return {
    ...user,
    isPro: !!isPro,
    isCanceled: !isPro && !!user.stripeSubscriptionId,
  }
}

/**
 * Check if user has an active subscription
 */
export async function checkSubscription(userId: string): Promise<boolean> {
  const subscription = await getUserSubscription(userId)
  return subscription?.isPro || false
}

/**
 * Check if user has a specific plan
 */
export async function hasActivePlan(
  userId: string,
  priceId: string
): Promise<boolean> {
  const subscription = await getUserSubscription(userId)
  return subscription?.isPro && subscription.stripePriceId === priceId
}

/**
 * Get subscription details from Stripe
 */
export async function getStripeSubscription(subscriptionId: string) {
  try {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId)
    return subscription
  } catch (error) {
    console.error("Error retrieving subscription:", error)
    return null
  }
}

/**
 * Cancel subscription at period end
 */
export async function cancelSubscription(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { stripeSubscriptionId: true },
  })

  if (!user?.stripeSubscriptionId) {
    throw new Error("No active subscription found")
  }

  const subscription = await stripe.subscriptions.update(
    user.stripeSubscriptionId,
    {
      cancel_at_period_end: true,
    }
  )

  return subscription
}

/**
 * Resume a canceled subscription
 */
export async function resumeSubscription(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { stripeSubscriptionId: true },
  })

  if (!user?.stripeSubscriptionId) {
    throw new Error("No subscription found")
  }

  const subscription = await stripe.subscriptions.update(
    user.stripeSubscriptionId,
    {
      cancel_at_period_end: false,
    }
  )

  return subscription
}

/**
 * Update subscription to a different price
 */
export async function updateSubscriptionPlan(
  userId: string,
  newPriceId: string
) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { stripeSubscriptionId: true },
  })

  if (!user?.stripeSubscriptionId) {
    throw new Error("No active subscription found")
  }

  const subscription = await stripe.subscriptions.retrieve(
    user.stripeSubscriptionId
  )

  const updatedSubscription = await stripe.subscriptions.update(
    user.stripeSubscriptionId,
    {
      items: [
        {
          id: subscription.items.data[0].id,
          price: newPriceId,
        },
      ],
      proration_behavior: "create_prorations", // Charge/credit prorated amount
    }
  )

  // Update database
  await prisma.user.update({
    where: { id: userId },
    data: {
      stripePriceId: newPriceId,
    },
  })

  return updatedSubscription
}

/**
 * Get all invoices for a user
 */
export async function getUserInvoices(userId: string, limit = 10) {
  const invoices = await prisma.invoice.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    take: limit,
  })

  return invoices
}

/**
 * Get usage for usage-based billing
 */
export async function recordUsage(
  subscriptionItemId: string,
  quantity: number
) {
  const usageRecord = await stripe.subscriptionItems.createUsageRecord(
    subscriptionItemId,
    {
      quantity,
      timestamp: Math.floor(Date.now() / 1000),
      action: "increment", // or "set"
    }
  )

  return usageRecord
}

/**
 * Apply coupon to subscription
 */
export async function applyCouponToSubscription(
  userId: string,
  couponId: string
) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { stripeSubscriptionId: true },
  })

  if (!user?.stripeSubscriptionId) {
    throw new Error("No active subscription found")
  }

  const subscription = await stripe.subscriptions.update(
    user.stripeSubscriptionId,
    {
      coupon: couponId,
    }
  )

  return subscription
}

/**
 * Get subscription with price details
 */
export async function getSubscriptionWithPrice(userId: string) {
  const subscription = await getUserSubscription(userId)

  if (!subscription?.stripePriceId) {
    return null
  }

  const price = await stripe.prices.retrieve(subscription.stripePriceId, {
    expand: ["product"],
  })

  return {
    subscription,
    price,
  }
}
