#!/bin/bash
# PLGames Board - Interactive Installation Script
# Optimized for production with pre-built Docker images
# Works in Russia and any region with restricted network access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
INSTALL_DIR="$HOME/plgames-board"
REPO_URL="https://github.com/Leonid1095/PLGames-Board.git"

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║        🎮 PLGames Board - Smart Installation       ║"
echo "║                                                      ║"
echo "║  Collaborative workspace for game teams & projects  ║"
echo "║  Uses pre-built images - Works in any region        ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================================
# REQUIREMENTS CHECK
# ============================================================================
echo -e "${YELLOW}[1/5] Checking system requirements...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Install from: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not found. Install from: https://docs.docker.com/compose/install/${NC}"
    exit 1
fi

# Check available disk space (minimum 5GB)
AVAILABLE_SPACE=$(df "$HOME" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 5242880 ]; then
    echo -e "${RED}❌ Less than 5GB free disk space available${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker ${GREEN}✓ Docker Compose ${GREEN}✓ Disk space${NC}\n"

# ============================================================================
# CONFIGURATION
# ============================================================================
echo -e "${YELLOW}[2/5] Configuration${NC}\n"

echo -e "${CYAN}Domain Setup:${NC}"
echo "  localhost      → Local/development (HTTP on port 80)"
echo "  example.com    → Production (HTTPS with Let's Encrypt)"
echo ""
read -p "Enter domain [localhost]: " DOMAIN
DOMAIN=${DOMAIN:-localhost}

# Auto-configure ports and URL
if [ "$DOMAIN" = "localhost" ]; then
    HTTP_PORT=80
    HTTPS_PORT=443
    BASE_URL="http://localhost"
    SKIP_FIREWALL=true
else
    BASE_URL="https://${DOMAIN}"
    read -p "HTTP port [80]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-80}
    read -p "HTTPS port [443]: " HTTPS_PORT
    HTTPS_PORT=${HTTPS_PORT:-443}
    read -p "Configure firewall? (y/n) [n]: " CONFIGURE_FIREWALL
    SKIP_FIREWALL=$([ "$CONFIGURE_FIREWALL" = "y" ] && echo "false" || echo "true")
fi

# Generate secure password
DB_PASSWORD=$(head -c 32 /dev/urandom | base64 | tr -d '=+/' | cut -c1-32)

# Show summary
echo ""
echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
echo -e "Domain:        ${GREEN}${DOMAIN}${NC}"
echo -e "Access URL:    ${GREEN}${BASE_URL}${NC}"
echo -e "Install Path:  ${GREEN}${INSTALL_DIR}${NC}"
echo -e "HTTP/HTTPS:    ${GREEN}${HTTP_PORT}/${HTTPS_PORT}${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════${NC}"
echo ""
read -p "Proceed? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}Installation cancelled${NC}"
    exit 0
fi

# ============================================================================
# REPOSITORY SETUP
# ============================================================================
echo ""
echo -e "${YELLOW}[3/5] Setting up repository${NC}"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${CYAN}Existing installation found at $INSTALL_DIR${NC}"
    read -p "Start fresh (will remove old data)? (y/n) [n]: " FRESH_INSTALL
    FRESH_INSTALL=${FRESH_INSTALL:-n}
    
    if [ "$FRESH_INSTALL" = "y" ] || [ "$FRESH_INSTALL" = "Y" ]; then
        echo -e "${YELLOW}Stopping containers...${NC}"
        (cd "$INSTALL_DIR" && docker compose down -v 2>/dev/null) || true
        
        echo -e "${YELLOW}Removing old data...${NC}"
        rm -rf "$INSTALL_DIR"
        
        echo -e "${YELLOW}Cloning fresh repository...${NC}"
        git clone "$REPO_URL" "$INSTALL_DIR" || {
            echo -e "${RED}❌ Failed to clone repository${NC}"
            exit 1
        }
    else
        echo -e "${YELLOW}Updating existing installation...${NC}"
        cd "$INSTALL_DIR"
        git stash 2>/dev/null || true
        git pull origin main || {
            echo -e "${RED}❌ Failed to update${NC}"
            exit 1
        }
    fi
else
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR" || {
        echo -e "${RED}❌ Failed to clone repository${NC}"
        exit 1
    }
fi

cd "$INSTALL_DIR"
echo -e "${GREEN}✓ Repository ready${NC}"

# ============================================================================
# ENVIRONMENT CONFIGURATION
# ============================================================================
echo ""
echo -e "${YELLOW}[4/5] Creating configuration${NC}"

cat > .env << EOF
# PLGames Board Configuration
# Generated on $(date)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Core Settings
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NODE_ENV=production
DOMAIN=${DOMAIN}
BASE_URL=${BASE_URL}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Network & Ports
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}
BACKEND_PORT=3010
AFFINE_SERVER_PORT=3010

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Database (PostgreSQL)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DB_USER=plgames
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=plgames
DATABASE_URL=postgres://plgames:${DB_PASSWORD}@postgres:5432/plgames

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Cache (Redis)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REDIS_SERVER_HOST=redis
REDIS_SERVER_PORT=6379

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AI & Optional Features (Disabled by default)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AFFINE_COPILOT_ENABLED=false
# AFFINE_COPILOT_OPENROUTER_API_KEY=
# AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OAuth (Yandex) - Optional
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OIDC_CLIENT_ID=
# OIDC_CLIENT_SECRET=

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Feature Flags
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AFFINE_TELEMETRY_ENABLED=false
AFFINE_METRICS_ENABLED=true
EOF

