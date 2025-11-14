#!/bin/bash

# Next.js Landing Pages Setup Script
# Automatically sets up landing page components and structure

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

# Check if Tailwind is installed
if ! grep -q "tailwindcss" package.json; then
  print_warning "Tailwind CSS not found. Installing..."
  $INSTALL_CMD -D tailwindcss postcss autoprefixer
  npx tailwindcss init -p
  print_success "Tailwind CSS installed"
else
  print_success "Tailwind CSS detected"
fi

# Install dependencies
echo ""
print_step "Installing required dependencies..."
$INSTALL_CMD clsx tailwind-merge lucide-react

# Optional dependencies
echo ""
read -p "Install react-hook-form and zod for forms? (y/n): " INSTALL_FORMS
if [ "$INSTALL_FORMS" = "y" ] || [ "$INSTALL_FORMS" = "Y" ]; then
  $INSTALL_CMD react-hook-form zod @hookform/resolvers
  print_success "Form dependencies installed"
fi

read -p "Install framer-motion for animations? (y/n): " INSTALL_MOTION
if [ "$INSTALL_MOTION" = "y" ] || [ "$INSTALL_MOTION" = "Y" ]; then
  $INSTALL_CMD framer-motion
  print_success "Framer Motion installed"
fi

# Create component directories
echo ""
print_step "Creating component directory structure..."

mkdir -p components/{hero,features,faq,cta,testimonials,newsletter,contact}

print_success "Component directories created"

# Create utility functions
echo ""
print_step "Creating utility functions..."

mkdir -p lib

cat > lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

print_success "Created lib/utils.ts"

# Ask which components to create
echo ""
print_step "Which components would you like to create?"
read -p "Create Hero section? (y/n): " CREATE_HERO
read -p "Create Features section? (y/n): " CREATE_FEATURES
read -p "Create FAQ section? (y/n): " CREATE_FAQ
read -p "Create CTA section? (y/n): " CREATE_CTA
read -p "Create Contact form? (y/n): " CREATE_CONTACT
read -p "Create Newsletter signup? (y/n): " CREATE_NEWSLETTER

# Create selected components
if [ "$CREATE_HERO" = "y" ] || [ "$CREATE_HERO" = "Y" ]; then
  cat > components/hero/hero-simple.tsx << 'EOF'
export function HeroSimple() {
  return (
    <section className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h1 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-6xl">
            Your Amazing Product
          </h1>
          <p className="mt-6 text-lg leading-8 text-gray-600">
            Transform your business with our innovative solution.
          </p>
          <div className="mt-10 flex items-center justify-center gap-x-6">
            <a
              href="#"
              className="rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500"
            >
              Get started
            </a>
            <a href="#" className="text-sm font-semibold leading-6 text-gray-900">
              Learn more <span aria-hidden="true">→</span>
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
EOF
  print_success "Created Hero component"
fi

if [ "$CREATE_FEATURES" = "y" ] || [ "$CREATE_FEATURES" = "Y" ]; then
  cat > components/features/features-simple.tsx << 'EOF'
const features = [
  { name: "Feature 1", description: "Description of feature 1" },
  { name: "Feature 2", description: "Description of feature 2" },
  { name: "Feature 3", description: "Description of feature 3" },
]

export function FeaturesSimple() {
  return (
    <section className="bg-gray-50 py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl lg:text-center">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
            Everything you need
          </h2>
        </div>
        <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
            {features.map((feature) => (
              <div key={feature.name} className="flex flex-col">
                <dt className="text-base font-semibold leading-7 text-gray-900">
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
EOF
  print_success "Created Features component"
fi

if [ "$CREATE_FAQ" = "y" ] || [ "$CREATE_FAQ" = "Y" ]; then
  cat > components/faq/faq-simple.tsx << 'EOF'
"use client"

import { useState } from "react"

const faqs = [
  { question: "Question 1?", answer: "Answer 1" },
  { question: "Question 2?", answer: "Answer 2" },
  { question: "Question 3?", answer: "Answer 3" },
]

export function FAQSimple() {
  const [openIndex, setOpenIndex] = useState<number | null>(null)

  return (
    <section className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-4xl">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900">
            Frequently asked questions
          </h2>
          <dl className="mt-10 space-y-6">
            {faqs.map((faq, index) => (
              <div key={index} className="pt-6">
                <dt>
                  <button
                    onClick={() => setOpenIndex(openIndex === index ? null : index)}
                    className="flex w-full items-start justify-between text-left"
                  >
                    <span className="text-base font-semibold">{faq.question}</span>
                  </button>
                </dt>
                {openIndex === index && (
                  <dd className="mt-2">
                    <p className="text-base text-gray-600">{faq.answer}</p>
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
EOF
  print_success "Created FAQ component"
fi

# Create legal page templates if App Router
if [ "$ROUTER_TYPE" = "app" ]; then
  echo ""
  read -p "Create legal pages (Terms, Privacy)? (y/n): " CREATE_LEGAL

  if [ "$CREATE_LEGAL" = "y" ] || [ "$CREATE_LEGAL" = "Y" ]; then
    mkdir -p app/terms app/privacy

    cat > app/terms/page.tsx << 'EOF'
export default function TermsPage() {
  return (
    <div className="bg-white px-6 py-32 lg:px-8">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-3xl font-bold">Terms of Service</h1>
        <p className="mt-6">Last updated: January 1, 2025</p>
        {/* Add your terms content here */}
      </div>
    </div>
  )
}
EOF

    cat > app/privacy/page.tsx << 'EOF'
export default function PrivacyPage() {
  return (
    <div className="bg-white px-6 py-32 lg:px-8">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-3xl font-bold">Privacy Policy</h1>
        <p className="mt-6">Last updated: January 1, 2025</p>
        {/* Add your privacy policy content here */}
      </div>
    </div>
  )
}
EOF

    print_success "Created legal pages"
  fi
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Landing pages setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was created:"
echo "  ✓ Component directories"
echo "  ✓ Utility functions"
if [ "$CREATE_HERO" = "y" ]; then echo "  ✓ Hero component"; fi
if [ "$CREATE_FEATURES" = "y" ]; then echo "  ✓ Features component"; fi
if [ "$CREATE_FAQ" = "y" ]; then echo "  ✓ FAQ component"; fi
if [ "$CREATE_LEGAL" = "y" ]; then echo "  ✓ Legal pages"; fi
echo ""
echo "📚 Next steps:"
echo "  1. Customize components in components/ directory"
echo "  2. Update content with your actual copy"
echo "  3. Add your brand colors to Tailwind config"
echo "  4. Import components into your pages"
echo ""
echo "💡 Example usage:"
echo "  import { HeroSimple } from '@/components/hero/hero-simple'"
echo ""
