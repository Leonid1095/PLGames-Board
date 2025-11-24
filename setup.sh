#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция проверки наличия команды
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo -e "${CYAN}Добро пожаловать в установщик PLGames!${NC}"
echo -e "${CYAN}Этот скрипт поможет вам развернуть проект на вашем сервере.${NC}"
echo ""

# --- Проверка и установка Docker ---
if ! command_exists docker; then
  echo -e "${YELLOW}Docker не найден. Попытка автоматической установки...${NC}"
  
  if command_exists curl; then
    curl -fsSL https://get.docker.com | sh
  elif command_exists wget; then
    wget -qO- https://get.docker.com | sh
  else
    echo -e "${RED}Ошибка: Не найдены curl или wget для скачивания Docker.${NC}"
    echo -e "${YELLOW}Пожалуйста, установите curl: sudo apt-get install curl${NC}"
    exit 1
  fi

  echo -e "${GREEN}Docker успешно установлен.${NC}"
  
  # Добавляем пользователя в группу docker, если это не root
  if [ "$USER" != "root" ]; then
    echo -e "${YELLOW}Добавляем пользователя $USER в группу docker...${NC}"
    sudo usermod -aG docker "$USER"
    echo -e "${RED}ВНИМАНИЕ: Вам нужно выйти из системы и зайти снова, чтобы изменения вступили в силу.${NC}"
    echo -e "${RED}Пожалуйста, перезагрузите сервер или выполните 'newgrp docker' и запустите скрипт снова.${NC}"
    exit 1
  fi
fi

# --- Проверка Docker Compose ---
if ! docker compose version >/dev/null 2>&1; then
  echo -e "${YELLOW}Docker Compose плагин не найден. Пробуем установить...${NC}"
  sudo apt-get update && sudo apt-get install -y docker-compose-plugin || {
      echo -e "${RED}Не удалось установить Docker Compose автоматически.${NC}"
      echo -e "${YELLOW}Пожалуйста, следуйте инструкции: https://docs.docker.com/compose/install/linux/${NC}"
      exit 1
  }
fi

# --- Проверка портов ---
check_port() {
  local port=$1
  if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${RED}ВНИМАНИЕ: Порт $port уже занят!${NC}"
    read -p "Хотите попытаться остановить процесс, занимающий этот порт? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      pid=$(lsof -Pi :$port -sTCP:LISTEN -t)
      echo -e "${YELLOW}Убиваем процесс с PID $pid...${NC}"
      kill -9 $pid || sudo kill -9 $pid
      echo -e "${GREEN}Порт $port освобожден.${NC}"
    else
      echo -e "${RED}Ошибка: Невозможно продолжить с занятым портом $port.${NC}"
      exit 1
    fi
  fi
}

if command_exists lsof; then
  check_port 3010
  check_port 8080
else
  echo -e "${YELLOW}Утилита lsof не найдена. Пропускаем проверку портов.${NC}"
  echo -e "${YELLOW}Если возникнут ошибки 'Address already in use', проверьте порты 3010 и 8080.${NC}"
fi

# --- Настройка .env ---
echo -e "${YELLOW}Настройка окружения...${NC}"

if [ -f .env ]; then
  echo -e "${YELLOW}Файл .env уже существует.${NC}"
  read -p "Хотите перезаписать его? (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Используем существующий .env.${NC}"
    SKIP_ENV_GEN=true
  fi
fi

if [ "$SKIP_ENV_GEN" != "true" ]; then
  echo -e "Нажмите Enter, чтобы использовать значение по умолчанию [в скобках]."

  read -p "Введите домен (например, localhost или example.com) [localhost]: " DOMAIN
  DOMAIN=${DOMAIN:-localhost}

  read -p "Введите имя пользователя БД [plgames]: " DB_USER
  DB_USER=${DB_USER:-plgames}

  read -p "Введите пароль БД [plgames]: " DB_PASSWORD
  DB_PASSWORD=${DB_PASSWORD:-plgames}

  read -p "Введите имя базы данных [plgames]: " DB_NAME
  DB_NAME=${DB_NAME:-plgames}

  echo ""
  echo -e "${YELLOW}Настройка авторизации через Яндекс (OIDC)${NC}"
  echo -e "Если вы не хотите настраивать сейчас, просто нажмите Enter."
  read -p "Введите Yandex Client ID: " OIDC_CLIENT_ID
  read -p "Введите Yandex Client Secret: " OIDC_CLIENT_SECRET

  echo ""
  echo -e "${YELLOW}Настройка AI (OpenRouter)${NC}"
  echo -e "Позволяет использовать любые модели (GPT-4, Claude, Llama) через единый API."
  read -p "Введите OpenRouter API Key: " OPENROUTER_API_KEY
  read -p "Введите модель по умолчанию [openai/gpt-4o-mini]: " OPENROUTER_MODEL
  OPENROUTER_MODEL=${OPENROUTER_MODEL:-openai/gpt-4o-mini}

  if [ "$DOMAIN" = "localhost" ]; then
    BASE_URL="http://localhost:8080"
  else
    BASE_URL="https://$DOMAIN"
  fi

  cat > .env <<EOF
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
OIDC_CLIENT_ID=$OIDC_CLIENT_ID
OIDC_CLIENT_SECRET=$OIDC_CLIENT_SECRET
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
OPENROUTER_MODEL=$OPENROUTER_MODEL
EOF
  echo -e "${GREEN}Файл .env успешно создан.${NC}"
fi

# --- Запуск ---
echo -e "${YELLOW}Запуск сервисов (это может занять несколько минут)...${NC}"
echo -e "${YELLOW}Сборка образов и запуск контейнеров...${NC}"

# Останавливаем старые контейнеры, если они есть, чтобы избежать конфликтов
docker compose -f docker-compose.prod.yml down --remove-orphans || true

if docker compose -f docker-compose.prod.yml up -d --build; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}   Установка успешно завершена! 🚀${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "Фронтенд доступен по адресу: ${CYAN}http://${DOMAIN}:8080${NC} (или https://${DOMAIN}, если настроен прокси)"
    echo -e "Бэкенд API доступен по адресу: ${CYAN}http://${DOMAIN}:3010${NC}"
    echo ""
    echo -e "${YELLOW}Полезные команды:${NC}"
    echo "  Просмотр логов: docker compose -f docker-compose.prod.yml logs -f"
    echo "  Остановка:      docker compose -f docker-compose.prod.yml down"
    echo "  Перезапуск:     docker compose -f docker-compose.prod.yml restart"
else
    echo -e "${RED}Произошла ошибка при запуске Docker Compose.${NC}"
    echo -e "${YELLOW}Попробуйте запустить 'docker compose -f docker-compose.prod.yml logs', чтобы увидеть детали.${NC}"
    exit 1
fi

