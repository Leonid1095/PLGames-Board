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

    read -p "Домен или IP [$SERVER_IP]: " DOMAIN
    DOMAIN=${DOMAIN:-$SERVER_IP}

    read -p "Порт frontend [8080]: " FRONTEND_PORT
    FRONTEND_PORT=${FRONTEND_PORT:-8080}

    read -p "Порт backend [3010]: " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-3010}

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
BASE_URL=http://${DOMAIN}:${FRONTEND_PORT}
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT

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
    echo "  Frontend: http://${DOMAIN}:${FRONTEND_PORT}"
    echo "  Backend: http://${DOMAIN}:${BACKEND_PORT}"
    echo "  БД: $DB_USER@$DB_NAME"
    echo "  Пароль БД: $DB_PASSWORD"
    echo ""
else
    # Файл .env уже есть - загружаем из него
    source .env
    warning "Используется существующий .env"
    info "Текущие настройки:"
    echo "  Домен: ${DOMAIN:-не указан}"
    echo "  Frontend порт: ${FRONTEND_PORT:-не указан}"
    echo "  Backend порт: ${BACKEND_PORT:-не указан}"
    echo ""
fi

# Сборка и запуск
info "Остановка старых контейнеров..."
docker compose down 2>/dev/null || true

info "Сборка образов (10-20 минут)..."
echo ""

# Сборка с логированием
docker compose build --no-cache 2>&1 | tee /tmp/plgames-build.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    success "Образы собраны"
else
    error "Ошибка сборки! Лог: /tmp/plgames-build.log"
    tail -50 /tmp/plgames-build.log
    exit 1
fi

# Запуск
info "Запуск сервисов..."
docker compose up -d

sleep 5

# Проверка
info "Проверка готовности..."
echo ""

# PostgreSQL
info "Ожидание PostgreSQL..."
for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U plgames &>/dev/null; then
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
    if curl -sf http://localhost:${BACKEND_PORT:-3010}/api/healthz &>/dev/null; then
        success "Backend готов"
        break
    fi
    [ $((i % 5)) -eq 0 ] && echo "  Ожидание... ($i/60)"
    sleep 2
done
echo ""

# Итог
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ PLGames Board установлен!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Frontend:  http://${DOMAIN}:${FRONTEND_PORT}"
echo "🔧 Backend:   http://${DOMAIN}:${BACKEND_PORT}"
echo "📊 GraphQL:   http://${DOMAIN}:${BACKEND_PORT}/graphql"
echo ""
echo "📁 Директория: $INSTALL_DIR"
echo "📝 Конфигурация: $INSTALL_DIR/.env"
echo ""
echo "Команды управления (от вашего пользователя):"
echo "  cd $INSTALL_DIR"
echo "  docker compose ps          # Статус"
echo "  docker compose logs -f     # Логи"
echo "  docker compose restart     # Перезапуск"
echo "  docker compose down        # Остановка"
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
