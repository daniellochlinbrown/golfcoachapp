# Golf Coach App - Deployment Guide

This guide walks you through deploying your Golf Coach App to production using Kamal 2.

## Prerequisites

Before deploying, ensure you have:

- [ ] A production server (Linux VM with Docker installed)
- [ ] SSH access to your server with root or sudo privileges
- [ ] A container registry account (Docker Hub, GitHub, or DigitalOcean)
- [ ] A PostgreSQL database (managed service or self-hosted)
- [ ] Your Claude API key from https://console.anthropic.com/
- [ ] A domain name (optional but recommended)

## Step 1: Prepare Your Server

### Server Requirements

- **OS**: Ubuntu 22.04 or newer (recommended)
- **RAM**: Minimum 2GB, 4GB+ recommended
- **Storage**: 20GB+ available
- **Ports**: 80 (HTTP), 443 (HTTPS), 22 (SSH)

### Install Docker on Server

SSH into your server and run:

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Allow non-root Docker (optional)
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

## Step 2: Set Up PostgreSQL Database

Your app requires **4 PostgreSQL databases**:
1. `golfcoachapp_production` - Main application data
2. `golfcoachapp_production_cache` - Solid Cache storage
3. `golfcoachapp_production_queue` - Solid Queue job storage
4. `golfcoachapp_production_cable` - Action Cable pub/sub

### Option A: Use Managed PostgreSQL (Recommended)

**Popular providers:**
- **Heroku Postgres**: https://www.heroku.com/postgres
- **DigitalOcean Managed Databases**: https://www.digitalocean.com/products/managed-databases
- **AWS RDS**: https://aws.amazon.com/rds/postgresql/
- **Railway**: https://railway.app/
- **Render**: https://render.com/docs/databases

After creating your database:

1. Create all 4 databases:
```sql
CREATE DATABASE golfcoachapp_production;
CREATE DATABASE golfcoachapp_production_cache;
CREATE DATABASE golfcoachapp_production_queue;
CREATE DATABASE golfcoachapp_production_cable;
```

2. Note your connection details:
   - Host
   - Port (usually 5432)
   - Username
   - Password
   - Database name

3. Set the password as an environment variable:
```bash
export GOLFCOACHAPP_DATABASE_PASSWORD="your_password_here"
```

### Option B: Run PostgreSQL on Same Server

Uncomment the accessories section in `config/deploy.yml` and follow the inline instructions.

## Step 3: Configure Container Registry

Choose one of these options and complete the setup:

### Option A: Docker Hub

1. Create account at https://hub.docker.com/
2. Create a new repository named `golfcoachapp`
3. Generate an access token:
   - Settings → Security → New Access Token
4. Export the token:
```bash
export DOCKER_HUB_TOKEN="your_token_here"
```

5. Update `config/deploy.yml`:
```yaml
image: yourusername/golfcoachapp

registry:
  server: hub.docker.com
  username: yourusername
  password:
    - KAMAL_REGISTRY_PASSWORD
```

6. Update `.kamal/secrets`:
```bash
KAMAL_REGISTRY_PASSWORD=${DOCKER_HUB_TOKEN:?DOCKER_HUB_TOKEN must be set}
```

### Option B: GitHub Container Registry

1. Create a Personal Access Token:
   - GitHub Settings → Developer settings → Personal access tokens → Generate new token
   - Select scopes: `write:packages`, `read:packages`, `delete:packages`

2. Export the token:
```bash
export GITHUB_TOKEN="your_token_here"
```

3. Update `config/deploy.yml`:
```yaml
image: ghcr.io/yourusername/golfcoachapp

registry:
  server: ghcr.io
  username: yourusername
  password:
    - KAMAL_REGISTRY_PASSWORD
```

4. Update `.kamal/secrets`:
```bash
KAMAL_REGISTRY_PASSWORD=${GITHUB_TOKEN:?GITHUB_TOKEN must be set}
```

## Step 4: Configure Environment Variables

1. Set your Claude API key:
```bash
export CLAUDE_API_KEY="sk-ant-your-key-here"
```

2. If using external database, set database password:
```bash
export GOLFCOACHAPP_DATABASE_PASSWORD="your_db_password"
```

3. Update `config/deploy.yml` with your server IP:
```yaml
servers:
  web:
    - 12.34.56.78  # Replace with your actual server IP
```

4. Update database host in `config/deploy.yml`:
```yaml
env:
  clear:
    DB_HOST: your-postgres-host.com  # Your PostgreSQL server hostname
```

## Step 5: Configure Production Settings

1. Update `config/environments/production.rb`:

```ruby
# Set your production domain
config.action_mailer.default_url_options = { host: "yourdomain.com" }

# Enable SSL (if you have SSL certificate)
config.force_ssl = true
config.assume_ssl = true

# Configure allowed hosts
config.hosts = [
  "yourdomain.com",
  "www.yourdomain.com",
  "your-server-ip"
]
```

2. If using a domain, update `config/deploy.yml`:
```yaml
proxy:
  ssl: true
  host: yourdomain.com
```

## Step 6: Prepare for Deployment

1. Ensure your `.env` file is NOT committed to git:
```bash
# Check .gitignore includes .env
grep ".env" .gitignore
```

2. Verify Rails master key exists:
```bash
cat config/master.key
```

If missing, generate it:
```bash
EDITOR=nano bin/rails credentials:edit
```

3. Test that secrets are properly configured:
```bash
# This should show your secrets without errors
bin/kamal secrets fetch
```

## Step 7: Deploy to Production

### First-Time Deployment

1. Set up the server (installs accessories, creates volumes):
```bash
bin/kamal setup
```

