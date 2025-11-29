# Render Deployment Checklist

## ✅ Configuration Complete

Your Golf Coach App is now configured for Render deployment. Here's what was done:

### Files Created
- ✅ `render.yaml` - Render Blueprint configuration (infrastructure as code)
- ✅ `RENDER_DEPLOYMENT.md` - Complete step-by-step deployment guide
- ✅ `bin/check_deploy_readiness` - Script to verify deployment readiness
- ✅ `DEPLOYMENT_CHECKLIST.md` - This file

### Files Updated
- ✅ `config/environments/production.rb` - Configured for Render (SSL, hosts, etc.)
- ✅ `.env.example` - Added all required environment variables
- ✅ `README.md` - Added deployment section
- ✅ `.kamal/secrets` - Updated with deployment secrets guide
- ✅ `config/deploy.yml` - Added notes about Render (kept for reference)

### What's Configured

**Automatic via render.yaml:**
- Web service (Rails app)
- PostgreSQL database
- SSL certificates (automatic)
- Zero-downtime deployments
- Auto-deploy from Git
- Health checks
- Environment variables structure

**Production Settings:**
- SSL enabled (`config.force_ssl = true`)
- Secure hosts configured (`.onrender.com` domains)
- Logging to STDOUT (required by Render)
- Static assets serving enabled
- Solid Queue running in Puma process

## 📋 Pre-Deployment Checklist

Before deploying, complete these steps:

### 1. Get Your Secrets Ready

You'll need these values for Render dashboard:

- [ ] **RAILS_MASTER_KEY**: Run `cat config/master.key` to get it
- [ ] **CLAUDE_API_KEY**: Get from https://console.anthropic.com/

### 2. Prepare Git Repository

- [ ] Commit all changes:
  ```bash
  git add .
  git commit -m "Configure for Render deployment"
  ```

- [ ] Push to GitHub (or GitLab/Bitbucket):
  ```bash
  git push origin main
  ```

### 3. Verify Readiness

- [ ] Run the readiness check:
  ```bash
  bin/check_deploy_readiness
  ```

- [ ] Fix any errors reported by the script

### 4. Create Render Account

- [ ] Sign up at https://render.com/ (free tier available)
- [ ] Connect your GitHub account
- [ ] Authorize Render to access your repositories

## 🚀 Deployment Steps

### Option 1: One-Click Deploy (Easiest)

1. Go to your repository on GitHub
2. Click "Deploy to Render" badge (or use Blueprint in Render dashboard)
3. Select your repo
4. Render auto-detects `render.yaml`
5. Click "Apply"

### Option 2: Manual Dashboard Deploy

Follow the detailed instructions in [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md)

## ⚙️ Post-Deployment Steps

After Render creates your services:

### 1. Add Environment Variables

In Render Dashboard → Your Web Service → Environment:

```
RAILS_MASTER_KEY = (from config/master.key)
CLAUDE_API_KEY = sk-ant-your-key-here
```

### 2. Create Additional Databases

Your app needs 4 databases total. Render creates 1, you need to create 3 more:

```sql
CREATE DATABASE golfcoachapp_production_cache;
CREATE DATABASE golfcoachapp_production_queue;
CREATE DATABASE golfcoachapp_production_cable;
```

See RENDER_DEPLOYMENT.md Step 5 for detailed instructions.

### 3. Run Migrations

In Render Dashboard → Your Web Service → Shell:

```bash
bin/rails db:migrate
```

### 4. Verify Deployment

- [ ] Check logs for errors
- [ ] Visit health endpoint: `https://your-app.onrender.com/up`
- [ ] Visit app: `https://your-app.onrender.com`
- [ ] Test user signup
- [ ] Test golf round entry
- [ ] Test handicap calculation (verifies Claude API)
- [ ] Test training plan generation (verifies Claude API)

## 🎯 Quick Commands Reference

```bash
# Check deployment readiness
bin/check_deploy_readiness

# View your master key
cat config/master.key

# Commit changes
git add .
git commit -m "Ready for deployment"
git push origin main

# After deployment - run migrations (in Render Shell)
bin/rails db:migrate

# Access Rails console on Render (in Render Shell)
bin/rails console
```

## 📚 Resources

- **Complete Deployment Guide**: [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md)
- **Render Documentation**: https://render.com/docs
- **Render Community**: https://community.render.com/

## 🆘 Troubleshooting

### "Build failed"
- Check Dockerfile syntax
- Ensure all files are committed to Git
- Try "Clear build cache & deploy" in Render

### "Database connection error"
- Verify DATABASE_URL is set
- Check database service is running
- Ensure all 4 databases are created

### "Claude API error"
- Verify CLAUDE_API_KEY is set in environment variables
- Check key starts with `sk-ant-`
- Test key at https://console.anthropic.com/

### "Assets not loading"
- Check build logs for asset precompilation errors
- Verify RAILS_ENV=production
- Check `public/assets` directory exists in container

For more troubleshooting, see RENDER_DEPLOYMENT.md "Troubleshooting" section.

## 💰 Cost Overview

### Free Tier
- Web service: Free (with limitations - spins down after 15 min)
- PostgreSQL: Free (1 GB storage)
- **Total: $0/month**

### Starter (Recommended)
- Web service: $7/month (always on)
- PostgreSQL: $7/month (with backups)
- **Total: $14/month**

### Production
- Web service: $25/month
- PostgreSQL: $25/month
- **Total: $50/month**

## ✨ What You Get with Render

- ✅ Automatic SSL certificates (HTTPS)
- ✅ Zero-downtime deployments
- ✅ Automatic deploys from Git
- ✅ Managed PostgreSQL with backups
- ✅ Free tier to start
- ✅ No credit card required for free tier
- ✅ Built-in monitoring and logs
- ✅ Easy scaling (vertical and horizontal)

## 🎉 Ready to Deploy?

1. Complete the Pre-Deployment Checklist above
2. Follow [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md)
3. Have your Golf Coach App live in under 10 minutes!

---

**Questions?** Check [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md) for detailed instructions and troubleshooting.
