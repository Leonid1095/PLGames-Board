#!/bin/bash
#
# PLGames Board - One-Click Installation Script
# https://github.com/Leonid1095/PLGames-Board
#
# Usage: curl -fsSL https://raw.githubusercontent.com/Leonid1095/PLGames-Board/main/plgames/install.sh | bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
INSTALL_DIR="${HOME}/plgames-board"
DOMAIN=""
USE_HTTPS="yes"
DB_PASSWORD=""
REDIS_PASSWORD=""

# Print banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║              PLGames Board Installation                   ║"
    echo "║                                                           ║"
    echo "║   Project Management & Knowledge Base Platform            ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print step
print_step() {
    echo -e "${GREEN}[*]${NC} $1"
}

# Print warning
print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Print error
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Generate random password
generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24
}

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Check system requirements
check_requirements() {
    print_step "Checking system requirements..."

    # Check Docker
    if ! check_command docker; then
        print_error "Docker is not installed!"
        echo ""
        echo "Install Docker first:"
        echo "  curl -fsSL https://get.docker.com | sh"
        echo "  sudo usermod -aG docker \$USER"
        echo ""
        exit 1
    fi

    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed!"
        echo ""
        echo "Docker Compose should come with Docker. Try updating Docker."
        echo ""
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running!"
        echo ""
        echo "Start Docker:"
        echo "  sudo systemctl start docker"
        echo ""
        exit 1
    fi

    print_step "All requirements satisfied!"
}

# Interactive configuration
configure() {
    echo ""
    echo -e "${BLUE}=== Configuration ===${NC}"
    echo ""

    # Installation directory
    read -p "Installation directory [$INSTALL_DIR]: " input
    INSTALL_DIR="${input:-$INSTALL_DIR}"

    # Domain
    echo ""
    echo "Do you have a domain name pointing to this server?"
    echo "Examples: example.com, board.mycompany.ru"
    echo "Leave empty to use IP address (not recommended for production)"
    read -p "Domain name: " DOMAIN

    if [ -z "$DOMAIN" ]; then
        # Get public IP
        PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "localhost")
        DOMAIN="$PUBLIC_IP"
        USE_HTTPS="no"
        print_warning "No domain specified. Using IP: $DOMAIN"
        print_warning "HTTPS will be disabled (not recommended for production)"
    else
        echo ""
        read -p "Enable HTTPS with Let's Encrypt? [Y/n]: " https_input
        if [[ "$https_input" =~ ^[Nn] ]]; then
            USE_HTTPS="no"
        else
            USE_HTTPS="yes"
        fi
    fi

    # Generate passwords
    DB_PASSWORD=$(generate_password)
    REDIS_PASSWORD=$(generate_password)

    echo ""
    echo -e "${BLUE}=== Configuration Summary ===${NC}"
    echo ""
    echo "  Installation directory: $INSTALL_DIR"
    echo "  Domain/IP: $DOMAIN"
    echo "  HTTPS: $USE_HTTPS"
    echo "  Database password: $DB_PASSWORD"
    echo ""
    read -p "Proceed with installation? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "Installation cancelled."
        exit 0
    fi
}

# Create directory structure
create_directories() {
    print_step "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/data/postgres"
    mkdir -p "$INSTALL_DIR/data/redis"
    mkdir -p "$INSTALL_DIR/data/storage"
}

# Create docker-compose.yml
create_docker_compose() {
    print_step "Creating docker-compose.yml..."

    if [ "$USE_HTTPS" = "yes" ]; then
        PROTOCOL="https"
        CADDY_CONFIG="$DOMAIN {
    reverse_proxy backend:3010

    header {
        X-Frame-Options SAMEORIGIN
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
    }
}"
    else
        PROTOCOL="http"
        CADDY_CONFIG=":80 {
    reverse_proxy backend:3010
}"
    fi

    cat > "$INSTALL_DIR/docker-compose.yml" << EOF
version: '3.8'

