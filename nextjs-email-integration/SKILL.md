---
name: nextjs-email-integration
description: Set up email functionality in Next.js v15 using Resend, including transactional emails, React Email templates, and email verification.
---

# Next.js Email Integration with Resend

You are an expert at implementing email functionality in Next.js v15 applications using Resend and React Email for beautiful, responsive email templates.

## Tech Stack Context
- **Next.js**: v15 with App Router
- **Email Service**: Resend
- **Email Templates**: React Email
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **Validation**: zod
- **Database**: Supabase without RLS
- **Deployment**: OpenNext compiled to Cloudflare Workers

## Core Email Setup

### 1. Install Dependencies

```bash
# Install Resend
npm install resend

# Install React Email
npm install react-email @react-email/components

# Install React Email CLI (optional, for preview)
npm install -D react-email
```

### 2. Configure Resend

```env
# .env.local
RESEND_API_KEY=re_xxxxxxxxxxxxx
RESEND_FROM_EMAIL=noreply@yourdomain.com
```

Create Resend client:
```typescript
// lib/email/resend.ts
import { Resend } from 'resend'

if (!process.env.RESEND_API_KEY) {
  throw new Error('RESEND_API_KEY is not defined')
}

export const resend = new Resend(process.env.RESEND_API_KEY)
```

### 3. Email Templates with React Email

Create email templates directory:
```
emails/
├── welcome.tsx
├── verify-email.tsx
├── reset-password.tsx
├── post-published.tsx
└── components/
    ├── layout.tsx
    └── button.tsx
```

#### Base Email Layout

```typescript
// emails/components/layout.tsx
import {
  Html,
  Head,
  Preview,
  Body,
  Container,
  Section,
  Img,
  Heading,
  Text,
  Hr,
} from '@react-email/components'

interface EmailLayoutProps {
  preview: string
  children: React.ReactNode
}

export function EmailLayout({ preview, children }: EmailLayoutProps) {
  return (
    <Html>
      <Head />
      <Preview>{preview}</Preview>
      <Body style={main}>
        <Container style={container}>
          <Section style={header}>
            <Img
              src="https://yourdomain.com/logo.png"
              width="48"
              height="48"
              alt="Logo"
            />
          </Section>
          {children}
          <Hr style={hr} />
          <Text style={footer}>
            © {new Date().getFullYear()} Your Company. All rights reserved.
          </Text>
        </Container>
      </Body>
    </Html>
  )
}

const main = {
  backgroundColor: '#f6f9fc',
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Ubuntu,sans-serif',
}

const container = {
  backgroundColor: '#ffffff',
  margin: '0 auto',
  padding: '20px 0 48px',
  marginBottom: '64px',
}

const header = {
  padding: '32px',
}

const hr = {
  borderColor: '#e6ebf1',
  margin: '20px 0',
}

const footer = {
  color: '#8898aa',
  fontSize: '12px',
  lineHeight: '16px',
  padding: '0 32px',
}
```

#### Email Button Component

```typescript
// emails/components/button.tsx
import { Button } from '@react-email/components'

interface EmailButtonProps {
  href: string
  children: React.ReactNode
}

export function EmailButton({ href, children }: EmailButtonProps) {
  return (
    <Button
      href={href}
      style={{
        backgroundColor: '#000000',
        borderRadius: '5px',
        color: '#fff',
        fontSize: '16px',
        fontWeight: 'bold',
        textDecoration: 'none',
        textAlign: 'center' as const,
        display: 'inline-block',
        padding: '12px 20px',
      }}
    >
      {children}
    </Button>
  )
}
```

#### Welcome Email Template

```typescript
// emails/welcome.tsx
import { Heading, Text, Section } from '@react-email/components'
import { EmailLayout } from './components/layout'
import { EmailButton } from './components/button'

interface WelcomeEmailProps {
  name: string
  dashboardUrl: string
}

export function WelcomeEmail({ name, dashboardUrl }: WelcomeEmailProps) {
  return (
    <EmailLayout preview="Welcome to our platform!">
      <Section style={{ padding: '0 32px' }}>
        <Heading style={heading}>Welcome, {name}! 👋</Heading>
        <Text style={text}>
          Thanks for signing up! We're excited to have you on board.
        </Text>
        <Text style={text}>
          To get started, click the button below to access your dashboard:
        </Text>
        <EmailButton href={dashboardUrl}>Go to Dashboard</EmailButton>
        <Text style={text}>
          If you have any questions, feel free to reply to this email.
        </Text>
      </Section>
    </EmailLayout>
  )
}

const heading = {
  fontSize: '32px',
  lineHeight: '1.3',
  fontWeight: '700',
  color: '#484848',
}

const text = {
  fontSize: '16px',
  lineHeight: '26px',
  color: '#484848',
}

export default WelcomeEmail
```

