# 🚀 Установка PLGames Board на сервере (Россия)

Полная инструкция по установке информационной системы PLGames Board на вашем сервере. Оптимизирована для работы в России с учетом блокировок.

## 📋 Требования

### Минимальные требования к серверу:
- **OS**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **CPU**: 2 ядра
- **RAM**: 4 GB
- **Диск**: 20 GB SSD
- **Сеть**: Внешний IP адрес

### Рекомендуемые требования:
- **CPU**: 4 ядра
- **RAM**: 8 GB
- **Диск**: 50 GB SSD
- **Сеть**: Внешний IP + домен

## 🇷🇺 Особенности для России

Скрипт **автоматически определяет** регион и настраивает:
- ✅ Зеркала для установки Docker
- ✅ Альтернативные registry для образов
- ✅ Настройку NPM/Yarn для работы через прокси
- ✅ Использование российских CDN

## 📦 Быстрая установка (One-Click)

### Шаг 1: Подключитесь к серверу

```bash
ssh user@your-server-ip
```

### Шаг 2: Клонируйте репозиторий

```bash
# Создайте директорию для проекта
mkdir -p /home/plg
cd /home/plg

# Клонируйте проект
git clone https://github.com/your-username/boards_plane.git
cd boards_plane

# Обновите submodules
git submodule update --init --recursive
```

### Шаг 3: Настройте переменные окружения (опционально)

```bash
# Установите домен перед запуском
export DOMAIN=your-domain.com
export REPO_DIR=/home/plg/boards_plane
```

### Шаг 4: Запустите установку

```bash
# Дайте права на выполнение
chmod +x deploy_production.sh

# Запустите установку (может потребовать sudo)
sudo ./deploy_production.sh
```

**Время установки:** 15-30 минут (зависит от скорости интернета)

## ⚙️ Настройка .env файла

После первой установки файл `.env` создается автоматически. Отредактируйте его для настройки дополнительных функций:

```bash
nano .env
```

### Обязательные параметры:

```env
# Ваш домен
DOMAIN=your-domain.com
BASE_URL=https://your-domain.com

# База данных (пароль генерируется автоматически)
DATABASE_URL=postgres://plgames:GENERATED_PASSWORD@postgres:5432/plgames
```

### Опциональные параметры:

#### 1. Включить AI-ассистента (OpenRouter)

```env
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-v1-xxx
AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct
```

**Получить API ключ:** https://openrouter.ai/

#### 2. Настроить OAuth через Яндекс

```env
AFFINE_OAUTH_OIDC_ISSUER=https://oauth.yandex.ru
OIDC_CLIENT_ID=your_client_id
OIDC_CLIENT_SECRET=your_client_secret
AFFINE_OAUTH_OIDC_ARGS_SCOPE=openid
```

**Создать OAuth приложение:** https://oauth.yandex.ru/client/new

#### 3. Настроить email (SMTP через Яндекс)

```env
MAILER_HOST=smtp.yandex.ru
MAILER_PORT=465
MAILER_USER=your-email@yandex.ru
MAILER_PASSWORD=your-app-password
MAILER_SENDER=noreply@your-domain.com
```

## 🌐 Настройка домена и HTTPS

### Вариант 1: Nginx (рекомендуется)

```bash
# Установите Nginx
sudo apt install nginx certbot python3-certbot-nginx

# Создайте конфиг
sudo nano /etc/nginx/sites-available/plgames
```

Вставьте:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:3010;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    location /graphql {
        proxy_pass http://localhost:3010;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    location /socket.io {
        proxy_pass http://localhost:3010;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
    }
}
```

Активируйте и получите SSL:

```bash
# Активируйте конфиг
sudo ln -s /etc/nginx/sites-available/plgames /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Получите SSL сертификат
sudo certbot --nginx -d your-domain.com
```

### Вариант 2: Caddy (автоматический HTTPS)

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

Вставьте:

```caddyfile
your-domain.com {
    reverse_proxy localhost:8080
    reverse_proxy /api/* localhost:3010
    reverse_proxy /graphql localhost:3010
    reverse_proxy /socket.io/* localhost:3010
}
```

Перезапустите Caddy:

```bash
sudo systemctl restart caddy
```

## 🔧 Управление системой

### Посмотреть логи

```bash
cd /home/plg/boards_plane
docker compose -f docker-compose.prod.yml logs -f
```

### Перезапустить сервисы

```bash
docker compose -f docker-compose.prod.yml restart
```

### Остановить систему

```bash
docker compose -f docker-compose.prod.yml down
```

### Обновить систему

```bash
cd /home/plg/boards_plane
./deploy_production.sh
```

### Бэкап базы данных

```bash
# Создать бэкап
docker compose -f docker-compose.prod.yml exec postgres pg_dump -U plgames plgames > backup_$(date +%Y%m%d).sql

# Восстановить из бэкапа
docker compose -f docker-compose.prod.yml exec -T postgres psql -U plgames plgames < backup_20241201.sql
```

## 📊 Доступ к системе

После успешной установки:

- **Frontend (Web UI):** http://your-server-ip:8080 или https://your-domain.com
- **Backend API:** http://your-server-ip:3010/api
- **GraphQL Playground:** http://your-server-ip:3010/graphql

## 🆘 Решение проблем

### Проблема: Контейнеры не запускаются

```bash
# Проверьте логи
docker compose -f docker-compose.prod.yml logs

# Проверьте доступность портов
sudo netstat -tulpn | grep -E '8080|3010|5432'

# Пересоберите контейнеры
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build
```

### Проблема: Не работает Docker в России

```bash
# Проверьте настройки зеркал
cat /etc/docker/daemon.json

# Перезапустите Docker
sudo systemctl restart docker
```

### Проблема: Медленная сборка

```bash
# Увеличьте таймауты для России
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Запустите заново
./deploy_production.sh
```

### Проблема: Ошибка миграции базы данных

```bash
# Зайдите в контейнер backend
docker compose -f docker-compose.prod.yml exec backend sh

# Запустите миграции вручную
npx prisma migrate deploy

# Выйдите
exit
```

## 🔒 Безопасность

### Рекомендации:

1. **Измените пароли в .env** после первой установки
2. **Настройте firewall:**

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

3. **Регулярно делайте бэкапы** базы данных
4. **Обновляйте систему:**

```bash
sudo apt update && sudo apt upgrade
```

## 📞 Поддержка

- **Документация:** [Ссылка на wiki]
- **GitHub Issues:** [Ссылка на issues]
- **Email:** support@your-domain.com

## 📄 Лицензия

MIT License - используйте свободно для коммерческих и личных проектов.

---

**Успешной установки! 🎉**
