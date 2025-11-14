---
name: nextjs-landing-pages
description: Complete guide for building professional landing pages in Next.js with modern components including Hero sections, Features, FAQ, Pricing, Legal pages, and Contact forms. Includes multiple design variants, responsive layouts, and accessibility best practices. Use when creating marketing sites, product pages, or SaaS landing pages.
license: Apache 2.0
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
---

# Next.js Landing Pages

A comprehensive guide for building high-converting, professional landing pages in Next.js.

## Overview

This skill provides production-ready components and templates for:
- ✅ Hero sections (5+ variants)
- ✅ Features showcase (grid, bento, cards)
- ✅ Pricing tables (integrates with Stripe skill)
- ✅ FAQ sections (accordion UI)
- ✅ Testimonials and social proof
- ✅ Call-to-action (CTA) sections
- ✅ Legal pages (Terms, Privacy, Cookies)
- ✅ Contact forms with validation
- ✅ Newsletter signup
- ✅ Fully responsive and accessible

---

## Quick Start

Run the automated setup script:

```bash
bash scripts/setup-landing-pages.sh
```

This will:
1. Create component directory structure
2. Install required dependencies
3. Generate base components
4. Set up Tailwind CSS configurations
5. Create example pages

For manual setup or customization, follow the detailed guide below.

---

## Phase 1: Project Setup

### 1.1 Prerequisites

- [ ] Next.js project initialized
- [ ] Tailwind CSS configured
- [ ] Optional: shadcn/ui for advanced components
- [ ] Optional: Framer Motion for animations

### 1.2 Install Dependencies

```bash
# Core dependencies
npm install clsx tailwind-merge

# Optional: For forms
npm install react-hook-form zod @hookform/resolvers

# Optional: For animations
npm install framer-motion

# Optional: For icons
npm install lucide-react
```

### 1.3 Tailwind Configuration

