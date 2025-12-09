#!/bin/bash
# PLGames Board - Полностью автоматическая установка
# Для продакшн-сервера с 8GB RAM
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-auto.sh | sudo bash
#
# Или:
#   wget https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-auto.sh
#   sudo bash install-auto.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║        🚀 PLGames Board - Автоматическая установка        ║"
echo "║                                                            ║"
echo "║   Всё сделаю сам: Docker + Сборка + Настройка + Запуск   ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Запустите с sudo: sudo bash install-auto.sh${NC}"
    exit 1
fi

# Get real user (when using sudo)
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo -e "${BLUE}👤 Пользователь: ${REAL_USER}${NC}"
echo -e "${BLUE}🏠 Домашний каталог: ${REAL_HOME}${NC}"
echo ""

# ============================================================================
# STEP 1: System checks
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 1: Проверка системы${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
echo -e "${BLUE}💾 RAM: ${TOTAL_RAM}GB${NC}"

if [ "$TOTAL_RAM" -lt 7 ]; then
    echo -e "${RED}❌ Недостаточно RAM: ${TOTAL_RAM}GB (нужно минимум 8GB)${NC}"
    echo "   Рекомендуется использовать install-prebuilt.sh на сервере с 2GB RAM"
    exit 1
fi

# Check disk space
AVAILABLE_GB=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
echo -e "${BLUE}💿 Свободно на диске: ${AVAILABLE_GB}GB${NC}"

if [ "$AVAILABLE_GB" -lt 20 ]; then
    echo -e "${RED}❌ Недостаточно места: ${AVAILABLE_GB}GB (нужно минимум 20GB)${NC}"
    exit 1
fi

# Check swap
SWAP_SIZE=$(free -g | awk '/^Swap:/{print $2}')
echo -e "${BLUE}💾 SWAP: ${SWAP_SIZE}GB${NC}"

if [ "$SWAP_SIZE" -lt 4 ]; then
    echo -e "${YELLOW}⚠️  SWAP меньше 4GB, создаю...${NC}"

    if [ -f /swapfile ]; then
        swapoff /swapfile 2>/dev/null || true
        rm -f /swapfile
    fi

    dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    sysctl vm.swappiness=10
    if ! grep -q 'vm.swappiness' /etc/sysctl.conf; then
        echo 'vm.swappiness=10' >> /etc/sysctl.conf
    fi

    echo -e "${GREEN}✓ SWAP 4GB создан${NC}"
fi

echo -e "${GREEN}✓ Система готова${NC}"
echo ""

# ============================================================================
# STEP 2: Install Docker
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 2: Установка Docker${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Устанавливаю Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    usermod -aG docker $REAL_USER
    echo -e "${GREEN}✓ Docker установлен${NC}"
else
    echo -e "${GREEN}✓ Docker уже установлен${NC}"
fi

if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Устанавливаю Docker Compose...${NC}"
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
         -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    echo -e "${GREEN}✓ Docker Compose установлен${NC}"
else
    echo -e "${GREEN}✓ Docker Compose уже установлен${NC}"
fi

echo ""

# ============================================================================
# STEP 3: Install Node.js
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 3: Установка Node.js 22${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if ! command -v node &> /dev/null || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt 22 ]; then
    echo -e "${YELLOW}Устанавливаю Node.js 22...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
    npm install -g corepack
    corepack enable
    echo -e "${GREEN}✓ Node.js $(node -v) установлен${NC}"
else
    echo -e "${GREEN}✓ Node.js $(node -v) уже установлен${NC}"
fi

echo ""

# ============================================================================
# STEP 4: Clone repository
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 4: Загрузка проекта${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

INSTALL_DIR="${REAL_HOME}/plane"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Директория ${INSTALL_DIR} уже существует${NC}"
    echo "Что делать?"
    echo "  1) Обновить (git pull)"
    echo "  2) Удалить и клонировать заново"
    echo "  3) Использовать существующую"
    read -p "Выбор (1/2/3): " repo_choice

    case $repo_choice in
        1)
            echo -e "${BLUE}Обновляю...${NC}"
            cd "$INSTALL_DIR"
            sudo -u $REAL_USER git pull origin main
            ;;
        2)
            echo -e "${YELLOW}Удаляю и клонирую заново...${NC}"
            rm -rf "$INSTALL_DIR"
            cd "$REAL_HOME"
            sudo -u $REAL_USER git clone https://github.com/Leonid1095/boards_plane.git plane
            ;;
        3)
            echo -e "${BLUE}Использую существующую${NC}"
            ;;
        *)
            echo -e "${RED}Неверный выбор${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${BLUE}Клонирую репозиторий...${NC}"
    cd "$REAL_HOME"
    sudo -u $REAL_USER git clone https://github.com/Leonid1095/boards_plane.git plane
fi

cd "$INSTALL_DIR"
echo -e "${GREEN}✓ Проект загружен в ${INSTALL_DIR}${NC}"
echo ""

# ============================================================================
# STEP 5: Configuration
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 5: Настройка${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Выберите тип установки:"
echo "  1) Домен с HTTPS (автоматический SSL через Let's Encrypt)"
echo "  2) IP адрес с HTTP (без SSL)"
echo ""
read -p "Ваш выбор (1/2): " setup_choice

if [ "$setup_choice" = "1" ]; then
    # Domain with HTTPS
    read -p "Введите ваш домен (например, plgames.example.com): " DOMAIN

    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}❌ Домен не может быть пустым${NC}"
        exit 1
    fi

    BASE_URL="https://${DOMAIN}"
    FRONTEND_PORT="443"
    BACKEND_PORT="3010"
    USE_HTTPS="yes"

    echo -e "${GREEN}✓ Настроен домен: ${DOMAIN}${NC}"
    echo -e "${YELLOW}⚠️  Убедитесь, что DNS запись ${DOMAIN} указывает на этот сервер!${NC}"
