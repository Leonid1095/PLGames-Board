# 🚀 One-Command Installation

> Install PLGames Board on any Linux server with a single command

## Quick Start (90 seconds)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/install.sh)
```

The script will:
- ✅ Check Docker & disk space
- ✅ Ask for domain (localhost or your domain)
- ✅ Download pre-built images (no compilation needed)
- ✅ Set up secure database
- ✅ Configure firewall (optional)
- ✅ Start all services

**Done!** Open your domain in browser → create account → start collaborating!

---

## Why This Works Everywhere

**Traditional Docker approach:**
- ❌ Builds locally → needs Rust, Node.js, 30 min → fails in Russia on Prisma engines
- ❌ Network-dependent
- ❌ Requires strong machine resources

**Our approach:**
- ✅ GitHub Actions builds once (USA) → images to GHCR
- ✅ Any server just downloads ready images (5-10 min)
- ✅ Works in Russia, China, anywhere with internet
- ✅ No compilation needed

---

## What You Need

- **Linux server** (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- **4GB RAM** (8GB+ recommended)
- **20GB disk space**
- **Docker + Docker Compose** (installer checks this)
- **Stable internet** (to download images)

---

## Documentation

- 📖 **Full Guide:** [`INSTALLATION_GUIDE.md`](INSTALLATION_GUIDE.md)
- 🏗️ **Architecture:** [`ARCHITECTURE.md`](ARCHITECTURE.md)
- 🌍 **Russia-Specific:** [`DEPLOYMENT_RUSSIA.md`](DEPLOYMENT_RUSSIA.md)
- ⚙️ **Configuration:** [`.env.example`](.env.example)

---

## Key Features

✨ **Collaborative Workspace**
- Real-time document editing
- Whiteboard & canvas
- Database views (Kanban, Table, List)
- Full-text search

🔐 **Secure & Private**
- Self-hosted on your server
- No cloud, no data leaks
- PostgreSQL + Redis
- Auto HTTPS with Let's Encrypt

⚡ **Easy Operations**
- One-command install
- Docker-based (easy backup/restore)
- Auto-updates
- Health monitoring

---

## Usage Examples

### First Time
```bash
# Run installer
bash <(curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/install.sh)

# Answer questions
# Wait 2 minutes
# Open browser to your domain
# Register admin account
```

### Common Commands
```bash
# Check status
docker compose ps

# View logs
docker compose logs -f backend

# Restart
docker compose restart

# Update
cd ~/plgames-board && git pull && docker compose pull && docker compose up -d

# Backup
docker compose exec postgres pg_dump -U plgames plgames > backup.sql

# Stop
docker compose down
```

---

## System Architecture

```
┌─────────────────────────────────────────────┐
│   PLGames Board (Your Server)               │
├─────────────────────────────────────────────┤
│                                             │
│  Frontend   Backend      Database   Cache   │
│  (React)    (NestJS)     (Postgres) (Redis) │
│  Port 80/443 Port 3010   Port 5432  Port 6379
│                                             │
│  ← All managed by Docker Compose →          │
│                                             │
└─────────────────────────────────────────────┘
```

**All data is yours:** Stored in PostgreSQL on your server, no cloud uploads.

---

## Troubleshooting

### "Image not found"
```bash
# Images built on GitHub Actions
# Check status: https://github.com/Leonid1095/PLGames-Board/actions

# Or wait a few minutes and try again
docker compose pull
docker compose up -d
```

### "Backend won't start"
```bash
# Check logs
docker compose logs backend

# Most common: old image without fixes
docker compose pull backend
docker compose up -d --force-recreate backend
```

### "Can't access from outside"
```bash
# Check firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Check DNS (if using domain)
nslookup your-domain.com
```

### Need help?
- 📌 Issues: https://github.com/Leonid1095/PLGames-Board/issues
- 💬 Discussions: https://github.com/Leonid1095/PLGames-Board/discussions
- 📖 Full docs: [`INSTALLATION_GUIDE.md`](INSTALLATION_GUIDE.md)

---

## Production Deployment

### Recommended Setup
1. **Domain + DNS** - Point A record to server IP
2. **Firewall** - Open ports 80 & 443
3. **Daily backups** - Export database to local file
4. **Monitor logs** - Set up log rotation if needed
5. **Update regularly** - Run `git pull && docker compose pull` weekly

### Backup Script
Add to crontab for daily automatic backups:
```bash
0 2 * * * cd ~/plgames-board && docker compose exec -T postgres pg_dump -U plgames plgames > /backup/plgames_$(date +\%Y\%m\%d).sql
```

---

## License

Built on [AFFiNE](https://github.com/toeverything/AFFiNE) - MIT License

---

**Ready?** Run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/install.sh)
```

🎮 **Happy collaborating!**
