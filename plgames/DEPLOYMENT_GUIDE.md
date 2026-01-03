# 🚀 Руководство по развертыванию PLGames на сервере

## 📋 Требования к серверу

- **CPU:** 4+ ядра (у вас: Xeon 10/20 ядер ✅)
- **RAM:** Минимум 8GB (у вас: 8GB ✅)
- **Диск:** 40GB+ (у вас: 40GB ✅)
- **ОС:** Ubuntu 20.04+ / Debian 11+
- **Порты:** 80, 443, 3010, 5432, 6379

---

## 🎯 Два способа установки

### **Способ 1: Готовые Docker образы из GitHub Actions (БЫСТРО - 2 минуты)**

GitHub Actions автоматически собирает и публикует Docker образы в `ghcr.io/toeverything/affine:stable`

#### Шаги установки:

```bash
# 1. Создайте директорию для проекта
mkdir -p ~/plgames && cd ~/plgames

# 2. Создайте docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: plgames
      POSTGRES_PASSWORD: your_strong_password_change_this
      POSTGRES_DB: plgames
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "plgames"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:latest
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: ghcr.io/toeverything/affine:stable
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://plgames:your_strong_password_change_this@postgres:5432/plgames
      REDIS_SERVER_HOST: redis
      AFFINE_SERVER_EXTERNAL_URL: http://YOUR_SERVER_IP:3010
      AFFINE_SERVER_HOST: YOUR_SERVER_IP
      AFFINE_SERVER_PORT: 3010
      NODE_ENV: production
    ports:
      - "3010:3010"
    volumes:
      - storage_data:/root/.affine/storage
      - config_data:/root/.affine/config
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3010/api/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  frontend:
    image: ghcr.io/toeverything/affine-front:stable
    depends_on:
      - backend
    ports:
      - "80:8080"
    restart: unless-stopped

volumes:
  postgres_data:
  storage_data:
  config_data:
EOF

# 3. Замените YOUR_SERVER_IP на IP вашего сервера
sed -i 's/YOUR_SERVER_IP/ВАШ_IP/g' docker-compose.yml

# 4. Установите Docker если его нет
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# 5. Запустите контейнеры
docker compose up -d

# 6. Проверьте статус
docker compose ps

# 7. Смотрите логи
docker compose logs -f backend
```

#### После запуска:
- **Фронтенд:** http://ваш-сервер-ip
- **Backend API:** http://ваш-сервер-ip:3010
- **Демо-аккаунты:**
  - Email: `dev@plgames.local` / Пароль: `dev`
  - Email: `pro@plgames.local` / Пароль: `pro`

#### Управление:
```bash
# Остановить
docker compose down

# Перезапустить
docker compose restart

# Обновить образы
docker compose pull
docker compose up -d

# Посмотреть логи
docker compose logs -f

# Удалить всё (включая данные!)
docker compose down -v
```

**✅ Плюсы:** Быстро, не требует сборки
**❌ Минусы:** Используется стандартный AFFiNE (не ваша кастомная версия)

---

### **Способ 2: Полная установка с помощью deploy-prod.sh (30-40 минут)**

Скрипт автоматически установит все зависимости и соберет проект из исходников.

#### Шаги установки:

```bash
# 1. Скачайте скрипт развертывания
wget https://raw.githubusercontent.com/Leonid1095/boards_plane/main/scripts/deploy-prod.sh

# 2. Сделайте его исполняемым
chmod +x deploy-prod.sh

# 3. Запустите с правами root
sudo PLG_DOMAIN=your-domain.com \
     PLG_ADMIN_EMAIL=admin@your-domain.com \
     PLG_DB_PASSWORD=your_strong_password \
     bash deploy-prod.sh
```

#### Что делает скрипт:

1. ✅ Устанавливает системные зависимости (build-essential, curl, git, python3)
2. ✅ Устанавливает Node.js 22.x
3. ✅ Устанавливает Rust toolchain
4. ✅ Устанавливает Yarn 4.9.1 через Corepack
5. ✅ Устанавливает Docker и Docker Compose
6. ✅ Устанавливает Caddy (для HTTPS)
7. ✅ Клонирует репозиторий в `/opt/plgames`
8. ✅ Устанавливает npm зависимости
9. ✅ Собирает native модули (Rust)
10. ✅ Запускает PostgreSQL + Redis через Docker
11. ✅ Выполняет миграции базы данных
12. ✅ Собирает backend и frontend
13. ✅ Настраивает Caddy для HTTPS
14. ✅ Создает systemd service `plgames-server`
15. ✅ Запускает приложение

