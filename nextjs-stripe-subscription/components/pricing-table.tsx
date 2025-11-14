// components/pricing-table.tsx
// Professional pricing table with Stripe integration

"use client"

import { useState } from "react"
import { getStripe } from "@/lib/stripe-client"
import { Check } from "lucide-react"

interface PricingTier {
  name: string
  priceId: string
  price: string
  description: string
  features: string[]
  popular?: boolean
}

const pricingTiers: PricingTier[] = [
  {
    name: "Starter",
    priceId: process.env.NEXT_PUBLIC_STRIPE_PRICE_STARTER!,
    price: "$9",
    description: "Perfect for individuals and small projects",
    features: [
      "Up to 10 projects",
      "Basic analytics",
      "24/7 email support",
      "1 GB storage",
      "API access",
    ],
  },
  {
    name: "Pro",
    priceId: process.env.NEXT_PUBLIC_STRIPE_PRICE_PRO!,
    price: "$29",
    description: "Best for growing teams and businesses",
    features: [
      "Unlimited projects",
      "Advanced analytics",
      "Priority support",
      "10 GB storage",
      "API access",
      "Custom domains",
      "Team collaboration",
    ],
    popular: true,
  },
  {
    name: "Enterprise",
    priceId: process.env.NEXT_PUBLIC_STRIPE_PRICE_ENTERPRISE!,
    price: "$99",
    description: "For large organizations with advanced needs",
    features: [
      "Everything in Pro",
      "Dedicated support",
      "100 GB storage",
      "Advanced security",
      "SSO authentication",
      "Custom integrations",
      "SLA guarantee",
      "Training & onboarding",
    ],
  },
]

export function PricingTable() {
  const [loadingPriceId, setLoadingPriceId] = useState<string | null>(null)
  const [billingInterval, setBillingInterval] = useState<"monthly" | "yearly">(
    "monthly"
  )

  const handleSubscribe = async (priceId: string) => {
    setLoadingPriceId(priceId)

    try {
      const response = await fetch("/api/stripe/create-checkout-session", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ priceId }),
      })

      if (!response.ok) {
        throw new Error("Failed to create checkout session")
      }

      const { sessionId } = await response.json()

      const stripe = await getStripe()
      const { error } = await stripe!.redirectToCheckout({ sessionId })

      if (error) {
        console.error("Stripe redirect error:", error)
        alert("Failed to redirect to checkout. Please try again.")
      }
    } catch (error) {
      console.error("Subscription error:", error)
      alert("Something went wrong. Please try again.")
    } finally {
      setLoadingPriceId(null)
    }
  }

  return (
    <div className="py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Simple, transparent pricing
          </h2>
          <p className="mt-4 text-lg text-gray-600">
            Choose the perfect plan for your needs. Always know what you'll pay.
          </p>
        </div>

        {/* Billing Toggle */}
        <div className="mt-12 flex justify-center">
          <div className="relative bg-gray-100 p-0.5 rounded-lg flex">
            <button
              onClick={() => setBillingInterval("monthly")}
              className={`relative px-6 py-2 rounded-md text-sm font-medium transition-all ${
                billingInterval === "monthly"
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-600"
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setBillingInterval("yearly")}
              className={`relative px-6 py-2 rounded-md text-sm font-medium transition-all ${
                billingInterval === "yearly"
                  ? "bg-white text-gray-900 shadow-sm"
                  : "text-gray-600"
              }`}
            >
              Yearly
              <span className="ml-1.5 inline-flex items-center rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-800">
                Save 20%
              </span>
            </button>
          </div>
        </div>

        {/* Pricing Cards */}
        <div className="mt-12 grid gap-8 lg:grid-cols-3">
          {pricingTiers.map((tier) => (
            <div
              key={tier.name}
              className={`relative flex flex-col rounded-2xl border ${
                tier.popular
                  ? "border-blue-500 shadow-xl ring-2 ring-blue-500"
                  : "border-gray-200 shadow-sm"
              } bg-white p-8`}
            >
              {tier.popular && (
                <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                  <span className="inline-flex rounded-full bg-blue-500 px-4 py-1 text-sm font-semibold text-white">
                    Most Popular
                  </span>
                </div>
              )}

              <div className="flex-1">
                {/* Plan Name */}
                <h3 className="text-xl font-semibold text-gray-900">
                  {tier.name}
                </h3>

                {/* Description */}
                <p className="mt-4 text-sm text-gray-600">
                  {tier.description}
                </p>

                {/* Price */}
                <p className="mt-8">
                  <span className="text-4xl font-bold tracking-tight text-gray-900">
                    {tier.price}
                  </span>
                  <span className="text-base font-medium text-gray-600">
                    /{billingInterval === "monthly" ? "month" : "year"}
                  </span>
                </p>

                {/* Features */}
                <ul className="mt-8 space-y-4">
                  {tier.features.map((feature) => (
                    <li key={feature} className="flex items-start">
                      <Check className="h-5 w-5 flex-shrink-0 text-blue-500" />
                      <span className="ml-3 text-sm text-gray-700">
                        {feature}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* CTA Button */}
              <button
                onClick={() => handleSubscribe(tier.priceId)}
                disabled={loadingPriceId === tier.priceId}
                className={`mt-8 w-full rounded-lg px-4 py-3 text-center text-sm font-semibold transition-all ${
                  tier.popular
                    ? "bg-blue-600 text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                    : "bg-gray-900 text-white hover:bg-gray-800 focus:ring-2 focus:ring-gray-900 focus:ring-offset-2"
                } disabled:cursor-not-allowed disabled:opacity-60`}
              >
                {loadingPriceId === tier.priceId
                  ? "Loading..."
                  : `Get ${tier.name}`}
              </button>
            </div>
          ))}
        </div>

        {/* FAQ or Additional Info */}
        <div className="mt-16 text-center">
          <p className="text-sm text-gray-600">
            All plans include a 14-day free trial. No credit card required.
          </p>
          <p className="mt-2 text-sm text-gray-600">
            Need a custom plan?{" "}
            <a
              href="/contact"
              className="font-medium text-blue-600 hover:text-blue-500"
            >
              Contact sales
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}
