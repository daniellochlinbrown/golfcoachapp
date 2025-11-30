# Email Setup Guide for Golf Coach App

This guide explains how to configure email confirmation for your Golf Coach App deployment on Render.

## Overview

The app uses ActionMailer to send confirmation emails when users sign up. In development, emails open in your browser automatically. In production (Render), you need to configure an SMTP email service.

## Email Providers

### Option 1: SendGrid (Recommended for Beginners)

**Free Tier**: 100 emails/day forever

**Setup Steps:**

1. **Sign up for SendGrid**
   - Go to https://signup.sendgrid.com/
   - Create a free account
   - Verify your email address

2. **Create an API Key**
   - Go to Settings → API Keys
   - Click "Create API Key"
   - Choose "Restricted Access"
   - Enable "Mail Send" permissions
   - Copy the API key (you won't see it again!)

3. **Configure Render Environment Variables**
   - Go to your Render dashboard
   - Select your web service
   - Go to "Environment" tab
   - Add these variables:
     ```
     SMTP_ADDRESS=smtp.sendgrid.net
     SMTP_PORT=587
     SMTP_USERNAME=apikey
     SMTP_PASSWORD=<your-sendgrid-api-key>
     SMTP_DOMAIN=golfcoachapp.com
     ```
   - Click "Save Changes"

4. **Verify Single Sender (Required for Free Tier)**
   - Go to Settings → Sender Authentication
   - Click "Verify a Single Sender"
   - Enter your email address
   - Verify the email they send you
   - Update `app/mailers/user_mailer.rb` line 2 to use your verified email:
     ```ruby
     default from: "your-verified-email@example.com"
     ```

### Option 2: Postmark

**Free Tier**: 100 emails/month

**Setup Steps:**

1. Sign up at https://postmarkapp.com/
2. Create a server
3. Get your Server API Token
4. Configure Render environment variables:
   ```
   SMTP_ADDRESS=smtp.postmarkapp.com
   SMTP_PORT=587
   SMTP_USERNAME=<your-server-api-token>
   SMTP_PASSWORD=<your-server-api-token>
   SMTP_DOMAIN=golfcoachapp.com
   ```
5. Verify your sender signature

### Option 3: Mailgun

**Free Tier**: 5,000 emails/month for 3 months

**Setup Steps:**

1. Sign up at https://www.mailgun.com/
2. Verify your domain or use the sandbox domain for testing
3. Get your SMTP credentials from the dashboard
4. Configure Render environment variables:
   ```
   SMTP_ADDRESS=smtp.mailgun.org
   SMTP_PORT=587
   SMTP_USERNAME=<your-mailgun-username>
   SMTP_PASSWORD=<your-mailgun-password>
   SMTP_DOMAIN=<your-domain>
   ```

### Option 4: AWS SES (Best for Scale)

**Cost**: $0.10 per 1,000 emails (cheapest at scale)

**Setup Steps:**

1. Sign up for AWS
2. Go to Amazon SES
3. Create SMTP credentials
4. Verify your domain or email
5. Request production access (initially in sandbox mode)
6. Configure Render environment variables:
   ```
   SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
   SMTP_PORT=587
   SMTP_USERNAME=<your-aws-smtp-username>
   SMTP_PASSWORD=<your-aws-smtp-password>
   SMTP_DOMAIN=<your-domain>
   ```

## Testing Email in Development

Emails in development automatically open in your browser using the `letter_opener` gem.

**To test:**

1. Start your Rails server: `bin/rails server`
2. Sign up for a new account at http://localhost:3000/signup
3. The confirmation email will open in your browser automatically
4. Click the confirmation link to test the full flow

## Testing Email in Production

After deploying to Render with SMTP configured:

1. Sign up with a real email address
2. Check your inbox for the confirmation email
3. Click the confirmation link
4. Verify you can log in

## Troubleshooting

### Emails not sending in production

1. **Check Render logs**: `heroku logs --tail` or use Render dashboard
2. **Verify environment variables**: Make sure all SMTP_* variables are set correctly
3. **Check sender verification**: Most providers require sender email verification
4. **Test SMTP credentials**: Use `rails console` in production to test:
   ```ruby
   UserMailer.confirmation_instructions(User.first).deliver_now
   ```

### "Invalid confirmation token" errors

- Token expires after 24 hours
- User can request a new confirmation email at `/confirmations/new`

### Emails going to spam

- Verify your domain with your email provider
- Set up SPF and DKIM records (provider-specific)
- Use a professional "from" email address (not gmail, yahoo, etc.)

## Production Deployment Checklist

- [ ] Choose an email provider (SendGrid recommended for beginners)
- [ ] Create account and get SMTP credentials
- [ ] Add environment variables to Render dashboard
- [ ] Verify sender email/domain with provider
- [ ] Update `app/mailers/user_mailer.rb` with verified "from" address
- [ ] Deploy to Render
- [ ] Test signup with real email address
- [ ] Verify confirmation email received
- [ ] Test confirmation link works

## Email Flow in the App

1. **User signs up** → `UsersController#create`
2. **User model generates token** → `before_create :generate_confirmation_token`
3. **Confirmation email sent** → `user.send_confirmation_instructions`
4. **User clicks link** → `ConfirmationsController#show`
5. **Token verified** → `user.confirm!` (sets `confirmed_at`)
6. **User can login** → `SessionsController#create` checks `user.confirmed?`

## Interview Talking Points

When discussing this feature in your Tanda interview:

1. **Security**: Tokens are securely generated with `SecureRandom.urlsafe_base64(24)` and stored with unique index
2. **Expiration**: Tokens expire after 24 hours for security
3. **User Experience**: Clear error messages, ability to resend confirmation
4. **Production Ready**: Environment variable configuration works with any SMTP provider
5. **Testing**: Letter_opener in development, real SMTP in production
6. **Database Design**: Added indexed `confirmation_token`, `confirmed_at`, and `confirmation_sent_at` columns
7. **Email Templates**: Both HTML and text versions for better compatibility
8. **Rails Patterns**: Uses callbacks (`before_create`), mailers (ActionMailer), and proper MVC separation

## Next Steps

Consider adding:
- Password reset functionality (similar pattern to email confirmation)
- Email notifications for training plan completion
- Welcome email series for new users
- Background jobs (Sidekiq) for email delivery to avoid blocking requests
