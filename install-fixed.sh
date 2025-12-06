#!/bin/bash
#
# PLGames Board - Исправленный установщик с поддержкой существующих директорий
# Автоматическая установка и настройка проекта
#
# Использование: bash install-fixed.sh
#

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для красивого вывода
info() {
    echo -e "${BLUE}ℹ ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Проверка запуска с root правами
check_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &> /dev/null; then
        error "Этот скрипт требует root прав или sudo"
        exit 1
    fi
}

# Проверка дискового пространства
check_disk_space() {
    info "Проверка дискового пространства..."

    AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    REQUIRED=15

    if [ "$AVAILABLE" -lt "$REQUIRED" ]; then
        warning "Мало места на диске: ${AVAILABLE}GB (требуется ${REQUIRED}GB)"

        read -p "Выполнить очистку Docker (docker system prune -af)? [y/N]: " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Очистка Docker..."
            docker system prune -af
            success "Очистка завершена"
        else
            error "Недостаточно места для продолжения"
            exit 1
        fi
    else
        success "Доступно ${AVAILABLE}GB места"
    fi
}

# Проверка существующей установки
check_existing_installation() {
    # Если переменная не задана, пытаемся определить автоматически
    if [ -z "$INSTALL_DIR" ]; then
        if [ -d ".git" ]; then
            INSTALL_DIR=$(pwd)
        else
            INSTALL_DIR="/opt/plgames"
        fi
    fi

    if [ -d "$INSTALL_DIR" ]; then
        warning "Директория $INSTALL_DIR уже существует"
        echo ""
        echo "Выберите действие:"
        echo "1) Обновить существующую установку (сохранить данные)"
        echo "2) Переустановить (удалить все и начать заново)"
        echo "3) Отменить установку"
        echo ""
        read -p "Ваш выбор [1-3]: " -r CHOICE

        case $CHOICE in
            1)
                info "Режим обновления"
                MODE="update"
                ;;
            2)
                warning "Все данные будут удалены!"
                read -p "Вы уверены? [y/N]: " -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    info "Подготовка к переустановке..."
                    
                    # Важно: выходим из директории, чтобы не потерять контекст при её удалении/перемещении
                    cd /

                    info "Остановка контейнеров..."
                    if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
                        docker compose -f "$INSTALL_DIR/docker-compose.yml" down -v 2>/dev/null || true
                    fi

                    info "Перемещение старой версии в бэкап..."
                    # Используем mv вместо rm, чтобы:
                    # 1. Сохранить данные на всякий случай
                    # 2. Не сломать выполнение скрипта, если он запущен из этой директории
                    BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%s)"
                    mv "$INSTALL_DIR" "$BACKUP_DIR"
                    
                    success "Старая версия перемещена в $BACKUP_DIR"
                    MODE="install"
                else
                    error "Установка отменена"
                    exit 0
                fi
                ;;
            3)
                error "Установка отменена"
                exit 0
                ;;
            *)
                error "Неверный выбор"
                exit 1
                ;;
        esac
    else
        MODE="install"
    fi
}

# Установка Docker
install_docker() {
    if command -v docker &> /dev/null; then
        success "Docker уже установлен ($(docker --version))"
        return 0
    fi

    info "Установка Docker..."

    # Для Ubuntu/Debian
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl start docker
    systemctl enable docker

    success "Docker установлен"
}

# Клонирование или обновление репозитория
setup_repository() {
    INSTALL_DIR=${INSTALL_DIR:-/opt/plgames}

    if [ "$MODE" = "update" ]; then
        info "Обновление репозитория..."
        cd "$INSTALL_DIR"

        # Сохранение .env если он существует
        if [ -f .env ]; then
            cp .env .env.backup
            success ".env файл сохранен"
        fi

        git pull origin main || {
            warning "Не удалось обновить через git, используем альтернативный метод"
            cd ..
            mv plgames plgames.backup.$(date +%s)
            git clone https://github.com/Leonid1095/boards_plane.git plgames
            cd plgames

            # Восстановление .env
            if [ -f ../plgames.backup.*/\.env ]; then
                cp ../plgames.backup.*/\.env .
                success ".env восстановлен"
            fi
        }
    else
        info "Клонирование репозитория..."
        mkdir -p "$INSTALL_DIR"
        git clone https://github.com/Leonid1095/boards_plane.git "$INSTALL_DIR"
    fi

    cd "$INSTALL_DIR"
    success "Репозиторий готов"
}

