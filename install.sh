#!/bin/bash
# PLGames Board - Interactive Installation Script
# This script helps you easily install and configure PLGames Board

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║          🎮 PLGames Board Installation           ║"
echo "║                                                   ║"
echo "║     Collaborative workspace for game teams       ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if Docker is installed
echo -e "${YELLOW}Checking requirements...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first:${NC}"
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first:${NC}"
    echo "   https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose are installed${NC}\n"

# Configuration questions
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# Domain configuration
echo -e "${YELLOW}Domain Configuration:${NC}"
echo "  • For local development: use 'localhost' (HTTP on port 80)"
echo "  • For production: use your domain (automatic HTTPS with Let's Encrypt)"
echo ""
read -p "Enter your domain [localhost]: " DOMAIN
DOMAIN=${DOMAIN:-localhost}

# Port configuration
echo ""
echo -e "${YELLOW}Port Configuration:${NC}"
if [ "$DOMAIN" = "localhost" ]; then
    echo "  Using HTTP on port 80 (localhost mode)"
    HTTP_PORT=80
    HTTPS_PORT=443
    BASE_URL="http://localhost"
else
    echo "  Using HTTPS with automatic Let's Encrypt certificate"
    read -p "HTTP port [80]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-80}
    read -p "HTTPS port [443]: " HTTPS_PORT
    HTTPS_PORT=${HTTPS_PORT:-443}
    BASE_URL="https://${DOMAIN}"
fi