echo -e "${GREEN}✓ Configuration created${NC}"

# ============================================================================
# FIREWALL CONFIGURATION
# ============================================================================
if [ "$SKIP_FIREWALL" = "false" ]; then
    echo ""
    echo -e "${YELLOW}Configuring firewall...${NC}"
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow ${HTTP_PORT}/tcp 2>/dev/null || true
        sudo ufw allow ${HTTPS_PORT}/tcp 2>/dev/null || true
        echo -e "${GREEN}✓ UFW rules added${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=${HTTP_PORT}/tcp 2>/dev/null || true
        sudo firewall-cmd --permanent --add-port=${HTTPS_PORT}/tcp 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
        echo -e "${GREEN}✓ Firewalld rules added${NC}"
    else
        echo -e "${YELLOW}⚠️  No firewall found, please open ports manually:${NC}"
        echo "   sudo iptables -A INPUT -p tcp --dport ${HTTP_PORT} -j ACCEPT"
        echo "   sudo iptables -A INPUT -p tcp --dport ${HTTPS_PORT} -j ACCEPT"
    fi
fi

# ============================================================================
# DOCKER STARTUP
# ============================================================================
echo ""
echo -e "${YELLOW}[5/5] Starting services${NC}"
echo -e "${CYAN}Downloading pre-built Docker images...${NC}"
echo -e "${CYAN}(Images built on GitHub, no compilation needed)${NC}"
echo ""

if docker compose pull 2>&1 | grep -E "(Error|error|Failed|ERROR)" > /dev/null; then
    echo -e "${RED}❌ Failed to download images${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  • Check internet connection: curl -I https://ghcr.io"
    echo "  • Docker daemon running: docker ps"
    echo "  • Disk space available: df -h"
    echo ""
    echo -e "${CYAN}Latest build status:${NC}"
    echo "  https://github.com/Leonid1095/PLGames-Board/actions"
    exit 1
fi

echo -e "${GREEN}✓ Images downloaded${NC}"
echo -e "${CYAN}Starting containers...${NC}"

if ! docker compose up -d; then
    echo -e "${RED}❌ Failed to start containers${NC}"
    echo -e "${CYAN}Logs:${NC}"
    docker compose logs --tail=30
    exit 1
fi

echo -e "${GREEN}✓ Containers started${NC}"

# ============================================================================
# HEALTH CHECK
# ============================================================================
echo ""
echo -e "${CYAN}Waiting for services to be ready... (this may take 1-2 minutes)${NC}"

WAIT_TIME=0
MAX_WAIT=180
HEALTH_OK=false

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Check backend health
    if docker compose exec -T backend curl -sf http://localhost:3010/api/healthz &>/dev/null 2>&1; then
        HEALTH_OK=true
        break
    fi
    
    if [ $((WAIT_TIME % 30)) -eq 0 ] && [ $WAIT_TIME -gt 0 ]; then
        echo -e "${YELLOW}Still waiting... ($WAIT_TIME/$MAX_WAIT sec)${NC}"
    fi
    
    sleep 3
    WAIT_TIME=$((WAIT_TIME + 3))
done

echo ""
docker compose ps
echo ""

if [ "$HEALTH_OK" = "true" ]; then
    echo -e "${GREEN}✓ All services are healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Services started but may still be initializing${NC}"
    echo -e "${CYAN}Check backend logs: docker compose logs backend${NC}"
fi

# ============================================================================
# SUCCESS MESSAGE
# ============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                      ║${NC}"
echo -e "${GREEN}║     ✅ PLGames Board installation complete!         ║${NC}"
echo -e "${GREEN}║                                                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📝 NEXT STEPS:${NC}"
echo ""
echo -e "  1. Open browser:  ${CYAN}${BASE_URL}${NC}"
echo ""
echo -e "  2. Create account (first user = admin)"
echo ""
echo -e "  3. Start using PLGames Board!"
echo ""
echo -e "${BLUE}📋 USEFUL COMMANDS:${NC}"
echo ""
echo -e "  Status:        ${CYAN}docker compose ps${NC}"
echo -e "  Logs:          ${CYAN}docker compose logs -f${NC}"
echo -e "  Stop:          ${CYAN}docker compose down${NC}"
echo -e "  Restart:       ${CYAN}docker compose restart${NC}"
echo -e "  Update:        ${CYAN}git pull && docker compose pull && docker compose up -d${NC}"
echo ""

if [ "$DOMAIN" != "localhost" ]; then
    echo -e "${YELLOW}⚠️  PRODUCTION SETUP:${NC}"
    echo ""
    echo -e "  • DNS: Point ${DOMAIN} A record to this server IP"
    echo -e "  • Certificate: Auto-issued via Let's Encrypt (wait ~30 sec for first HTTPS)"
    echo -e "  • Firewall: Ports ${HTTP_PORT}/${HTTPS_PORT} must be open"
    echo ""
fi

echo -e "${CYAN}Questions/Issues: https://github.com/Leonid1095/PLGames-Board/issues${NC}"
echo -e "${GREEN}Happy collaborating! 🎮${NC}"
echo ""

