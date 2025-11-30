#!/bin/bash
set -e

# Configuration
DOMAIN="uwow-guide.online"
REPO_DIR="/home/plg/boards_plane"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] $1${NC}"
}

# 1. System Preparation
log "🚀 Starting One-Click Deployment for PLGames..."

if [ "$(id -u)" -ne 0 ]; then
    warn "This script is not running as root. Some installation steps might fail or require sudo."
    warn "If you encounter errors, try running with: sudo ./deploy_production.sh"
fi

# Install Docker if missing
if ! command -v docker &> /dev/null; then
    log "📦 Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    log "✅ Docker installed."
else
    log "✅ Docker is already installed."
fi

# 2. Repository Synchronization
log "🔄 Synchronizing repository..."
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR" || exit
    git config --global --add safe.directory "$REPO_DIR"
    git pull origin master || warn "Failed to pull changes. Continuing with local version..."
    git submodule update --init --recursive
else
    error "Repository directory $REPO_DIR not found!"
    exit 1
fi

# 3. Environment Configuration
log "⚙️  Configuring environment..."

# Generate secure passwords if not present
if [ ! -f .env ]; then
    log "📝 Creating new .env file..."
    DB_PASSWORD=$(openssl rand -hex 16)
    cat > .env <<EOF
NODE_ENV=production
DOMAIN=${DOMAIN}
BASE_URL=https://${DOMAIN}

# Database
DB_USER=plgames
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=plgames
DATABASE_URL=postgres://plgames:${DB_PASSWORD}@postgres:5432/plgames

# Ports
PORT=3010

# AI Configuration (Optional - Fill these in to enable AI)
OPENROUTER_API_KEY=
OIDC_CLIENT_ID=
OIDC_CLIENT_SECRET=
EOF
else
    log "✅ .env file already exists. Skipping generation."
fi

# 4. Deployment
log "🛑 Stopping old containers..."
docker compose -f docker-compose.prod.yml down --remove-orphans || true

log "🏗️  Building and Starting PLGames Stack..."
# Ensure we use the correct compose file and build from source
docker compose -f docker-compose.prod.yml up -d --build

# 5. Verification
log "🔍 Verifying deployment..."
if docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo -e "\n${GREEN}==============================================${NC}"
    echo -e "${GREEN}✅ Deployment Successful!${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo -e "🌍 Frontend: http://localhost:8080 (or https://${DOMAIN})"
    echo -e "🔌 Backend:  http://localhost:3010"
    echo -e "📂 Location: $(pwd)"
    echo -e "\nTo view logs: docker compose -f docker-compose.prod.yml logs -f"
else
    error "❌ Deployment failed. Containers are not running."
    exit 1
fi