# Database configuration
echo ""
echo -e "${YELLOW}Database Configuration:${NC}"
DB_PASSWORD=$(openssl rand -hex 16 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo "  Auto-generated secure database password"

# Firewall configuration
CONFIGURE_FIREWALL="n"
if [ "$DOMAIN" != "localhost" ]; then
    echo ""
    echo -e "${YELLOW}Firewall Configuration:${NC}"
    read -p "Configure firewall rules for ports ${HTTP_PORT} and ${HTTPS_PORT}? (y/n) [n]: " CONFIGURE_FIREWALL
    CONFIGURE_FIREWALL=${CONFIGURE_FIREWALL:-n}
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Installation Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "Domain:       ${GREEN}${DOMAIN}${NC}"
echo -e "Access URL:   ${GREEN}${BASE_URL}${NC}"
echo -e "HTTP Port:    ${GREEN}${HTTP_PORT}${NC}"
echo -e "HTTPS Port:   ${GREEN}${HTTPS_PORT}${NC}"
echo -e "Install Dir:  ${GREEN}~/plgames-board${NC}"
echo ""
read -p "Continue with installation? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 0
fi

# Start installation
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Installing PLGames Board${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"

# Clone or update repository
echo -e "${YELLOW}📦 Setting up repository...${NC}"
if [ -d ~/plgames-board ]; then
    echo -e "${YELLOW}⚠️  Directory ~/plgames-board already exists${NC}"
    read -p "Remove and reinstall? (y/n) [n]: " REMOVE
    REMOVE=${REMOVE:-n}
    if [ "$REMOVE" = "y" ] || [ "$REMOVE" = "Y" ]; then
        echo -e "${YELLOW}Removing old installation...${NC}"
        # Stop containers if running
        cd ~/plgames-board && docker compose down 2>/dev/null || true
        cd ~
        rm -rf ~/plgames-board
        echo -e "${YELLOW}Cloning fresh copy...${NC}"
        git clone https://github.com/Leonid1095/PLGames-Board.git ~/plgames-board
    else
        echo -e "${YELLOW}Updating existing installation...${NC}"
        cd ~/plgames-board
        # Stash any local changes
        git stash 2>/dev/null || true
        # Pull latest changes
        git pull origin main || {
            echo -e "${RED}❌ Failed to update repository. Check your internet connection.${NC}"
            exit 1
        }
        echo -e "${GREEN}✓ Repository updated to latest version${NC}"
    fi
else
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/Leonid1095/PLGames-Board.git ~/plgames-board || {
        echo -e "${RED}❌ Failed to clone repository. Check your internet connection.${NC}"
        exit 1
    }
fi

cd ~/plgames-board

# Create .env file
echo ""
echo -e "${YELLOW}⚙️  Creating configuration file...${NC}"
cat > .env << EOF
# PLGames Board Configuration
# Generated by install.sh on $(date)

# Basic Configuration
NODE_ENV=production

# Domain Configuration
DOMAIN=${DOMAIN}
BASE_URL=${BASE_URL}

# Gateway Ports
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}

# Database Configuration
DB_USER=plgames
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=plgames
DATABASE_URL=postgres://plgames:${DB_PASSWORD}@postgres:5432/plgames

# Server Configuration
PORT=3010
AFFINE_SERVER_HOST=0.0.0.0
AFFINE_SERVER_PORT=3010
AFFINE_SERVER_EXTERNAL_URL=${BASE_URL}

# Redis Configuration
REDIS_SERVER_HOST=redis
REDIS_SERVER_PORT=6379

# AI Configuration (Disabled by default)
AFFINE_COPILOT_ENABLED=false

# Feature Flags
AFFINE_TELEMETRY_ENABLED=false
AFFINE_METRICS_ENABLED=true
EOF

echo -e "${GREEN}✓ Configuration created${NC}"

# Configure firewall if requested
if [ "$CONFIGURE_FIREWALL" = "y" ] || [ "$CONFIGURE_FIREWALL" = "Y" ]; then
    echo ""
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    if command -v ufw &> /dev/null; then
        sudo ufw allow ${HTTP_PORT}/tcp
        sudo ufw allow ${HTTPS_PORT}/tcp
        echo -e "${GREEN}✓ UFW rules added${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=${HTTP_PORT}/tcp
        sudo firewall-cmd --permanent --add-port=${HTTPS_PORT}/tcp
        sudo firewall-cmd --reload
        echo -e "${GREEN}✓ Firewall-cmd rules added${NC}"
    else
        echo -e "${YELLOW}⚠️  No supported firewall found (ufw or firewalld)${NC}"
        echo "   Manually open ports ${HTTP_PORT} and ${HTTPS_PORT}"
    fi
fi

# Build and start services
echo ""
echo -e "${YELLOW}🏗️  Building Docker images (this may take 20-30 minutes)...${NC}"
echo -e "${YELLOW}   The build process includes:${NC}"
echo -e "${YELLOW}   - Installing Rust (trying multiple mirrors for Russia)${NC}"
echo -e "${YELLOW}   - Downloading Prisma engines${NC}"
echo -e "${YELLOW}   - Building backend and frontend${NC}"
echo ""
echo -e "${YELLOW}   💡 You can monitor progress in another terminal with:${NC}"
echo -e "${YELLOW}      cd ~/plgames-board && docker compose logs -f${NC}"
echo ""

# Build with error handling
if docker compose up -d --build; then
    echo -e "${GREEN}✓ Docker build completed${NC}"
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    echo ""
    echo -e "${YELLOW}Showing last 50 lines of build logs:${NC}"
    docker compose logs --tail=50
    echo ""
    echo -e "${YELLOW}💡 Common issues:${NC}"
    echo "   1. Network timeout downloading Rust/Prisma - retry the installation"
    echo "   2. Out of disk space - free up space and retry"
    echo "   3. Out of memory - close other applications and retry"
    echo ""
    echo -e "${YELLOW}Full logs available with: docker compose logs${NC}"
    echo -e "${YELLOW}To retry: cd ~/plgames-board && docker compose up -d --build${NC}"
    exit 1
fi

# Wait for services to be healthy
echo ""
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
echo -e "${YELLOW}   This may take 1-2 minutes...${NC}"

# Wait up to 120 seconds for services to be healthy
WAIT_TIME=0
MAX_WAIT=120
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Check if backend is healthy
    if docker compose exec -T backend curl -sf http://localhost:3010/api/healthz >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend is healthy${NC}"
        break
    fi

    # Show progress
    if [ $((WAIT_TIME % 10)) -eq 0 ]; then
        echo -e "${YELLOW}   Still waiting... (${WAIT_TIME}s / ${MAX_WAIT}s)${NC}"
    fi

    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
done

# Final status check
echo ""
echo -e "${YELLOW}📊 Services status:${NC}"
docker compose ps

# Check if all services are running
RUNNING_COUNT=$(docker compose ps | grep -c "Up" || echo "0")
if [ "$RUNNING_COUNT" -ge 4 ]; then
    echo -e "${GREEN}✓ All services are running${NC}"
else
    echo -e "${YELLOW}⚠️  Some services may still be starting or have issues${NC}"
    echo ""
    echo -e "${YELLOW}Check logs with:${NC}"
    echo "   docker compose logs backend"
    echo "   docker compose logs frontend"
    echo "   docker compose logs postgres"
fi

# Success message
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                   ║${NC}"
echo -e "${GREEN}║          ✅ Installation Complete!               ║${NC}"
echo -e "${GREEN}║                                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo ""
echo -e "1. Open your browser and go to: ${GREEN}${BASE_URL}${NC}"
echo ""
echo -e "2. ${YELLOW}First-time setup:${NC}"
echo "   • The first user to register will become the admin"
echo "   • Create your account and start using PLGames Board"
echo ""
echo -e "3. ${YELLOW}Useful commands:${NC}"
echo "   • Check status:  docker compose ps"
echo "   • View logs:     docker compose logs -f"
echo "   • Stop:          docker compose down"
echo "   • Restart:       docker compose restart"
echo ""
echo -e "4. ${YELLOW}Documentation:${NC}"
echo "   • README:        ~/plgames-board/README.md"
echo "   • GitHub:        https://github.com/Leonid1095/PLGames-Board"
echo ""

if [ "$DOMAIN" != "localhost" ]; then
    echo -e "${YELLOW}⚠️  Important for production:${NC}"
    echo "   • Make sure your domain's DNS A record points to this server's IP"
    echo "   • Let's Encrypt will automatically issue HTTPS certificate"
    echo "   • First HTTPS request may take a few seconds while certificate is issued"
    echo ""
fi

echo -e "${GREEN}Happy collaborating! 🎮${NC}"
echo ""
