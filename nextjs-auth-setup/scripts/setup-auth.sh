#!/bin/bash

# Next.js Auth.js Setup Script
# Automatically configures Auth.js (NextAuth.js) in your Next.js project

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

# Detect Next.js version and router type
NEXT_VERSION=$(node -p "require('./package.json').dependencies.next" | tr -d '^~' | cut -d'.' -f1)
print_step "Detected Next.js version: $NEXT_VERSION"

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
  INSTALL_DEV_CMD="pnpm add -D"
elif [ -f "yarn.lock" ]; then
  PKG_MANAGER="yarn"
  INSTALL_CMD="yarn add"
  INSTALL_DEV_CMD="yarn add -D"
elif [ -f "bun.lockb" ]; then
  PKG_MANAGER="bun"
  INSTALL_CMD="bun add"
  INSTALL_DEV_CMD="bun add -D"
else
  PKG_MANAGER="npm"
  INSTALL_CMD="npm install"
  INSTALL_DEV_CMD="npm install -D"
fi

print_success "Using package manager: $PKG_MANAGER"

# Prompt for Auth.js version
echo ""
print_step "Which version would you like to install?"
echo "  1) Auth.js v5 (beta) - Recommended for new projects"
echo "  2) NextAuth.js v4 (stable) - Production-ready"
read -p "Enter choice (1 or 2): " AUTH_VERSION_CHOICE

if [ "$AUTH_VERSION_CHOICE" = "1" ]; then
  AUTH_VERSION="v5"
  NEXT_AUTH_PKG="next-auth@beta"
  ADAPTER_PKG="@auth/prisma-adapter"
  print_success "Selected: Auth.js v5"
else
  AUTH_VERSION="v4"
  NEXT_AUTH_PKG="next-auth"
  ADAPTER_PKG="@next-auth/prisma-adapter"
  print_success "Selected: NextAuth.js v4"
fi

# Prompt for features
echo ""
print_step "What features do you need?"
read -p "Use database sessions with Prisma? (y/n): " USE_DATABASE
read -p "Include credentials (email/password) provider? (y/n): " USE_CREDENTIALS
read -p "Include Google OAuth? (y/n): " USE_GOOGLE
read -p "Include GitHub OAuth? (y/n): " USE_GITHUB

# Install core dependencies
echo ""
print_step "Installing Auth.js packages..."
$INSTALL_CMD $NEXT_AUTH_PKG

if [ "$USE_DATABASE" = "y" ] || [ "$USE_DATABASE" = "Y" ]; then
  print_step "Installing Prisma adapter..."
  $INSTALL_CMD $ADAPTER_PKG @prisma/client
  $INSTALL_DEV_CMD prisma
fi

if [ "$USE_CREDENTIALS" = "y" ] || [ "$USE_CREDENTIALS" = "Y" ]; then
  print_step "Installing bcryptjs for password hashing..."
  $INSTALL_CMD bcryptjs
  $INSTALL_DEV_CMD @types/bcryptjs
fi

print_success "Dependencies installed"

# Create environment variables file
echo ""
print_step "Setting up environment variables..."

if [ ! -f ".env.local" ]; then
  touch .env.local
  print_success "Created .env.local"
else
  print_warning ".env.local already exists, appending to it"
fi

# Generate secret
SECRET=$(openssl rand -base64 32)

# Add to .env.local
echo "" >> .env.local
echo "# Auth.js Configuration" >> .env.local
echo "NEXTAUTH_URL=http://localhost:3000" >> .env.local

if [ "$AUTH_VERSION" = "v5" ]; then
  echo "AUTH_SECRET=$SECRET" >> .env.local
else
  echo "NEXTAUTH_SECRET=$SECRET" >> .env.local
fi

if [ "$USE_DATABASE" = "y" ] || [ "$USE_DATABASE" = "Y" ]; then
  echo "" >> .env.local
  echo "# Database" >> .env.local
  echo "DATABASE_URL=\"postgresql://user:password@localhost:5432/mydb\"" >> .env.local
fi