Update `tailwind.config.js`:

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#f0f9ff",
          100: "#e0f2fe",
          200: "#bae6fd",
          300: "#7dd3fc",
          400: "#38bdf8",
          500: "#0ea5e9",
          600: "#0284c7",
          700: "#0369a1",
          800: "#075985",
          900: "#0c4a6e",
        },
      },
      animation: {
        "fade-in": "fade-in 0.5s ease-in-out",
        "slide-up": "slide-up 0.5s ease-out",
        "slide-down": "slide-down 0.5s ease-out",
      },
      keyframes: {
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        "slide-up": {
          "0%": { transform: "translateY(20px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
        "slide-down": {
          "0%": { transform: "translateY(-20px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
      },
    },
  },
  plugins: [],
}
```

---

## Phase 2: Hero Sections

### Hero Variant 1: Centered with CTA

**Use case:** SaaS products, simple offers

```tsx
// components/hero/hero-centered.tsx
export function HeroCentered() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-blue-50 to-white py-20 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          {/* Badge */}
          <div className="mb-8 flex justify-center">
            <div className="relative rounded-full px-3 py-1 text-sm leading-6 text-gray-600 ring-1 ring-gray-900/10 hover:ring-gray-900/20">
              Announcing our next round of funding.{" "}
              <a href="#" className="font-semibold text-blue-600">
                Read more <span aria-hidden="true">&rarr;</span>
              </a>
            </div>
          </div>

          {/* Heading */}
          <h1 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-6xl">
            Data to enrich your{" "}
            <span className="text-blue-600">online business</span>
          </h1>

          {/* Description */}
          <p className="mt-6 text-lg leading-8 text-gray-600">
            Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure qui
            lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat
            fugiat aliqua.
          </p>

          {/* CTA Buttons */}
          <div className="mt-10 flex items-center justify-center gap-x-6">
            <a
              href="#"
              className="rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
            >
              Get started
            </a>
            <a
              href="#"
              className="text-sm font-semibold leading-6 text-gray-900"
            >
              Learn more <span aria-hidden="true">→</span>
            </a>
          </div>
        </div>

        {/* Optional: Hero Image */}
        <div className="mt-16 flow-root sm:mt-24">
          <div className="relative rounded-xl bg-gray-900/5 p-2 ring-1 ring-inset ring-gray-900/10 lg:-m-4 lg:rounded-2xl lg:p-4">
            <img
              src="/placeholder-dashboard.png"
              alt="App screenshot"
              width={2432}
              height={1442}
              className="rounded-md shadow-2xl ring-1 ring-gray-900/10"
            />
          </div>
        </div>
      </div>
    </section>
  )
}
```

### Hero Variant 2: Split with Image

**Use case:** Products with strong visual appeal

```tsx
// components/hero/hero-split.tsx
export function HeroSplit() {
  return (
    <section className="relative bg-white">
      <div className="mx-auto max-w-7xl lg:grid lg:grid-cols-12 lg:gap-x-8 lg:px-8">
        <div className="px-6 pb-24 pt-10 sm:pb-32 lg:col-span-7 lg:px-0 lg:pb-56 lg:pt-48 xl:col-span-6">
          <div className="mx-auto max-w-2xl lg:mx-0">
            {/* Logo or Brand */}
            <div className="hidden sm:mt-32 sm:flex lg:mt-16">
              <div className="relative rounded-full px-3 py-1 text-sm leading-6 text-gray-500 ring-1 ring-gray-900/10 hover:ring-gray-900/20">
                Featured in TechCrunch.{" "}
                <a href="#" className="whitespace-nowrap font-semibold text-blue-600">
                  <span className="absolute inset-0" aria-hidden="true" />
                  Read more <span aria-hidden="true">&rarr;</span>
                </a>
              </div>
            </div>

            <h1 className="mt-24 text-4xl font-bold tracking-tight text-gray-900 sm:mt-10 sm:text-6xl">
              Deploy to the cloud with confidence
            </h1>

            <p className="mt-6 text-lg leading-8 text-gray-600">
              Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure qui
              lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat.
            </p>

            <div className="mt-10 flex items-center gap-x-6">
              <a
                href="#"
                className="rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
              >
                Get started
              </a>
              <a href="#" className="text-sm font-semibold leading-6 text-gray-900">
                Live demo <span aria-hidden="true">→</span>
              </a>
            </div>
          </div>
        </div>

        <div className="relative lg:col-span-5 lg:-mr-8 xl:absolute xl:inset-0 xl:left-1/2 xl:mr-0">
          <img
            className="aspect-[3/2] w-full bg-gray-50 object-cover lg:absolute lg:inset-0 lg:aspect-auto lg:h-full"
            src="/placeholder-hero.jpg"
            alt="Hero image"
          />
        </div>
      </div>
    </section>
  )
}
```

### Hero Variant 3: Gradient Background

**Use case:** Modern SaaS, tech products

See `components/hero/hero-gradient.tsx` for implementation.

### Hero Variant 4: Video Background

**Use case:** Lifestyle products, apps with demo videos

See `components/hero/hero-video.tsx` for implementation.

### Hero Variant 5: Animated

**Use case:** Interactive products, creative agencies

See `components/hero/hero-animated.tsx` for implementation.

---

## Phase 3: Features Section

### Features Grid Layout

```tsx
// components/features/features-grid.tsx
import { Zap, Shield, TrendingUp, Users } from "lucide-react"

const features = [
  {
    name: "Lightning Fast",
    description: "Built for speed with edge computing and global CDN.",
    icon: Zap,
  },
  {
    name: "Secure by Default",
    description: "Enterprise-grade security with SOC 2 compliance.",
    icon: Shield,
  },
  {
    name: "Analytics",
    description: "Powerful insights to grow your business.",
    icon: TrendingUp,
  },
  {
    name: "Team Collaboration",
    description: "Work together seamlessly with your team.",
    icon: Users,
  },
]

