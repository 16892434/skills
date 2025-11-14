# Next.js Landing Pages Skill

A comprehensive skill for building professional, high-converting landing pages in Next.js.

## Features

- ✅ **5+ Hero Variants**: Centered, split, gradient, video, and animated
- ✅ **Multiple Layouts**: Grid, bento, and screenshot-based features
- ✅ **Interactive Components**: FAQ accordions, contact forms, newsletters
- ✅ **Legal Templates**: Terms of Service, Privacy Policy (GDPR/CCPA compliant)
- ✅ **Conversion-Optimized**: CTAs, testimonials, social proof
- ✅ **Fully Responsive**: Mobile-first design
- ✅ **Accessible**: WCAG AA compliant
- ✅ **SEO Ready**: Semantic HTML, meta tags
- ✅ **Tailwind CSS**: Modern styling with utility classes
- ✅ **TypeScript Support**: Full type safety

## Quick Start

### Automated Setup

Run the setup script in your Next.js project:

```bash
bash scripts/setup-landing-pages.sh
```

This interactive script will:
1. Check for Tailwind CSS (install if needed)
2. Install required dependencies
3. Create component directory structure
4. Generate selected components
5. Create utility functions

### Manual Usage with Claude Code

Simply ask:

```
"Create a landing page with a gradient hero, features grid, FAQ, and contact form"
```

Claude will use this skill to build a complete, professional landing page.

## What's Included

### Components

#### Hero Sections (5 Variants)

1. **Centered Hero** (`hero/hero-centered.tsx`)
   - Clean, minimal design
   - Perfect for SaaS products
   - Badge, heading, description, dual CTAs

2. **Split Hero** (`hero/hero-split.tsx`)
   - Content on left, image on right
   - Great for visual products
   - Asymmetric layout

3. **Gradient Hero** (`hero/hero-gradient.tsx`)
   - Modern gradient background
   - Animated elements
   - Stats/social proof included

4. **Video Hero** (`hero/hero-video.tsx`)
   - Video background support
   - Modal video player
   - Trust indicators

5. **Animated Hero** (reference in SKILL.md)
   - Framer Motion animations
   - Interactive elements

#### Features Sections

- **Grid Layout** (`features/features-grid.tsx`)
  - 4-column responsive grid
  - Icon + description

- **Bento Grid** (`features/features-bento.tsx`)
  - Visual hierarchy
  - Mixed sizes for emphasis
  - Image support

- **Screenshots** (reference in SKILL.md)
  - Feature showcases with visuals

#### Interactive Components

- **FAQ Accordion** (in SKILL.md)
  - Expandable Q&A
  - Smooth animations
  - Accessible keyboard navigation

- **Contact Form** (in SKILL.md)
  - React Hook Form validation
  - Zod schema validation
  - Success/error states
  - API route included

- **Newsletter Signup** (in SKILL.md)
  - Email collection
  - Loading states
  - Success feedback

#### CTAs

- **Simple CTA** (in SKILL.md)
  - Centered, high-contrast
  - Dual-action buttons

- **CTA with App** (reference in SKILL.md)
  - Screenshot integration

#### Testimonials

- **Grid Layout** (in SKILL.md)
  - Customer quotes
  - Avatar + name
  - Responsive grid

### Legal Pages

Professional templates for:

- **Terms of Service** (`templates/legal/terms-of-service.tsx`)
  - Comprehensive sections
  - Subscription clauses
  - Refund policy
  - Liability disclaimers

- **Privacy Policy** (`templates/legal/privacy-policy.tsx`)
  - GDPR compliant
  - CCPA (California) compliant
  - Cookie policy
  - Data usage explanation

### Utilities

- **`lib/utils.ts`**: className merging with `clsx` and `tailwind-merge`

## Component Structure

```
components/
├── hero/
│   ├── hero-centered.tsx
│   ├── hero-split.tsx
│   ├── hero-gradient.tsx
│   └── hero-video.tsx
├── features/
│   ├── features-grid.tsx
│   └── features-bento.tsx
├── faq/
│   └── faq-accordion.tsx
├── cta/
│   └── cta-simple.tsx
├── testimonials/
│   └── testimonials-grid.tsx
├── newsletter/
│   └── newsletter-simple.tsx
└── contact/
    └── contact-form.tsx
```

## Usage Examples

### Complete Landing Page

```tsx
// app/page.tsx
import { HeroCentered } from "@/components/hero/hero-centered"
import { FeaturesGrid } from "@/components/features/features-grid"
import { FAQAccordion } from "@/components/faq/faq-accordion"
import { CTASimple } from "@/components/cta/cta-simple"

export default function HomePage() {
  return (
    <>
      <HeroCentered />
      <FeaturesGrid />
      <FAQAccordion />
      <CTASimple />
    </>
  )
}
```

### Product Page

```tsx
import { HeroSplit } from "@/components/hero/hero-split"
import { FeaturesBento } from "@/components/features/features-bento"
import { TestimonialsGrid } from "@/components/testimonials/testimonials-grid"
```

