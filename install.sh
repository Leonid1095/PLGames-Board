#!/bin/bash
#
# PLGames Board - Умный установщик
# Автоматическая установка и настройка проекта
#
# Использование: curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install.sh | bash
# Или: wget -qO- https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install.sh | bash
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

    info "Обнаружена ОС: $OS $VER"
}

# Определение региона (Россия?)
detect_region() {
    info "Проверка региона..."

    # Проверка по IP (простой способ)
    REGION=$(curl -s --max-time 3 https://ipapi.co/country/ || echo "UNKNOWN")

    if [ "$REGION" = "RU" ]; then
        warning "Обнаружен регион: Россия"
        warning "Будут использованы зеркала для Docker и NPM"
        USE_MIRRORS=1
    else
        info "Регион: $REGION (зеркала не требуются)"
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

    # Удаление старых версий
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Установка зависимостей
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    if [ "$USE_MIRRORS" -eq 1 ]; then
        # Для России - использовать зеркало
        warning "Использование зеркала Docker для России"
        curl -fsSL https://mirror.yandex.ru/mirrors/docker/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirror.yandex.ru/mirrors/docker/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        # Обычная установка
        curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Запуск Docker
    systemctl start docker
    systemctl enable docker

    success "Docker установлен: $(docker --version)"
}

# Клонирование репозитория
clone_repo() {
    info "Скачивание проекта PLGames Board..."

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

    # Клонирование
    git clone --recurse-submodules https://github.com/Leonid1095/boards_plane.git . || {
        error "Не удалось клонировать репозиторий"
        exit 1
    }

    success "Проект скачан в $INSTALL_DIR"
}

