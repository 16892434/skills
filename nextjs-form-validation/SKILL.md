---
name: nextjs-form-validation
description: Implement robust form validation in Next.js v15 using zod schemas with shadcn/ui form components and Server Actions.
---

# Next.js Form Validation with Zod

You are an expert at implementing form validation in Next.js v15 applications using zod schemas, shadcn/ui forms, and Server Actions.

## Tech Stack Context
- **Next.js**: v15 with App Router
- **Validation**: zod for schema validation
- **Forms**: shadcn/ui form components with react-hook-form
- **UI Components**: shadcn/ui
- **Styling**: Tailwind CSS v4
- **State Management**: zustand
- **Database**: Supabase without RLS
- **Deployment**: OpenNext compiled to Cloudflare Workers

## Core Form Validation Setup

### 1. Install Dependencies

```bash
# Install required packages
npm install zod react-hook-form @hookform/resolvers

# Install shadcn form components
npx shadcn@latest add form input label button textarea select checkbox radio-group
```

### 2. Zod Schema Patterns

Create reusable validation schemas:

```typescript
// lib/validations/auth.ts
import { z } from 'zod'

export const signUpSchema = z.object({
  email: z
    .string()
    .min(1, 'Email is required')
    .email('Invalid email address'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(100, 'Password must be less than 100 characters')
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      'Password must contain at least one uppercase letter, one lowercase letter, and one number'
    ),
  confirmPassword: z.string(),
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(50, 'Name must be less than 50 characters'),
  terms: z
    .boolean()
    .refine((val) => val === true, 'You must accept the terms and conditions'),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
})

export const signInSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
})

export const resetPasswordSchema = z.object({
  email: z.string().email('Invalid email address'),
})

export const updatePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      'Password must contain uppercase, lowercase, and number'
    ),
  confirmNewPassword: z.string(),
}).refine((data) => data.newPassword === data.confirmNewPassword, {
  message: "Passwords don't match",
  path: ['confirmNewPassword'],
})

export type SignUpInput = z.infer<typeof signUpSchema>
export type SignInInput = z.infer<typeof signInSchema>
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>
export type UpdatePasswordInput = z.infer<typeof updatePasswordSchema>
```

```typescript
// lib/validations/post.ts
import { z } from 'zod'

export const createPostSchema = z.object({
  title: z
    .string()
    .min(1, 'Title is required')
    .max(200, 'Title must be less than 200 characters'),
  content: z
    .string()
    .max(10000, 'Content must be less than 10000 characters')
    .optional(),
  status: z.enum(['draft', 'published', 'archived']).default('draft'),
  tags: z.array(z.string()).max(5, 'Maximum 5 tags allowed').optional(),
  coverImage: z
    .string()
    .url('Invalid URL')
    .optional()
    .or(z.literal('')),
})

export const updatePostSchema = createPostSchema.partial()

export const commentSchema = z.object({
  postId: z.string().uuid('Invalid post ID'),
  content: z
    .string()
    .min(1, 'Comment cannot be empty')
    .max(1000, 'Comment must be less than 1000 characters'),
})

export type CreatePostInput = z.infer<typeof createPostSchema>
export type UpdatePostInput = z.infer<typeof updatePostSchema>
export type CommentInput = z.infer<typeof commentSchema>
```

```typescript
// lib/validations/profile.ts
import { z } from 'zod'

export const updateProfileSchema = z.object({
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(50, 'Name must be less than 50 characters'),
  bio: z
    .string()
    .max(500, 'Bio must be less than 500 characters')
    .optional(),
  website: z
    .string()
    .url('Invalid URL')
    .optional()
    .or(z.literal('')),
  location: z.string().max(100).optional(),
  avatar: z
    .instanceof(File)
    .refine((file) => file.size <= 5 * 1024 * 1024, 'File must be less than 5MB')
    .refine(
      (file) => ['image/jpeg', 'image/png', 'image/webp'].includes(file.type),
      'File must be a JPEG, PNG, or WebP image'
    )
    .optional(),
})

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>
```

### 3. Server Actions with Validation