#### Email Verification Template

```typescript
// emails/verify-email.tsx
import { Heading, Text, Section, Code } from '@react-email/components'
import { EmailLayout } from './components/layout'
import { EmailButton } from './components/button'

interface VerifyEmailProps {
  name: string
  verificationUrl: string
  verificationCode?: string
}

export function VerifyEmail({ name, verificationUrl, verificationCode }: VerifyEmailProps) {
  return (
    <EmailLayout preview="Verify your email address">
      <Section style={{ padding: '0 32px' }}>
        <Heading style={heading}>Verify your email</Heading>
        <Text style={text}>Hi {name},</Text>
        <Text style={text}>
          Please verify your email address to complete your registration.
        </Text>
        <EmailButton href={verificationUrl}>Verify Email</EmailButton>
        {verificationCode && (
          <>
            <Text style={text}>Or enter this code manually:</Text>
            <Code>{verificationCode}</Code>
          </>
        )}
        <Text style={text}>
          This link will expire in 24 hours. If you didn't create an account,
          you can safely ignore this email.
        </Text>
      </Section>
    </EmailLayout>
  )
}

const heading = {
  fontSize: '32px',
  lineHeight: '1.3',
  fontWeight: '700',
  color: '#484848',
}

const text = {
  fontSize: '16px',
  lineHeight: '26px',
  color: '#484848',
}

export default VerifyEmail
```

#### Password Reset Template

```typescript
// emails/reset-password.tsx
import { Heading, Text, Section } from '@react-email/components'
import { EmailLayout } from './components/layout'
import { EmailButton } from './components/button'

interface ResetPasswordEmailProps {
  name: string
  resetUrl: string
}

export function ResetPasswordEmail({ name, resetUrl }: ResetPasswordEmailProps) {
  return (
    <EmailLayout preview="Reset your password">
      <Section style={{ padding: '0 32px' }}>
        <Heading style={heading}>Reset your password</Heading>
        <Text style={text}>Hi {name},</Text>
        <Text style={text}>
          We received a request to reset your password. Click the button below to
          create a new password:
        </Text>
        <EmailButton href={resetUrl}>Reset Password</EmailButton>
        <Text style={text}>
          This link will expire in 1 hour. If you didn't request a password reset,
          you can safely ignore this email.
        </Text>
      </Section>
    </EmailLayout>
  )
}

const heading = {
  fontSize: '32px',
  lineHeight: '1.3',
  fontWeight: '700',
  color: '#484848',
}

const text = {
  fontSize: '16px',
  lineHeight: '26px',
  color: '#484848',
}

export default ResetPasswordEmail
```

#### Post Published Notification

```typescript
// emails/post-published.tsx
import { Heading, Text, Section, Img } from '@react-email/components'
import { EmailLayout } from './components/layout'
import { EmailButton } from './components/button'

interface PostPublishedEmailProps {
  authorName: string
  postTitle: string
  postExcerpt: string
  postUrl: string
  postImage?: string
}

export function PostPublishedEmail({
  authorName,
  postTitle,
  postExcerpt,
  postUrl,
  postImage,
}: PostPublishedEmailProps) {
  return (
    <EmailLayout preview={`New post: ${postTitle}`}>
      <Section style={{ padding: '0 32px' }}>
        <Heading style={heading}>New post published! 🎉</Heading>
        <Text style={text}>{authorName} just published a new post:</Text>
        {postImage && (
          <Img
            src={postImage}
            alt={postTitle}
            width="600"
            style={{ borderRadius: '8px', marginBottom: '20px' }}
          />
        )}
        <Heading style={postTitle}>{postTitle}</Heading>
        <Text style={text}>{postExcerpt}</Text>
        <EmailButton href={postUrl}>Read Full Post</EmailButton>
      </Section>
    </EmailLayout>
  )
}

const heading = {
  fontSize: '32px',
  lineHeight: '1.3',
  fontWeight: '700',
  color: '#484848',
}

const postTitle = {
  fontSize: '24px',
  lineHeight: '1.4',
  fontWeight: '600',
  color: '#484848',
}

const text = {
  fontSize: '16px',
  lineHeight: '26px',
  color: '#484848',
}

export default PostPublishedEmail
```

