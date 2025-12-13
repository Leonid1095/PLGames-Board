# PLGames Board

> **Modern collaborative workspace and project management platform**
> Built on [AFFiNE](https://github.com/toeverything/AFFiNE) with enhanced features for team collaboration

[![Docker](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/Node.js-22-green?logo=node.js)](https://nodejs.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🚀 Quick Start (Production)

**One-line installation** - like GitLab, Nextcloud, or official AFFiNE:

```bash
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install.sh | bash
```

That's it! The script will:
- ✅ Clone the repository
- ✅ Build everything inside Docker (20-30 minutes)
- ✅ Start all services automatically
- ✅ Provide you with access URL at http://localhost:8080

**Requirements:** Any Linux with Docker, 8GB RAM, 20GB disk space

---

## ✨ Features

### Core Features (AFFiNE Base)
- 📝 **Rich Document Editor** - Block-based editor with Markdown support
- 🎨 **Whiteboard Canvas** - Visual collaboration and diagramming
- 📊 **Database Views** - Kanban, Table, and List views
- 👥 **Real-time Collaboration** - Multiple users editing simultaneously
- 🔍 **Full-text Search** - Fast search across all content
- 🌐 **Multi-language Support** - i18n ready
- 🔐 **Authentication** - OAuth (Yandex) and email/password
- 🤖 **AI Integration** - Optional AI assistant via OpenRouter

### PLGames Board Enhancements
- 🎯 **Optimized for Production** - Fully automated installation
- 🔒 **Secure by Default** - Auto-generated secrets, secure defaults
- 🚀 **Performance Optimized** - 8GB RAM build, optimized Docker images
- 📦 **Easy Updates** - One command to update
- 🌍 **Automatic HTTPS** - Let's Encrypt integration via Caddy
- 💾 **Built-in Backups** - Database backup commands included

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PLGames Board                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Frontend (React + Vite)  ←→  Backend (NestJS)         │
│         Port 8080/443              Port 3010            │
│                                         ↓                │
│                                    PostgreSQL            │
│                                    (pgvector)            │
│                                         ↓                │
│                                      Redis               │
│                                   (Cache/Queue)          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Technology Stack:**
- **Frontend:** React 18, Vite, Jotai (state), BlockSuite (editor)
- **Backend:** NestJS, Prisma ORM, GraphQL, Socket.io
- **Database:** PostgreSQL 16 + pgvector extension
- **Cache:** Redis Alpine
- **Build:** Yarn 4 workspaces, Node.js 22
- **Deploy:** Docker Compose, Caddy (reverse proxy)

---

## 📖 Documentation

- **[install.sh](install.sh)** - One-line production installer
- **[docker-compose.yml](docker-compose.yml)** - Docker orchestration configuration
- **[plgames/Dockerfile](plgames/Dockerfile)** - Multi-stage build for backend and frontend

---

## 🛠️ Manual Installation (Developers)

If you prefer manual control:

```bash
# 1. Clone repository
git clone https://github.com/Leonid1095/boards_plane.git
cd boards_plane

# 2. Start services (builds everything inside Docker)
docker compose up -d --build

# 3. Check status
docker compose ps
```

**Access:**
- **Production (with domain):** https://yourdomain.com
- **Development (localhost):** http://localhost
- Backend API (direct): http://localhost:3010
- Health check: http://localhost:3010/api/healthz

**Note:** Frontend and backend are automatically proxied through the gateway.

**Note:** First build takes 20-30 minutes as it builds the entire monorepo inside Docker.

---

## ⚙️ Configuration

Main configuration is in `.env` file:

### Domain Configuration

**For localhost (development):**
```env
DOMAIN=localhost
BASE_URL=http://localhost
HTTP_PORT=80
HTTPS_PORT=443
```
Access at: http://localhost

**For production domain:**
```env
DOMAIN=yourdomain.com
BASE_URL=https://yourdomain.com
HTTP_PORT=80
HTTPS_PORT=443
```
Access at: https://yourdomain.com (automatic HTTPS via Let's Encrypt)

### Other Configuration

```env
# Backend
BACKEND_PORT=3010

# Database (auto-generated secure password)
DB_USER=plgames
DB_PASSWORD=<auto-generated>
DB_NAME=plgames

# Optional: AI via OpenRouter
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-v1-your-key

# Optional: OAuth (Yandex)
OIDC_CLIENT_ID=your-client-id
OIDC_CLIENT_SECRET=your-client-secret
```

---

## 🔧 Common Commands

```bash
# Check status
docker compose ps

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend

# Restart services
docker compose restart

# Stop services
docker compose down

# Update to latest version
cd ~/plgames-board
git pull
docker compose up -d --build

# Backup database
docker compose exec postgres \
  pg_dump -U plgames plgames > backup_$(date +%Y%m%d).sql

# Restore database
cat backup.sql | docker compose exec -T postgres \
  psql -U plgames plgames
```

---

## 🔒 Security

- ✅ **Secure passwords** - Auto-generated 24-character passwords
- ✅ **Network isolation** - Docker internal network
- ✅ **HTTPS support** - Automatic Let's Encrypt certificates
- ✅ **OAuth integration** - Yandex OAuth ready
- ⚠️ **Firewall** - Remember to configure firewall rules:

```bash
# For production (HTTPS)
sudo ufw allow 80/tcp   # HTTP (redirects to HTTPS)
sudo ufw allow 443/tcp  # HTTPS

# For development (localhost only - optional)
# No firewall rules needed for localhost access

# For direct backend access (not recommended for production)
# sudo ufw allow 3010/tcp
```

---

## 📊 System Requirements

### Production (Docker)
- **OS:** Any Linux with Docker
- **RAM:** 8GB minimum (for initial build)
- **CPU:** 2+ cores
- **Disk:** 20GB free space
- **Network:** Stable internet connection

### Development (Local)
- **OS:** Linux, macOS, Windows (WSL2)
- **Node.js:** 22.x
- **Yarn:** 4.x (via corepack)
- **RAM:** 8GB minimum
- **Disk:** 25GB free space (for node_modules)

---

## 🚨 Troubleshooting

### Build fails with "not enough RAM"
```bash
# Check RAM
free -h

# Docker build requires 8GB RAM
# You may need to add swap space or use a larger server
```

### Backend not starting
```bash
# Check logs
docker compose logs backend

# Common issues:
# 1. Database not ready - wait 30 seconds
# 2. Build failed - check build logs:
docker compose logs backend | grep -i error
```

### Frontend shows "Cannot connect to backend"
```bash
# Check backend health
curl http://localhost:3010/api/healthz

# If backend is down, restart:
docker compose restart backend
```

### Port already in use
```bash
# Change ports in .env file (create if doesn't exist)
echo "FRONTEND_PORT=8081" >> .env
echo "BACKEND_PORT=3011" >> .env

# Then restart:
docker compose down
docker compose up -d
```

---

## 🤝 Contributing

Contributions are welcome! This project is built on [AFFiNE](https://github.com/toeverything/AFFiNE).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Based on:**
- [AFFiNE](https://github.com/toeverything/AFFiNE) - MIT License
- [Plane](https://github.com/makeplane/plane) - AGPL-3.0 License (for future CRM integration)

---

## 🙏 Acknowledgments

- [AFFiNE Team](https://github.com/toeverything/AFFiNE) - For the amazing collaborative platform
- [Plane Team](https://github.com/makeplane/plane) - For CRM inspiration
- Community contributors

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/Leonid1095/boards_plane/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Leonid1095/boards_plane/discussions)

---

## 🎯 Quick Links

- 🏠 [Homepage](#plgames-board)
- 🚀 [Quick Start](#-quick-start-production)
- 📖 [Documentation](#-documentation)
- 🛠️ [Manual Installation](#%EF%B8%8F-manual-installation-developers)
- 🔧 [Configuration](#%EF%B8%8F-configuration)
- 🚨 [Troubleshooting](#-troubleshooting)

---

**Made with ❤️ for productive teams**

**Status:** ✅ Production Ready
**Version:** 1.0.0
**Last Updated:** December 10, 2024
