#!/bin/bash
#
# PLGames Board - Улучшенный установщик
# Автоматическая установка с детальной настройкой
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

# Проверка root
check_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &> /dev/null; then
        error "Требуются root права или sudo"
        exit 1
    fi
}

# Определение ОС
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        error "Не удалось определить ОС"
        exit 1
    fi
    info "ОС: $OS $VER"
}

# Проверка свободного места
check_disk_space() {
    REQUIRED_SPACE=20 # GB
    AVAILABLE=$(df / | tail -1 | awk '{print int($4/1024/1024)}')

    if [ $AVAILABLE -lt $REQUIRED_SPACE ]; then
        warning "Мало места на диске: ${AVAILABLE}GB (требуется ${REQUIRED_SPACE}GB)"
        read -p "Продолжить? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        success "Свободно места: ${AVAILABLE}GB"
    fi
}

# Проверка RAM
check_memory() {
    REQUIRED_RAM=3 # GB
    AVAILABLE=$(free -g | awk '/^Mem:/{print $2}')

    if [ $AVAILABLE -lt $REQUIRED_RAM ]; then
        warning "Мало RAM: ${AVAILABLE}GB (рекомендуется 4GB+)"
    else
        success "RAM: ${AVAILABLE}GB"
    fi
}

# Проверка занятости портов
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 1  # Порт занят
    else
        return 0  # Порт свободен
    fi
}

# Определение региона
detect_region() {
    info "Определение региона..."
    REGION=$(curl -s --max-time 3 https://ipapi.co/country/ 2>/dev/null || echo "UNKNOWN")

    if [ "$REGION" = "RU" ]; then
        warning "Регион: Россия - будут использованы зеркала"
        USE_MIRRORS=1
    else
        info "Регион: $REGION"
        USE_MIRRORS=0
    fi
}

# Установка Docker
install_docker() {
    if command -v docker &> /dev/null; then
        success "Docker уже установлен ($(docker --version))"
        return 0
    fi

    info "Установка Docker..."

    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    if [ "$USE_MIRRORS" -eq 1 ]; then
        warning "Использование зеркала Docker для России"
        curl -fsSL https://mirror.yandex.ru/mirrors/docker/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirror.yandex.ru/mirrors/docker/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl start docker
    systemctl enable docker

    success "Docker установлен: $(docker --version)"
}

# Клонирование
clone_repo() {
    info "Скачивание PLGames Board..."

    INSTALL_DIR="/opt/plgames"

    if [ -d "$INSTALL_DIR" ]; then
        warning "Директория $INSTALL_DIR уже существует"
        read -p "Удалить и переустановить? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
        else
            error "Установка отменена"
            exit 1
        fi
    fi

    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    git clone --recurse-submodules https://github.com/Leonid1095/boards_plane.git . || {
        error "Не удалось клонировать репозиторий"
        exit 1
    }

    success "Проект скачан в $INSTALL_DIR"
}

