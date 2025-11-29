#!/bin/bash
set -e

# Configuration
DOMAIN="uwow-guide.online"
BASE_URL="https://${DOMAIN}"
PROJECT_DIR="/opt/plgames" # Adjust if your path is different, e.g., /home/plg/boards_plane if you moved files there

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Starting Deployment for ${DOMAIN}...${NC}"

# 1. Ensure we are in the right directory
# If the script is run from the directory, use current dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo -e "${YELLOW}📂 Working directory: $(pwd)${NC}"

# 2. Create/Update .env file
echo -e "${YELLOW}⚙️  Configuring environment variables...${NC}"

# Check if .env exists, if so, we append/update, or just overwrite for this specific deployment to be sure
# For safety, we'll write the critical vars.
cat > .env <<EOF
NODE_ENV=production
DOMAIN=${DOMAIN}
BASE_URL=${BASE_URL}
# Database Config (Defaulting to plgames/plgames if not set, change if needed)
DB_USER=plgames
DB_PASSWORD=plgames
DB_NAME=plgames
# Ports
PORT=3010
# AI / OIDC (Empty by default, fill in if you have keys)
OPENROUTER_API_KEY=
OIDC_CLIENT_ID=
OIDC_CLIENT_SECRET=
EOF

echo -e "${GREEN}✅ .env updated for ${DOMAIN}${NC}"

# 3. Stop conflicting containers
echo -e "${YELLOW}🛑 Stopping old containers...${NC}"
docker compose -f docker-compose.prod.yml down --remove-orphans || true

# 4. Build and Start
echo -e "${YELLOW}🏗️  Building and Starting PLGames...${NC}"
docker compose -f docker-compose.prod.yml up -d --build

# 5. Final Status
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "🌍 Frontend should be available at: ${GREEN}http://localhost:8080${NC}"
echo -e "   (Or via your reverse proxy at: ${GREEN}${BASE_URL}${NC})"
echo -e "🔌 Backend API: ${GREEN}http://localhost:3010${NC}"
echo -e ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Ensure your host's Nginx/Caddy is proxying '${DOMAIN}' to 'localhost:8080'."
echo -e "2. Check logs if needed: docker compose -f docker-compose.prod.yml logs -f"
