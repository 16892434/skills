# Next.js Auth Setup Skill

A comprehensive skill for implementing Auth.js (NextAuth.js) authentication in Next.js projects.

## Features

- ✅ **Multiple Authentication Methods**: OAuth (Google, GitHub, etc.) + Credentials
- ✅ **Flexible Session Management**: JWT or Database sessions
- ✅ **Route Protection**: Middleware-based authentication
- ✅ **TypeScript Support**: Full type safety
- ✅ **Both Router Types**: App Router (Next.js 13+) and Pages Router support
- ✅ **Database Integration**: Prisma adapter included
- ✅ **Role-Based Access Control**: Admin/user role examples
- ✅ **Production Ready**: Security best practices included

## Quick Start

### Automated Setup

Run the setup script in your Next.js project:

```bash
bash scripts/setup-auth.sh
```

This will:
1. Detect your Next.js version and router type
2. Install required dependencies
3. Create auth configuration files
4. Set up environment variables
5. Generate TypeScript types
6. Create middleware for route protection

### Manual Usage

When using Claude Code with this skill, simply ask:

```
"Set up Auth.js authentication with Google OAuth and credentials provider"
```

Claude will follow the comprehensive guide in `SKILL.md` to implement authentication step-by-step.

## What's Included

### Core Files

- **SKILL.md**: Complete implementation guide with decision trees and best practices
- **scripts/setup-auth.sh**: Automated setup script
- **templates/**: Reference code templates
  - `auth-app-router.ts`: Complete Auth.js v5 config for App Router
  - `middleware-advanced.ts`: Advanced middleware with RBAC
  - `prisma-schema.prisma`: Complete database schema
  - `signin-page-app-router.tsx`: Professional sign-in page
- **reference/**: Documentation and guides
  - `oauth-setup-guides.md`: Step-by-step OAuth provider setup
  - `troubleshooting.md`: Common issues and solutions

## Supported Providers

- Google OAuth
- GitHub OAuth
- Discord OAuth
- Microsoft/Azure AD
- Apple Sign In
- Email/Password (Credentials)
- Custom providers

## Requirements

- Next.js 12+ (Pages Router) or Next.js 13+ (App Router)
- Node.js 18+
- TypeScript (recommended)
- Database (optional, for database sessions)

## Usage Examples

### Basic Setup

```typescript
// Claude Code prompt
"Use the nextjs-auth-setup skill to implement Google OAuth"
```

### Advanced Setup

```typescript
// Claude Code prompt
"Set up Auth.js with:
- Google and GitHub OAuth
- Email/password authentication
- Database sessions with Prisma
- Role-based access control
- Protected dashboard routes"
```

## Documentation Structure

```
nextjs-auth-setup/
├── SKILL.md                    # Main implementation guide
├── LICENSE.txt
├── README.md
├── scripts/
│   └── setup-auth.sh          # Automated setup
├── templates/
│   ├── auth-app-router.ts     # Complete App Router config
│   ├── middleware-advanced.ts  # Advanced middleware
│   ├── prisma-schema.prisma   # Database schema
│   └── signin-page-app-router.tsx
└── reference/
    ├── oauth-setup-guides.md  # OAuth provider guides
    └── troubleshooting.md     # Common issues
```

## Key Features Explained

### Decision Trees

The skill automatically adapts to your project:
- Detects App Router vs Pages Router
- Chooses appropriate Auth.js version
- Configures based on your auth strategy (JWT vs Database)
- Suggests providers based on your needs

### Security Best Practices

- Secure session management
- CSRF protection (built-in)
- Password hashing with bcrypt
- Environment variable validation
- Security headers in middleware
- Rate limiting guidance

### TypeScript Integration

Full type safety with:
- Extended session types
- User model types
- JWT token types
- Custom field support

## Common Use Cases

1. **SaaS Authentication**: Complete auth flow with role management
2. **E-commerce**: User accounts with order history
3. **Internal Tools**: SSO with Microsoft/Google Workspace
4. **Community Platform**: Social login + custom profiles
5. **API Platform**: JWT-based authentication

## Testing Checklist

The skill includes a comprehensive testing checklist:
- [ ] OAuth sign-in flows
- [ ] Credentials authentication
- [ ] Session persistence
- [ ] Route protection
- [ ] Error handling
- [ ] Database integration
- [ ] TypeScript compilation

## Resources

- [Auth.js Documentation](https://authjs.dev/)
- [NextAuth.js v4 Docs](https://next-auth.js.org/)
- [Next.js Authentication](https://nextjs.org/docs/authentication)

## Version Support

- ✅ Auth.js v5 (beta) - Next.js 13+ App Router
- ✅ NextAuth.js v4 (stable) - Next.js 12+ Pages Router
- ✅ Next.js 14 & 15 compatible
- ✅ TypeScript & JavaScript

## Contributing

This skill is designed to be iterative. After each implementation:
1. Note what worked well
2. Document issues encountered
3. Update the skill with lessons learned
4. Share improvements

## License

Apache 2.0 - See LICENSE.txt

## Support

For issues specific to this skill, refer to:
1. `reference/troubleshooting.md` for common problems
2. `reference/oauth-setup-guides.md` for provider setup
3. The main `SKILL.md` for implementation details

For Auth.js/NextAuth.js issues, see the official documentation.