#### Переменные окружения:

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `PLG_DOMAIN` | Публичный домен | localhost |
| `PLG_ADMIN_EMAIL` | Email администратора | admin@domain |
| `PLG_INSTALL_DIR` | Директория установки | /opt/plgames |
| `PLG_SERVER_PORT` | Порт API сервера | 3010 |
| `PLG_DB_USER` | Пользователь PostgreSQL | plgames |
| `PLG_DB_NAME` | Имя БД PostgreSQL | plgames |
| `PLG_DB_PASSWORD` | Пароль БД | (генерируется) |

#### После установки:

```bash
# Просмотр логов сервера
journalctl -u plgames-server -f

# Перезапуск сервера
sudo systemctl restart plgames-server

# Остановка сервера
sudo systemctl stop plgames-server

# Статус сервера
sudo systemctl status plgames-server

# Просмотр логов Docker
cd /opt/plgames
docker compose -f .docker/dev/compose.yml logs -f

# Обновление приложения
cd /opt/plgames
git pull
sudo bash scripts/deploy-prod.sh
```

**✅ Плюсы:** Ваша кастомная версия, полный контроль
**❌ Минусы:** Долгая сборка (30-40 минут), требует много ресурсов

---

## 🔧 Способ 3: Ручная установка для разработки

Если нужна разработческая среда:

```bash
# 1. Установите зависимости
sudo apt-get update
sudo apt-get install -y build-essential curl git python3 libssl-dev docker.io docker-compose-plugin

# 2. Установите Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt-get install -y nodejs

# 3. Установите Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# 4. Активируйте Yarn через Corepack
sudo corepack enable
corepack prepare yarn@4.9.1 --activate

# 5. Клонируйте репозиторий
git clone https://github.com/Leonid1095/boards_plane.git ~/plgames
cd ~/plgames

# 6. Скопируйте конфигурационные файлы
cp .docker/dev/compose.yml.example .docker/dev/compose.yml
cp .docker/dev/.env.example .docker/dev/.env
cp packages/backend/server/.env.example packages/backend/server/.env

# 7. Настройте .docker/dev/.env
cat > .docker/dev/.env <<'EOF'
DB_VERSION=16
DB_USERNAME=plgames
DB_PASSWORD=plgames123
DB_DATABASE_NAME=plgames
MANTICORE_VERSION=10.1.0
EOF

# 8. Настройте packages/backend/server/.env
cat > packages/backend/server/.env <<'EOF'
DATABASE_URL="postgresql://plgames:plgames123@localhost:5432/plgames"
REDIS_SERVER_HOST=127.0.0.1
AFFINE_SERVER_EXTERNAL_URL="http://localhost:3010"
AFFINE_SERVER_HOST="localhost"
AFFINE_SERVER_PORT=3010
NODE_ENV=development
EOF

# 9. Установите npm зависимости
export NODE_OPTIONS="--max-old-space-size=6144"
export YARN_ENABLE_IMMUTABLE_INSTALLS=false
corepack yarn install --mode skip-build

# 10. Инициализация и сборка native модулей
corepack yarn plgames init
corepack yarn plgames @affine/server-native build
corepack yarn plgames @affine/reader build

# 11. Запустите Docker сервисы (PostgreSQL, Redis, Mailpit)
sudo usermod -aG docker $USER
newgrp docker
docker compose -f .docker/dev/compose.yml up -d

# 12. Дождитесь запуска PostgreSQL (10-15 секунд)
sleep 15

# 13. Инициализируйте базу данных
corepack yarn plgames server init

# 14. Запустите backend (в отдельном терминале)
corepack yarn plgames server dev

# 15. Запустите frontend (в другом терминале)
corepack yarn dev
```

#### Доступ к сервисам:
- **Frontend:** http://localhost:8080
- **Backend API:** http://localhost:3010
- **PostgreSQL:** localhost:5432
- **Redis:** localhost:6379
- **Mailpit UI:** http://localhost:8025

#### Демо-аккаунты:
| Tier | Email | Password | Members |
|------|-------|----------|---------|
| Dev | dev@plgames.local | dev | 3 |
| Pro | pro@plgames.local | pro | 10 |
| Team | team@plgames.local | team | 10 |

---

## 🐛 Решение типичных проблем

### Ошибка 1: "JavaScript heap out of memory"

```bash
# Увеличьте лимит памяти Node.js
export NODE_OPTIONS="--max-old-space-size=8192"
```

### Ошибка 2: Ошибки сборки Rust native модулей

```bash
# Обновите Rust до последней версии
rustup update stable
rustup default stable

# Убедитесь что версия >= 1.82
rustc --version
```

### Ошибка 3: Docker Permission Denied

```bash
# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER

# Перелогиньтесь или используйте
newgrp docker
```

### Ошибка 4: Порты уже заняты

```bash
# Проверьте какие порты заняты
sudo netstat -tulpn | grep -E ':(3010|5432|6379|8025|8080)'

# Остановите конфликтующие сервисы
sudo systemctl stop postgresql
sudo systemctl stop redis-server
sudo systemctl stop nginx
```