export function FeaturesGrid() {
  return (
    <section className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl lg:text-center">
          <h2 className="text-base font-semibold leading-7 text-blue-600">
            Deploy faster
          </h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Everything you need to deploy your app
          </p>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            Quis tellus eget adipiscing convallis sit sit eget aliquet quis.
            Suspendisse eget egestas a elementum pulvinar et feugiat blandit at.
          </p>
        </div>

        <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-4">
            {features.map((feature) => (
              <div key={feature.name} className="flex flex-col">
                <dt className="flex items-center gap-x-3 text-base font-semibold leading-7 text-gray-900">
                  <feature.icon
                    className="h-5 w-5 flex-none text-blue-600"
                    aria-hidden="true"
                  />
                  {feature.name}
                </dt>
                <dd className="mt-4 flex flex-auto flex-col text-base leading-7 text-gray-600">
                  <p className="flex-auto">{feature.description}</p>
                </dd>
              </div>
            ))}
          </dl>
        </div>
      </div>
    </section>
  )
}
```

### Bento Grid Features

**Use case:** Showcasing multiple features with visual hierarchy

See `components/features/features-bento.tsx` for implementation.

### Features with Screenshots

**Use case:** Apps with strong visual features

See `components/features/features-screenshots.tsx` for implementation.

---

## Phase 4: FAQ Section

```tsx
// components/faq/faq-accordion.tsx
"use client"

import { useState } from "react"
import { ChevronDown } from "lucide-react"

const faqs = [
  {
    question: "What's the best thing about Switzerland?",
    answer:
      "I don't know, but the flag is a big plus. Lorem ipsum dolor sit amet consectetur adipisicing elit. Quas cupiditate laboriosam fugiat.",
  },
  {
    question: "How do you make holy water?",
    answer:
      "You boil the hell out of it. Lorem ipsum dolor sit amet consectetur adipisicing elit. Quas cupiditate laboriosam fugiat.",
  },
  {
    question: "What do you call someone with no body and no nose?",
    answer:
      "Nobody knows. Lorem ipsum dolor sit amet consectetur adipisicing elit. Quas cupiditate laboriosam fugiat.",
  },
  {
    question: "Why do you never see elephants hiding in trees?",
    answer:
      "Because they're so good at it. Lorem ipsum dolor sit amet consectetur adipisicing elit. Quas cupiditate laboriosam fugiat.",
  },
]