services:
  gateway:
    image: caddy:2-alpine
    container_name: plgames-gateway
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - backend
    networks:
      - plgames

  backend:
    image: ghcr.io/leonid1095/plgames-board-backend:latest
    container_name: plgames-backend
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DEPLOYMENT_TYPE=selfhosted
      - AFFINE_SERVER_HOST=0.0.0.0
      - AFFINE_SERVER_PORT=3010
      - AFFINE_SERVER_HTTPS=${USE_HTTPS}
      - AFFINE_SERVER_EXTERNAL_URL=${PROTOCOL}://${DOMAIN}
      - DATABASE_URL=postgresql://plgames:${DB_PASSWORD}@postgres:5432/plgames
      - REDIS_SERVER_HOST=redis
      - REDIS_SERVER_PORT=6379
      - REDIS_SERVER_PASSWORD=${REDIS_PASSWORD}
    volumes:
      - ./data/storage:/app/storage
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - plgames
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3010/api/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  postgres:
    image: pgvector/pgvector:pg16
    container_name: plgames-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=plgames
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=plgames
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - plgames
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U plgames"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: plgames-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - ./data/redis:/data
    networks:
      - plgames

volumes:
  caddy_data:
  caddy_config:

networks:
  plgames:
    driver: bridge
EOF
}

# Create Caddyfile
create_caddyfile() {
    print_step "Creating Caddyfile..."

    if [ "$USE_HTTPS" = "yes" ]; then
        cat > "$INSTALL_DIR/Caddyfile" << EOF
$DOMAIN {
    reverse_proxy backend:3010

    header {
        X-Frame-Options SAMEORIGIN
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
        -Server
    }

    # Enable compression
    encode gzip

    # Logging
    log {
        output file /var/log/caddy/access.log
        format json
    }
}
EOF
    else
        cat > "$INSTALL_DIR/Caddyfile" << EOF
:80 {
    reverse_proxy backend:3010

    header {
        X-Frame-Options SAMEORIGIN
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
        -Server
    }

    encode gzip
}
EOF
    fi
}

# Create .env file
create_env_file() {
    print_step "Creating .env file..."

    cat > "$INSTALL_DIR/.env" << EOF
# PLGames Board Configuration
# Generated by install.sh on $(date)

# Domain and URL
DOMAIN=$DOMAIN
PROTOCOL=${PROTOCOL:-http}
USE_HTTPS=$USE_HTTPS

# Database
DB_PASSWORD=$DB_PASSWORD

# Redis
REDIS_PASSWORD=$REDIS_PASSWORD

# Paths
INSTALL_DIR=$INSTALL_DIR
EOF
}

# Pull and start containers
start_services() {
    print_step "Pulling Docker images..."
    cd "$INSTALL_DIR"
    docker compose pull

    print_step "Starting services..."
    docker compose up -d

    print_step "Waiting for services to be ready..."
    sleep 10

    # Check if backend is healthy
    for i in {1..30}; do
        if docker compose ps backend | grep -q "healthy"; then
            break
        fi
        echo "  Waiting for backend to be ready... ($i/30)"
        sleep 5
    done
}

# Print completion message
print_completion() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║           Installation Complete!                          ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$USE_HTTPS" = "yes" ]; then
        echo -e "  ${BLUE}Access your PLGames Board:${NC}"
        echo "  https://$DOMAIN"
    else
        echo -e "  ${BLUE}Access your PLGames Board:${NC}"
        echo "  http://$DOMAIN"
    fi

    echo ""
    echo -e "  ${BLUE}Management commands:${NC}"
    echo "  cd $INSTALL_DIR"
    echo "  docker compose logs -f      # View logs"
    echo "  docker compose restart      # Restart services"
    echo "  docker compose down         # Stop services"
    echo "  docker compose pull && docker compose up -d  # Update"
    echo ""
    echo -e "  ${BLUE}Configuration:${NC}"
    echo "  $INSTALL_DIR/.env"
    echo "  $INSTALL_DIR/docker-compose.yml"
    echo ""

    if [ "$USE_HTTPS" = "no" ]; then
        print_warning "HTTPS is disabled. For production, use a domain with HTTPS!"
    fi

    echo ""
    echo "  First time? Create an admin account at:"
    if [ "$USE_HTTPS" = "yes" ]; then
        echo "  https://$DOMAIN/admin/setup"
    else
        echo "  http://$DOMAIN/admin/setup"
    fi
    echo ""
}

# Main installation flow
main() {
    print_banner
    check_requirements
    configure
    create_directories
    create_docker_compose
    create_caddyfile
    create_env_file
    start_services
    print_completion
}

# Run main function
main
