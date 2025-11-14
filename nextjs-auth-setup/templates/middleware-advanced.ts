// middleware.ts - Advanced middleware with role-based access control
// Place this file in the root of your Next.js project

import { auth } from "@/auth"
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

// Define route access rules
const routeConfig = {
  // Public routes (no auth required)
  public: [
    "/",
    "/about",
    "/pricing",
    "/features",
    "/blog",
    "/auth/signin",
    "/auth/signup",
    "/auth/error",
    "/api/auth",
  ],

  // Protected routes (auth required)
  protected: [
    "/dashboard",
    "/profile",
    "/settings",
  ],

  // Admin-only routes
  admin: [
    "/admin",
    "/admin/users",
    "/admin/settings",
  ],

  // Moderator routes
  moderator: [
    "/moderation",
  ],
} as const

function isPublicRoute(pathname: string): boolean {
  return routeConfig.public.some(route =>
    pathname.startsWith(route) || pathname === route
  )
}

function isAdminRoute(pathname: string): boolean {
  return routeConfig.admin.some(route => pathname.startsWith(route))
}

function isModeratorRoute(pathname: string): boolean {
  return routeConfig.moderator.some(route => pathname.startsWith(route))
}

export default auth(async (req) => {
  const { pathname } = req.nextUrl
  const session = req.auth

  // Allow public routes
  if (isPublicRoute(pathname)) {
    return NextResponse.next()
  }

  // Allow API routes (handle auth separately in API handlers)
  if (pathname.startsWith("/api/") && !pathname.startsWith("/api/auth")) {
    return NextResponse.next()
  }

  // Redirect unauthenticated users
  if (!session) {
    const signInUrl = new URL("/auth/signin", req.url)
    signInUrl.searchParams.set("callbackUrl", pathname)
    return NextResponse.redirect(signInUrl)
  }

  // Check admin routes
  if (isAdminRoute(pathname)) {
    if (session.user?.role !== "ADMIN") {
      return NextResponse.redirect(new URL("/dashboard", req.url))
    }
  }

  // Check moderator routes
  if (isModeratorRoute(pathname)) {
    const allowedRoles = ["ADMIN", "MODERATOR"]
    if (!allowedRoles.includes(session.user?.role || "")) {
      return NextResponse.redirect(new URL("/dashboard", req.url))
    }
  }

  // Redirect authenticated users away from auth pages
  if (pathname.startsWith("/auth/signin") || pathname.startsWith("/auth/signup")) {
    return NextResponse.redirect(new URL("/dashboard", req.url))
  }

  // Add security headers
  const response = NextResponse.next()

  // Security headers
  response.headers.set("X-Frame-Options", "DENY")
  response.headers.set("X-Content-Type-Options", "nosniff")
  response.headers.set("Referrer-Policy", "strict-origin-when-cross-origin")

  // CSP header (adjust based on your needs)
  response.headers.set(
    "Content-Security-Policy",
    "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
  )

  return response
})

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     * - files with extensions (e.g., .png, .jpg, .svg)
     */
    "/((?!_next/static|_next/image|favicon.ico|public/|.*\\..*|api/webhook).*)",
  ],
}