export function FAQAccordion() {
  const [openIndex, setOpenIndex] = useState<number | null>(0)

  return (
    <section className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-4xl divide-y divide-gray-900/10">
          <h2 className="text-2xl font-bold leading-10 tracking-tight text-gray-900">
            Frequently asked questions
          </h2>
          <dl className="mt-10 space-y-6 divide-y divide-gray-900/10">
            {faqs.map((faq, index) => (
              <div key={index} className="pt-6">
                <dt>
                  <button
                    onClick={() => setOpenIndex(openIndex === index ? null : index)}
                    className="flex w-full items-start justify-between text-left text-gray-900"
                  >
                    <span className="text-base font-semibold leading-7">
                      {faq.question}
                    </span>
                    <span className="ml-6 flex h-7 items-center">
                      <ChevronDown
                        className={`h-6 w-6 transition-transform ${
                          openIndex === index ? "rotate-180" : ""
                        }`}
                        aria-hidden="true"
                      />
                    </span>
                  </button>
                </dt>
                {openIndex === index && (
                  <dd className="mt-2 pr-12">
                    <p className="text-base leading-7 text-gray-600">
                      {faq.answer}
                    </p>
                  </dd>
                )}
              </div>
            ))}
          </dl>
        </div>
      </div>
    </section>
  )
}
```

---

## Phase 5: Call-to-Action (CTA) Sections

### Simple CTA

```tsx
// components/cta/cta-simple.tsx
export function CTASimple() {
  return (
    <section className="bg-blue-600">
      <div className="px-6 py-24 sm:px-6 sm:py-32 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
            Boost your productivity.
            <br />
            Start using our app today.
          </h2>
          <p className="mx-auto mt-6 max-w-xl text-lg leading-8 text-blue-100">
            Incididunt sint fugiat pariatur cupidatat consectetur sit cillum
            anim id veniam aliqua proident excepteur commodo do ea.
          </p>
          <div className="mt-10 flex items-center justify-center gap-x-6">
            <a
              href="#"
              className="rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-blue-600 shadow-sm hover:bg-blue-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
            >
              Get started
            </a>
            <a
              href="#"
              className="text-sm font-semibold leading-6 text-white"
            >
              Learn more <span aria-hidden="true">→</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
```

### CTA with App Screenshots

See `components/cta/cta-with-app.tsx` for implementation.

---

## Phase 6: Contact Form

```tsx
// components/contact/contact-form.tsx
"use client"

import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"

const contactSchema = z.object({
  firstName: z.string().min(1, "First name is required"),
  lastName: z.string().min(1, "Last name is required"),
  email: z.string().email("Invalid email address"),
  company: z.string().optional(),
  message: z.string().min(10, "Message must be at least 10 characters"),
})

type ContactFormData = z.infer<typeof contactSchema>

export function ContactForm() {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitSuccess, setSubmitSuccess] = useState(false)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ContactFormData>({
    resolver: zodResolver(contactSchema),
  })

  const onSubmit = async (data: ContactFormData) => {
    setIsSubmitting(true)

    try {
      // Send to your API endpoint
      const response = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      })

      if (response.ok) {
        setSubmitSuccess(true)
        reset()
      }
    } catch (error) {
      console.error("Error submitting form:", error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <section className="isolate bg-white px-6 py-24 sm:py-32 lg:px-8">
      <div className="mx-auto max-w-2xl text-center">
        <h2 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
          Contact sales
        </h2>
        <p className="mt-2 text-lg leading-8 text-gray-600">
          Aute magna irure deserunt veniam aliqua magna enim voluptate.
        </p>
      </div>

      <form
        onSubmit={handleSubmit(onSubmit)}
        className="mx-auto mt-16 max-w-xl sm:mt-20"
      >
        <div className="grid grid-cols-1 gap-x-8 gap-y-6 sm:grid-cols-2">
          <div>
            <label
              htmlFor="firstName"
              className="block text-sm font-semibold leading-6 text-gray-900"
            >
              First name
            </label>
            <div className="mt-2.5">
              <input
                {...register("firstName")}
                type="text"
                id="firstName"
                className="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
              />
              {errors.firstName && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.firstName.message}
                </p>
              )}
            </div>
          </div>

          <div>
            <label
              htmlFor="lastName"
              className="block text-sm font-semibold leading-6 text-gray-900"
            >
              Last name
            </label>
            <div className="mt-2.5">
              <input
                {...register("lastName")}
                type="text"
                id="lastName"
                className="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
              />
              {errors.lastName && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.lastName.message}
                </p>
              )}
            </div>
          </div>

          <div className="sm:col-span-2">
            <label
              htmlFor="email"
              className="block text-sm font-semibold leading-6 text-gray-900"
            >
              Email
            </label>
            <div className="mt-2.5">
              <input
                {...register("email")}
                type="email"
                id="email"
                className="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
              />
              {errors.email && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.email.message}
                </p>
              )}
            </div>
          </div>

          <div className="sm:col-span-2">
            <label
              htmlFor="company"
              className="block text-sm font-semibold leading-6 text-gray-900"
            >
              Company
            </label>
            <div className="mt-2.5">
              <input
                {...register("company")}
                type="text"
                id="company"
                className="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
              />
            </div>
          </div>

          <div className="sm:col-span-2">
            <label
              htmlFor="message"
              className="block text-sm font-semibold leading-6 text-gray-900"
            >
              Message
            </label>
            <div className="mt-2.5">
              <textarea
                {...register("message")}
                id="message"
                rows={4}
                className="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
              />
              {errors.message && (
                <p className="mt-1 text-sm text-red-600">
                  {errors.message.message}
                </p>
              )}
            </div>
          </div>
        </div>

        <div className="mt-10">
          <button
            type="submit"
            disabled={isSubmitting}
            className="block w-full rounded-md bg-blue-600 px-3.5 py-2.5 text-center text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 disabled:opacity-50"
          >
            {isSubmitting ? "Sending..." : "Let's talk"}
          </button>
        </div>

        {submitSuccess && (
          <p className="mt-4 text-center text-sm text-green-600">
            Thank you for your message! We'll get back to you soon.
          </p>
        )}
      </form>
    </section>
  )
}
```

### Contact API Route (App Router)

```typescript
// app/api/contact/route.ts
import { NextResponse } from "next/server"
import { z } from "zod"

const contactSchema = z.object({
  firstName: z.string(),
  lastName: z.string(),
  email: z.string().email(),
  company: z.string().optional(),
  message: z.string(),
})

