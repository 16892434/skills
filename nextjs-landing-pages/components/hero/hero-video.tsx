// components/hero/hero-video.tsx
// Hero section with video background

"use client"

import { Play } from "lucide-react"
import { useState } from "react"

export function HeroVideo() {
  const [isVideoPlaying, setIsVideoPlaying] = useState(false)

  return (
    <section className="relative h-screen overflow-hidden bg-gray-900">
      {/* Video background */}
      <div className="absolute inset-0">
        <video
          autoPlay
          muted
          loop
          playsInline
          className="h-full w-full object-cover opacity-40"
        >
          <source src="/hero-video.mp4" type="video/mp4" />
        </video>
        <div className="absolute inset-0 bg-gradient-to-b from-gray-900/50 to-gray-900/80"></div>
      </div>

      {/* Content */}
      <div className="relative flex h-full items-center">
        <div className="mx-auto max-w-7xl px-6 text-center lg:px-8">
          <div className="mx-auto max-w-3xl">
            <h1 className="text-5xl font-bold tracking-tight text-white sm:text-7xl">
              Experience the future of{" "}
              <span className="text-blue-400">productivity</span>
            </h1>
            <p className="mt-6 text-lg leading-8 text-gray-300">
              Transform the way you work with our innovative platform designed
              for modern teams. Collaborate, create, and succeed together.
            </p>

            {/* Video modal trigger */}
            <div className="mt-10 flex flex-col items-center gap-6 sm:flex-row sm:justify-center">
              <button className="rounded-lg bg-blue-600 px-8 py-4 text-base font-semibold text-white shadow-lg transition-all hover:bg-blue-700 hover:shadow-xl">
                Get started for free
              </button>
              <button
                onClick={() => setIsVideoPlaying(true)}
                className="group flex items-center gap-3 text-white transition-colors hover:text-blue-400"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/10 backdrop-blur-sm ring-1 ring-white/20 transition-all group-hover:bg-white/20">
                  <Play className="h-5 w-5 fill-current" />
                </div>
                <span className="text-sm font-medium">Watch demo (2 min)</span>
              </button>
            </div>

            {/* Trust indicators */}
            <div className="mt-16">
              <p className="text-sm text-gray-400">Trusted by industry leaders</p>
              <div className="mt-6 flex items-center justify-center gap-x-8 opacity-70 grayscale">
                {/* Add company logos here */}
                <img src="/logos/company-1.svg" alt="Company 1" className="h-8" />
                <img src="/logos/company-2.svg" alt="Company 2" className="h-8" />
                <img src="/logos/company-3.svg" alt="Company 3" className="h-8" />
                <img src="/logos/company-4.svg" alt="Company 4" className="h-8" />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Video modal */}
      {isVideoPlaying && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 p-4"
          onClick={() => setIsVideoPlaying(false)}
        >
          <div className="relative w-full max-w-5xl">
            <button
              onClick={() => setIsVideoPlaying(false)}
              className="absolute -top-12 right-0 text-white hover:text-gray-300"
            >
              <span className="sr-only">Close</span>
              <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <div className="aspect-video w-full">
              <iframe
                src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowFullScreen
                className="h-full w-full rounded-lg"
              ></iframe>
            </div>
          </div>
        </div>
      )}
    </section>
  )
}