### 4. Email Sending Functions

```typescript
// lib/email/send.ts
'use server'

import { resend } from './resend'
import { WelcomeEmail } from '@/emails/welcome'
import { VerifyEmail } from '@/emails/verify-email'
import { ResetPasswordEmail } from '@/emails/reset-password'
import { PostPublishedEmail } from '@/emails/post-published'

const fromEmail = process.env.RESEND_FROM_EMAIL || 'noreply@yourdomain.com'

export async function sendWelcomeEmail(to: string, name: string) {
  try {
    const { data, error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: 'Welcome to our platform!',
      react: WelcomeEmail({
        name,
        dashboardUrl: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard`,
      }),
    })

    if (error) {
      console.error('Failed to send welcome email:', error)
      return { error: error.message }
    }

    return { data }
  } catch (error) {
    console.error('Failed to send welcome email:', error)
    return { error: 'Failed to send email' }
  }
}

export async function sendVerificationEmail(
  to: string,
  name: string,
  verificationToken: string
) {
  try {
    const verificationUrl = `${process.env.NEXT_PUBLIC_APP_URL}/auth/verify?token=${verificationToken}`

    const { data, error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: 'Verify your email address',
      react: VerifyEmail({
        name,
        verificationUrl,
      }),
    })

    if (error) {
      console.error('Failed to send verification email:', error)
      return { error: error.message }
    }

    return { data }
  } catch (error) {
    console.error('Failed to send verification email:', error)
    return { error: 'Failed to send email' }
  }
}

export async function sendPasswordResetEmail(
  to: string,
  name: string,
  resetToken: string
) {
  try {
    const resetUrl = `${process.env.NEXT_PUBLIC_APP_URL}/auth/reset-password?token=${resetToken}`

    const { data, error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: 'Reset your password',
      react: ResetPasswordEmail({
        name,
        resetUrl,
      }),
    })

    if (error) {
      console.error('Failed to send password reset email:', error)
      return { error: error.message }
    }

    return { data }
  } catch (error) {
    console.error('Failed to send password reset email:', error)
    return { error: 'Failed to send email' }
  }
}

export async function sendPostPublishedEmail(
  to: string,
  postData: {
    authorName: string
    postTitle: string
    postExcerpt: string
    postUrl: string
    postImage?: string
  }
) {
  try {
    const { data, error } = await resend.emails.send({
      from: fromEmail,
      to,
      subject: `New post: ${postData.postTitle}`,
      react: PostPublishedEmail(postData),
    })

    if (error) {
      console.error('Failed to send post published email:', error)
      return { error: error.message }
    }

    return { data }
  } catch (error) {
    console.error('Failed to send post published email:', error)
    return { error: 'Failed to send email' }
  }
}

// Batch email sending
export async function sendBatchEmails(
  emails: Array<{
    to: string
    subject: string
    react: React.ReactElement
  }>
) {
  try {
    const { data, error } = await resend.batch.send(
      emails.map((email) => ({
        from: fromEmail,
        ...email,
      }))
    )

    if (error) {
      console.error('Failed to send batch emails:', error)
      return { error: error.message }
    }

    return { data }
  } catch (error) {
    console.error('Failed to send batch emails:', error)
    return { error: 'Failed to send emails' }
  }
}
```

### 5. Integration with Authentication

Update your signup action to send welcome email:

```typescript
// app/actions/auth.ts
'use server'

import { createClient } from '@/lib/supabase/server'
import { sendWelcomeEmail } from '@/lib/email/send'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

export async function signUp(formData: FormData) {
  const supabase = await createClient()

  const email = formData.get('email') as string
  const password = formData.get('password') as string
  const name = formData.get('name') as string

  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        name,
      },
    },
  })

  if (error) {
    return { error: error.message }
  }

  // Send welcome email asynchronously
  await sendWelcomeEmail(email, name)

  revalidatePath('/', 'layout')
  redirect('/dashboard')
}
```

### 6. Email Preview Server

Add script to package.json:
```json
{
  "scripts": {
    "email:dev": "email dev"
  }
}
```

Run preview server:
```bash
npm run email:dev
```

This opens a preview at `http://localhost:3000` where you can view all your email templates.

### 7. Email Queue (Optional)

For better reliability, implement an email queue:

