#!/bin/bash
#
# PLGames Board - Установщик для сервера
# Полная автоматическая установка из GitHub
#
# Использование: sudo bash install.sh
#

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PLGames Board - Установка на сервер"
echo "  Основа: AFFINE + CRM (Plane)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Проверка root
if [ "$EUID" -ne 0 ]; then
    error "Запустите с sudo: sudo bash install.sh"
    exit 1
fi

# Проверка места на диске
info "Проверка дискового пространства..."
AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
REQUIRED=15

if [ "$AVAILABLE" -lt "$REQUIRED" ]; then
    error "Недостаточно места: ${AVAILABLE}GB (требуется ${REQUIRED}GB)"
    exit 1
fi
success "Доступно ${AVAILABLE}GB"

# Установка директории (по умолчанию в домашней директории пользователя)
INSTALL_DIR="${INSTALL_DIR:-$HOME/plgames}"

# Если запущено через sudo, используем домашнюю директорию реального пользователя
if [ -n "$SUDO_USER" ]; then
    INSTALL_DIR="/home/$SUDO_USER/plgames"
fi

# Проверка существующей установки
if [ -d "$INSTALL_DIR" ]; then
    warning "Директория $INSTALL_DIR уже существует"
    echo ""
    echo "Выберите действие:"
    echo "1) Обновить (git pull + пересборка)"
    echo "2) Переустановить (удалить всё)"
    echo "3) Использовать текущую версию"
    echo "4) Отмена"
    echo ""
    read -p "Ваш выбор [1-4]: " CHOICE

    case $CHOICE in
        1) MODE="update" ;;
        2)
            warning "Все данные будут удалены!"
            read -p "Продолжить? [y/N]: " CONFIRM
            if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
                error "Отменено"
                exit 0
            fi
            info "Остановка контейнеров..."
            cd "$INSTALL_DIR" && docker compose down -v 2>/dev/null || true
            cd /
            BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%s)"
            mv "$INSTALL_DIR" "$BACKUP_DIR"
            success "Бэкап: $BACKUP_DIR"
            MODE="install"
            ;;
        3) MODE="skip_git" ;;
        4) error "Отменено"; exit 0 ;;
        *) error "Неверный выбор"; exit 1 ;;
    esac
else
    MODE="install"
fi

# Установка Docker
if ! command -v docker &> /dev/null; then
    info "Установка Docker..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
    success "Docker установлен"
else
    success "Docker уже установлен ($(docker --version))"
fi

# Клонирование/обновление репозитория
if [ "$MODE" = "install" ]; then
    info "Клонирование репозитория..."
    git clone https://github.com/Leonid1095/boards_plane.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
