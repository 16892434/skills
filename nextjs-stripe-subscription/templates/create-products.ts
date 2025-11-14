// scripts/create-products.ts
// Script to programmatically create Stripe products and prices
// Run with: npx tsx scripts/create-products.ts

import Stripe from "stripe"

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2024-11-20.acacia",
})

const products = [
  {
    name: "Starter",
    description: "Perfect for individuals and small projects",
    prices: [
      {
        amount: 900, // $9.00
        interval: "month" as const,
        nickname: "Starter Monthly",
      },
      {
        amount: 8640, // $86.40 (20% off annual)
        interval: "year" as const,
        nickname: "Starter Yearly",
      },
    ],
  },
  {
    name: "Pro",
    description: "Best for growing teams and businesses",
    prices: [
      {
        amount: 2900, // $29.00
        interval: "month" as const,
        nickname: "Pro Monthly",
      },
      {
        amount: 27840, // $278.40 (20% off annual)
        interval: "year" as const,
        nickname: "Pro Yearly",
      },
    ],
  },
  {
    name: "Enterprise",
    description: "For large organizations with advanced needs",
    prices: [
      {
        amount: 9900, // $99.00
        interval: "month" as const,
        nickname: "Enterprise Monthly",
      },
      {
        amount: 95040, // $950.40 (20% off annual)
        interval: "year" as const,
        nickname: "Enterprise Yearly",
      },
    ],
  },
]

async function createProducts() {
  console.log("Creating Stripe products and prices...\n")

  for (const productData of products) {
    try {
      // Create product
      const product = await stripe.products.create({
        name: productData.name,
        description: productData.description,
      })

      console.log(`✓ Created product: ${product.name} (${product.id})`)

      // Create prices for this product
      for (const priceData of productData.prices) {
        const price = await stripe.prices.create({
          product: product.id,
          unit_amount: priceData.amount,
          currency: "usd",
          recurring: {
            interval: priceData.interval,
          },
          nickname: priceData.nickname,
        })

        console.log(
          `  ✓ Created price: ${price.nickname} - $${
            price.unit_amount! / 100
          }/${price.recurring?.interval} (${price.id})`
        )
      }

      console.log("")
    } catch (error) {
      console.error(`Error creating product ${productData.name}:`, error)
    }
  }

  console.log("Done! Add these Price IDs to your .env.local:")
  console.log("")
  console.log("NEXT_PUBLIC_STRIPE_PRICE_STARTER_MONTHLY=price_xxx")
  console.log("NEXT_PUBLIC_STRIPE_PRICE_STARTER_YEARLY=price_xxx")
  console.log("NEXT_PUBLIC_STRIPE_PRICE_PRO_MONTHLY=price_xxx")
  console.log("NEXT_PUBLIC_STRIPE_PRICE_PRO_YEARLY=price_xxx")
  console.log("NEXT_PUBLIC_STRIPE_PRICE_ENTERPRISE_MONTHLY=price_xxx")
  console.log("NEXT_PUBLIC_STRIPE_PRICE_ENTERPRISE_YEARLY=price_xxx")
}

createProducts()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Fatal error:", error)
    process.exit(1)
  })