```typescript
// app/actions/posts.ts
'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { getCurrentUser } from '@/lib/auth/get-user'
import { createPostSchema, updatePostSchema } from '@/lib/validations/post'
import type { CreatePostInput, UpdatePostInput } from '@/lib/validations/post'

export async function createPostAction(data: CreatePostInput) {
  const user = await getCurrentUser()
  if (!user) {
    return { error: 'Unauthorized' }
  }

  // Validate input
  const result = createPostSchema.safeParse(data)
  if (!result.success) {
    return {
      error: 'Validation failed',
      fieldErrors: result.error.flatten().fieldErrors,
    }
  }

  const supabase = await createClient()

  const { data: post, error } = await supabase
    .from('posts')
    .insert({
      user_id: user.id,
      ...result.data,
    })
    .select()
    .single()

  if (error) {
    return { error: error.message }
  }

  revalidatePath('/dashboard/posts')
  redirect(`/dashboard/posts/${post.id}`)
}

export async function updatePostAction(postId: string, data: UpdatePostInput) {
  const user = await getCurrentUser()
  if (!user) {
    return { error: 'Unauthorized' }
  }

  // Validate input
  const result = updatePostSchema.safeParse(data)
  if (!result.success) {
    return {
      error: 'Validation failed',
      fieldErrors: result.error.flatten().fieldErrors,
    }
  }

  const supabase = await createClient()

  // Check ownership
  const { data: existingPost } = await supabase
    .from('posts')
    .select('user_id')
    .eq('id', postId)
    .single()

  if (!existingPost || existingPost.user_id !== user.id) {
    return { error: 'Forbidden' }
  }

  const { error } = await supabase
    .from('posts')
    .update(result.data)
    .eq('id', postId)

  if (error) {
    return { error: error.message }
  }

  revalidatePath('/dashboard/posts')
  revalidatePath(`/dashboard/posts/${postId}`)
  return { success: true }
}
```

### 4. Form Components with shadcn/ui

```typescript
// components/forms/create-post-form.tsx
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useRouter } from 'next/navigation'
import { createPostSchema, type CreatePostInput } from '@/lib/validations/post'
import { createPostAction } from '@/app/actions/posts'
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { toast } from 'sonner'

export function CreatePostForm() {
  const router = useRouter()

  const form = useForm<CreatePostInput>({
    resolver: zodResolver(createPostSchema),
    defaultValues: {
      title: '',
      content: '',
      status: 'draft',
      tags: [],
      coverImage: '',
    },
  })

  async function onSubmit(data: CreatePostInput) {
    const result = await createPostAction(data)

    if (result?.error) {
      if (result.fieldErrors) {
        // Set individual field errors
        Object.entries(result.fieldErrors).forEach(([field, errors]) => {
          form.setError(field as keyof CreatePostInput, {
            message: errors?.[0],
          })
        })
      } else {
        toast.error(result.error)
      }
      return
    }

    toast.success('Post created successfully')
    // Redirect happens in server action
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        <FormField
          control={form.control}
          name="title"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Title</FormLabel>
              <FormControl>
                <Input placeholder="Enter post title" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="content"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Content</FormLabel>
              <FormControl>
                <Textarea
                  placeholder="Write your post content..."
                  className="min-h-[200px]"
                  {...field}
                />
              </FormControl>
              <FormDescription>
                Write your post content in markdown format
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="status"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Status</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="draft">Draft</SelectItem>
                  <SelectItem value="published">Published</SelectItem>
                  <SelectItem value="archived">Archived</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="coverImage"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Cover Image URL</FormLabel>
              <FormControl>
                <Input
                  type="url"
                  placeholder="https://example.com/image.jpg"
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="flex gap-4">
          <Button type="submit" disabled={form.formState.isSubmitting}>
            {form.formState.isSubmitting ? 'Creating...' : 'Create Post'}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => router.back()}
          >
            Cancel
          </Button>
        </div>
      </form>
    </Form>
  )
}
```

### 5. Advanced Form Patterns

#### Multi-step Form with Validation