# Интерактивная конфигурация
configure_project() {
    info "Настройка конфигурации..."

    # Если .env существует и режим обновления, пропускаем
    if [ "$MODE" = "update" ] && [ -f .env ]; then
        warning "Используется существующий .env файл"
        read -p "Хотите изменить конфигурацию? [y/N]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    # Получение IP сервера
    SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Конфигурация PLGames Board"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    read -p "Домен или IP [$SERVER_IP]: " DOMAIN
    DOMAIN=${DOMAIN:-$SERVER_IP}

    read -p "Порт frontend [8080]: " FRONTEND_PORT
    FRONTEND_PORT=${FRONTEND_PORT:-8080}

    read -p "Порт backend [3010]: " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-3010}

    BASE_URL="http://${DOMAIN}:${FRONTEND_PORT}"

    # База данных
    read -p "Имя пользователя БД [plgames]: " DB_USER
    DB_USER=${DB_USER:-plgames}

    read -p "Пароль БД (или Enter для генерации): " DB_PASSWORD
    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        info "Сгенерирован пароль БД: $DB_PASSWORD"
    fi

    read -p "Имя БД [plgames]: " DB_NAME
    DB_NAME=${DB_NAME:-plgames}

    # AI
    read -p "Включить AI (OpenRouter)? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ENABLE_AI=true
        read -p "OpenRouter API ключ: " OPENROUTER_KEY
    else
        ENABLE_AI=false
    fi

    # OAuth
    read -p "Настроить OAuth (Yandex)? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Client ID: " OIDC_CLIENT_ID
        read -p "Client Secret: " OIDC_CLIENT_SECRET
    fi

    # Создание .env файла
    cat > .env << EOF
# PLGames Board Configuration
# Автоматически создано: $(date)

# Основные настройки
NODE_ENV=production
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT

# База данных
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
POSTGRES_PORT=5432

# AI (OpenRouter)
AFFINE_COPILOT_ENABLED=$ENABLE_AI
EOF

    if [ "$ENABLE_AI" = "true" ]; then
        echo "AFFINE_COPILOT_OPENROUTER_API_KEY=$OPENROUTER_KEY" >> .env
        echo "AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct" >> .env
    fi

    if [ -n "$OIDC_CLIENT_ID" ]; then
        echo "" >> .env
        echo "# OAuth (Yandex)" >> .env
        echo "OIDC_CLIENT_ID=$OIDC_CLIENT_ID" >> .env
        echo "OIDC_CLIENT_SECRET=$OIDC_CLIENT_SECRET" >> .env
    fi

    # Безопасные права
    chmod 600 .env

    success "Конфигурация сохранена в .env"
}

# Сборка и запуск
build_and_start() {
    info "Остановка существующих контейнеров..."
    docker compose down 2>/dev/null || true

    info "Сборка Docker образов (это может занять 10-20 минут)..."

    # Используем правильный docker-compose файл
    if [ -f docker-compose.yml ]; then
        COMPOSE_FILE="docker-compose.yml"
    elif [ -f docker-compose.prod.yml ]; then
        COMPOSE_FILE="docker-compose.prod.yml"
    else
        error "Не найден docker-compose файл!"
        exit 1
    fi

    info "Использую $COMPOSE_FILE"

    # Сборка с логами
    docker compose -f "$COMPOSE_FILE" build --no-cache 2>&1 | tee /tmp/plgames-build.log

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        success "Образы собраны"
    else
        error "Ошибка сборки! Проверьте лог: /tmp/plgames-build.log"
        exit 1
    fi

    # Запуск
    info "Запуск сервисов..."
    docker compose -f "$COMPOSE_FILE" up -d

    success "Сервисы запущены"
}

# Проверка здоровья сервисов
check_health() {
    info "Проверка состояния сервисов..."

    sleep 5

    docker compose ps

    echo ""
    info "Ожидание готовности PostgreSQL..."
    for i in {1..30}; do
        if docker compose exec -T postgres pg_isready -U ${DB_USER:-plgames} &>/dev/null; then
            success "PostgreSQL готов"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""

    info "Ожидание готовности backend..."
    for i in {1..30}; do
        if curl -sf http://localhost:${BACKEND_PORT:-3010}/api/healthz &>/dev/null; then
            success "Backend готов"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
}

# Вывод финальной информации
show_summary() {
    SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ PLGames Board успешно установлен!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 URL Frontend: $BASE_URL"
    echo "🔧 URL Backend:  http://${DOMAIN:-$SERVER_IP}:${BACKEND_PORT:-3010}"
    echo "📊 GraphQL:      http://${DOMAIN:-$SERVER_IP}:${BACKEND_PORT:-3010}/graphql"
    echo ""
    echo "📁 Директория:   $INSTALL_DIR"
    echo "📝 Конфигурация: $INSTALL_DIR/.env"
    echo ""
    echo "Команды управления:"
    echo "  cd $INSTALL_DIR"
    echo "  docker compose ps          # Статус"
    echo "  docker compose logs -f     # Логи"
    echo "  docker compose restart     # Перезапуск"
    echo "  docker compose down        # Остановка"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Главная функция
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PLGames Board - Исправленный установщик"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    check_root
    check_disk_space
    check_existing_installation
    install_docker
    setup_repository
    configure_project
    build_and_start
    check_health
    show_summary
}

# Запуск
main