elif [ "$MODE" = "update" ]; then
    info "Обновление репозитория..."
    cd "$INSTALL_DIR"
    [ -f .env ] && cp .env .env.backup
    git pull origin main || {
        warning "git pull не удался, клонирую заново..."
        cd /
        mv "$INSTALL_DIR" "${INSTALL_DIR}_old_$(date +%s)"
        git clone https://github.com/Leonid1095/boards_plane.git "$INSTALL_DIR"
        cd "$INSTALL_DIR"
        [ -f ../*.backup/.env ] && cp ../*.backup/.env .
    }
elif [ "$MODE" = "skip_git" ]; then
    info "Используется текущая версия кода"
    cd "$INSTALL_DIR"
fi

success "Код готов: $INSTALL_DIR"

# Конфигурация
if [ ! -f .env ]; then
    # Файла .env нет - создаём новый с вопросами
    info "Настройка конфигурации..."

    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Конфигурация"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Определяем: домен или IP
    echo "У вас есть домен для этого проекта?"
    echo "1) Да, у меня есть домен (автоматический HTTPS)"
    echo "2) Нет, буду использовать IP (HTTP на портах)"
    echo ""
    read -p "Ваш выбор [1-2]: " DOMAIN_CHOICE

    if [ "$DOMAIN_CHOICE" = "1" ]; then
        # Режим с доменом и HTTPS
        read -p "Введите ваш домен (например, uwow-guide.online): " DOMAIN

        if [ -z "$DOMAIN" ]; then
            error "Домен не может быть пустым!"
            exit 1
        fi

        USE_HTTPS=true
        FRONTEND_PORT=443
        BACKEND_PORT=3010
        BASE_URL="https://${DOMAIN}"
        DISPLAY_URL="https://${DOMAIN}"

        info "Режим: HTTPS с автоматическим сертификатом"
        warning "Убедитесь что DNS-запись для $DOMAIN указывает на $SERVER_IP"

    else
        # Режим с IP и портами
        read -p "IP адрес сервера [$SERVER_IP]: " DOMAIN
        DOMAIN=${DOMAIN:-$SERVER_IP}

        read -p "Порт frontend [8080]: " FRONTEND_PORT
        FRONTEND_PORT=${FRONTEND_PORT:-8080}

        read -p "Порт backend [3010]: " BACKEND_PORT
        BACKEND_PORT=${BACKEND_PORT:-3010}

        USE_HTTPS=false
        BASE_URL="http://${DOMAIN}:${FRONTEND_PORT}"
        DISPLAY_URL="http://${DOMAIN}:${FRONTEND_PORT}"

        info "Режим: HTTP на портах (для тестирования)"
    fi

    read -p "Имя БД [plgames]: " DB_NAME
    DB_NAME=${DB_NAME:-plgames}

    read -p "Пользователь БД [plgames]: " DB_USER
    DB_USER=${DB_USER:-plgames}

    # Генерируем случайный пароль или просим ввести свой
    RANDOM_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo ""
    echo "Пароль БД (оставьте пустым для автогенерации):"
    read -p "Пароль БД [$RANDOM_PASSWORD]: " DB_PASSWORD
    DB_PASSWORD=${DB_PASSWORD:-$RANDOM_PASSWORD}

    cat > .env << EOF
# PLGames Configuration ($(date))
NODE_ENV=production
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT
USE_HTTPS=$USE_HTTPS

# Database
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
POSTGRES_PORT=5432

# AI (опционально)
AFFINE_COPILOT_ENABLED=false
# AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-v1-ваш-ключ
EOF

    chmod 600 .env
    success "Конфигурация создана (.env)"
    echo ""
    info "Ваши настройки:"
    echo "  Домен: $DOMAIN"
    echo "  URL: $DISPLAY_URL"
    echo "  Backend: http://${DOMAIN}:${BACKEND_PORT}"
    echo "  БД: $DB_USER@$DB_NAME"
    echo "  Пароль БД: $DB_PASSWORD"
    if [ "$USE_HTTPS" = "true" ]; then
        echo ""
        warning "ВАЖНО: Откройте порты 80 и 443 для автоматического получения SSL-сертификата:"
        echo "  sudo ufw allow 80/tcp"
        echo "  sudo ufw allow 443/tcp"
    fi
    echo ""
else
    # Файл .env уже есть - загружаем из него
    source .env
    warning "Используется существующий .env"
    info "Текущие настройки:"
    echo "  Домен: ${DOMAIN:-не указан}"
    echo "  URL: ${BASE_URL:-не указан}"
    echo "  HTTPS: ${USE_HTTPS:-false}"
    echo ""
fi

# Сборка и запуск
info "Остановка старых контейнеров..."
if [ "$USE_HTTPS" = "true" ]; then
    docker compose -f docker-compose.yml -f docker-compose.https.yml down 2>/dev/null || true
else
    docker compose down 2>/dev/null || true
fi

info "Сборка образов (20-30 минут)..."
echo ""
warning "Некоторые этапы (Rust, установка зависимостей) могут занять 5-10 минут без видимого прогресса"
info "Следите за сообщениями ⏳ и ✓ в выводе ниже"
echo ""

# Сборка с логированием
# При обновлении используем кэш для ускорения, при установке - без кэша
if [ "$MODE" = "use_existing" ]; then
    info "Используется кэш Docker для ускорения сборки..."
    docker compose build --progress=plain 2>&1 | tee /tmp/plgames-build.log
else
    docker compose build --no-cache --progress=plain 2>&1 | tee /tmp/plgames-build.log
fi

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    success "Образы собраны"
else
    error "Ошибка сборки! Лог: /tmp/plgames-build.log"
    tail -50 /tmp/plgames-build.log
    exit 1
fi

# Запуск
info "Запуск сервисов..."
if [ "$USE_HTTPS" = "true" ]; then
    info "Запуск в режиме HTTPS с автоматическим сертификатом..."
    docker compose -f docker-compose.yml -f docker-compose.https.yml up -d
else
    docker compose up -d
fi

if [ $? -ne 0 ]; then
    error "Не удалось запустить контейнеры!"
    exit 1
fi

success "Контейнеры запущены"
sleep 5

# Проверка
info "Проверка готовности..."
echo ""

# Определяем compose команду в зависимости от режима
if [ "$USE_HTTPS" = "true" ]; then
    COMPOSE_CMD="docker compose -f docker-compose.yml -f docker-compose.https.yml"
else
    COMPOSE_CMD="docker compose"
fi

# PostgreSQL
info "Ожидание PostgreSQL..."
for i in {1..30}; do
    if $COMPOSE_CMD exec -T postgres pg_isready -U ${DB_USER:-plgames} &>/dev/null; then
        success "PostgreSQL готов"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Backend
info "Ожидание Backend..."
for i in {1..60}; do
    # Проверяем healthcheck внутри контейнера (работает для любого режима)
    if $COMPOSE_CMD exec -T backend curl -sf http://localhost:3010/api/healthz &>/dev/null; then
        success "Backend готов"
        break
    fi
    [ $((i % 5)) -eq 0 ] && echo "  Ожидание... ($i/60)"
    sleep 2
done
echo ""

# Frontend/Caddy
if [ "$USE_HTTPS" = "true" ]; then
    info "Ожидание Caddy (HTTPS)..."
    for i in {1..30}; do
        if $COMPOSE_CMD exec -T caddy wget -q --spider http://frontend:80 &>/dev/null; then
            success "Caddy готов"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
fi

# Итог
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ PLGames Board установлен!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$USE_HTTPS" = "true" ]; then
    echo "🌐 URL:       https://${DOMAIN}"
    echo "🔒 HTTPS:     Автоматический сертификат Let's Encrypt"
    echo "🔧 Backend:   http://${DOMAIN}:${BACKEND_PORT}"
    echo ""
    info "Caddy автоматически получит SSL-сертификат при первом обращении."
    info "Это может занять несколько минут."
else
    echo "🌐 Frontend:  http://${DOMAIN}:${FRONTEND_PORT}"
    echo "🔧 Backend:   http://${DOMAIN}:${BACKEND_PORT}"
    echo "📊 GraphQL:   http://${DOMAIN}:${BACKEND_PORT}/graphql"
fi

echo ""
echo "📁 Директория: $INSTALL_DIR"
echo "📝 Конфигурация: $INSTALL_DIR/.env"
echo ""
echo "Команды управления (от вашего пользователя):"
echo "  cd $INSTALL_DIR"

if [ "$USE_HTTPS" = "true" ]; then
    echo "  docker compose -f docker-compose.yml -f docker-compose.https.yml ps       # Статус"
    echo "  docker compose -f docker-compose.yml -f docker-compose.https.yml logs -f  # Логи"
    echo "  docker compose -f docker-compose.yml -f docker-compose.https.yml restart  # Перезапуск"
    echo "  docker compose -f docker-compose.yml -f docker-compose.https.yml down     # Остановка"
else
    echo "  docker compose ps          # Статус"
    echo "  docker compose logs -f     # Логи"
    echo "  docker compose restart     # Перезапуск"
    echo "  docker compose down        # Остановка"
fi
echo ""

# Если запущено через sudo, покажем как передать права
if [ -n "$SUDO_USER" ]; then
    info "Устанавливаем права доступа для пользователя $SUDO_USER..."
    chown -R $SUDO_USER:$SUDO_USER "$INSTALL_DIR"
    success "Права установлены"
fi

# Проверка firewall
if command -v ufw &> /dev/null; then
    warning "Не забудьте открыть порты в firewall:"
    echo "  sudo ufw allow ${FRONTEND_PORT}/tcp"
    echo "  sudo ufw allow ${BACKEND_PORT}/tcp"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Показать статус
docker compose ps

exit 0
