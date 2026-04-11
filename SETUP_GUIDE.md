# Worklenz — Local Development Setup Guide

> **Last Updated:** April 2026
> **Platform:** Docker Desktop (Windows / macOS / Linux)
> **Time Required:** ~10 minutes

---

## Prerequisites

Before you begin, make sure you have:

| Tool | Version | Download |
|------|---------|----------|
| **Docker Desktop** | 4.x+ | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| **Git** | Any | [git-scm.com](https://git-scm.com/) |
| **Text Editor** | Any | VS Code recommended |

> [!IMPORTANT]
> Docker Desktop must be **running** before you proceed. Verify with `docker --version` in your terminal.

---

## Step 1: Clone the Repository

```bash
git clone <your-repo-url> worklenz
cd worklenz
```

---

## Step 2: Configure Environment Variables

The project includes a pre-configured `.env` file with sensible defaults. **No changes are required for local development.**

If you want to review/customize the config:

```bash
# Open .env in your editor and review the following sections:
# - DB_PASSWORD (default: Worklenz_DB_Pass_2024)
# - REDIS_PASSWORD (default: Worklenz_Redis_Pass_2024)  
# - SESSION_SECRET, COOKIE_SECRET, JWT_SECRET (pre-generated)
```

> [!NOTE]
> For production deployments, you MUST change all passwords and secrets. For local development, the defaults work fine.

---

## Step 3: Add MinIO Hostname (REQUIRED)

The file storage system (MinIO) runs inside Docker but the browser needs to access it directly to display uploaded images/files. You must add a hostname mapping.

### Windows
1. Open **Notepad as Administrator** (right-click → Run as Administrator)
2. Open the file: `C:\Windows\System32\drivers\etc\hosts`
3. Add this line at the bottom:
   ```
   127.0.0.1 minio
   ```
4. Save and close

### macOS / Linux
```bash
echo "127.0.0.1 minio" | sudo tee -a /etc/hosts
```

### Verify it works:
```bash
ping minio
# Should resolve to 127.0.0.1
```

> [!WARNING]
> If you skip this step, file uploads will work but **images/attachments won't display** in the browser. You'll see broken image icons instead.

---

## Step 4: Start the Application

```bash
docker compose up -d
```

This will pull images and start all services. **First run takes 3–5 minutes** (subsequent starts are instant).

### Wait for all services to become healthy:

```bash
docker compose ps
```

You should see all services as `Up (healthy)`:

```
NAME                 STATUS
worklenz-postgres    Up (healthy)
worklenz-redis       Up (healthy)
worklenz-minio       Up (healthy)
worklenz-minio-init  Exited (0)     ← This is normal, it's a one-time init job
worklenz-backend     Up (healthy)
worklenz-frontend    Up (healthy)
worklenz-nginx       Up (healthy)
```

> [!TIP]
> If `worklenz-backend` stays in `(health: starting)` for more than 2 minutes, check the logs: `docker compose logs backend --tail 50`

---

## Step 5: Open the Application

Open your browser and navigate to:

```
http://localhost/worklenz
```

### First-Time Setup:
1. Click **"Sign Up"** to create your admin account
2. Fill in your name, email, and password
3. Complete the onboarding wizard (organization name, role, first project)
4. You'll land on the Home dashboard — you're ready to go! 🎉

---

## Architecture Overview

```
┌──────────────────────────────────────────────┐
│                   Browser                     │
│              http://localhost                  │
└─────────────────────┬────────────────────────┘
                      │
              ┌───────▼────────┐
              │   Nginx :80    │  ← Reverse proxy
              └───┬────────┬───┘
                  │        │
         /api/*   │        │  /*
                  │        │
          ┌───────▼──┐  ┌──▼───────┐
          │ Backend  │  │ Frontend │
          │ :3000    │  │ :4200    │
          └──┬───┬───┘  └──────────┘
             │   │
     ┌───────▼┐ ┌▼────────┐
     │Postgres│ │  Redis   │
     │ :5432  │ │  :6379   │
     └────────┘ └──────────┘
                      
          ┌──────────┐
          │  MinIO   │  ← S3-compatible file storage
          │ :9000    │
          └──────────┘
```

---

## Common Commands

### Start / Stop

```bash
# Start all services
docker compose up -d

# Stop all services (preserves data)
docker compose down

# Stop and DELETE all data (fresh start)
docker compose down -v
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f postgres
docker compose logs -f frontend
```

### Rebuild After Code Changes

```bash
# Backend changes only
docker compose build --no-cache backend
docker compose up -d --force-recreate backend

# Frontend changes only
docker compose build --no-cache frontend
docker compose up -d --force-recreate frontend

# Everything
docker compose build --no-cache
docker compose up -d --force-recreate
```

### Database Access

```bash
# Open a psql shell
docker exec -it worklenz-postgres psql -U postgres -d worklenz_db

# Run a specific SQL file
docker exec -i worklenz-postgres psql -U postgres -d worklenz_db < path/to/file.sql
```

### MinIO Console (File Storage Admin)

Open `http://localhost:9001` in your browser.
- **Username:** `minioadmin`
- **Password:** `Worklenz_Minio_Pass_2024`

---

## Project Structure

```
worklenz/
├── worklenz-backend/          # Node.js + Express API server
│   ├── src/
│   │   ├── controllers/       # Route handlers & business logic
│   │   ├── routes/            # API route definitions
│   │   ├── config/            # Database & service configs
│   │   ├── shared/            # Utilities, constants, SQL helpers
│   │   └── socket.io/         # Real-time WebSocket handlers
│   └── database/
│       └── sql/               # Schema, functions, migrations
│           ├── 1_tables.sql   # Table definitions
│           ├── 4_functions.sql # Stored procedures
│           └── migrations/    # Schema migration scripts
│
├── worklenz-frontend/         # React + TypeScript SPA
│   ├── src/
│   │   ├── pages/             # Page components (Home, Projects, Reporting)
│   │   ├── features/          # Redux slices & feature modules
│   │   ├── components/        # Reusable UI components
│   │   ├── api/               # API service modules
│   │   └── types/             # TypeScript type definitions
│   └── public/                # Static assets
│
├── nginx/                     # Nginx reverse proxy config
├── scripts/                   # Database init & utility scripts
├── docker-compose.yaml        # Service orchestration
├── .env                       # Environment configuration
└── SETUP_GUIDE.md            # ← You are here
```

---

## Troubleshooting

### "Cannot connect to server" / Blank page
1. Check all containers are running: `docker compose ps`
2. Wait for healthchecks: backend takes 10–15 seconds after starting
3. Try hard-refreshing: `Ctrl + Shift + R`

### Broken images / attachments not displaying
You forgot Step 3 (hosts file). Add `127.0.0.1 minio` to your hosts file and refresh.

### "Unknown error has occurred" on Reporting filters
This was a known bug that has been fixed. If you see it, rebuild the backend:
```bash
docker compose build --no-cache backend && docker compose up -d --force-recreate backend
```

### Backend crashes on startup with DB errors
If the database was initialized with an older schema, run the migration:
```bash
docker exec -i worklenz-postgres psql -U postgres -d worklenz_db -f /database/sql/migrations/001_add_missing_project_columns.sql
```

### Port 80 already in use
Another service (IIS, Apache, Skype) is using port 80. Either:
- Stop that service, OR
- Change `HTTP_PORT=80` to another port (e.g., `8080`) in `.env`, then access via `http://localhost:8080`

### Fresh start (reset everything)
```bash
docker compose down -v    # Removes all containers AND data volumes
docker compose up -d      # Rebuilds from scratch
```
> [!CAUTION]
> `docker compose down -v` will **delete all your data** including projects, tasks, and user accounts. After reset, you'll need to repeat Step 3 (hosts file is preserved) and create a new account.

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, TypeScript, Ant Design, Redux Toolkit |
| Backend | Node.js, Express, TypeScript |
| Database | PostgreSQL 15 |
| Cache | Redis 7 |
| File Storage | MinIO (S3-compatible) |
| Reverse Proxy | Nginx |
| Real-time | Socket.IO |
| Containerization | Docker Compose |

---

## Need Help?

- Check backend logs: `docker compose logs backend --tail 100`
- Check frontend logs: `docker compose logs frontend --tail 100`
- Check database logs: `docker compose logs postgres --tail 100`
- Inspect a container: `docker exec -it worklenz-backend sh`
