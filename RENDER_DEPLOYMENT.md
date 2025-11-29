# Deploy Golf Coach App to Render

This guide shows you how to deploy your Golf Coach App to [Render](https://render.com/) - a modern cloud platform that makes deployment simple.

## Why Render?

- **Free tier available** - PostgreSQL and web service
- **Automatic SSL certificates** - HTTPS enabled by default
- **Zero-downtime deploys** - Automatic rollback on failure
- **Automatic deploys from Git** - Push to deploy
- **Managed PostgreSQL** - Backups and scaling included
- **No credit card required** to start

## Prerequisites

- [ ] GitHub account (or GitLab/Bitbucket)
- [ ] Your code pushed to a Git repository
- [ ] Claude API key from https://console.anthropic.com/
- [ ] Rails master key (in `config/master.key`)

## Step 1: Prepare Your Repository

1. **Ensure sensitive files are not committed:**

```bash
# Check that these files are in .gitignore
cat .gitignore | grep -E "\.env$|master.key"
```

If not present, add them:
```bash
echo ".env" >> .gitignore
echo "/config/master.key" >> .gitignore
```

2. **Commit the render.yaml configuration:**

```bash
git add render.yaml
git add config/environments/production.rb
git commit -m "Configure for Render deployment"
git push origin main
```

## Step 2: Sign Up for Render

1. Go to https://render.com/
2. Click "Get Started for Free"
3. Sign up with your GitHub account (recommended for easy repo access)
4. Authorize Render to access your repositories

## Step 3: Deploy Using Blueprint (Easiest Method)

Render Blueprint deploys your entire stack (web app + database) from the `render.yaml` file.

### Option A: Deploy via Dashboard

1. Click "New +" → "Blueprint"
2. Connect your GitHub repository
3. Select the repository containing your Golf Coach App
4. Render will detect `render.yaml` automatically
5. Click "Apply"

### Option B: Deploy via URL

Use this one-click deploy link (replace YOUR_USERNAME and YOUR_REPO):

```
https://render.com/deploy?repo=https://github.com/YOUR_USERNAME/YOUR_REPO
```

## Step 4: Configure Environment Variables

After Blueprint creates your services, you need to add secret environment variables:

### 4.1 Add RAILS_MASTER_KEY

1. Get your master key:
```bash
cat config/master.key
```

2. In Render Dashboard:
   - Go to your web service → "Environment"
   - Click "Add Environment Variable"
   - Key: `RAILS_MASTER_KEY`
   - Value: (paste your master key)
   - Click "Save Changes"

### 4.2 Add CLAUDE_API_KEY

1. Get your Claude API key from https://console.anthropic.com/

2. In Render Dashboard:
   - Go to your web service → "Environment"
   - Click "Add Environment Variable"
   - Key: `CLAUDE_API_KEY`
   - Value: (paste your API key starting with `sk-ant-`)
   - Click "Save Changes"

### 4.3 Verify Environment Variables

Your web service should have these environment variables:

- ✅ `RAILS_ENV` = `production` (auto-set)
- ✅ `RAILS_MASTER_KEY` = `your-key-here` (manual)
- ✅ `CLAUDE_API_KEY` = `sk-ant-...` (manual)
- ✅ `DATABASE_URL` = `postgres://...` (auto-linked)
- ✅ `SOLID_QUEUE_IN_PUMA` = `true` (auto-set)

## Step 5: Set Up PostgreSQL Databases

Your app needs **4 PostgreSQL databases**. Render creates one by default, so you need to create 3 more.

### 5.1 Connect to Database via Render Shell

1. In Render Dashboard:
   - Go to your PostgreSQL database
   - Click "Connect" → "External Connection"
   - Copy the `PSQL Command`

2. Run locally (or use Render Shell):
```bash
# The command will look like:
PGPASSWORD=your_password psql -h dpg-xxx.oregon-postgres.render.com -U golfcoachapp_user golfcoachapp_production
```

3. Create additional databases:
```sql
-- Create the three additional databases
CREATE DATABASE golfcoachapp_production_cache;
CREATE DATABASE golfcoachapp_production_queue;
CREATE DATABASE golfcoachapp_production_cable;

-- Verify all databases exist
\l

-- Exit
\q
```

### 5.2 Update Database Configuration

Your app is configured to use these databases automatically via the DATABASE_URL connection string that Render provides.

## Step 6: Run Database Migrations

After deployment completes:

1. Go to your web service in Render Dashboard
2. Click "Shell" tab
3. Run migrations:
```bash
bin/rails db:migrate
```

Or use the Render CLI:
```bash
render shell -s golfcoachapp
bin/rails db:migrate
```

## Step 7: Verify Deployment

### Check Application Status

1. **View Logs:**
   - In Render Dashboard → Your web service → "Logs"
   - Look for: "Puma starting in cluster mode" and "Booted Uninterruptible"

2. **Test Health Endpoint:**
   - Your app URL: `https://your-app-name.onrender.com`
   - Health check: `https://your-app-name.onrender.com/up`
   - Should return "ok" with 200 status

3. **Access Your App:**
   - Visit: `https://your-app-name.onrender.com`
   - You should see the Golf Coach App homepage

### Test Core Functionality

1. **Sign up for an account**
2. **Enter 3 golf rounds**
3. **Calculate handicap** (tests Claude API integration)
4. **Generate training plan** (tests Claude API integration)

## Step 8: Configure Custom Domain (Optional)

If you have a custom domain:

1. In Render Dashboard → Your web service → "Settings"
2. Scroll to "Custom Domains"
3. Click "Add Custom Domain"
4. Enter your domain (e.g., `golfcoach.yourdomain.com`)
5. Add the CNAME record to your DNS provider:
   - Type: `CNAME`
   - Name: `golfcoach` (or `@` for root domain)
   - Value: `your-app-name.onrender.com`
6. Wait for DNS propagation (5-60 minutes)
7. Render will automatically provision SSL certificate

Update production.rb if needed:
```ruby
config.hosts << "yourdomain.com"
```

## Common Render Commands

### Using Render Dashboard

- **View Logs**: Web Service → Logs tab
- **Shell Access**: Web Service → Shell tab
- **Restart Service**: Web Service → Manual Deploy → "Clear build cache & deploy"
- **Environment Variables**: Web Service → Environment tab

### Using Render CLI (Optional)

Install Render CLI:
```bash
brew install render  # macOS
# or
npm install -g render-cli
```

Login:
```bash
render login
```

Common commands:
```bash
# View services
render services list

# View logs
render logs -s golfcoachapp -f

# Open shell
render shell -s golfcoachapp

# Trigger deploy
render deploy -s golfcoachapp
```

## Automatic Deployments

Render automatically deploys when you push to your main branch:

```bash
git add .
git commit -m "Update feature"
git push origin main
```

Render will:
1. Detect the push
2. Build new Docker image
3. Run database migrations
4. Deploy with zero downtime
5. Rollback automatically if deployment fails

### Disable Auto-Deploy (Optional)

If you prefer manual deploys:
1. Web Service → Settings → "Build & Deploy"
2. Toggle off "Auto-Deploy"
3. Use "Manual Deploy" button when ready

## Troubleshooting

### Build Failures

**Error: "failed to solve with frontend dockerfile.v0"**

- Check Dockerfile syntax
- Ensure all required files are committed to git
- Try "Clear build cache & deploy"

### Database Connection Errors

**Error: "could not connect to server"**

1. Verify DATABASE_URL is set:
   - Web Service → Environment → Check DATABASE_URL exists
2. Check database is running:
   - PostgreSQL service should show "Available"
3. Verify database exists:
   - Connect via Shell and run `\l`

### Claude API Errors

**Error: "unauthorized" or "API key not found"**

1. Check CLAUDE_API_KEY is set:
   - Web Service → Environment → Verify CLAUDE_API_KEY
2. Test the key locally:
```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $CLAUDE_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-20250514","max_tokens":1024,"messages":[{"role":"user","content":"Hello"}]}'
```

### Asset Loading Issues (404 on CSS/JS)

**Assets not loading:**

1. Check if assets were precompiled:
   - Shell → `ls -la public/assets`
2. Verify RAILS_ENV=production
3. Check build logs for asset compilation errors

### Application Not Starting

**"Web service failed to bind to $PORT"**

- Render expects app to bind to port in `$PORT` environment variable
- Puma configuration in `config/puma.rb` should use `ENV.fetch("PORT", 3000)`
- Check this is configured correctly

### Slow First Request (Cold Start)

Render free tier spins down after 15 minutes of inactivity:

- **Upgrade to Starter plan** ($7/month) for always-on service
- Or keep the free tier and accept 30-60 second cold starts
- Use a uptime monitor to ping your app every 10 minutes (keeps it warm)

## Performance Optimization

### Upgrade Your Plan

Free tier limitations:
- 750 hours/month (shared across all free services)
- Spins down after 15 minutes of inactivity
- 512 MB RAM
- 0.1 CPU

**Starter Plan ($7/month):**
- Always on
- 512 MB RAM
- 0.5 CPU
- Faster builds

**Standard Plan ($25/month):**
- 2 GB RAM
- 1 CPU
- Even faster performance

### Increase Concurrency

In render.yaml, adjust based on your plan:

```yaml
envVars:
  - key: WEB_CONCURRENCY
    value: 2  # Free: 1, Starter: 2, Standard: 4+
  - key: JOB_CONCURRENCY
    value: 3
```

### Add Redis (Optional)

For production caching:

1. Add Redis service in render.yaml
2. Update cache_store in production.rb
3. Add `redis` gem to Gemfile

## Monitoring and Logs

### View Application Logs

Real-time logs in dashboard:
- Web Service → Logs tab
- Filter by level: Info, Warn, Error

Download logs:
- Logs tab → Download logs (last 7 days)

### Enable Notifications

1. Web Service → Notifications
2. Add email or Slack webhook
3. Get notified on:
   - Deploy failures
   - Service downtime
   - Build errors

### Monitor Performance

Render provides basic metrics:
- CPU usage
- Memory usage
- Request count
- Response times

For advanced monitoring:
- Use New Relic (free tier available)
- Use Scout APM
- Use Honeybadger for error tracking

## Database Backups

### Automatic Backups

Render automatically backs up your database:
- **Free tier**: Daily backups (7 day retention)
- **Paid plans**: Daily backups (30+ day retention)

### Manual Backup

Create snapshot in dashboard:
1. PostgreSQL service → Snapshots
2. Click "Create Snapshot"
3. Download or restore later

### Restore from Backup

1. PostgreSQL service → Snapshots
2. Select snapshot
3. Click "Restore"

## Scaling Your Application

### Vertical Scaling (More Resources)

Upgrade your plan for more RAM/CPU:
1. Web Service → Settings → Instance Type
2. Select larger instance
3. Save changes

### Horizontal Scaling (More Instances)

Add multiple web servers:
1. Web Service → Settings → Scaling
2. Increase instance count
3. Render load balances automatically

**Note:** With multiple instances, you may need:
- External Redis for Action Cable
- Separate background worker service
- Sticky sessions for some features

### Background Workers

Create dedicated worker service:

1. Uncomment worker section in render.yaml
2. Re-apply blueprint or create manually
3. Worker runs Solid Queue in separate container

## Cost Estimate

### Free Tier (Getting Started)
- **Web Service**: Free (with limitations)
- **PostgreSQL**: Free (1 GB storage)
- **Total**: $0/month

### Starter Setup (Recommended for Production)
- **Web Service**: $7/month (Starter plan)
- **PostgreSQL**: $7/month (Starter plan)
- **Total**: $14/month

### Production Setup (Serious Traffic)
- **Web Service**: $25/month (Standard plan)
- **PostgreSQL**: $25/month (Standard plan)
- **Redis**: $10/month (Optional, for caching)
- **Background Worker**: $7/month (Starter plan)
- **Total**: $67/month (without Redis)

## Security Checklist

Before launching:

- [x] SSL enabled automatically (Render handles this)
- [x] `config.force_ssl = true` in production.rb
- [x] Allowed hosts configured
- [x] RAILS_MASTER_KEY is set (not in git)
- [x] CLAUDE_API_KEY is set securely
- [x] Database password is auto-generated by Render
- [x] Environment variables are encrypted at rest
- [ ] Set up monitoring/alerting
- [ ] Configure database backups (automatic on Render)
- [ ] Review Render security docs: https://render.com/docs/security

## Support and Resources

- **Render Documentation**: https://render.com/docs
- **Render Community Forum**: https://community.render.com/
- **Render Status**: https://status.render.com/
- **Rails Deployment Guide**: https://guides.rubyonrails.org/deployment.html

## Quick Reference

### Your App URLs

- **Web App**: `https://your-app-name.onrender.com`
- **Health Check**: `https://your-app-name.onrender.com/up`
- **Dashboard**: `https://dashboard.render.com/`

### Required Environment Variables

| Variable | Where to Set | Value |
|----------|--------------|-------|
| `RAILS_MASTER_KEY` | Render Dashboard | From `config/master.key` |
| `CLAUDE_API_KEY` | Render Dashboard | From Anthropic console |
| `DATABASE_URL` | Auto-set by Render | PostgreSQL connection string |

### Required Databases

| Database Name | Purpose |
|---------------|---------|
| `golfcoachapp_production` | Main app data (auto-created) |
| `golfcoachapp_production_cache` | Solid Cache (manual create) |
| `golfcoachapp_production_queue` | Solid Queue (manual create) |
| `golfcoachapp_production_cable` | Action Cable (manual create) |

---

## Next Steps

1. ✅ Deploy to Render using Blueprint
2. ✅ Set environment variables (RAILS_MASTER_KEY, CLAUDE_API_KEY)
3. ✅ Create additional databases
4. ✅ Run migrations
5. ✅ Test the application
6. 🎉 Share your Golf Coach App with the world!

**Need help?** Check the Troubleshooting section or reach out to Render support.