export async function POST(req: Request) {
  try {
    const body = await req.json()
    const data = contactSchema.parse(body)

    // TODO: Send email or save to database
    // Example: await sendEmail(data)
    // Example: await prisma.contact.create({ data })

    console.log("Contact form submission:", data)

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("Contact form error:", error)
    return NextResponse.json(
      { error: "Failed to submit form" },
      { status: 400 }
    )
  }
}
```

---

## Phase 7: Legal Pages

### Terms of Service Template

```typescript
// app/terms/page.tsx
export default function TermsPage() {
  return (
    <div className="bg-white px-6 py-32 lg:px-8">
      <div className="mx-auto max-w-3xl text-base leading-7 text-gray-700">
        <p className="text-base font-semibold leading-7 text-blue-600">
          Legal
        </p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
          Terms of Service
        </h1>
        <p className="mt-6 text-xl leading-8">
          Last updated: January 1, 2025
        </p>

        <div className="mt-10 max-w-2xl">
          <h2 className="mt-16 text-2xl font-bold tracking-tight text-gray-900">
            1. Acceptance of Terms
          </h2>
          <p className="mt-6">
            By accessing and using this service, you accept and agree to be
            bound by the terms and provision of this agreement.
          </p>

          <h2 className="mt-16 text-2xl font-bold tracking-tight text-gray-900">
            2. Use License
          </h2>
          <p className="mt-6">
            Permission is granted to temporarily download one copy of the
            materials (information or software) on Company Name's website for
            personal, non-commercial transitory viewing only.
          </p>

          <h2 className="mt-16 text-2xl font-bold tracking-tight text-gray-900">
            3. Disclaimer
          </h2>
          <p className="mt-6">
            The materials on Company Name's website are provided on an 'as is'
            basis. Company Name makes no warranties, expressed or implied, and
            hereby disclaims and negates all other warranties including, without
            limitation, implied warranties or conditions of merchantability,
            fitness for a particular purpose, or non-infringement of
            intellectual property or other violation of rights.
          </p>

          {/* Add more sections as needed */}
        </div>
      </div>
    </div>
  )
}
```

### Privacy Policy Template

See `templates/legal/privacy-policy.tsx` for complete template.

### Cookie Policy Template

See `templates/legal/cookie-policy.tsx` for complete template.

---

## Phase 8: Testimonials

```tsx
// components/testimonials/testimonials-grid.tsx
const testimonials = [
  {
    body: "Laborum quis quam. Dolorum et ut quod quia. Voluptas numquam delectus nihil. Aut enim doloremque et ipsam.",
    author: {
      name: "Leslie Alexander",
      handle: "lesliealexander",
      imageUrl: "/testimonials/avatar-1.jpg",
    },
  },
  // More testimonials...
]

