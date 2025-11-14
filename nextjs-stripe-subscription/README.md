# Next.js Stripe Subscription Skill

A comprehensive skill for implementing Stripe subscription payments in Next.js projects.

## Features

- ✅ **Complete Checkout Flow**: Stripe Checkout integration for subscriptions
- ✅ **Webhook Handling**: Production-ready webhook event processing
- ✅ **Subscription Management**: Full lifecycle management (create, update, cancel)
- ✅ **Customer Portal**: Self-service subscription management
- ✅ **Multiple Pricing Tiers**: Support for different subscription levels
- ✅ **Invoice Management**: Track and store customer invoices
- ✅ **TypeScript Support**: Full type safety throughout
- ✅ **Both Router Types**: App Router and Pages Router support
- ✅ **Database Integration**: Prisma schemas included
- ✅ **Test Mode Support**: Easy local development with Stripe CLI

## Quick Start

### Automated Setup

Run the setup script in your Next.js project:

```bash
bash scripts/setup-stripe.sh
```

This will:
1. Install Stripe dependencies
2. Create Stripe client configurations
3. Generate API route handlers
4. Set up environment variables template
5. Create TypeScript type definitions

### Manual Usage with Claude Code

Simply ask:

```
"Set up Stripe subscriptions with monthly and yearly pricing tiers"
```

Claude will follow the comprehensive guide in `SKILL.md` to implement the complete subscription system.

## What's Included

### Core Files