### Ошибка 5: Prisma generate fails

```bash
# Сгенерируйте Prisma клиента вручную
cd ~/plgames/packages/backend/server
npx prisma generate
```

### Ошибка 6: Frontend build timeout

```bash
# Увеличьте timeout в Dockerfile (строка 77)
# Или соберите локально без timeout
cd ~/plgames
export NODE_OPTIONS="--max-old-space-size=8192"
corepack yarn plgames @affine/web build
```

### Ошибка 7: Docker compose не найден

```bash
# Используйте docker compose (через пробел, не docker-compose)
docker compose version

# Если не установлен plugin
sudo apt-get install docker-compose-plugin
```

### Ошибка 8: Yarn install fails

```bash
# Отключите immutable режим
export YARN_ENABLE_IMMUTABLE_INSTALLS=false
corepack yarn install --mode skip-build
```

---

## 📊 Архитектура развертывания

### Продакшн (Способ 1 - Docker):
```
┌─────────────────────────────────────┐
│         Nginx/Caddy (80/443)        │
│         Reverse Proxy + SSL         │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼────┐         ┌──────▼──────┐
│Frontend│         │   Backend   │
│ :8080  │         │    :3010    │
└────────┘         └──────┬──────┘
                          │
              ┌───────────┴───────────┐
              │                       │
         ┌────▼─────┐          ┌─────▼────┐
         │PostgreSQL│          │  Redis   │
         │  :5432   │          │  :6379   │
         └──────────┘          └──────────┘
```

### Разработка (Способ 3 - Local):
```
┌─────────────────────────────────────┐
│      Vite Dev Server (:8080)        │
│         Hot Reload Frontend         │
└──────────────┬──────────────────────┘
               │
         ┌─────▼──────┐
         │  NestJS    │
         │  Backend   │
         │   :3010    │
         └─────┬──────┘
               │
    ┌──────────┴──────────────┐
    │                         │
┌───▼────┐  ┌──────┐  ┌───────▼────┐
│Postgres│  │Redis │  │  Mailpit   │
│ :5432  │  │:6379 │  │ :1025/8025 │
└────────┘  └──────┘  └────────────┘
```

---

## 🔒 Безопасность

### Обязательные шаги для продакшна:

1. **Смените пароли БД:**
```bash
# В docker-compose.yml или .env файлах
POSTGRES_PASSWORD=your_very_strong_random_password
```

2. **Настройте HTTPS через Caddy:**
```bash
# Скрипт deploy-prod.sh автоматически настраивает SSL через Let's Encrypt
```

3. **Настройте firewall:**
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

4. **Ограничьте доступ к PostgreSQL/Redis:**
```bash
# Не открывайте порты 5432/6379 наружу
# В docker-compose.yml закомментируйте:
# ports:
#   - "5432:5432"
#   - "6379:6379"
```

5. **Регулярные бэкапы:**
```bash
# Бэкап PostgreSQL
docker exec -t plgames-postgres-1 pg_dump -U plgames plgames > backup_$(date +%Y%m%d).sql

# Бэкап хранилища
tar -czf storage_backup_$(date +%Y%m%d).tar.gz ~/plgames/storage
```

---

## 📈 Мониторинг

### Проверка здоровья сервисов:

```bash
# Healthcheck endpoint
curl http://localhost:3010/api/healthz

# Docker статус
docker compose ps

# Использование ресурсов
docker stats

# Логи в реальном времени
docker compose logs -f backend
journalctl -u plgames-server -f
```

### Метрики (если настроен Prometheus):
- http://localhost:3010/metrics

---

## 🚀 Обновление приложения

### Для Docker-версии:
```bash
cd ~/plgames
docker compose pull
docker compose up -d
```

### Для ручной установки:
```bash
cd /opt/plgames
git pull
sudo bash scripts/deploy-prod.sh
```

---

## 📚 Дополнительные ресурсы

- [Документация по разработке сервера](docs/developing-server.md)
- [Документация по сборке](docs/BUILDING.md)
- [CRM функционал](docs/CRM.md)
- [GitHub репозиторий](https://github.com/Leonid1095/boards_plane)

---

## 💡 Рекомендации

**Для вашего сервера (Xeon 10/20 cores, 8GB RAM):**

1. **Используйте Способ 1** (готовые Docker образы) для быстрого старта
2. Если нужна кастомная версия - используйте **Способ 2** (deploy-prod.sh)
3. Настройте swap если RAM < 16GB:
```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

4. Мониторьте использование памяти во время сборки:
```bash
watch -n 1 free -h
```

---

**Создано:** 2025-12-28
**Автор:** Claude Code Analysis
**Версия:** 1.0
