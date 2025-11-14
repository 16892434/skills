# OAuth Provider Setup Guides

Complete step-by-step guides for configuring popular OAuth providers with Auth.js.

---

## Google OAuth Setup

### 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name your project and click "Create"

### 2. Enable Google+ API

1. In the sidebar, go to "APIs & Services" → "Library"
2. Search for "Google+ API"
3. Click on it and click "Enable"

### 3. Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. If prompted, configure the OAuth consent screen:
   - Choose "External" (unless you have Google Workspace)
   - Fill in app name, user support email, developer contact
   - Add scopes: `email`, `profile`, `openid`
   - Add test users (for development)

4. Configure OAuth client:
   - Application type: "Web application"
   - Name: Your app name
   - Authorized JavaScript origins:
     - Development: `http://localhost:3000`
     - Production: `https://yourdomain.com`
   - Authorized redirect URIs:
     - Development: `http://localhost:3000/api/auth/callback/google`
     - Production: `https://yourdomain.com/api/auth/callback/google`

5. Click "Create"
6. Copy the Client ID and Client Secret

### 4. Add to .env.local

```env
GOOGLE_CLIENT_ID=your_client_id_here.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret_here
```

### 5. Configure in Auth.js

```typescript
import Google from "next-auth/providers/google"

providers: [
  Google({
    clientId: process.env.GOOGLE_CLIENT_ID!,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    authorization: {
      params: {
        prompt: "consent",
        access_type: "offline",
        response_type: "code"
      }
    }
  }),
]
```

### Publishing Your App

To move from testing to production:
1. Go to OAuth consent screen
2. Click "Publish App"
3. You may need to go through Google's verification process for sensitive scopes

---

## GitHub OAuth Setup

### 1. Create GitHub OAuth App

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click "OAuth Apps" → "New OAuth App"

### 2. Configure OAuth App

Fill in the application details:

- **Application name**: Your app name
- **Homepage URL**:
  - Development: `http://localhost:3000`
  - Production: `https://yourdomain.com`
- **Application description**: Brief description (optional)
- **Authorization callback URL**:
  - Development: `http://localhost:3000/api/auth/callback/github`
  - Production: `https://yourdomain.com/api/auth/callback/github`

### 3. Generate Client Secret

