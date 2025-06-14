# Admin Panel Setup Guide

This guide explains how to set up master admin users for production and staging environments.

## Security Best Practices

1. **Use strong passwords**: Minimum 12 characters with mixed case, numbers, and symbols
2. **Environment variables**: Never hardcode passwords in code or config files
3. **Limit access**: Only create the minimum number of admin users needed
4. **Regular rotation**: Change admin passwords regularly
5. **Monitoring**: Monitor admin access and actions

## Production Setup

### Method 1: Environment Variables (Recommended)

Set the following environment variables in your production environment:

```bash
export MASTER_USER_EMAIL="admin@yourdomain.com"
export MASTER_USER_PASSWORD="your-secure-password-here"
export MASTER_USER_NAME="Master Administrator"
```

Then run the database seed:

```bash
bin/rails db:seed
```

### Method 2: Rake Task

Generate a secure password:

```bash
bin/rails admin:generate_password
```

Create the master user:

```bash
MASTER_USER_EMAIL="admin@yourdomain.com" \
MASTER_USER_PASSWORD="generated-password" \
MASTER_USER_NAME="Master Admin" \
bin/rails admin:create_master
```

## Development Setup

For development, a default admin user is automatically created:

- **Email**: admin@example.com
- **Password**: password

## Management Tasks

### Reset Master User Password

Interactive password reset:

```bash
bin/rails admin:reset_password
```

### Check Admin Users

To see all admin users:

```bash
bin/rails console
> Role.find_by(name: 'admin').users.pluck(:email, :name)
```

## Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `MASTER_USER_EMAIL` | Yes | Admin email address | `admin@company.com` |
| `MASTER_USER_PASSWORD` | Yes | Secure password (12+ chars) | `SecureP@ssw0rd123!` |
| `MASTER_USER_NAME` | No | Display name | `Master Administrator` |

## Security Checklist

- [ ] Strong password set (12+ characters)
- [ ] Environment variables configured securely
- [ ] No passwords in code or logs
- [ ] Admin access limited to necessary users
- [ ] Regular password rotation schedule established
- [ ] Admin actions monitored
- [ ] Backup admin user created (if needed)

## Troubleshooting

### Common Issues

1. **"Master user not created"**
   - Check that environment variables are set correctly
   - Ensure password meets minimum requirements (12+ characters)

2. **"User already exists"**
   - The task is idempotent - running it again is safe
   - Check if user already has admin role assigned

3. **"Admin role not found"**
   - Run `bin/rails db:seed` to create system roles first

### Support

For additional help, contact the development team or check the application logs for specific error messages.