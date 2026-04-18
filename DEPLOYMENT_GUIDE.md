# Worklenz — Production Deployment Guide

> **For:** Server/DevOps team deploying Worklenz on DigitalOcean or any Linux VPS
> **Last Updated:** April 2026

---

## Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **RAM** | 2 GB | 4 GB |
| **CPU** | 2 vCPU | 4 vCPU |
| **Disk** | 20 GB SSD | 50 GB SSD |
| **OS** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| **Ports** | 80, 443 | 80, 443 |

---

## Step 1: Install Docker on the Server

```bash
ssh root@YOUR_SERVER_IP

# Install Docker
curl -fsSL https://get.docker.com | sh
apt install docker-compose-plugin -y

# Verify
docker --version
docker compose version
```

---

## Step 2: Clone the Repository

```bash
git clone https://github.com/VinitChaudhari85/worklenz-fixed.git
cd worklenz-fixed
```

---

## Step 3: Configure Environment

```bash
cp .env.example .env
nano .env
```

### Required Changes (MUST do before starting)

Replace `YOUR_DOMAIN_OR_IP` with your server's public IP (e.g., `164.92.100.50`) or domain name (e.g., `tasks.yourcompany.com`):

```env
# ============================================
# DOMAIN & URL CONFIGURATION
# ============================================
DOMAIN=YOUR_DOMAIN_OR_IP
VITE_API_URL=http://YOUR_DOMAIN_OR_IP
VITE_SOCKET_URL=ws://YOUR_DOMAIN_OR_IP
FRONTEND_URL=http://YOUR_DOMAIN_OR_IP
SOCKET_IO_CORS=http://YOUR_DOMAIN_OR_IP

# ============================================
# FILE STORAGE — REQUIRED for images to work!
# ============================================
# S3_URL stays as-is (internal Docker communication)
S3_URL=http://minio:9000
# S3_PUBLIC_URL is what browsers use to load images/files
S3_PUBLIC_URL=http://YOUR_DOMAIN_OR_IP:9000

# ============================================
# PASSWORDS — Change ALL of these!
# ============================================
DB_PASSWORD=YourStrongDBPassword123!
REDIS_PASSWORD=YourStrongRedisPass456!
AWS_SECRET_ACCESS_KEY=YourStrongMinioPass789!

# ============================================
# SECURITY SECRETS — Generate unique values!
# Run this command 3 times: openssl rand -hex 32
# Use a different output for each:
# ============================================
SESSION_SECRET=<paste_first_output_here>
COOKIE_SECRET=<paste_second_output_here>
JWT_SECRET=<paste_third_output_here>
```

**How to generate secrets:**
```bash
openssl rand -hex 32
# Run 3 times, copy each output into the corresponding field above
```

### Settings you can leave as default

| Variable | Default | Notes |
|----------|---------|-------|
| `DEPLOYMENT_MODE` | `express` | Keep as-is for bundled setup |
| `DB_NAME` | `worklenz_db` | No need to change |
| `DB_USER` | `postgres` | No need to change |
| `HTTP_PORT` | `80` | Change only if port 80 is occupied |
| `AWS_ACCESS_KEY_ID` | `minioadmin` | MinIO admin username |
| `AWS_BUCKET` | `worklenz-bucket` | Storage bucket name |
| `STORAGE_PROVIDER` | `s3` | Keep as-is (uses MinIO) |

---

## Step 4: Add MinIO Hostname

```bash
echo "127.0.0.1 minio" >> /etc/hosts
```

**Why:** The file storage service (MinIO) uses the hostname `minio` internally. This entry ensures file URLs resolve correctly on the server.

> **Note on image/attachment display:** Files uploaded by users generate URLs like `http://minio:9000/worklenz-bucket/file.png`. The server resolves this because of the hosts entry. However, **end users' browsers** may not be able to resolve `minio` — in which case uploaded images will show as broken icons. See the [Image Fix for End Users](#image-fix-for-end-users) section below for the production solution.

---

## Step 5: Start the Application

```bash
docker compose up -d
```

**First run takes 3–5 minutes.** Check status with:

```bash
docker compose ps
```

All services should show `Up (healthy)`:

```
worklenz-postgres    Up (healthy)
worklenz-redis       Up (healthy)
worklenz-minio       Up (healthy)
worklenz-minio-init  Exited (0)      ← Normal
worklenz-backend     Up (healthy)
worklenz-frontend    Up (healthy)
worklenz-nginx       Up (healthy)
```

---

## Step 6: Access and Create Admin Account

Open in browser:

```
http://YOUR_DOMAIN_OR_IP/worklenz
```

1. Click **Sign Up**
2. Create the admin account (this becomes the organization owner)
3. Complete the onboarding wizard
4. Invite team members via the **Invite** button

---

## Image Fix for End Users

The `S3_PUBLIC_URL` setting in `.env` (configured in Step 3 above) handles this automatically. When set to `http://YOUR_SERVER_IP:9000`, all file/image URLs in the app will use the server's public IP instead of the internal Docker hostname.

**Important:** Port 9000 must be accessible from the internet. Make sure your firewall allows it:
```bash
ufw allow 9000
```

