// components/hero/hero-gradient.tsx
// Modern gradient hero with animated background

"use client"

import { ArrowRight } from "lucide-react"

export function HeroGradient() {
  return (
    <section className="relative min-h-screen overflow-hidden bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500">
      {/* Animated gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-blue-600/50 via-purple-600/50 to-pink-600/50 animate-pulse"></div>

      {/* Grid pattern overlay */}
      <div
        className="absolute inset-0 opacity-20"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.4'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
        }}
      ></div>

      <div className="relative mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8 lg:py-40">
        <div className="mx-auto max-w-4xl text-center">
          {/* Badge */}
          <div className="mb-8 inline-flex items-center rounded-full bg-white/10 px-3 py-1 text-sm font-medium text-white backdrop-blur-sm ring-1 ring-inset ring-white/20">
            <span className="mr-2">🎉</span>
            Introducing our new feature
          </div>

          {/* Main heading */}
          <h1 className="text-5xl font-bold tracking-tight text-white sm:text-7xl">
            Build something
            <span className="block bg-gradient-to-r from-yellow-200 to-pink-200 bg-clip-text text-transparent">
              amazing today
            </span>
          </h1>

          {/* Description */}
          <p className="mt-6 text-lg leading-8 text-gray-100 sm:text-xl">
            Create stunning landing pages in minutes with our modern component library.
            No design skills required. Just beautiful, responsive, and accessible by default.
          </p>

          {/* CTA buttons */}
          <div className="mt-10 flex items-center justify-center gap-x-6">
            <button className="group flex items-center gap-2 rounded-lg bg-white px-6 py-3 text-sm font-semibold text-gray-900 shadow-lg transition-all hover:scale-105 hover:shadow-xl">
              Get started free
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
            </button>
            <button className="rounded-lg bg-white/10 px-6 py-3 text-sm font-semibold text-white backdrop-blur-sm ring-1 ring-inset ring-white/20 transition-all hover:bg-white/20">
              Watch demo
            </button>
          </div>

          {/* Stats or social proof */}
          <div className="mt-16 flex items-center justify-center gap-x-12 text-white">
            <div>
              <div className="text-3xl font-bold">50K+</div>
              <div className="text-sm text-gray-200">Active users</div>
            </div>
            <div className="h-12 w-px bg-white/20"></div>
            <div>
              <div className="text-3xl font-bold">4.9/5</div>
              <div className="text-sm text-gray-200">User rating</div>
            </div>
            <div className="h-12 w-px bg-white/20"></div>
            <div>
              <div className="text-3xl font-bold">99.9%</div>
              <div className="text-sm text-gray-200">Uptime</div>
            </div>
          </div>
        </div>

        {/* Optional: Mockup/Screenshot */}
        <div className="mt-20">
          <div className="relative mx-auto max-w-5xl">
            <div className="absolute -inset-4 rounded-3xl bg-gradient-to-r from-yellow-400 to-pink-400 opacity-30 blur-2xl"></div>
            <div className="relative rounded-2xl bg-white/10 p-2 backdrop-blur-sm ring-1 ring-white/20">
              <img
                src="/placeholder-dashboard.png"
                alt="Product screenshot"
                className="w-full rounded-lg shadow-2xl"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
