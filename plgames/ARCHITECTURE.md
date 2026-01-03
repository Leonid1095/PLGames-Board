# PLGames Board - Architecture & Design Principles

## Project Vision

PLGames Board is a **self-hosted first** project management and knowledge base platform, forked from AFFiNE and Plane. The core principle is **zero external dependencies** - everything runs on the user's own infrastructure.

## Design Principles

### 1. Self-Hosted First
- NO external CDN dependencies
- NO hardcoded external URLs
- ALL assets served from the same origin
- Works completely offline after installation

### 2. One-Click Installation
- Single script installs everything
- Interactive prompts for configuration
- Sensible defaults for quick setup
- No manual Docker/database configuration required

### 3. Configuration Over Convention
All settings are configurable via environment variables:
- Domain/hostname
- Database credentials
- Storage paths
- Feature flags

### 4. AI-Friendly Codebase
This document and the codebase structure are designed to be understood by AI assistants for maintenance and feature development.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      User's Browser                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Caddy (Gateway)                           │
│              - HTTPS termination                             │
│              - Automatic Let's Encrypt                       │
│              - Reverse proxy                                 │
└─────────────────────────────────────────────────────────────┘
                     │                    │
                     ▼                    ▼
┌──────────────────────────┐  ┌──────────────────────────────┐
│      Frontend            │  │         Backend              │
│   (Caddy static)         │  │     (Node.js/NestJS)         │
│                          │  │                              │
│  - React SPA             │  │  - GraphQL API               │
│  - All assets from /     │  │  - WebSocket (sync)          │
│  - selfhost.html entry   │  │  - REST endpoints            │
└──────────────────────────┘  └──────────────────────────────┘
                                         │
                     ┌───────────────────┼───────────────────┐
                     ▼                   ▼                   ▼
            ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
            │  PostgreSQL  │    │    Redis     │    │  File Store  │
            │  + pgvector  │    │   (cache)    │    │   (local)    │
            └──────────────┘    └──────────────┘    └──────────────┘
```

---

## Key Components

### Frontend (`packages/frontend/`)
- **Technology**: React, TypeScript, Webpack
- **Entry Point**: `selfhost.html` (for self-hosted deployments)
- **Asset Loading**: `PUBLIC_PATH=/` - all assets from same origin
- **Build**: `yarn plgames build -p @affine/web`

### Backend (`packages/backend/server/`)
- **Technology**: NestJS, GraphQL, Prisma
- **Database**: PostgreSQL with pgvector extension
- **Real-time**: WebSocket for document sync
- **Native Module**: `@affine/server-native` (Rust, requires compilation)

### Gateway
- **Technology**: Caddy 2
- **Features**: Automatic HTTPS, reverse proxy, static file serving

---

## Environment Variables

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@postgres:5432/affine` |
| `REDIS_SERVER_HOST` | Redis hostname | `redis` |

### Optional
| Variable | Default | Description |
|----------|---------|-------------|
| `AFFINE_SERVER_HOST` | `0.0.0.0` | Server bind address |
| `AFFINE_SERVER_PORT` | `3010` | Server port |
| `AFFINE_SERVER_HTTPS` | `false` | Enable HTTPS |
| `DEPLOYMENT_TYPE` | `selfhosted` | Deployment mode |
| `PUBLIC_PATH` | `/` | Asset URL prefix (MUST be `/` for selfhost) |

---

## Installation Methods

### Method 1: Installation Script (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/plgames/install.sh | bash
```

### Method 2: Docker Compose
```bash
git clone https://github.com/Leonid1095/PLGames-Board.git
cd PLGames-Board/plgames
docker compose up -d
```

### Method 3: Manual Build
```bash
# Requires: Node.js 22+, Rust 1.82+, PostgreSQL 15+
yarn install
yarn plgames build
yarn workspace @affine/server start
```

---

## Development Guidelines

### Adding New Features
1. Check if feature exists in upstream AFFiNE/Plane
2. Ensure feature works in self-hosted mode
3. No external service dependencies
4. All configuration via environment variables

### Building Docker Images
```bash
# Build locally
docker build -t plgames-backend --target backend .
docker build -t plgames-frontend --target frontend .

# Or use GitHub Actions (automatic on push)
```

### Common Issues

#### "Cannot find module server-native.x64.node"
- Native module requires Rust compilation
- Use Docker images which have pre-compiled binaries

#### "Assets loading from CDN"
- Ensure `PUBLIC_PATH=/` is set during build
- Use `selfhost.html` entry point, not `index.html`

#### "Database connection failed"
- Check `DATABASE_URL` format
- Ensure PostgreSQL has `pgvector` extension

---

## File Structure

```
plgames/
├── ARCHITECTURE.md          # This file - project overview
├── Dockerfile               # Multi-stage build (backend + frontend)
├── docker-compose.yml       # Production deployment
├── install.sh               # One-click installation script
├── .env.example             # Configuration template
├── packages/
│   ├── frontend/
│   │   └── apps/
│   │       └── web/         # Main web application
│   └── backend/
│       ├── server/          # NestJS backend
│       └── native/          # Rust native module
└── tools/
    └── cli/                 # Build tools
```

---

## For AI Assistants

When working on this codebase:

1. **Self-hosted is the priority** - Never add external dependencies
2. **Environment variables** - All config must be overridable
3. **PUBLIC_PATH must be /** - For asset loading
4. **Use selfhost.html** - Not index.html for deployment
5. **Docker images are pre-built** - Don't ask users to compile Rust

Key files to understand:
- `tools/cli/src/webpack/html-plugin.ts` - Asset path configuration
- `packages/backend/server/src/env.ts` - Environment detection
- `packages/backend/server/src/core/selfhost/static.ts` - Static file serving
- `Dockerfile` - Build process
- `install.sh` - User-facing installation

---

## Roadmap

- [ ] Interactive installation script
- [ ] CRM module integration
- [ ] Notification system
- [ ] AI copilot features
- [ ] Mobile app support