```typescript
// components/forms/multi-step-form.tsx
'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'

// Step 1 schema
const step1Schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})

// Step 2 schema
const step2Schema = z.object({
  name: z.string().min(2),
  bio: z.string().max(500).optional(),
})

// Step 3 schema
const step3Schema = z.object({
  interests: z.array(z.string()).min(1, 'Select at least one interest'),
})

// Combined schema
const completeSchema = step1Schema.merge(step2Schema).merge(step3Schema)

type FormData = z.infer<typeof completeSchema>

export function MultiStepForm() {
  const [step, setStep] = useState(1)
  const totalSteps = 3

  const form = useForm<FormData>({
    resolver: zodResolver(
      step === 1 ? step1Schema : step === 2 ? step2Schema : step3Schema
    ),
    mode: 'onChange',
  })

  async function onSubmit(data: FormData) {
    if (step < totalSteps) {
      setStep(step + 1)
      return
    }

    // Final submission
    console.log('Complete form data:', data)
  }

  const progress = (step / totalSteps) * 100

  return (
    <div className="space-y-6">
      <Progress value={progress} />

      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        {step === 1 && <Step1Fields form={form} />}
        {step === 2 && <Step2Fields form={form} />}
        {step === 3 && <Step3Fields form={form} />}

        <div className="flex gap-4">
          {step > 1 && (
            <Button type="button" variant="outline" onClick={() => setStep(step - 1)}>
              Back
            </Button>
          )}
          <Button type="submit">
            {step === totalSteps ? 'Submit' : 'Next'}
          </Button>
        </div>
      </form>
    </div>
  )
}
```

#### Dynamic Field Arrays

```typescript
// components/forms/dynamic-array-form.tsx
'use client'

import { useFieldArray, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { X, Plus } from 'lucide-react'

const formSchema = z.object({
  links: z.array(
    z.object({
      title: z.string().min(1, 'Title is required'),
      url: z.string().url('Invalid URL'),
    })
  ).min(1, 'Add at least one link'),
})

type FormData = z.infer<typeof formSchema>

export function DynamicArrayForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      links: [{ title: '', url: '' }],
    },
  })

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: 'links',
  })

  return (
    <form onSubmit={form.handleSubmit((data) => console.log(data))}>
      <div className="space-y-4">
        {fields.map((field, index) => (
          <div key={field.id} className="flex gap-4 items-start">
            <div className="flex-1 space-y-2">
              <Input
                {...form.register(`links.${index}.title`)}
                placeholder="Title"
              />
              {form.formState.errors.links?.[index]?.title && (
                <p className="text-sm text-destructive">
                  {form.formState.errors.links[index]?.title?.message}
                </p>
              )}

              <Input
                {...form.register(`links.${index}.url`)}
                placeholder="https://example.com"
              />
              {form.formState.errors.links?.[index]?.url && (
                <p className="text-sm text-destructive">
                  {form.formState.errors.links[index]?.url?.message}
                </p>
              )}
            </div>

            {fields.length > 1 && (
              <Button
                type="button"
                variant="ghost"
                size="icon"
                onClick={() => remove(index)}
              >
                <X className="h-4 w-4" />
              </Button>
            )}
          </div>
        ))}

        <Button
          type="button"
          variant="outline"
          onClick={() => append({ title: '', url: '' })}
        >
          <Plus className="h-4 w-4 mr-2" />
          Add Link
        </Button>

        {form.formState.errors.links?.root && (
          <p className="text-sm text-destructive">
            {form.formState.errors.links.root.message}
          </p>
        )}
      </div>

      <Button type="submit" className="mt-6">
        Submit
      </Button>
    </form>
  )
}
```

#### File Upload with Validation

```typescript
// components/forms/file-upload-form.tsx
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Upload } from 'lucide-react'

const MAX_FILE_SIZE = 5 * 1024 * 1024 // 5MB
const ACCEPTED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']

const formSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  image: z
    .instanceof(FileList)
    .refine((files) => files.length > 0, 'Image is required')
    .refine(
      (files) => files[0]?.size <= MAX_FILE_SIZE,
      'Max file size is 5MB'
    )
    .refine(
      (files) => ACCEPTED_IMAGE_TYPES.includes(files[0]?.type),
      'Only .jpg, .jpeg, .png and .webp formats are supported'
    ),
})

type FormData = z.infer<typeof formSchema>

export function FileUploadForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
  })

  async function onSubmit(data: FormData) {
    const file = data.image[0]
    const formData = new FormData()
    formData.append('title', data.title)
    formData.append('image', file)

    // Upload to server
    const response = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    })

    const result = await response.json()
    console.log(result)
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <Label htmlFor="title">Title</Label>
        <Input id="title" {...form.register('title')} />
        {form.formState.errors.title && (
          <p className="text-sm text-destructive mt-1">
            {form.formState.errors.title.message}
          </p>
        )}
      </div>

      <div>
        <Label htmlFor="image">Image</Label>
        <Input
          id="image"
          type="file"
          accept="image/*"
          {...form.register('image')}
        />
        {form.formState.errors.image && (
          <p className="text-sm text-destructive mt-1">
            {form.formState.errors.image.message as string}
          </p>
        )}
      </div>

      <Button type="submit">
        <Upload className="mr-2 h-4 w-4" />
        Upload
      </Button>
    </form>
  )
}
```