if [ "$USE_GOOGLE" = "y" ] || [ "$USE_GOOGLE" = "Y" ]; then
  echo "" >> .env.local
  echo "# Google OAuth" >> .env.local
  echo "GOOGLE_CLIENT_ID=your_google_client_id" >> .env.local
  echo "GOOGLE_CLIENT_SECRET=your_google_client_secret" >> .env.local
fi

if [ "$USE_GITHUB" = "y" ] || [ "$USE_GITHUB" = "Y" ]; then
  echo "" >> .env.local
  echo "# GitHub OAuth" >> .env.local
  echo "GITHUB_CLIENT_ID=your_github_client_id" >> .env.local
  echo "GITHUB_CLIENT_SECRET=your_github_client_secret" >> .env.local
fi

print_success "Environment variables configured"

# Create auth configuration file
echo ""
print_step "Creating auth configuration..."

if [ "$ROUTER_TYPE" = "app" ]; then
  # Create auth.ts for App Router
  cat > auth.ts << 'EOF'
import NextAuth from "next-auth"
EOF

  if [ "$USE_GOOGLE" = "y" ] || [ "$USE_GOOGLE" = "Y" ]; then
    echo 'import Google from "next-auth/providers/google"' >> auth.ts
  fi

  if [ "$USE_GITHUB" = "y" ] || [ "$USE_GITHUB" = "Y" ]; then
    echo 'import GitHub from "next-auth/providers/github"' >> auth.ts
  fi

  if [ "$USE_CREDENTIALS" = "y" ] || [ "$USE_CREDENTIALS" = "Y" ]; then
    echo 'import Credentials from "next-auth/providers/credentials"' >> auth.ts
    echo 'import bcrypt from "bcryptjs"' >> auth.ts
  fi

  if [ "$USE_DATABASE" = "y" ] || [ "$USE_DATABASE" = "Y" ]; then
    echo 'import { PrismaAdapter } from "@auth/prisma-adapter"' >> auth.ts
    echo 'import { PrismaClient } from "@prisma/client"' >> auth.ts
    echo '' >> auth.ts
    echo 'const prisma = new PrismaClient()' >> auth.ts
  fi

  cat >> auth.ts << 'EOF'

export const { handlers, signIn, signOut, auth } = NextAuth({
EOF

  if [ "$USE_DATABASE" = "y" ] || [ "$USE_DATABASE" = "Y" ]; then
    echo '  adapter: PrismaAdapter(prisma),' >> auth.ts
  fi

  cat >> auth.ts << 'EOF'
  session: { strategy: "jwt" },
  providers: [
EOF

  if [ "$USE_GOOGLE" = "y" ] || [ "$USE_GOOGLE" = "Y" ]; then
    cat >> auth.ts << 'EOF'
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
EOF
  fi

  if [ "$USE_GITHUB" = "y" ] || [ "$USE_GITHUB" = "Y" ]; then
    cat >> auth.ts << 'EOF'
    GitHub({
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    }),
EOF
  fi

  if [ "$USE_CREDENTIALS" = "y" ] || [ "$USE_CREDENTIALS" = "Y" ]; then
    cat >> auth.ts << 'EOF'
    Credentials({
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials) {
        // TODO: Implement your credential verification logic
        // const user = await getUserByEmail(credentials.email)
        // const isValid = await bcrypt.compare(credentials.password, user.password)
        // return isValid ? user : null
        return null
      },
    }),
EOF
  fi

  cat >> auth.ts << 'EOF'
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) token.id = user.id
      return token
    },
    async session({ session, token }) {
      if (session.user) session.user.id = token.id as string
      return session
    },
  },
})
EOF

  print_success "Created auth.ts"

  # Create API route handler
  mkdir -p app/api/auth/\[...nextauth\]
  cat > app/api/auth/\[...nextauth\]/route.ts << 'EOF'
import { handlers } from "@/auth"

export const { GET, POST } = handlers
EOF

  print_success "Created API route handler"

else
  # Create Pages Router configuration
  mkdir -p pages/api/auth

  cat > pages/api/auth/\[...nextauth\].ts << 'EOF'
