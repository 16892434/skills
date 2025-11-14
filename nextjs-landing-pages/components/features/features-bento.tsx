// components/features/features-bento.tsx
// Bento grid layout for features with visual hierarchy

import { BarChart, Lock, Zap, Users, Globe, Smartphone } from "lucide-react"

const features = [
  {
    name: "Analytics",
    description: "Powerful insights to grow your business with real-time data.",
    icon: BarChart,
    className: "col-span-2 row-span-2",
    image: "/features/analytics.png",
  },
  {
    name: "Security",
    description: "Bank-level encryption and security.",
    icon: Lock,
    className: "col-span-1 row-span-1",
  },
  {
    name: "Fast Performance",
    description: "Lightning-fast load times globally.",
    icon: Zap,
    className: "col-span-1 row-span-1",
  },
  {
    name: "Team Collaboration",
    description: "Work together seamlessly in real-time.",
    icon: Users,
    className: "col-span-1 row-span-2",
    image: "/features/collaboration.png",
  },
  {
    name: "Global CDN",
    description: "Content delivered from the edge.",
    icon: Globe,
    className: "col-span-1 row-span-1",
  },
  {
    name: "Mobile First",
    description: "Beautiful on every device.",
    icon: Smartphone,
    className: "col-span-1 row-span-1",
  },
]

export function FeaturesBento() {
  return (
    <section className="bg-gray-50 py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        {/* Header */}
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-base font-semibold leading-7 text-blue-600">
            Everything you need
          </h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            All-in-one platform
          </p>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            Powerful features designed to help you build, launch, and scale your business.
          </p>
        </div>

        {/* Bento grid */}
        <div className="mx-auto mt-16 grid max-w-7xl grid-cols-1 gap-6 sm:mt-20 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div
              key={feature.name}
              className={`group relative overflow-hidden rounded-2xl bg-white p-6 shadow-sm ring-1 ring-gray-900/5 transition-all hover:shadow-lg ${feature.className}`}
            >
              {/* Icon */}
              <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-blue-600">
                <feature.icon className="h-6 w-6 text-white" aria-hidden="true" />
              </div>

              {/* Content */}
              <div className="mt-4">
                <h3 className="text-lg font-semibold text-gray-900">
                  {feature.name}
                </h3>
                <p className="mt-2 text-sm text-gray-600">
                  {feature.description}
                </p>
              </div>

              {/* Optional image for larger cards */}
              {feature.image && (
                <div className="mt-6 overflow-hidden rounded-lg">
                  <img
                    src={feature.image}
                    alt={feature.name}
                    className="w-full object-cover transition-transform group-hover:scale-105"
                  />
                </div>
              )}

              {/* Hover effect */}
              <div className="absolute inset-0 -z-10 bg-gradient-to-br from-blue-50 to-purple-50 opacity-0 transition-opacity group-hover:opacity-100"></div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