### 6. Custom Validation Helpers

```typescript
// lib/validations/helpers.ts
import { z } from 'zod'

// Custom phone number validator
export const phoneNumber = () =>
  z.string().regex(/^\+?[1-9]\d{1,14}$/, 'Invalid phone number')

// Custom slug validator
export const slug = () =>
  z
    .string()
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Invalid slug format')
    .min(3)
    .max(100)

// Custom date range validator
export const dateRange = () =>
  z
    .object({
      from: z.date(),
      to: z.date(),
    })
    .refine((data) => data.to >= data.from, {
      message: 'End date must be after start date',
      path: ['to'],
    })

// Custom password match validator
export const passwordMatch = (
  passwordField: string,
  confirmPasswordField: string
) =>
  z
    .object({
      [passwordField]: z.string(),
      [confirmPasswordField]: z.string(),
    })
    .refine((data) => data[passwordField] === data[confirmPasswordField], {
      message: "Passwords don't match",
      path: [confirmPasswordField],
    })

// Conditional validation
export const conditionalRequired = <T extends z.ZodTypeAny>(
  schema: T,
  condition: (data: any) => boolean
) => z.preprocess((val, ctx) => (condition(ctx) ? val : undefined), schema)
```

## Best Practices

### 1. Validation Strategy
- **Client-side**: Use react-hook-form with zod for immediate feedback
- **Server-side**: Always re-validate in Server Actions (never trust client)
- **Share schemas**: Use same zod schemas on client and server

### 2. Error Handling
- Display field-level errors near inputs
- Show form-level errors in a toast or alert
- Provide helpful, actionable error messages
- Use FormMessage component from shadcn/ui

### 3. User Experience
- Enable real-time validation with `mode: 'onChange'` or `mode: 'onBlur'`
- Disable submit button while submitting
- Show loading states during submission
- Clear form after successful submission
- Provide confirmation feedback

### 4. Performance
- Use `defaultValues` to avoid unnecessary re-renders
- Memoize expensive computations
- Debounce async validations
- Lazy load large forms

### 5. Accessibility
- Use semantic HTML form elements
- Include proper labels and ARIA attributes
- Support keyboard navigation
- Announce errors to screen readers

## Common Patterns

### Async Validation (Check Username Availability)

```typescript
const signUpSchema = z.object({
  username: z
    .string()
    .min(3)
    .refine(async (username) => {
      const response = await fetch(`/api/check-username?username=${username}`)
      const { available } = await response.json()
      return available
    }, 'Username is already taken'),
})
```

### Dependent Fields

```typescript
const formSchema = z.object({
  hasShipping: z.boolean(),
  shippingAddress: z.string().optional(),
}).refine(
  (data) => {
    if (data.hasShipping) {
      return !!data.shippingAddress
    }
    return true
  },
  {
    message: 'Shipping address is required',
    path: ['shippingAddress'],
  }
)
```

### Transform Data Before Validation

```typescript
const formSchema = z.object({
  email: z.string().email().transform((val) => val.toLowerCase()),
  age: z.string().transform((val) => parseInt(val, 10)),
  tags: z.string().transform((val) => val.split(',').map((t) => t.trim())),
})
```

## Testing

```typescript
// __tests__/validations/post.test.ts
import { createPostSchema } from '@/lib/validations/post'

describe('createPostSchema', () => {
  it('should validate correct data', () => {
    const data = {
      title: 'Test Post',
      content: 'Test content',
      status: 'draft' as const,
    }

    const result = createPostSchema.safeParse(data)
    expect(result.success).toBe(true)
  })

  it('should reject empty title', () => {
    const data = {
      title: '',
      content: 'Test content',
    }

    const result = createPostSchema.safeParse(data)
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Title is required')
    }
  })

  it('should reject long title', () => {
    const data = {
      title: 'a'.repeat(201),
      content: 'Test content',
    }

    const result = createPostSchema.safeParse(data)
    expect(result.success).toBe(false)
  })
})
```

## Follow-up Tasks

- Add toast notifications for form feedback (install sonner)
- Implement form auto-save functionality
- Add form analytics tracking
- Create reusable form components library
- Set up form error monitoring (Sentry)
- Add internationalization for error messages