- **SKILL.md**: Complete 12-phase implementation guide
- **scripts/setup-stripe.sh**: Automated setup script
- **templates/**:
  - `create-products.ts`: Script to create Stripe products via API
  - `subscription-helpers.ts`: Utility functions for subscription management
- **components/**:
  - `pricing-table.tsx`: Production-ready pricing page
- **reference/**:
  - `stripe-setup-guide.md`: Detailed Stripe dashboard configuration

### What Gets Created

When you run the setup or use the skill, you'll get:

1. **API Routes**:
   - `/api/stripe/create-checkout-session` - Create subscription checkout
   - `/api/stripe/create-portal-session` - Customer portal access
   - `/api/stripe/webhook` - Webhook event handler

2. **Stripe Clients**:
   - `lib/stripe.ts` - Server-side Stripe client
   - `lib/stripe-client.ts` - Client-side Stripe loader

3. **Helper Functions**:
   - `getUserSubscription()` - Get user's subscription status
   - `checkSubscription()` - Verify active subscription
   - `cancelSubscription()` - Cancel at period end
   - `updateSubscriptionPlan()` - Change pricing tiers
   - And more...

4. **UI Components**:
   - Professional pricing table
   - Subscribe buttons
   - Manage subscription button
   - Loading states

5. **Database Schema**:
   - Prisma schema for storing subscription data
   - Invoice tracking
   - Customer relationships

## Implementation Phases

The skill guides you through:

1. **Project Analysis** - Detect router type and stack
2. **Stripe Account Setup** - Configure Stripe dashboard
3. **Installation** - Install dependencies
4. **Database Schema** - Add Stripe fields to your schema
5. **Stripe Clients** - Set up server and client Stripe instances
6. **Checkout Flow** - Implement subscription creation
7. **Webhook Handling** - Process Stripe events
8. **Customer Portal** - Self-service management
9. **Subscription Status** - Check and validate subscriptions
10. **Pricing Page** - Build pricing UI
11. **Testing** - Test with Stripe test cards
12. **Production Deployment** - Go live checklist

## Supported Features

### Subscription Types

- Recurring monthly billing
- Recurring yearly billing
- Multiple pricing tiers
- Free trials
- Usage-based billing (metered)

### Payment Features

- Credit card payments
- 3D Secure (SCA compliance)
- Automatic invoice generation
- Failed payment handling
- Payment method updates

### Customer Features

- Self-service portal
- Subscription upgrades/downgrades
- Cancellation (at period end)
- Invoice history
- Payment method management

## Prerequisites

- Next.js 12+ (Pages Router) or Next.js 13+ (App Router)
- Node.js 18+
- Authentication system (or use `nextjs-auth-setup` skill)
- Database (Prisma recommended)
- Stripe account

## Environment Variables

Required environment variables:

```env
# Stripe keys
STRIPE_SECRET_KEY=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Price IDs
NEXT_PUBLIC_STRIPE_PRICE_STARTER=price_...
NEXT_PUBLIC_STRIPE_PRICE_PRO=price_...
NEXT_PUBLIC_STRIPE_PRICE_ENTERPRISE=price_...

# App URL
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## Testing

### Test Cards

Use these in Stripe test mode:

| Card | Result |
|------|--------|
| `4242 4242 4242 4242` | Success |
| `4000 0000 0000 0002` | Decline |
| `4000 0025 0000 3155` | 3D Secure required |

### Local Webhook Testing

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Forward webhooks to local server
stripe listen --forward-to localhost:3000/api/stripe/webhook
```

## Production Checklist

Before going live:

- [ ] Switch to live Stripe API keys
- [ ] Create products in live mode
- [ ] Configure production webhook endpoint
- [ ] Test complete flow in production
- [ ] Enable 3D Secure
- [ ] Set up tax collection (if applicable)
- [ ] Configure email receipts
- [ ] Test failed payment handling

## Common Use Cases

1. **SaaS Subscriptions**: Monthly/yearly billing for software
2. **Membership Sites**: Tiered access levels
3. **API Products**: Usage-based or tier-based pricing
4. **Content Platforms**: Subscription access to premium content
5. **E-learning**: Course subscriptions

## Advanced Features

The skill includes guidance for:

- **Usage-based billing**: Meter API calls, storage, etc.
- **Prorations**: Automatic when changing plans
- **Coupons**: Discount codes
- **Trial periods**: Free trials
- **Add-ons**: Additional features
- **Multiple subscriptions**: Per-user multi-subscription

## Documentation Structure

```
nextjs-stripe-subscription/
├── SKILL.md                           # Main implementation guide
├── README.md
├── LICENSE.txt
├── scripts/
│   └── setup-stripe.sh               # Automated setup
├── templates/
│   ├── create-products.ts            # Product creation script
│   └── subscription-helpers.ts       # Utility functions
├── components/
│   └── pricing-table.tsx             # Pricing page component
└── reference/
    └── stripe-setup-guide.md         # Stripe configuration guide
```

## Best Practices

The skill enforces:

### Security
- Webhook signature verification
- HTTPS in production
- Secure API key storage
- Idempotent event handling

### Performance
- Subscription status caching
- Efficient database queries
- Webhook-driven updates (not polling)

### User Experience
- Clear pricing display
- Easy cancellation
- Loading states
- Error handling
- Email notifications

## Troubleshooting

Common issues covered in the skill:

- Webhook events not received
- Customer created multiple times
- Subscription status out of sync
- Payment failures
- 3D Secure challenges
- Proration calculations

See `SKILL.md` for detailed solutions.

## Integration with Other Skills

Works well with:

- `nextjs-auth-setup` - User authentication
- `nextjs-dashboard-scaffold` - Dashboard UI
- `nextjs-email-integration` - Send receipts and notifications

## Resources

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe API Reference](https://stripe.com/docs/api)
- [Next.js Stripe Example](https://github.com/vercel/next.js/tree/canary/examples/with-stripe-typescript)
- [Stripe Testing Guide](https://stripe.com/docs/testing)

## Version Support

- ✅ Stripe API version: 2024-11-20.acacia
- ✅ Next.js 12+ (Pages Router)
- ✅ Next.js 13+ (App Router)
- ✅ TypeScript & JavaScript

## Contributing

This skill is designed to evolve. After each implementation:

1. Note successful patterns
2. Document edge cases encountered
3. Update skill with improvements
4. Share optimizations

## License

Apache 2.0 - See LICENSE.txt

## Support

For Stripe-specific issues:
- Check `SKILL.md` for implementation details
- Review `reference/stripe-setup-guide.md` for configuration
- Consult [Stripe Documentation](https://stripe.com/docs)
- Contact [Stripe Support](https://support.stripe.com)

---

**Ready to add subscriptions to your Next.js app?** Start with `bash scripts/setup-stripe.sh` or ask Claude Code to implement it for you!