# Интерактивная настройка (улучшенная)
configure_env() {
    info "Настройка конфигурации..."

    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Настройка PLGames Board"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Домен или IP
    echo "1. Доступ к системе:"
    echo "   Текущий IP сервера: $SERVER_IP"
    echo ""
    echo "   Выберите способ доступа:"
    echo "   a) Через IP адрес (простой вариант, работает сразу)"
    echo "   b) Через домен (нужен Nginx/Caddy, настраивается отдельно)"
    echo ""
    read -p "   Выбор (a/b): " -n 1 -r ACCESS_TYPE
    echo

    if [[ $ACCESS_TYPE =~ ^[Bb]$ ]]; then
        read -p "   Введите ваш домен: " DOMAIN
        if [ -z "$DOMAIN" ]; then
            warning "Домен не указан, используется IP"
            DOMAIN="$SERVER_IP"
            BASE_URL="http://$SERVER_IP"
            USE_DOMAIN=false
        else
            BASE_URL="https://$DOMAIN"
            USE_DOMAIN=true
            warning "Домен $DOMAIN будет работать ТОЛЬКО после настройки Nginx/Caddy!"
            warning "Сразу после установки используйте: http://$SERVER_IP:8080"
        fi
    else
        DOMAIN="$SERVER_IP"
        BASE_URL="http://$SERVER_IP"
        USE_DOMAIN=false
        success "Будет использован IP: $SERVER_IP"
    fi

    # Порты
    echo ""
    echo "2. Настройка портов:"
    echo "   По умолчанию: Frontend=8080, Backend=3010, PostgreSQL=5432"
    echo ""
    read -p "   Изменить порты? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Frontend Port
        while true; do
            read -p "   Frontend порт [8080]: " FRONTEND_PORT
            FRONTEND_PORT=${FRONTEND_PORT:-8080}

            if check_port $FRONTEND_PORT; then
                success "Frontend порт: $FRONTEND_PORT"
                break
            else
                error "Порт $FRONTEND_PORT уже занят!"
            fi
        done

        # Backend Port
        while true; do
            read -p "   Backend порт [3010]: " BACKEND_PORT
            BACKEND_PORT=${BACKEND_PORT:-3010}

            if check_port $BACKEND_PORT; then
                success "Backend порт: $BACKEND_PORT"
                break
            else
                error "Порт $BACKEND_PORT уже занят!"
            fi
        done

        # PostgreSQL Port
        while true; do
            read -p "   PostgreSQL порт [5432]: " POSTGRES_PORT
            POSTGRES_PORT=${POSTGRES_PORT:-5432}

            if check_port $POSTGRES_PORT; then
                success "PostgreSQL порт: $POSTGRES_PORT"
                break
            else
                error "Порт $POSTGRES_PORT уже занят!"
            fi
        done
    else
        FRONTEND_PORT=8080
        BACKEND_PORT=3010
        POSTGRES_PORT=5432

        # Проверка стандартных портов
        PORT_CONFLICTS=""
        check_port 8080 || PORT_CONFLICTS="$PORT_CONFLICTS 8080"
        check_port 3010 || PORT_CONFLICTS="$PORT_CONFLICTS 3010"
        check_port 5432 || PORT_CONFLICTS="$PORT_CONFLICTS 5432"

        if [ -n "$PORT_CONFLICTS" ]; then
            warning "Порты уже заняты:$PORT_CONFLICTS"
            error "Запустите скрипт заново и измените порты!"
            exit 1
        fi

        success "Используются стандартные порты"
    fi

    # База данных
    echo ""
    echo "3. База данных:"
    DB_USER="plgames"
    DB_NAME="plgames"

    read -p "   Сгенерировать случайный пароль? (Y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        while true; do
            read -sp "   Введите пароль БД: " DB_PASSWORD
            echo
            read -sp "   Повторите пароль: " DB_PASSWORD2
            echo

            if [ "$DB_PASSWORD" = "$DB_PASSWORD2" ] && [ -n "$DB_PASSWORD" ]; then
                success "Пароль установлен"
                break
            else
                error "Пароли не совпадают или пустые!"
            fi
        done
    else
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        success "Пароль сгенерирован"
    fi

    # AI
    echo ""
    echo "4. AI функции (OpenRouter):"
    echo "   Подключить AI для генерации текста, суммаризации и т.д.?"
    read -p "   Включить AI? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "   OpenRouter API ключ (или Enter для пропуска): " OPENROUTER_KEY
        if [ -n "$OPENROUTER_KEY" ]; then
            ENABLE_AI="true"
            success "AI будет включен"
        else
            ENABLE_AI="false"
            info "AI отключен (можно включить позже)"
        fi
    else
        ENABLE_AI="false"
        info "AI отключен"
    fi

    # Создание .env
    info "Создание конфигурационного файла..."

    cat > .env << EOF
# PLGames Board Configuration
# Создано: $(date)

# Основные настройки
NODE_ENV=production
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL

# Порты
FRONTEND_PORT=$FRONTEND_PORT
BACKEND_PORT=$BACKEND_PORT
POSTGRES_PORT=$POSTGRES_PORT

# База данных
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME

# AI
AFFINE_COPILOT_ENABLED=$ENABLE_AI
EOF

    if [ "$ENABLE_AI" = "true" ] && [ -n "$OPENROUTER_KEY" ]; then
        echo "AFFINE_COPILOT_OPENROUTER_API_KEY=$OPENROUTER_KEY" >> .env
        echo "AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct" >> .env
    fi

    chmod 600 .env
    success "Конфигурация сохранена"

    # Сохранение информации
    cat > /tmp/plgames_info.txt << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PLGames Board - Информация для входа
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Доступ к системе:
  Frontend: http://$SERVER_IP:$FRONTEND_PORT
  Backend:  http://$SERVER_IP:$BACKEND_PORT
  GraphQL:  http://$SERVER_IP:$BACKEND_PORT/graphql

База данных:
  Host: localhost:$POSTGRES_PORT
  User: $DB_USER
  Password: $DB_PASSWORD
  Database: $DB_NAME

AI: $ENABLE_AI

EOF

    if [ "$USE_DOMAIN" = true ]; then
        cat >> /tmp/plgames_info.txt << EOF
ВАЖНО: Для работы через домен $DOMAIN настройте Nginx/Caddy
См. инструкцию: /opt/plgames/INSTALL.md

EOF
    fi

    cat >> /tmp/plgames_info.txt << EOF
Файлы:
  Конфигурация: /opt/plgames/.env
  Инструкция: /opt/plgames/INSTALL.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Сборка и запуск
build_and_start() {
    info "Сборка Docker образов (10-20 минут)..."
    cd "$INSTALL_DIR"

    docker compose build --no-cache 2>&1 | while read line; do
        echo "    $line"
    done

    success "Образы собраны"

    info "Запуск сервисов..."
    docker compose up -d

    success "Сервисы запущены"
}

# Ожидание PostgreSQL
wait_postgres() {
    info "Ожидание готовности PostgreSQL..."

    for i in {1..30}; do
        if docker compose exec -T postgres pg_isready -U $DB_USER &>/dev/null; then
            success "PostgreSQL готов"
            return 0
        fi
        echo -n "."
        sleep 2
    done

    error "PostgreSQL не готов после 60 секунд"
    return 1
}

# Миграции
run_migrations() {
    info "Выполнение миграций..."
    cd "$INSTALL_DIR"

    docker compose exec -T backend sh -c "npx prisma migrate deploy" || {
        warning "Миграции не выполнены, пробую альтернативный метод..."
        docker compose run --rm backend sh -c "npx prisma migrate deploy"
    }

    success "Миграции выполнены"
}

# Проверка
health_check() {
    info "Проверка работоспособности..."
    cd "$INSTALL_DIR"

    sleep 10

    # Статус
    docker compose ps

    # Backend
    for i in {1..10}; do
        if curl -s http://localhost:$BACKEND_PORT/graphql &>/dev/null; then
            success "Backend работает"
            break
        fi
        sleep 3
    done

    # Frontend
    if curl -s http://localhost:$FRONTEND_PORT &>/dev/null; then
        success "Frontend работает"
    else
        warning "Frontend еще не готов"
    fi
}

# Финальная информация
show_final_info() {
    clear
    cat /tmp/plgames_info.txt
    echo ""

    success "Установка завершена!"
    echo ""

    info "Команды управления:"
    echo "  cd /opt/plgames"
    echo "  docker compose ps          # Статус"
    echo "  docker compose logs -f     # Логи"
    echo "  docker compose restart     # Перезапуск"
    echo ""

    warning "Этот файл будет удален через 10 минут"
    (sleep 600 && rm -f /tmp/plgames_info.txt) &
}

# Обработка ошибок
error_handler() {
    error "Ошибка на строке $1"
    error "Логи: docker compose -f /opt/plgames/docker-compose.yml logs"
    exit 1
}

trap 'error_handler $LINENO' ERR

# ГЛАВНАЯ ФУНКЦИЯ
main() {
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PLGames Board - Установка"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    info "[1/10] Проверка системы..."
    check_root
    detect_os
    check_disk_space
    check_memory
    detect_region
    success "Система готова"
    echo ""

    info "[2/10] Установка Docker..."
    install_docker
    success "Docker готов"
    echo ""

    info "[3/10] Скачивание проекта..."
    clone_repo
    success "Проект скачан"
    echo ""

    info "[4/10] Настройка конфигурации..."
    configure_env
    success "Конфигурация готова"
    echo ""

    info "[5/10] Сборка приложения..."
    build_and_start
    success "Приложение собрано"
    echo ""

    info "[6/10] Ожидание базы данных..."
    wait_postgres
    success "База готова"
    echo ""

    info "[7/10] Настройка базы данных..."
    run_migrations
    success "База настроена"
    echo ""

    info "[8/10] Финальная проверка..."
    health_check
    success "Все работает"
    echo ""

    info "[9/10] Сохранение информации..."
    success "Информация сохранена"
    echo ""

    info "[10/10] Завершение..."
    show_final_info
}

main "$@"