```typescript
// lib/email/queue.ts
'use server'

import { createClient } from '@/lib/supabase/server'

interface EmailJob {
  to: string
  subject: string
  template: string
  data: Record<string, any>
}

export async function queueEmail(job: EmailJob) {
  const supabase = await createClient()

  const { error } = await supabase.from('email_queue').insert({
    to: job.to,
    subject: job.subject,
    template: job.template,
    data: job.data,
    status: 'pending',
    attempts: 0,
  })

  if (error) {
    throw new Error(`Failed to queue email: ${error.message}`)
  }
}

// Process email queue (run via cron job or worker)
export async function processEmailQueue() {
  const supabase = await createClient()

  const { data: jobs, error } = await supabase
    .from('email_queue')
    .select('*')
    .eq('status', 'pending')
    .lt('attempts', 3)
    .limit(10)

  if (error || !jobs) {
    console.error('Failed to fetch email queue:', error)
    return
  }

  for (const job of jobs) {
    try {
      // Send email based on template
      // Update status to 'sent'
      await supabase
        .from('email_queue')
        .update({ status: 'sent', sent_at: new Date().toISOString() })
        .eq('id', job.id)
    } catch (error) {
      // Increment attempts
      await supabase
        .from('email_queue')
        .update({ attempts: job.attempts + 1 })
        .eq('id', job.id)
    }
  }
}
```

Create email_queue table:
```sql
CREATE TABLE email_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  to TEXT NOT NULL,
  subject TEXT NOT NULL,
  template TEXT NOT NULL,
  data JSONB NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  attempts INT DEFAULT 0,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_email_queue_status ON email_queue(status);
```

### 8. Email Tracking (Optional)

Track email opens and clicks:

```typescript
// app/api/email/track/[id]/route.ts
import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  const supabase = await createClient()

  // Record email open
  await supabase
    .from('email_tracking')
    .update({ opened_at: new Date().toISOString() })
    .eq('id', params.id)

  // Return 1x1 transparent pixel
  return new NextResponse(
    Buffer.from(
      'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
      'base64'
    ),
    {
      headers: {
        'Content-Type': 'image/gif',
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      },
    }
  )
}
```

## Best Practices

### 1. Email Design
- Keep it simple and focused
- Use responsive design
- Include plain text alternative
- Test across email clients
- Optimize images

### 2. Deliverability
- Use verified domain
- Include unsubscribe link
- Avoid spam trigger words
- Keep email size under 100KB
- Maintain good sender reputation

### 3. Performance
- Send emails asynchronously
- Use email queues for reliability
- Implement retry logic
- Monitor bounce rates
- Track delivery metrics

### 4. Security
- Validate email addresses
- Rate limit email sending
- Use environment variables for API keys
- Implement email verification
- Protect against abuse

### 5. User Experience
- Set clear expectations
- Provide actionable content
- Include relevant links
- Make it easy to unsubscribe
- Send at appropriate times

## Common Patterns

### Contact Form Email

```typescript
export async function sendContactFormEmail(data: {
  name: string
  email: string
  message: string
}) {
  return resend.emails.send({
    from: fromEmail,
    to: 'support@yourdomain.com',
    replyTo: data.email,
    subject: `Contact Form: ${data.name}`,
    text: `From: ${data.name} (${data.email})\n\n${data.message}`,
  })
}
```

### Weekly Digest Email

```typescript
export async function sendWeeklyDigest(
  to: string,
  posts: Array<{ title: string; url: string }>
) {
  return resend.emails.send({
    from: fromEmail,
    to,
    subject: 'Your Weekly Digest',
    react: WeeklyDigestEmail({ posts }),
  })
}
```

## Testing

```typescript
// __tests__/email/send.test.ts
import { sendWelcomeEmail } from '@/lib/email/send'

jest.mock('@/lib/email/resend', () => ({
  resend: {
    emails: {
      send: jest.fn().mockResolvedValue({
        data: { id: 'test-email-id' },
        error: null,
      }),
    },
  },
}))

describe('sendWelcomeEmail', () => {
  it('should send welcome email successfully', async () => {
    const result = await sendWelcomeEmail('test@example.com', 'Test User')
    expect(result.data).toBeDefined()
    expect(result.error).toBeUndefined()
  })
})
```

## Follow-up Tasks

- Set up custom domain in Resend
- Add email templates for all user actions
- Implement email preferences/unsubscribe
- Add email analytics dashboard
- Set up email monitoring and alerting
- Implement A/B testing for emails
- Add multilingual email support