import NextAuth, { NextAuthOptions } from "next-auth"
EOF

  if [ "$USE_GOOGLE" = "y" ] || [ "$USE_GOOGLE" = "Y" ]; then
    echo 'import GoogleProvider from "next-auth/providers/google"' >> pages/api/auth/\[...nextauth\].ts
  fi

  if [ "$USE_GITHUB" = "y" ] || [ "$USE_GITHUB" = "Y" ]; then
    echo 'import GitHubProvider from "next-auth/providers/github"' >> pages/api/auth/\[...nextauth\].ts
  fi

  if [ "$USE_CREDENTIALS" = "y" ] || [ "$USE_CREDENTIALS" = "Y" ]; then
    echo 'import CredentialsProvider from "next-auth/providers/credentials"' >> pages/api/auth/\[...nextauth\].ts
  fi

  cat >> pages/api/auth/\[...nextauth\].ts << 'EOF'

export const authOptions: NextAuthOptions = {
  session: { strategy: "jwt" },
  providers: [
EOF

  if [ "$USE_GOOGLE" = "y" ] || [ "$USE_GOOGLE" = "Y" ]; then
    cat >> pages/api/auth/\[...nextauth\].ts << 'EOF'
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
EOF
  fi

  if [ "$USE_GITHUB" = "y" ] || [ "$USE_GITHUB" = "Y" ]; then
    cat >> pages/api/auth/\[...nextauth\].ts << 'EOF'
    GitHubProvider({
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    }),
EOF
  fi

  cat >> pages/api/auth/\[...nextauth\].ts << 'EOF'
  ],
}

export default NextAuth(authOptions)
EOF

  print_success "Created pages/api/auth/[...nextauth].ts"
fi

# Create TypeScript type declarations
echo ""
print_step "Creating TypeScript definitions..."

mkdir -p types
cat > types/next-auth.d.ts << 'EOF'
import { DefaultSession } from "next-auth"

declare module "next-auth" {
  interface Session {
    user: {
      id: string
    } & DefaultSession["user"]
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id: string
  }
}
EOF

print_success "Created types/next-auth.d.ts"

# Setup Prisma if requested
if [ "$USE_DATABASE" = "y" ] || [ "$USE_DATABASE" = "Y" ]; then
  echo ""
  print_step "Setting up Prisma..."

  if [ ! -d "prisma" ]; then
    npx prisma init --datasource-provider postgresql
    print_success "Initialized Prisma"
  fi

  print_warning "Don't forget to:"
  echo "  1. Update DATABASE_URL in .env.local"
  echo "  2. Add Auth.js models to prisma/schema.prisma"
  echo "  3. Run: npx prisma migrate dev"
fi

# Create middleware
echo ""
print_step "Creating middleware for route protection..."

cat > middleware.ts << 'EOF'
import { auth } from "@/auth"
import { NextResponse } from "next/server"

export default auth((req) => {
  const { pathname } = req.nextUrl
  const isAuthenticated = !!req.auth

  // Public routes
  const publicRoutes = ["/", "/auth/signin"]
  const isPublicRoute = publicRoutes.some(route => pathname.startsWith(route))

  if (!isAuthenticated && !isPublicRoute) {
    return NextResponse.redirect(new URL("/auth/signin", req.url))
  }

  return NextResponse.next()
})

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|public/).*)"],
}
EOF

print_success "Created middleware.ts"

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Auth.js setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Update .env.local with your OAuth credentials"

if [ "$USE_DATABASE" = "y" ] || [ "$USE_DATABASE" = "Y" ]; then
  echo "2. Update DATABASE_URL in .env.local"
  echo "3. Add Auth.js models to prisma/schema.prisma"
  echo "4. Run: npx prisma migrate dev"
  echo "5. Create your sign-in page"
else
  echo "2. Create your sign-in page"
fi

echo ""
echo "📚 Resources:"
echo "  - Auth.js docs: https://authjs.dev"
echo "  - OAuth setup: See reference/oauth-setup-guides.md"
echo "  - Troubleshooting: See reference/troubleshooting.md"
echo ""