1. After creating, click "Generate a new client secret"
2. Copy the Client ID and Client Secret immediately (you won't see it again)

### 4. Add to .env.local

```env
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
```

### 5. Configure in Auth.js

```typescript
import GitHub from "next-auth/providers/github"

providers: [
  GitHub({
    clientId: process.env.GITHUB_CLIENT_ID!,
    clientSecret: process.env.GITHUB_CLIENT_SECRET!,
  }),
]
```

### Optional: Request Additional Scopes

```typescript
GitHub({
  clientId: process.env.GITHUB_CLIENT_ID!,
  clientSecret: process.env.GITHUB_CLIENT_SECRET!,
  authorization: {
    params: {
      scope: "read:user user:email",
    },
  },
})
```

---

## Discord OAuth Setup

### 1. Create Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click "New Application"
3. Name your application and click "Create"

### 2. Configure OAuth2

1. Go to the "OAuth2" tab in the left sidebar
2. Add Redirects:
   - Development: `http://localhost:3000/api/auth/callback/discord`
   - Production: `https://yourdomain.com/api/auth/callback/discord`

### 3. Get Credentials

1. Copy the Client ID
2. Click "Reset Secret" to generate a new Client Secret
3. Copy the Client Secret

### 4. Add to .env.local

```env
DISCORD_CLIENT_ID=your_discord_client_id
DISCORD_CLIENT_SECRET=your_discord_client_secret
```

### 5. Configure in Auth.js

```typescript
import Discord from "next-auth/providers/discord"

providers: [
  Discord({
    clientId: process.env.DISCORD_CLIENT_ID!,
    clientSecret: process.env.DISCORD_CLIENT_SECRET!,
  }),
]
```

---

## Apple OAuth Setup

### 1. Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Go to "Certificates, Identifiers & Profiles"
3. Click "Identifiers" → "+" → "App IDs"
4. Configure:
   - Description: Your app name
   - Bundle ID: Explicit (e.g., `com.yourcompany.app`)
   - Enable "Sign In with Apple"

### 2. Create Service ID

1. Click "Identifiers" → "+" → "Services IDs"
2. Configure:
   - Description: Your app name (Web)
   - Identifier: `com.yourcompany.app.web`
   - Enable "Sign In with Apple"
   - Click "Configure"
   - Add domains and return URLs:
     - Domains: `yourdomain.com` (no http/https)
     - Return URLs: `https://yourdomain.com/api/auth/callback/apple`

### 3. Create Private Key

1. Go to "Keys" → "+"
2. Name: "Sign In with Apple Key"
3. Enable "Sign In with Apple"
4. Click "Configure" → Select your App ID
5. Click "Save" → "Continue" → "Register"
6. Download the .p8 key file (keep it safe!)
7. Note the Key ID

### 4. Get Team ID

1. In the top right, note your Team ID

### 5. Add to .env.local

```env
APPLE_ID=com.yourcompany.app.web
APPLE_TEAM_ID=your_team_id
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
your_private_key_contents_here
-----END PRIVATE KEY-----"
APPLE_KEY_ID=your_key_id
```

### 6. Configure in Auth.js

```typescript
import Apple from "next-auth/providers/apple"

providers: [
  Apple({
    clientId: process.env.APPLE_ID!,
    clientSecret: {
      appleId: process.env.APPLE_ID!,
      teamId: process.env.APPLE_TEAM_ID!,
      privateKey: process.env.APPLE_PRIVATE_KEY!,
      keyId: process.env.APPLE_KEY_ID!,
    },
  }),
]
```

---

## Microsoft/Azure AD Setup

### 1. Register Application

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to "Azure Active Directory" → "App registrations"
3. Click "New registration"
4. Configure:
   - Name: Your app name
   - Supported account types: Choose based on your needs
   - Redirect URI: `http://localhost:3000/api/auth/callback/azure-ad`

### 2. Get Application ID

1. Copy the "Application (client) ID"

### 3. Create Client Secret

1. Go to "Certificates & secrets"
2. Click "New client secret"
3. Add description and set expiry
4. Copy the secret value immediately

### 4. Get Tenant ID

1. Go back to "Overview"
2. Copy the "Directory (tenant) ID"

### 5. Add to .env.local

```env
AZURE_AD_CLIENT_ID=your_client_id
AZURE_AD_CLIENT_SECRET=your_client_secret
AZURE_AD_TENANT_ID=your_tenant_id
```

### 6. Configure in Auth.js

```typescript
import AzureAD from "next-auth/providers/azure-ad"

providers: [
  AzureAD({
    clientId: process.env.AZURE_AD_CLIENT_ID!,
    clientSecret: process.env.AZURE_AD_CLIENT_SECRET!,
    tenantId: process.env.AZURE_AD_TENANT_ID!,
  }),
]
```

---

## Testing OAuth Flows

### Local Development Tips

1. **Use ngrok for testing**:
   ```bash
   npx ngrok http 3000
   ```
   Use the ngrok URL as your callback URL during development

2. **Check callback URL format**:
   ```
   http://localhost:3000/api/auth/callback/{provider}
   ```
   Replace `{provider}` with: google, github, discord, etc.

3. **Common issues**:
   - Redirect URI mismatch: Ensure exact match including http/https
   - Missing scopes: Check provider documentation for required scopes
   - CORS errors: Usually a callback URL configuration issue

### Production Checklist

- [ ] Update all OAuth callback URLs to production domain
- [ ] Use HTTPS in production
- [ ] Set `NEXTAUTH_URL` to production domain
- [ ] Test OAuth flow in production environment
- [ ] Check rate limits for each provider
- [ ] Implement error handling for OAuth failures

---

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use different OAuth apps** for dev/staging/production
3. **Rotate secrets regularly**
4. **Implement rate limiting** on authentication endpoints
5. **Monitor OAuth errors** in production
6. **Set up alerts** for failed authentication attempts
7. **Review OAuth scopes** - only request what you need
8. **Handle account linking carefully** - see Auth.js docs on `allowDangerousEmailAccountLinking`

---

## Resources

- [Auth.js Providers Documentation](https://authjs.dev/getting-started/providers)
- [Google OAuth 2.0 Guide](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Apps Guide](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [Discord OAuth2 Documentation](https://discord.com/developers/docs/topics/oauth2)
- [Sign in with Apple Documentation](https://developer.apple.com/sign-in-with-apple/)