### Coming Soon Page

```tsx
import { HeroGradient } from "@/components/hero/hero-gradient"
import { NewsletterSimple } from "@/components/newsletter/newsletter-simple"
```

## Dependencies

### Required

```json
{
  "clsx": "^2.0.0",
  "tailwind-merge": "^2.0.0",
  "lucide-react": "^0.300.0"
}
```

### Optional

```json
{
  "react-hook-form": "^7.0.0",
  "zod": "^3.0.0",
  "@hookform/resolvers": "^3.0.0",
  "framer-motion": "^10.0.0"
}
```

## Customization

### Colors

Update your `tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      brand: {
        50: "#your-color",
        // ... rest of shades
      },
    },
  },
}
```

### Typography

```javascript
theme: {
  extend: {
    fontFamily: {
      sans: ['Inter', 'system-ui', 'sans-serif'],
      display: ['Cal Sans', 'sans-serif'],
    },
  },
}
```

### Animations

Add custom animations to Tailwind config as shown in SKILL.md.

## Best Practices

### Design

- ✅ Consistent spacing (use Tailwind's spacing scale)
- ✅ Clear visual hierarchy
- ✅ Adequate white space
- ✅ Limited color palette (2-3 main colors)
- ✅ Professional imagery

### Performance

- ✅ Use Next.js Image component
- ✅ Lazy load below-the-fold components
- ✅ Optimize fonts with next/font
- ✅ Minimize JavaScript bundle

### Accessibility

- ✅ Semantic HTML (proper heading hierarchy)
- ✅ Alt text for all images
- ✅ Keyboard navigation
- ✅ Sufficient color contrast (4.5:1 minimum)
- ✅ Focus indicators

### SEO

- ✅ One H1 per page
- ✅ Meta titles and descriptions
- ✅ Open Graph tags
- ✅ Structured data (JSON-LD)
- ✅ Fast loading (Core Web Vitals)

## Conversion Optimization

### Above the Fold

- Clear value proposition
- Strong CTA within first screen
- Trust indicators (logos, stats)
- Minimal distractions

### CTAs

- Action-oriented language ("Get started", not "Submit")
- Create urgency
- High contrast colors
- Multiple CTAs throughout page

### Social Proof

- Customer testimonials with photos
- Company logos (trusted brands)
- Usage statistics
- Reviews and ratings

## Testing Checklist

Before launching:

- [ ] Test on mobile devices
- [ ] Test on tablets
- [ ] Test on desktop (various resolutions)
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Lighthouse score > 90
- [ ] Accessibility audit (axe DevTools)
- [ ] All forms validate correctly
- [ ] All links work
- [ ] Images load and have alt text
- [ ] Loading states work
- [ ] Error states handle gracefully

## Common Use Cases

1. **SaaS Product Landing**: Hero + Features + Pricing + FAQ
2. **App Launch**: Video Hero + Bento Features + Testimonials
3. **Coming Soon**: Gradient Hero + Newsletter
4. **Product Page**: Split Hero + Features + CTA
5. **Agency Portfolio**: Animated Hero + Projects + Contact

## Integration with Other Skills

Works seamlessly with:

- **nextjs-stripe-subscription**: Add pricing tables
- **nextjs-auth-setup**: User authentication
- **nextjs-dashboard-scaffold**: Post-signup experience

## File Structure

```
nextjs-landing-pages/
├── SKILL.md                  # Comprehensive guide
├── README.md
├── LICENSE.txt
├── scripts/
│   └── setup-landing-pages.sh
├── components/
│   ├── hero/
│   │   ├── hero-gradient.tsx
│   │   └── hero-video.tsx
│   └── features/
│       └── features-bento.tsx
└── templates/
    └── legal/
        ├── privacy-policy.tsx
        └── terms-of-service.tsx
```

## Resources

- [Tailwind UI](https://tailwindui.com) - Premium components
- [Headless UI](https://headlessui.com) - Unstyled, accessible components
- [Hero Icons](https://heroicons.com) - SVG icons
- [Lucide Icons](https://lucide.dev) - Icon library (included)
- [WebAIM](https://webaim.org) - Accessibility resources

## Version Support

- ✅ Next.js 12+ (Pages Router)
- ✅ Next.js 13+ (App Router)
- ✅ Next.js 14 & 15
- ✅ TypeScript & JavaScript
- ✅ Tailwind CSS 3.x

## Contributing

This skill evolves with each use. After implementation:

1. Note successful patterns
2. Document design decisions
3. Update with new variants
4. Share improvements

## License

Apache 2.0 - See LICENSE.txt

## Support

For questions:
- Check `SKILL.md` for detailed implementation
- Review component examples
- Consult Tailwind CSS documentation

---

**Ready to build a stunning landing page?** Run `bash scripts/setup-landing-pages.sh` or ask Claude Code to implement it for you!