else
    # IP with HTTP
    SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    echo ""
    echo -e "Обнаружен IP: ${GREEN}${SERVER_IP}${NC}"
    read -p "Использовать этот IP? (y/n): " use_ip

    if [[ ! "$use_ip" =~ ^[Yy]$ ]]; then
        read -p "Введите IP адрес сервера: " SERVER_IP
    fi

    DOMAIN="${SERVER_IP}"
    BASE_URL="http://${SERVER_IP}:8080"
    FRONTEND_PORT="8080"
    BACKEND_PORT="3010"
    USE_HTTPS="no"

    echo -e "${GREEN}✓ Настроен IP: ${SERVER_IP}${NC}"
fi

# Generate secure password
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)

# Create .env file
cat > .env << EOF
# PLGames Board Configuration
# Generated: $(date)

# Domain/IP
DOMAIN=${DOMAIN}
BASE_URL=${BASE_URL}

# Ports
FRONTEND_PORT=${FRONTEND_PORT}
BACKEND_PORT=${BACKEND_PORT}

# Database
DB_USER=plgames
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=plgames
POSTGRES_PORT=5432

# Node
NODE_ENV=production

# Optional: AI (OpenRouter)
AFFINE_COPILOT_ENABLED=false
# AFFINE_COPILOT_OPENROUTER_API_KEY=your-key-here

# Optional: OAuth (Yandex)
# OIDC_CLIENT_ID=your-client-id
# OIDC_CLIENT_SECRET=your-client-secret
EOF

echo -e "${GREEN}✓ Конфигурация сохранена в .env${NC}"
echo ""

# ============================================================================
# STEP 6: Build project
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 6: Сборка проекта (это займет 20-30 минут)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$INSTALL_DIR"

# Check if already built
if [ -d "plgames/packages/backend/server/dist" ] && [ -d "plgames/packages/frontend/apps/web/dist" ]; then
    echo -e "${YELLOW}Проект уже собран${NC}"
    read -p "Пересобрать? (y/n): " rebuild
    if [[ ! "$rebuild" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Пропускаю сборку${NC}"
        SKIP_BUILD=true
    fi
fi

if [ "$SKIP_BUILD" != "true" ]; then
    echo -e "${BLUE}🔨 Начинаю сборку...${NC}"
    echo ""

    # Run build script as real user
    sudo -u $REAL_USER bash build.sh

    echo ""
    echo -e "${GREEN}✓ Сборка завершена${NC}"
else
    echo -e "${GREEN}✓ Используется существующая сборка${NC}"
fi

echo ""

# ============================================================================
# STEP 7: Start Docker
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 7: Запуск Docker контейнеров${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$INSTALL_DIR"

# Choose docker-compose file
if [ "$USE_HTTPS" = "yes" ]; then
    COMPOSE_CMD="docker compose -f docker-compose.simple.yml -f docker-compose.https.yml"
else
    COMPOSE_CMD="docker compose -f docker-compose.simple.yml"
fi

echo -e "${BLUE}🐳 Собираю Docker образы...${NC}"
$COMPOSE_CMD build

echo ""
echo -e "${BLUE}🚀 Запускаю контейнеры...${NC}"
$COMPOSE_CMD up -d

echo ""

# ============================================================================
# STEP 8: Wait and verify
# ============================================================================

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  ШАГ 8: Проверка работоспособности${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}⏳ Ожидание запуска сервисов (1-2 минуты)...${NC}"
sleep 20

# Health check
MAX_ATTEMPTS=12
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -sf http://localhost:3010/api/healthz > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Backend работает${NC}"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 5
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Backend еще запускается...${NC}"
    echo "   Проверьте логи: cd ${INSTALL_DIR} && docker compose logs -f backend"
fi

# ============================================================================
# DONE
# ============================================================================

clear
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║            ✅ PLGames Board успешно установлен!           ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}🌐 Ваш сайт доступен по адресу:${NC}"
echo -e "${CYAN}   ${BASE_URL}${NC}"
echo ""

if [ "$USE_HTTPS" = "yes" ]; then
    echo -e "${YELLOW}⚠️  Для HTTPS убедитесь что:${NC}"
    echo "   1. DNS запись ${DOMAIN} указывает на IP: $(curl -s ifconfig.me)"
    echo "   2. Порты открыты:"
    echo "      sudo ufw allow 80/tcp"
    echo "      sudo ufw allow 443/tcp"
    echo ""
fi

echo -e "${BLUE}📊 Полезные команды:${NC}"
echo ""
echo "  Статус:"
echo "    cd ${INSTALL_DIR} && docker compose -f docker-compose.simple.yml ps"
echo ""
echo "  Логи:"
echo "    cd ${INSTALL_DIR} && docker compose -f docker-compose.simple.yml logs -f"
echo ""
echo "  Перезапуск:"
echo "    cd ${INSTALL_DIR} && docker compose -f docker-compose.simple.yml restart"
echo ""
echo "  Остановка:"
echo "    cd ${INSTALL_DIR} && docker compose -f docker-compose.simple.yml down"
echo ""
echo "  Бэкап базы:"
echo "    cd ${INSTALL_DIR} && docker compose -f docker-compose.simple.yml exec postgres pg_dump -U plgames plgames > backup.sql"
echo ""
echo -e "${GREEN}✨ Готово! Откройте ${BASE_URL} в браузере${NC}"
echo ""
