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
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-auto.sh | sudo bash
```

That's it! The script will:
- ✅ Install Docker, Node.js 22, and all dependencies
- ✅ Clone the repository
- ✅ Configure domain/HTTPS or IP/HTTP
- ✅ Build the entire project (20-30 minutes)
- ✅ Start all services automatically
- ✅ Provide you with access URL

**Requirements:** Ubuntu 20.04+, 8GB RAM, 20GB disk space

---

## 📦 Alternative: Fast Installation (Pre-built Images)

**Coming soon** - 2-3 minute installation using pre-built Docker images:

```bash
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-prebuilt.sh | bash
```

**Requirements:** Any Linux with Docker, 2GB RAM, 10GB disk space

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

### For Users
- **[INSTALL.md](INSTALL.md)** - Detailed installation guide
- **[README-QUICKSTART.md](README-QUICKSTART.md)** - Quick start tutorial

### For Developers
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[ROADMAP.md](ROADMAP.md)** - Future development plans

### Installation Scripts
- **[install-auto.sh](install-auto.sh)** - Automated production installer (8GB RAM)
- **[install-prebuilt.sh](install-prebuilt.sh)** - Fast installer with pre-built images (2GB RAM)
- **[build.sh](build.sh)** - Optimized build script
- **[prepare-server.sh](prepare-server.sh)** - Server preparation (swap, etc.)

---

## 🛠️ Manual Installation (Developers)

If you prefer manual control:

```bash
# 1. Clone repository
git clone https://github.com/Leonid1095/boards_plane.git
cd boards_plane

# 2. Prepare server (Ubuntu 20.04+)
sudo bash prepare-server.sh

# 3. Build project (requires 8GB RAM)
bash build.sh

# 4. Start services
docker compose -f docker-compose.simple.yml up -d --build

# 5. Check status
docker compose -f docker-compose.simple.yml ps
```

**Access:**
- Frontend: http://localhost:8080
- Backend API: http://localhost:3010
- Health check: http://localhost:3010/api/healthz

---

## ⚙️ Configuration

Main configuration is in `.env` file (auto-generated during installation):

```env
# Domain/IP
DOMAIN=your-domain.com
BASE_URL=https://your-domain.com

# Ports
FRONTEND_PORT=443
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
docker compose -f docker-compose.simple.yml ps

# View logs
docker compose -f docker-compose.simple.yml logs -f

# View specific service logs
docker compose -f docker-compose.simple.yml logs -f backend

# Restart services
docker compose -f docker-compose.simple.yml restart

# Stop services
docker compose -f docker-compose.simple.yml down

# Update to latest version (when using prebuilt images)
cd ~/plgames-board
docker compose pull
docker compose up -d

# Backup database
docker compose -f docker-compose.simple.yml exec postgres \
  pg_dump -U plgames plgames > backup_$(date +%Y%m%d).sql

# Restore database
cat backup.sql | docker compose -f docker-compose.simple.yml exec -T postgres \
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
# For HTTP (port 8080)
sudo ufw allow 8080/tcp

# For HTTPS (ports 80, 443)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# For direct backend access (optional, not recommended for production)
sudo ufw allow 3010/tcp
```

---

## 📊 System Requirements

### Production (Full Build)
- **OS:** Ubuntu 20.04+ (or any Linux with Docker)
- **RAM:** 8GB minimum (4GB SWAP auto-created)
- **CPU:** 2+ cores
- **Disk:** 20GB free space
- **Network:** Stable internet connection

### Production (Pre-built Images)
- **OS:** Any Linux with Docker
- **RAM:** 2GB minimum
- **CPU:** 1+ core
- **Disk:** 10GB free space

### Development
- **OS:** Linux, macOS, Windows (WSL2)
- **Node.js:** 22.x
- **Yarn:** 4.x (via corepack)
- **RAM:** 8GB minimum
- **Disk:** 25GB free space (for node_modules)

---

## 🚨 Troubleshooting

### Installation fails with "not enough RAM"
```bash
# Check RAM
free -h

# Check if swap is configured
swapon --show

# Manually run prepare-server.sh to create swap
sudo bash prepare-server.sh
```

### Backend not starting
```bash
# Check logs
docker compose -f docker-compose.simple.yml logs backend

# Common issues:
# 1. Database not ready - wait 30 seconds
# 2. Prisma engines not found - rebuild:
docker compose -f docker-compose.simple.yml build --no-cache backend
docker compose -f docker-compose.simple.yml up -d backend
```

### Frontend shows "Cannot connect to backend"
```bash
# Check backend health
curl http://localhost:3010/api/healthz

# If backend is down, restart:
docker compose -f docker-compose.simple.yml restart backend
```

### Port already in use
```bash
# Change ports in .env file
nano .env

# Update FRONTEND_PORT and BACKEND_PORT
# Then restart:
docker compose -f docker-compose.simple.yml down
docker compose -f docker-compose.simple.yml up -d
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
- **Documentation:** [INSTALL.md](INSTALL.md)

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