2. This command will:
   - Connect to your server via SSH
   - Start any accessories (databases, redis, etc.)
   - Build your Docker image
   - Push to container registry
   - Deploy the application
   - Run database migrations
   - Start the web server

### Subsequent Deployments

For updates after the initial deployment:

```bash
bin/kamal deploy
```

This performs a zero-downtime deployment by:
1. Building new Docker image
2. Pushing to registry
3. Starting new container
4. Running migrations
5. Switching traffic to new container
6. Stopping old container

## Step 8: Run Database Migrations

Migrations run automatically during deployment, but you can run them manually:

```bash
bin/kamal app exec "bin/rails db:migrate"
```

To create all 4 production databases:
```bash
bin/kamal app exec "bin/rails db:create"
```

## Step 9: Verify Deployment

1. Check application status:
```bash
bin/kamal app details
```

2. View logs:
```bash
bin/kamal app logs
```

3. Access Rails console:
```bash
bin/kamal console
```

4. Check health endpoint:
```bash
curl http://your-server-ip/up
```

5. Visit your application:
   - With domain: `https://yourdomain.com`
   - With IP: `http://your-server-ip`

## Common Kamal Commands

```bash
# View all logs
bin/kamal app logs -f

# Access Rails console
bin/kamal console

# SSH into the server
bin/kamal app exec --interactive --reuse bash

# Restart the application
bin/kamal app restart

# View running containers
bin/kamal app containers

# Rollback to previous version
bin/kamal rollback

# Remove everything and start fresh
bin/kamal remove
```

## Troubleshooting

### Database Connection Errors

If you see "could not connect to server":

1. Verify database host and credentials:
```bash
bin/kamal app exec "bin/rails dbconsole"
```

2. Check if DB_HOST is set:
```bash
bin/kamal app exec "env | grep DB"
```

3. Ensure all 4 databases exist:
```bash
psql -h your-host -U username -l
```

### Claude API Errors

If training plans fail with "API key not found":

1. Verify CLAUDE_API_KEY is set:
```bash
bin/kamal app exec "env | grep CLAUDE"
```

2. Check the key in .kamal/secrets:
```bash
echo $CLAUDE_API_KEY
```

### Asset Loading Issues

If CSS/JS files return 404:

1. Precompile assets locally first:
```bash
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
```

2. Verify assets exist in container:
```bash
bin/kamal app exec "ls -la public/assets"
```

### Container Registry Authentication

If you see "unauthorized" errors:

1. Test registry login locally:
```bash
docker login hub.docker.com  # or ghcr.io, etc.
```

2. Verify KAMAL_REGISTRY_PASSWORD is set:
```bash
bin/kamal secrets fetch
```

## Security Checklist

Before going live:

- [ ] SSL/TLS enabled (`config.force_ssl = true`)
- [ ] Allowed hosts configured
- [ ] Database password is strong and unique
- [ ] `config/master.key` is NOT in git
- [ ] `.env` file is NOT in git
- [ ] Claude API key is kept secure
- [ ] Container registry uses access tokens (not passwords)
- [ ] Server firewall configured (only ports 80, 443, 22 open)
- [ ] Regular database backups scheduled
- [ ] Monitoring/alerting set up

## Performance Optimization

For better production performance:

1. **Increase web concurrency** in `config/deploy.yml`:
```yaml
env:
  clear:
    WEB_CONCURRENCY: 2  # Adjust based on server RAM
```

2. **Enable Solid Queue workers** for background jobs:
```yaml
env:
  clear:
    JOB_CONCURRENCY: 3
```

3. **Use CDN** for static assets (optional)

4. **Database connection pooling** - Already configured in `config/database.yml`

## Monitoring and Maintenance

### View Application Logs

```bash
# Real-time logs
bin/kamal app logs -f

# Last 100 lines
bin/kamal app logs --lines 100

# Filter by severity
bin/kamal app logs | grep ERROR
```

### Database Maintenance

```bash
# Create backup
bin/kamal app exec "bin/rails db:dump"

# Run migrations
bin/kamal app exec "bin/rails db:migrate"

# Access database console
bin/kamal dbc
```

### Update Application

1. Make your code changes
2. Commit to git
3. Deploy:
```bash
bin/kamal deploy
```

## Scaling Considerations

When your app grows:

1. **Multiple Servers**: Add more IPs to `servers.web` array
2. **Separate Job Server**: Uncomment `servers.job` in config/deploy.yml
3. **External Redis**: For Action Cable in multi-server setup
4. **Load Balancer**: Use proxy configuration in deploy.yml
5. **Database Replication**: Configure read replicas in database.yml

## Support Resources

- **Kamal Documentation**: https://kamal-deploy.org/
- **Rails Deployment Guide**: https://guides.rubyonrails.org/deployment.html
- **Troubleshooting Issues**: Check logs with `bin/kamal app logs`

## Quick Reference: Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CLAUDE_API_KEY` | Yes | Anthropic API key for AI features |
| `RAILS_MASTER_KEY` | Yes | Rails encrypted credentials key |
| `KAMAL_REGISTRY_PASSWORD` | Yes | Container registry access token |
| `GOLFCOACHAPP_DATABASE_PASSWORD` | Yes* | PostgreSQL password |
| `DB_HOST` | Yes* | PostgreSQL server hostname |
| `WEB_CONCURRENCY` | No | Number of Puma workers (default: 1) |
| `JOB_CONCURRENCY` | No | Solid Queue workers (default: 1) |

*Required if using external PostgreSQL database

---

**Ready to Deploy?** Follow the steps above in order, and you'll have your Golf Coach App running in production!