If you **don't want to expose port 9000**, you can proxy MinIO through Nginx instead:

1. Edit `nginx/conf.d/worklenz.conf` and add this block **before** the `location /` block:

```nginx
location /minio-storage/ {
    proxy_pass http://minio:9000/;
    proxy_http_version 1.1;
    proxy_set_header Host minio:9000;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

2. Set `S3_PUBLIC_URL=http://YOUR_DOMAIN_OR_IP/minio-storage` in `.env`

3. Restart: `docker compose down && docker compose up -d`

---

## HTTPS / SSL Setup (Optional but Recommended)

If you have a domain name and want HTTPS:

### 1. Point DNS to your server

Create an **A record** in your DNS settings:
```
tasks.yourcompany.com → YOUR_SERVER_IP
```

### 2. Update `.env` for HTTPS

```env
DOMAIN=tasks.yourcompany.com
VITE_API_URL=https://tasks.yourcompany.com
VITE_SOCKET_URL=wss://tasks.yourcompany.com
FRONTEND_URL=https://tasks.yourcompany.com
SOCKET_IO_CORS=https://tasks.yourcompany.com
LETSENCRYPT_EMAIL=admin@yourcompany.com
```

### 3. Start with SSL profile

```bash
docker compose down
docker compose --profile ssl up -d
```

This automatically provisions a free Let's Encrypt certificate.

---

## Common Operations

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend --tail 100
docker compose logs -f postgres --tail 100
```

### Restart Services

```bash
# Restart everything
docker compose restart

# Restart specific service
docker compose restart backend
```

### Rebuild After Code Update

```bash
git pull
docker compose build --no-cache
docker compose up -d --force-recreate
```

### Backup Database

```bash
docker exec worklenz-postgres pg_dump -U postgres worklenz_db > backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
docker exec -i worklenz-postgres psql -U postgres -d worklenz_db < backup_20260418.sql
```

### MinIO Admin Console

```
URL:      http://YOUR_DOMAIN_OR_IP:9001
Username: minioadmin  (or your AWS_ACCESS_KEY_ID value)
Password: (your AWS_SECRET_ACCESS_KEY value)
```

### Complete Reset (Wipe Everything)

```bash
docker compose down -v    # Deletes ALL data
docker compose up -d      # Fresh start
```

> ⚠️ This permanently deletes all projects, tasks, users, and uploaded files.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Page won't load** | Wait 2 minutes for all services to start. Check: `docker compose ps` |
| **"Cannot connect to server"** | Check backend logs: `docker compose logs backend --tail 50` |
| **Broken images** | See [Image Fix for End Users](#image-fix-for-end-users) above |
| **Port 80 in use** | Change `HTTP_PORT=8080` in `.env`, access via `:8080` |
| **WebSocket errors** | Ensure `VITE_SOCKET_URL` matches your domain with correct protocol (`ws://` or `wss://`) |
| **Backend restart loop** | Usually database isn't ready. Wait 2 min and check: `docker compose logs backend` |
| **Out of memory** | Server needs minimum 2 GB RAM. Check: `free -m` |

---

## Firewall Configuration

Ensure these ports are open on your server:

| Port | Service | Required |
|------|---------|----------|
| 22 | SSH | Yes |
| 80 | HTTP | Yes |
| 443 | HTTPS | Only if using SSL |
| 9000 | MinIO API | Yes (for file/image access from browsers) |
| 9001 | MinIO Console | Optional (admin access) |

**DigitalOcean Firewall:**
```
Inbound rules: SSH (22), HTTP (80), HTTPS (443)
```

**UFW (Ubuntu):**
```bash
ufw allow 22
ufw allow 80
ufw allow 443
ufw enable
```

---

## Architecture

```
     Users' Browsers
           │
    ┌──────▼──────┐
    │  Nginx :80  │  ← Reverse proxy (only exposed port)
    └───┬─────┬───┘
        │     │
  /api/ │     │ /*
        │     │
  ┌─────▼─┐ ┌▼───────┐
  │Backend│ │Frontend │
  │ :3000 │ │ :5000   │
  └┬──┬──┬┘ └─────────┘
   │  │  │
   ▼  ▼  ▼
 [PostgreSQL] [Redis] [MinIO]
   :5432      :6379    :9000
```

All services run inside Docker. Only Nginx port 80/443 is exposed externally.

---

## Quick Checklist

Before going live, verify:

- [ ] `.env` file created from `.env.example`
- [ ] All `localhost` values replaced with server IP/domain
- [ ] `S3_PUBLIC_URL` set to `http://YOUR_SERVER_IP:9000`
- [ ] All default passwords changed
- [ ] All 3 secrets regenerated (`SESSION_SECRET`, `COOKIE_SECRET`, `JWT_SECRET`)
- [ ] `127.0.0.1 minio` added to server's `/etc/hosts`
- [ ] Port 9000 open in firewall (`ufw allow 9000`)
- [ ] `docker compose ps` shows all services healthy
- [ ] Can access `http://YOUR_IP/worklenz` in browser
- [ ] Can sign up and create a project
- [ ] Can upload a file attachment and see it display
- [ ] Firewall allows ports 80 (and 443 if using SSL)
