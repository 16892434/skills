# Complete Stripe Setup Guide

Step-by-step guide for configuring your Stripe account for subscriptions.

---

## Table of Contents

1. [Account Setup](#account-setup)
2. [Creating Products](#creating-products)
3. [Webhook Configuration](#webhook-configuration)
4. [Testing Setup](#testing-setup)
5. [Production Checklist](#production-checklist)

---

## Account Setup

### 1. Create Stripe Account

1. Go to [stripe.com/register](https://stripe.com/register)
2. Enter your email and create a password
3. Verify your email address
4. Complete your business profile

### 2. Activate Your Account

For test mode, no activation needed. For production:

1. Navigate to **Settings** → **Account details**
2. Click **Activate your account**
3. Provide:
   - Business information
   - Bank account details
   - Tax information (if applicable)
   - Identity verification

**Note:** You can start development in test mode while activation is pending.

### 3. Get Your API Keys

**Test Mode:**
1. Dashboard → **Developers** → **API keys**
2. Note that test mode toggle is ON
3. Copy your **Publishable key** (starts with `pk_test_`)
4. Reveal and copy your **Secret key** (starts with `sk_test_`)

**Live Mode:**
1. Toggle to "Live mode" in the dashboard
2. Go to **Developers** → **API keys**
3. Copy your **Publishable key** (starts with `pk_live_`)
4. Reveal and copy your **Secret key** (starts with `sk_live_`)

⚠️ **Security:** Never commit API keys to version control!

---

## Creating Products

### Option 1: Via Dashboard (Recommended for Beginners)

#### Create Your First Product

1. Navigate to **Products** in the dashboard
2. Click **Add product**

#### Configure Product Details

**Product Information:**
- **Name**: "Starter Plan" (or your tier name)
- **Description**: Brief description of what's included
- **Image**: Optional product image

**Pricing:**
- **Pricing model**: Choose "Standard pricing"
- **Price**: Enter amount (e.g., 9.00)
- **Billing period**: Select "Monthly"
- **Currency**: USD (or your currency)

#### Advanced Options

Click **Show more options** to configure:

- **Trial period**: Set trial days (e.g., 14 days)
- **Tax behavior**: Choose tax treatment
- **Metered billing**: Enable for usage-based billing

#### Save the Product

1. Click **Add product**
2. Copy the **Price ID** (starts with `price_`)
3. Save this ID to your `.env.local`

#### Create Multiple Tiers

Repeat the process for each pricing tier:
- Starter: $9/month
- Pro: $29/month
- Enterprise: $99/month

### Option 2: Via API (Recommended for Automation)

Use the provided script:

```bash
# Install dependencies
npm install --save-dev tsx

# Create products
npx tsx scripts/create-products.ts
```

This will:
1. Create all your products
2. Create monthly and yearly prices
3. Display Price IDs to add to your environment

### Option 3: Via Stripe CLI

```bash
# Create a product
stripe products create \
  --name="Starter Plan" \
  --description="Perfect for individuals"

# Create a price for the product
stripe prices create \
  --product=prod_xxxxxxxxxxxxx \
  --unit-amount=900 \
  --currency=usd \
  --recurring[interval]=month
```

---

## Webhook Configuration

Webhooks notify your application of events happening in Stripe.

### Development Webhooks (Stripe CLI)

#### Install Stripe CLI

**macOS:**
```bash
brew install stripe/stripe-cli/stripe
```

**Linux:**
```bash
# Download the latest linux tar.gz file from:
# https://github.com/stripe/stripe-cli/releases/latest
tar -xvf stripe_X.X.X_linux_x86_64.tar.gz
sudo mv stripe /usr/local/bin
```

**Windows:**
Download from [GitHub releases](https://github.com/stripe/stripe-cli/releases/latest)

#### Login to Stripe

```bash
stripe login
```

This opens a browser to authorize the CLI.

#### Forward Webhooks to Local Server

```bash
stripe listen --forward-to localhost:3000/api/stripe/webhook
```

You'll see output like:
```
> Ready! Your webhook signing secret is whsec_xxx...
```

Copy the webhook secret and add to `.env.local`:
```env
STRIPE_WEBHOOK_SECRET=whsec_xxx...
```

#### Keep It Running

Keep this terminal window open while developing. The CLI will:
- Forward all webhook events to your local server
- Show real-time event logs
- Help you test webhook handling

### Production Webhooks

#### Create Webhook Endpoint

1. Navigate to **Developers** → **Webhooks**
2. Click **Add endpoint**

#### Configure Endpoint

**Endpoint URL:**
```
https://yourdomain.com/api/stripe/webhook
```

**Description:** "Production webhook endpoint"

**Events to Send:**

Select these events (at minimum):

**Checkout:**
- `checkout.session.completed`
- `checkout.session.expired`

**Subscriptions:**
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `customer.subscription.trial_will_end`

**Invoices:**
- `invoice.created`
- `invoice.finalized`
- `invoice.payment_succeeded`
- `invoice.payment_failed`
- `invoice.upcoming`

**Payments:**
- `payment_intent.succeeded`
- `payment_intent.payment_failed`

**Optional (for advanced features):**
- `customer.created`
- `customer.updated`
- `charge.succeeded`
- `charge.failed`
- `charge.refunded`

#### Get Webhook Secret

1. After creating the endpoint, click on it
2. Click **Reveal** under "Signing secret"
3. Copy the secret (starts with `whsec_`)
4. Add to your production environment variables

#### Test the Webhook

1. In the webhook details page, click **Send test webhook**
2. Select an event type (e.g., `checkout.session.completed`)
3. Click **Send test webhook**
4. Check your application logs to verify receipt

---

## Testing Setup

### Test Cards

Use these test card numbers in test mode:

| Card Number | Scenario |
|------------|----------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0000 0000 0002` | Card declined |
| `4000 0000 0000 9995` | Insufficient funds |
| `4000 0000 0000 3220` | 3D Secure required |
| `4000 0025 0000 3155` | 3D Secure required (authentication required) |

**Other details:**
- **Expiration**: Any future date
- **CVC**: Any 3 digits
- **ZIP**: Any valid ZIP code

### Testing Scenarios

#### 1. Successful Subscription

1. Navigate to your pricing page
2. Click "Subscribe" on any plan
3. Use card `4242 4242 4242 4242`
4. Complete checkout
5. Verify:
   - User redirected to success page
   - Database updated with subscription
   - Webhook event received

#### 2. Failed Payment

1. Start checkout flow
2. Use card `4000 0000 0000 0002`
3. Verify:
   - Error message displayed
   - No subscription created
   - User can retry

#### 3. 3D Secure Authentication

1. Start checkout flow
2. Use card `4000 0025 0000 3155`
3. Complete 3D Secure challenge
4. Verify successful subscription

#### 4. Subscription Upgrade

1. Subscribe to Starter plan
2. Upgrade to Pro plan
3. Verify:
   - Proration calculated
   - Subscription updated
   - Database reflects new plan

#### 5. Subscription Cancellation

1. Open customer portal
2. Cancel subscription
3. Verify:
   - Subscription marked for cancellation
   - Access continues until period end
   - Database updated

### Testing Webhooks

#### Using Stripe CLI

Trigger specific events:

```bash
# Successful payment
stripe trigger checkout.session.completed

# Failed payment
stripe trigger invoice.payment_failed

# Subscription created
stripe trigger customer.subscription.created
```

#### Using Dashboard

1. Go to **Developers** → **Webhooks**
2. Select your endpoint
3. Click **Send test webhook**
4. Choose event type and send

### Monitoring Test Events

**Via Dashboard:**
1. Go to **Developers** → **Events**
2. Filter by event type
3. Click on an event to see details
4. Check webhook delivery status

**Via CLI:**
```bash
# View recent events
stripe events list

# View specific event
stripe events retrieve evt_xxx
```

---

## Production Checklist

Before going live with Stripe:

### Account Configuration

- [ ] Complete Stripe account activation
- [ ] Add business information
- [ ] Verify bank account
- [ ] Configure payout schedule
- [ ] Set up tax settings (if applicable)

### Product Setup

- [ ] Create all products in live mode
- [ ] Set correct pricing
- [ ] Configure trial periods
- [ ] Set up coupons/promotions (if needed)
- [ ] Test products in live mode

### API Keys

- [ ] Generate live API keys
- [ ] Update production environment variables
- [ ] Remove all test mode keys from production
- [ ] Secure keys (use environment variables, never hardcode)

### Webhooks

- [ ] Create production webhook endpoint
- [ ] Configure all necessary events
- [ ] Set webhook secret in production environment
- [ ] Test webhook endpoint (send test events)
- [ ] Monitor webhook delivery in dashboard

### Security

- [ ] Enable HTTPS on production domain
- [ ] Verify webhook signatures in code
- [ ] Implement rate limiting
- [ ] Add request validation
- [ ] Set up error monitoring (Sentry, etc.)

### User Experience

- [ ] Test complete checkout flow
- [ ] Verify email receipts are sent
- [ ] Test customer portal access
- [ ] Verify subscription management works
- [ ] Test edge cases (cancellation, upgrades, etc.)

### Compliance

- [ ] Add terms of service
- [ ] Add privacy policy
- [ ] Add refund policy
- [ ] Ensure SCA (3D Secure) compliance for EU
- [ ] Configure tax collection (Stripe Tax)
- [ ] Set up invoice numbering

### Monitoring

- [ ] Set up Stripe webhook monitoring
- [ ] Configure failed payment alerts
- [ ] Monitor subscription churn
- [ ] Track MRR (Monthly Recurring Revenue)
- [ ] Set up anomaly detection

### Documentation

- [ ] Document subscription tiers
- [ ] Create internal runbook for common issues
- [ ] Document webhook event handling
- [ ] Create customer support resources

---

## Common Configuration Issues

### Issue: Webhook signatures failing

**Solution:**
1. Verify webhook secret is correct
2. Check you're using the right secret for environment (test vs live)
3. Ensure raw request body is used for verification
4. Check for body parsing middleware interfering

### Issue: Customers created multiple times

**Solution:**
Always check for existing customer before creating:
```typescript
const existingCustomers = await stripe.customers.list({
  email: userEmail,
  limit: 1,
})

const customer = existingCustomers.data[0] || await stripe.customers.create({
  email: userEmail,
})
```

### Issue: Prices not appearing

**Solution:**
1. Ensure products are active
2. Verify prices are in correct mode (test/live)
3. Check currency matches your account
4. Confirm price IDs in environment variables

### Issue: Test mode vs Live mode confusion

**Solution:**
- Always check mode indicator in dashboard
- Use different API keys for test and live
- Test thoroughly in test mode first
- Never use test cards in live mode

---

## Resources

- [Stripe Dashboard](https://dashboard.stripe.com)
- [Stripe API Documentation](https://stripe.com/docs/api)
- [Stripe CLI Documentation](https://stripe.com/docs/stripe-cli)
- [Webhook Testing Guide](https://stripe.com/docs/webhooks/test)
- [SCA/3D Secure](https://stripe.com/docs/strong-customer-authentication)
- [Stripe Support](https://support.stripe.com)

---

## Getting Help

If you encounter issues:

1. **Check Stripe logs**: Dashboard → Developers → Logs
2. **Review webhook events**: Dashboard → Developers → Events
3. **Read error messages**: Stripe provides detailed error info
4. **Search Stripe docs**: Most issues are documented
5. **Contact Stripe support**: Available for all accounts

---

Last updated: 2025-01