# Интерактивная настройка
configure_env() {
    info "Настройка конфигурации..."

    # Определение IP адреса
    SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Настройка PLGames Board"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Домен
    echo "1. Настройка домена:"
    echo "   Текущий IP сервера: $SERVER_IP"
    read -p "   Введите домен (или оставьте пустым для использования IP): " DOMAIN

    if [ -z "$DOMAIN" ]; then
        DOMAIN="$SERVER_IP"
        BASE_URL="http://$SERVER_IP"
        warning "Будет использован IP адрес: $SERVER_IP"
    else
        BASE_URL="https://$DOMAIN"
        success "Домен: $DOMAIN"
    fi

    # База данных
    echo ""
    echo "2. Настройка базы данных:"
    DB_USER="plgames"
    DB_NAME="plgames"
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    success "Автоматически сгенерирован пароль БД"

    # AI (опционально)
    echo ""
    echo "3. AI функции (опционально):"
    read -p "   Включить AI через OpenRouter? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "   Введите OpenRouter API ключ: " OPENROUTER_KEY
        if [ -n "$OPENROUTER_KEY" ]; then
            ENABLE_AI="true"
            success "AI будет включен"
        else
            ENABLE_AI="false"
            warning "AI ключ не указан, функция будет отключена"
        fi
    else
        ENABLE_AI="false"
        info "AI будет отключен (можно включить позже в .env)"
    fi

    # Создание .env файла
    info "Создание конфигурационного файла..."

    cat > .env << EOF
# PLGames Board Configuration
# Автоматически создано: $(date)

# Основные настройки
NODE_ENV=production
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL

# База данных
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME

# AI (OpenRouter)
AFFINE_COPILOT_ENABLED=$ENABLE_AI
EOF

    if [ "$ENABLE_AI" = "true" ]; then
        echo "AFFINE_COPILOT_OPENROUTER_API_KEY=$OPENROUTER_KEY" >> .env
        echo "AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct" >> .env
    fi

    # Безопасные права
    chmod 600 .env

    success "Конфигурация сохранена в .env"

    # Сохранение информации для пользователя
    cat > /tmp/plgames_credentials.txt << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PLGames Board - Данные для входа
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

URL: $BASE_URL
URL Backend: http://$DOMAIN:3010

База данных:
  Host: localhost:5432
  User: $DB_USER
  Password: $DB_PASSWORD
  Database: $DB_NAME

AI: $ENABLE_AI

ВАЖНО: Сохраните эту информацию в надежном месте!
       Файл будет удален через 10 минут.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Сборка и запуск
build_and_start() {
    info "Сборка Docker образов (это займет 10-20 минут)..."

    cd "$INSTALL_DIR"

    # Сборка
    docker compose -f docker-compose.prod.yml build --no-cache 2>&1 | while read line; do
        echo "    $line"
    done

    success "Образы собраны"

    # Запуск
    info "Запуск сервисов..."
    docker compose -f docker-compose.prod.yml up -d

    success "Сервисы запущены"
}

# Ожидание готовности PostgreSQL
wait_postgres() {
    info "Ожидание готовности PostgreSQL..."

    for i in {1..30}; do
        if docker compose -f docker-compose.prod.yml exec -T postgres pg_isready -U $DB_USER &>/dev/null; then
            success "PostgreSQL готов"
            return 0
        fi
        echo -n "."
        sleep 2
    done

    error "PostgreSQL не готов после 60 секунд"
    return 1
}

# Выполнение миграций
run_migrations() {
    info "Выполнение миграций базы данных..."

    cd "$INSTALL_DIR"

    docker compose -f docker-compose.prod.yml exec -T backend sh -c "npx prisma migrate deploy" || {
        warning "Миграции не выполнены, пробую альтернативный метод..."
        docker compose -f docker-compose.prod.yml run --rm backend sh -c "npx prisma migrate deploy"
    }

    success "Миграции выполнены"
}

# Проверка работоспособности
health_check() {
    info "Проверка работоспособности..."

    cd "$INSTALL_DIR"

    # Проверка статуса контейнеров
    if ! docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        error "Контейнеры не запущены!"
        return 1
    fi

    # Ожидание запуска backend (до 60 секунд)
    info "Ожидание запуска backend сервера..."
    for i in {1..30}; do
        if curl -s http://localhost:3010/graphql &>/dev/null; then
            success "Backend сервер запущен"
            break
        fi
        echo -n "."
        sleep 2
    done

    # Финальная проверка
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3010/graphql | grep -q "200\|400"; then
        success "✓ Backend работает (порт 3010)"
    else
        warning "Backend может быть не готов, проверьте логи"
    fi

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
        success "✓ Frontend работает (порт 8080)"
    else
        warning "Frontend может быть не готов"
    fi

    success "Проверка завершена"
}

# Показать финальную информацию
show_final_info() {
    clear
    cat /tmp/plgames_credentials.txt
    echo ""

    success "Установка завершена!"
    echo ""

    info "Команды управления:"
    echo "  Статус:      docker compose -f $INSTALL_DIR/docker-compose.prod.yml ps"
    echo "  Логи:        docker compose -f $INSTALL_DIR/docker-compose.prod.yml logs -f"
    echo "  Остановка:   docker compose -f $INSTALL_DIR/docker-compose.prod.yml down"
    echo "  Перезапуск:  docker compose -f $INSTALL_DIR/docker-compose.prod.yml restart"
    echo ""

    info "Файлы:"
    echo "  Директория:  $INSTALL_DIR"
    echo "  Конфигурация: $INSTALL_DIR/.env"
    echo "  Документация: $INSTALL_DIR/README.md"
    echo ""

    # Удаление файла с паролями через 10 минут
    (sleep 600 && rm -f /tmp/plgames_credentials.txt) &
}

# Обработка ошибок
error_handler() {
    error "Произошла ошибка на строке $1"
    error "Проверьте логи: docker compose -f $INSTALL_DIR/docker-compose.prod.yml logs"
    exit 1
}

trap 'error_handler $LINENO' ERR

# ============================================
# ГЛАВНАЯ ФУНКЦИЯ
# ============================================

main() {
    clear
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PLGames Board - Автоматическая установка"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    info "Начало установки..."
    echo ""

    # Шаг 1: Проверки
    info "[1/8] Проверка системы..."
    check_root
    detect_os
    detect_region
    success "Система готова"
    echo ""

    # Шаг 2: Docker
    info "[2/8] Установка Docker..."
    install_docker
    success "Docker готов"
    echo ""

    # Шаг 3: Скачивание
    info "[3/8] Скачивание проекта..."
    clone_repo
    success "Проект скачан"
    echo ""

    # Шаг 4: Настройка
    info "[4/8] Настройка конфигурации..."
    configure_env
    success "Конфигурация готова"
    echo ""

    # Шаг 5: Сборка
    info "[5/8] Сборка приложения..."
    build_and_start
    success "Приложение собрано"
    echo ""

    # Шаг 6: Ожидание PostgreSQL
    info "[6/8] Ожидание базы данных..."
    wait_postgres
    success "База данных готова"
    echo ""

    # Шаг 7: Миграции
    info "[7/8] Настройка базы данных..."
    run_migrations
    success "База данных настроена"
    echo ""

    # Шаг 8: Проверка
    info "[8/8] Финальная проверка..."
    health_check
    success "Все сервисы работают"
    echo ""

    # Показать информацию
    show_final_info
}

# Запуск
main "$@"