export function TestimonialsGrid() {
  return (
    <section className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-xl text-center">
          <h2 className="text-lg font-semibold leading-8 tracking-tight text-blue-600">
            Testimonials
          </h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            We have worked with thousands of amazing people
          </p>
        </div>
        <div className="mx-auto mt-16 flow-root max-w-2xl sm:mt-20 lg:mx-0 lg:max-w-none">
          <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {testimonials.map((testimonial, index) => (
              <div
                key={index}
                className="rounded-2xl bg-gray-50 p-8 text-sm leading-6"
              >
                <p className="text-gray-900">{testimonial.body}</p>
                <div className="mt-6 flex items-center gap-x-4">
                  <img
                    className="h-10 w-10 rounded-full bg-gray-50"
                    src={testimonial.author.imageUrl}
                    alt=""
                  />
                  <div>
                    <div className="font-semibold text-gray-900">
                      {testimonial.author.name}
                    </div>
                    <div className="text-gray-600">
                      @{testimonial.author.handle}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
```

---

## Phase 9: Newsletter Signup

```tsx
// components/newsletter/newsletter-simple.tsx
"use client"

import { useState } from "react"

export function NewsletterSimple() {
  const [email, setEmail] = useState("")
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      await fetch("/api/newsletter", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      })
      setSuccess(true)
      setEmail("")
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <section className="bg-white py-16 sm:py-24">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Stay updated
          </h2>
          <p className="mt-4 text-lg leading-8 text-gray-600">
            Get the latest news and articles to your inbox every month.
          </p>
          <form onSubmit={handleSubmit} className="mt-10 flex gap-x-4">
            <label htmlFor="email-address" className="sr-only">
              Email address
            </label>
            <input
              id="email-address"
              name="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="min-w-0 flex-auto rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6"
              placeholder="Enter your email"
            />
            <button
              type="submit"
              disabled={loading}
              className="flex-none rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 disabled:opacity-50"
            >
              {loading ? "Subscribing..." : "Subscribe"}
            </button>
          </form>
          {success && (
            <p className="mt-4 text-sm text-green-600">
              Thanks for subscribing!
            </p>
          )}
        </div>
      </div>
    </section>
  )
}
```

---

## Phase 10: Complete Landing Page Example

```tsx
// app/page.tsx (or pages/index.tsx)
import { HeroCentered } from "@/components/hero/hero-centered"
import { FeaturesGrid } from "@/components/features/features-grid"
import { TestimonialsGrid } from "@/components/testimonials/testimonials-grid"
import { FAQAccordion } from "@/components/faq/faq-accordion"
import { CTASimple } from "@/components/cta/cta-simple"
import { NewsletterSimple } from "@/components/newsletter/newsletter-simple"

export default function HomePage() {
  return (
    <>
      <HeroCentered />
      <FeaturesGrid />
      <TestimonialsGrid />
      <FAQAccordion />
      <CTASimple />
      <NewsletterSimple />
    </>
  )
}
```

---

## Best Practices

### Design

1. **Consistency**: Use a consistent design system (colors, spacing, typography)
2. **White Space**: Don't overcrowd sections
3. **Visual Hierarchy**: Clear heading levels (H1 → H2 → H3)
4. **Brand Colors**: Use your brand colors consistently
5. **Typography**: 2-3 fonts maximum

### Performance

1. **Image Optimization**: Use Next.js Image component
2. **Lazy Loading**: Load components as needed
3. **Code Splitting**: Split large pages into smaller chunks
4. **Font Loading**: Use next/font for optimal font loading

### Accessibility

1. **Semantic HTML**: Use proper heading hierarchy
2. **Alt Text**: All images need descriptive alt text
3. **Keyboard Navigation**: Ensure all interactive elements are keyboard accessible
4. **Color Contrast**: Ensure sufficient contrast (WCAG AA minimum)
5. **Focus States**: Visible focus indicators

### SEO

1. **Meta Tags**: Proper title, description, OG tags
2. **Structured Data**: Schema.org markup
3. **Headings**: One H1 per page, logical hierarchy
4. **Internal Linking**: Link to related pages
5. **Fast Loading**: Optimize for Core Web Vitals

---

## Conversion Optimization

### Above the Fold

- Clear value proposition
- Strong CTA within first screen
- Trust indicators (logos, testimonials)
- Minimal distractions

### CTAs

- Use action-oriented language
- Create urgency (limited time, spots)
- Make buttons stand out
- Multiple CTAs throughout page

### Social Proof

- Customer testimonials
- Company logos
- Usage statistics
- Reviews and ratings

### Trust Signals

- Security badges
- Money-back guarantee
- Free trial
- Privacy assurance

---

## Testing Checklist

- [ ] **Responsive**: Test on mobile, tablet, desktop
- [ ] **Cross-browser**: Chrome, Firefox, Safari, Edge
- [ ] **Performance**: Lighthouse score > 90
- [ ] **Accessibility**: WCAG AA compliance
- [ ] **Forms**: All validations work
- [ ] **Links**: No broken links
- [ ] **Images**: All images load and have alt text
- [ ] **Loading States**: All async operations show loading
- [ ] **Error States**: Errors are handled gracefully

---

## Resources

- [Tailwind UI](https://tailwindui.com)
- [Headless UI](https://headlessui.com)
- [Radix UI](https://radix-ui.com)
- [Framer Motion](https://www.framer.com/motion)
- [React Hook Form](https://react-hook-form.com)

---

## Reference Files

- `components/hero/` - 5 hero variants
- `components/features/` - Feature section layouts
- `components/faq/` - FAQ accordion
- `components/cta/` - CTA sections
- `components/contact/` - Contact forms
- `components/testimonials/` - Testimonial layouts
- `components/newsletter/` - Newsletter signups
- `templates/legal/` - Legal page templates

---

Last updated: 2025-01
