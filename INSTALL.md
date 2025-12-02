# PLGames Board - Руководство по установке

Полная инструкция по установке PLGames Board на Linux сервер.

---

## 📋 Содержание

1. [Быстрая установка (рекомендуется)](#-быстрая-установка)
2. [Требования к системе](#-требования-к-системе)
3. [Ручная установка](#-ручная-установка-пошагово)
4. [Настройка](#-настройка)
5. [Проверка работы](#-проверка-работы)
6. [Управление](#-управление-системой)
7. [Решение проблем](#-решение-проблем)

---

## 🚀 Быстрая установка

### Автоматическая установка (1 команда):

```bash
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install.sh | sudo bash
```

Или через wget:
```bash
wget -qO- https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install.sh | sudo bash
```

**Время установки:** 15-20 минут

Скрипт автоматически:
- ✅ Проверит систему
- ✅ Установит Docker
- ✅ Скачает проект
- ✅ Настроит конфигурацию (спросит домен и AI)
- ✅ Соберет и запустит все сервисы
- ✅ Выполнит миграции базы данных
- ✅ Проверит работоспособность

После установки перейдите к разделу [Проверка работы](#-проверка-работы).

---

## 💻 Требования к системе

### Минимальные требования:
- **ОС:** Ubuntu 20.04+ или Debian 11+
- **CPU:** 2 ядра
- **RAM:** 4 GB
- **Диск:** 20 GB свободного места
- **Сеть:** Постоянное подключение к интернету
- **Права:** root или sudo доступ

### Рекомендуемые требования:
- **ОС:** Ubuntu 22.04 LTS
- **CPU:** 4 ядра
- **RAM:** 8 GB
- **Диск:** 50 GB (SSD)
- **Домен:** Собственный домен с SSL сертификатом

### Открытые порты:
- **22** - SSH доступ
- **80** - HTTP (для Let's Encrypt)
- **443** - HTTPS
- **3010** - Backend API (опционально, для прямого доступа)
- **8080** - Frontend (если не используется proxy)

---

## 🔧 Ручная установка (пошагово)

Если не хотите использовать автоматический скрипт, следуйте инструкции ниже.

### Шаг 1: Подготовка сервера

#### 1.1. Подключитесь к серверу

```bash
ssh root@your-server-ip
# или
ssh your-user@your-server-ip
```

#### 1.2. Обновите систему

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

#### 1.3. Установите необходимые пакеты

```bash
sudo apt-get install -y \
    git \
    curl \
    wget \
    openssl \
    ca-certificates \
    gnupg \
    lsb-release
```

### Шаг 2: Установка Docker

#### 2.1. Удалите старые версии Docker (если есть)

```bash
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
```

#### 2.2. Добавьте репозиторий Docker

```bash
# Добавьте GPG ключ
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавьте репозиторий
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**Для России (если медленно скачивается):**
```bash
# Используйте зеркало Yandex
curl -fsSL https://mirror.yandex.ru/mirrors/docker/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirror.yandex.ru/mirrors/docker/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### 2.3. Установите Docker

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

#### 2.4. Запустите Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

#### 2.5. Проверьте установку

```bash
docker --version
# Должно показать: Docker version 24.x.x

docker compose version
# Должно показать: Docker Compose version v2.x.x
```

### Шаг 3: Создание директории и клонирование проекта

#### 3.1. Создайте директорию для проекта

```bash
sudo mkdir -p /opt/plgames
cd /opt/plgames
```

**Почему /opt/plgames?**
- `/opt/` - стандартная директория для опциональных приложений в Linux
- Все файлы проекта будут в одном месте
- Легко делать backup всей директории

#### 3.2. Клонируйте репозиторий

```bash
sudo git clone --recurse-submodules https://github.com/Leonid1095/boards_plane.git .
```

**Важно:**
- Точка `.` в конце означает "клонировать в текущую директорию"
- `--recurse-submodules` обязателен, иначе не скачается подмодуль `plgames/`

#### 3.3. Проверьте что скачалось

```bash
ls -la
```

Должны быть файлы:
- `docker-compose.yml`
- `install.sh`
- `.env.example`
- `README.md`
- `plgames/` (директория)

### Шаг 4: Настройка конфигурации

#### 4.1. Создайте файл конфигурации

```bash
sudo cp .env.example .env
```

#### 4.2. Определите IP адрес сервера

```bash
curl -4 ifconfig.me
# Покажет ваш внешний IP, например: 192.168.1.100
```

#### 4.3. Отредактируйте .env файл

```bash
sudo nano .env
```

**Обязательные параметры:**

```env
# Основные настройки
NODE_ENV=production
DOMAIN=your-domain.com          # Замените на ваш домен или IP
BASE_URL=https://your-domain.com # Или http://192.168.1.100

# База данных (оставьте как есть или измените пароль)
DB_USER=plgames
DB_PASSWORD=измените_на_свой_пароль_длинный_и_сложный
DB_NAME=plgames
```

**Опциональные параметры:**

```env
# AI через OpenRouter (если нужно)
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-v1-ваш_ключ
AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct

# OAuth через Yandex (если нужно)
OIDC_CLIENT_ID=ваш_client_id
OIDC_CLIENT_SECRET=ваш_secret

# Порты (если нужно изменить)
BACKEND_PORT=3010
FRONTEND_PORT=8080
POSTGRES_PORT=5432
```

**Генерация безопасного пароля:**
```bash
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
```

#### 4.4. Установите права доступа

```bash
sudo chmod 600 .env
```

Это защитит файл с паролями от чтения другими пользователями.

### Шаг 5: Сборка и запуск

#### 5.1. Соберите Docker образы

```bash
sudo docker compose build --no-cache
```

**Это займет 15-20 минут.** Будут скачаны и собраны:
- Backend (NestJS)
- Frontend (React + Caddy)
- PostgreSQL с pgvector
- Redis

#### 5.2. Запустите контейнеры

```bash
sudo docker compose up -d
```

Флаг `-d` означает "в фоновом режиме".

#### 5.3. Проверьте статус

```bash
sudo docker compose ps
```

**Ожидаемый результат:**
```
NAME                          STATUS              PORTS
plgames-backend-1             Up (healthy)        0.0.0.0:3010->3010/tcp
plgames-frontend-1            Up                  0.0.0.0:8080->80/tcp
plgames-postgres-1            Up (healthy)        5432/tcp
plgames-redis-1               Up                  6379/tcp
```

Все контейнеры должны быть в статусе `Up`.

### Шаг 6: Инициализация базы данных

#### 6.1. Дождитесь готовности PostgreSQL

```bash
# Подождите 30 секунд для инициализации
sleep 30

# Проверьте что PostgreSQL готов
sudo docker compose exec postgres pg_isready -U plgames
```

Должно показать: `postgres:5432 - accepting connections`

#### 6.2. Выполните миграции

```bash
sudo docker compose exec backend sh -c "npx prisma migrate deploy"
```

**Ожидаемый результат:**
```
✓ Applying migration `20241201_initial_crm`
✓ Applying migration `20241201_add_crm_tables`
✓ All migrations have been successfully applied
```

**Если ошибка "backend is not running":**
```bash
# Проверьте логи
sudo docker compose logs backend --tail=50

# Перезапустите backend
sudo docker compose restart backend
sleep 10

# Попробуйте снова
sudo docker compose exec backend sh -c "npx prisma migrate deploy"
```

### Шаг 7: Проверка работы

#### 7.1. Проверьте логи

```bash
# Backend логи
sudo docker compose logs backend --tail=30
```

**Должна быть строка:**
```
[Nest] ... INFO [NestApplication] Nest application successfully started
```

#### 7.2. Проверьте доступность

```bash
# Backend API
curl -I http://localhost:3010/graphql

# Должно быть HTTP/1.1 400 или 200
```

```bash
# Frontend
curl -I http://localhost:8080

# Должно быть HTTP/1.1 200
```

#### 7.3. Откройте в браузере

Перейдите на:
- `http://ваш-ip:8080` - Frontend
- `http://ваш-ip:3010/graphql` - GraphQL Playground

**Готово!** PLGames Board установлен и работает.

---

## ⚙️ Настройка

### Настройка HTTPS (рекомендуется)

#### Вариант 1: Caddy (простой способ)

```bash
# Установите Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Создайте Caddyfile
sudo nano /etc/caddy/Caddyfile
```

**Содержимое:**
```
your-domain.com {
    reverse_proxy localhost:8080
}

api.your-domain.com {
    reverse_proxy localhost:3010
}
```

```bash
# Перезапустите Caddy
sudo systemctl restart caddy
```

#### Вариант 2: Nginx + Let's Encrypt

```bash
# Установите Nginx и Certbot
sudo apt install -y nginx certbot python3-certbot-nginx

# Создайте конфиг
sudo nano /etc/nginx/sites-available/plgames
```

**Содержимое:**
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 80;
    server_name api.your-domain.com;

    location / {
        proxy_pass http://localhost:3010;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Активируйте конфиг
sudo ln -s /etc/nginx/sites-available/plgames /etc/nginx/sites-enabled/

# Проверьте конфиг
sudo nginx -t

# Перезапустите Nginx
sudo systemctl restart nginx

# Получите SSL сертификат
sudo certbot --nginx -d your-domain.com -d api.your-domain.com
```

### Настройка AI (OpenRouter)

1. Зарегистрируйтесь на https://openrouter.ai/
2. Создайте API ключ
3. Добавьте в `.env`:
```env
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-v1-ваш_ключ
```
4. Перезапустите backend:
```bash
sudo docker compose restart backend
```

### Настройка OAuth (Yandex)

1. Перейдите на https://oauth.yandex.ru/client/new
2. Создайте приложение:
   - Название: PLGames Board
   - Redirect URI: `https://ваш-домен.com/oauth/callback`
   - Права: `login:email`, `login:info`
3. Скопируйте Client ID и Client Secret
4. Добавьте в `.env`:
```env
OIDC_CLIENT_ID=ваш_client_id
OIDC_CLIENT_SECRET=ваш_secret
```
5. Перезапустите backend

---

## ✅ Проверка работы

### Проверка контейнеров

```bash
sudo docker compose ps
```

Все должны быть `Up`.

### Проверка логов

```bash
# Все логи
sudo docker compose logs -f

# Только backend
sudo docker compose logs -f backend

# Последние 50 строк
sudo docker compose logs backend --tail=50
```

### Проверка базы данных

```bash
# Подключитесь к PostgreSQL
sudo docker compose exec postgres psql -U plgames -d plgames

# Выполните запрос
SELECT COUNT(*) FROM "User";

# Выйдите
\q
```

### Проверка API

```bash
# GraphQL доступен
curl http://localhost:3010/graphql

# Health check
curl http://localhost:3010/api/healthz
```

---

## 🛠️ Управление системой

### Основные команды

```bash
# Статус сервисов
sudo docker compose ps

# Логи (все сервисы)
sudo docker compose logs -f

# Логи конкретного сервиса
sudo docker compose logs -f backend
sudo docker compose logs -f frontend
sudo docker compose logs -f postgres

# Перезапуск всех сервисов
sudo docker compose restart

# Перезапуск конкретного сервиса
sudo docker compose restart backend

# Остановка
sudo docker compose down

# Запуск после остановки
sudo docker compose up -d

# Просмотр использования ресурсов
sudo docker stats
```

### Обновление системы

```bash
cd /opt/plgames

# Остановите контейнеры
sudo docker compose down

# Скачайте обновления
sudo git pull

# Пересоберите образы
sudo docker compose build --no-cache

# Запустите
sudo docker compose up -d

# Выполните миграции (если есть)
sudo docker compose exec backend sh -c "npx prisma migrate deploy"
```

### Резервное копирование

#### Backup базы данных

```bash
# Создайте backup
sudo docker compose exec postgres pg_dump -U plgames plgames > backup_$(date +%Y%m%d_%H%M%S).sql

# Или с архивацией
sudo docker compose exec postgres pg_dump -U plgames plgames | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

#### Восстановление из backup

```bash
# Из обычного файла
cat backup_20241202_120000.sql | sudo docker compose exec -T postgres psql -U plgames -d plgames

# Из архива
gunzip -c backup_20241202_120000.sql.gz | sudo docker compose exec -T postgres psql -U plgames -d plgames
```

#### Backup файлов проекта

```bash
# Backup всей директории
sudo tar -czf plgames_backup_$(date +%Y%m%d).tar.gz /opt/plgames

# Backup только данных (volumes)
sudo docker run --rm -v plgames_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_data_$(date +%Y%m%d).tar.gz /data
```

### Очистка системы

```bash
# Удалите неиспользуемые образы и контейнеры
sudo docker system prune -a

# Удалите старые логи
sudo docker compose logs --tail=0 backend
sudo docker compose logs --tail=0 frontend

# Очистите место на диске
sudo apt-get clean
sudo apt-get autoremove -y
```

---

## 🚨 Решение проблем

### Backend не запускается

**Симптомы:**
- `docker compose ps` показывает `Restarting` или `Exited`
- Сайт отдает 502 Bad Gateway

**Решение:**

1. Посмотрите логи:
```bash
sudo docker compose logs backend --tail=100
```

2. Проверьте что PostgreSQL готов:
```bash
sudo docker compose exec postgres pg_isready -U plgames
```

3. Пересоберите backend:
```bash
sudo docker compose down
sudo docker compose build --no-cache backend
sudo docker compose up -d
```

4. Проверьте миграции:
```bash
sudo docker compose exec backend sh -c "npx prisma migrate deploy"
```

### Frontend не открывается

**Симптомы:**
- `curl http://localhost:8080` не отвечает
- Страница не загружается

**Решение:**

1. Проверьте статус:
```bash
sudo docker compose ps frontend
```

2. Посмотрите логи:
```bash
sudo docker compose logs frontend
```

3. Перезапустите:
```bash
sudo docker compose restart frontend
```

### Ошибки миграций

**Симптомы:**
- `Error: P3009: migrate found failed migrations`

**Решение:**

1. Сбросьте миграции:
```bash
sudo docker compose exec backend sh -c "npx prisma migrate reset --force"
```

2. Выполните заново:
```bash
sudo docker compose exec backend sh -c "npx prisma migrate deploy"
```

**⚠️ ВНИМАНИЕ:** `migrate reset` удалит все данные!

### Нет места на диске

**Симптомы:**
- Ошибки при сборке образов
- `no space left on device`

**Решение:**

1. Проверьте использование:
```bash
df -h
```

2. Удалите старые образы:
```bash
sudo docker system prune -a
```

3. Удалите логи:
```bash
sudo journalctl --vacuum-time=3d
```

4. Очистите apt:
```bash
sudo apt-get clean
sudo apt-get autoremove -y
```

### PostgreSQL не готов

**Симптомы:**
- Backend не может подключиться к базе
- `connection refused` в логах

**Решение:**

1. Проверьте статус PostgreSQL:
```bash
sudo docker compose ps postgres
sudo docker compose logs postgres
```

2. Перезапустите:
```bash
sudo docker compose restart postgres
sleep 30
sudo docker compose restart backend
```

3. Проверьте переменные в `.env`:
```bash
grep DB_ .env
```

### Медленная работа

**Причины:**
- Мало RAM (< 4GB)
- Медленный диск (HDD вместо SSD)
- Много запущенных контейнеров

**Решение:**

1. Проверьте использование ресурсов:
```bash
sudo docker stats
```

2. Увеличьте RAM для сервера

3. Оптимизируйте Redis:
```bash
# В .env добавьте
REDIS_MAXMEMORY=256mb
REDIS_MAXMEMORY_POLICY=allkeys-lru
```

4. Перезапустите систему

---

## 📞 Дополнительная помощь

### Сбор информации для отчета об ошибке

```bash
cd /opt/plgames

# Версии
echo "=== Docker Version ===" > debug_info.txt
docker --version >> debug_info.txt
docker compose version >> debug_info.txt

# Статус
echo "=== Container Status ===" >> debug_info.txt
docker compose ps >> debug_info.txt

# Логи
echo "=== Backend Logs ===" >> debug_info.txt
docker compose logs backend --tail=100 >> debug_info.txt

echo "=== Frontend Logs ===" >> debug_info.txt
docker compose logs frontend --tail=50 >> debug_info.txt

# Конфигурация (БЕЗ ПАРОЛЕЙ!)
echo "=== Environment ===" >> debug_info.txt
grep -v PASSWORD .env >> debug_info.txt

# Отправьте файл debug_info.txt
```

### Ссылки

- **GitHub:** https://github.com/Leonid1095/boards_plane
- **Issues:** https://github.com/Leonid1095/boards_plane/issues
- **CHANGELOG:** [CHANGELOG.md](CHANGELOG.md)
- **Roadmap:** [ROADMAP.md](ROADMAP.md)

---

**Последнее обновление:** 2024-12-02
**Версия:** 1.1.0
