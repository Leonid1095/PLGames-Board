# 🚀 PLGames Board - Deployment Checklist

Используйте этот чек-лист для развертывания проекта на production сервере.

---

## Перед Развертыванием

- [ ] Сервер имеет **4 ГБ+ RAM**
- [ ] На диске **20 ГБ+ свободного места**
- [ ] Ubuntu/Debian 20.04+ или CentOS 7+
- [ ] SSH доступ на сервер
- [ ] Домен готов и DNS указывает на IP сервера (если используется домен)
- [ ] Информация об IP адресе или домене

---

## Шаг 1: Базовая Подготовка Сервера

```bash
# Обновить систему
sudo apt-get update && sudo apt-get upgrade -y

# Установить необходимые пакеты
sudo apt-get install -y \
    curl \
    wget \
    git \
    htop \
    nano

# Установить Docker (если не установлен)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $(whoami)

# Установить Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**Проверка:**
```bash
docker --version
docker-compose --version
```

---

## Шаг 2: Клонирование Репозитория

```bash
# Перейти в домашнюю директорию
cd ~

# Клонировать репозиторий
git clone https://github.com/Leonid1095/PLGames-Board.git plgames-board

# Перейти в директорию проекта
cd ~/plgames-board
```

---

## Шаг 3: Конфигурация Окружения

```bash
# Скопировать .env.example
cp .env.example .env

# Отредактировать .env
nano .env
```

**Параметры для редактирования:**

```env
# Домен или IP
DOMAIN=example.com              # или оставить localhost
BASE_URL=http://example.com     # или http://ВАШ_IP_АДРЕС

# Порты
HTTP_PORT=80
HTTPS_PORT=443
BACKEND_PORT=3010

# База данных (отредактировать пароли!)
DB_USER=plgames
DB_PASSWORD=СГЕНЕРИРУЙТЕ_СВОЙ_ПАРОЛЬ  # генератор: `openssl rand -base64 32`
DB_NAME=plgames

# NODE окружение
NODE_ENV=production

# Опционально (AI функции)
AFFINE_COPILOT_ENABLED=false    # пока отключаем

# Опционально (OAuth)
AFFINE_OAUTH_OIDC_ISSUER=       # оставить пусто если не нужен
```

**Генерация безопасного пароля:**
```bash
openssl rand -base64 32
# Скопируйте результат в DB_PASSWORD
```

---

## Шаг 4: Запуск Docker Compose

```bash
# Проверить синтаксис
docker-compose config > /dev/null && echo "✅ Config valid" || echo "❌ Config error"

# Запустить все сервисы
docker-compose up -d

# Проверить статус контейнеров
docker-compose ps
```

**Ожидаемый результат:**
```
NAME                        STATUS
plgames-board-postgres-1    Up (healthy)
plgames-board-redis-1       Up
plgames-board-backend-1     Up (health: starting)
plgames-board-frontend-1    Up
plgames-board-gateway-1     Up
```

---

## Шаг 5: Проверка Здоровья Сервисов

```bash
# Посмотреть логи backend (первые 50 строк)
docker-compose logs --tail=50 backend

# Ждите пока не увидите:
# "[Nest] X - ... LOG [NestFactory] Nest application successfully started"

# Если ошибка DI - читайте TECHNICAL_AUDIT.md
```

**Проверка API:**
```bash
# Проверить backend
curl -s http://localhost:3010/api/healthz | jq .

# Проверить frontend
curl -s http://localhost:80 | head -20
```

---

## Шаг 6: Firewall Настройка (Опционально)

```bash
# Если используется UFW
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 3010/tcp # Backend (опционально)
sudo ufw reload

# Если используется firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=3010/tcp
sudo firewall-cmd --reload
```

---

## Шаг 7: Доступ к Приложению

**Откройте в браузере:**
```
http://example.com:8080
# или
http://ВАШ_IP_АДРЕС:8080
```

**Если используется домен с HTTPS:**
```
https://example.com
```

---

## Мониторинг и Обслуживание

### Проверка Статуса

```bash
# Посмотреть все логи
docker-compose logs -f backend

# Только ошибки
docker-compose logs backend 2>&1 | grep -i error

# Посмотреть использование ресурсов
docker stats
```

### Перезапуск Сервисов

```bash
# Перезапустить только backend
docker-compose restart backend

# Перезапустить все
docker-compose restart

# Остановить
docker-compose down

# Запустить заново
docker-compose up -d
```

### Обновление на Новую Версию

```bash
cd ~/plgames-board

# Получить новый код
git pull

# Получить новый образ
docker-compose pull

# Пересоздать контейнеры
docker-compose down
docker-compose up -d

# Проверить логи
docker-compose logs -n 100 backend | tail -50
```

### Резервная Копия БД

```bash
# Создать резервную копию
docker-compose exec postgres pg_dump \
  -U plgames plgames > ~/plgames-backup-$(date +%Y%m%d).sql

# Восстановить из резервной копии
docker-compose exec -T postgres psql \
  -U plgames plgames < ~/plgames-backup-20240101.sql
```

---

## Решение Проблем

### Problem: "Connection refused"
```bash
# Проверьте что все контейнеры запущены
docker-compose ps

# Проверьте логи
docker-compose logs backend

# Перезагрузите
docker-compose down && docker-compose up -d
```

### Problem: "UnknownDependenciesException"
```bash
# Это ошибка Nest DI - нужно обновить образ
git pull
docker-compose pull backend
docker-compose up -d --force-recreate backend

# Ждите новый образ от CI (5-10 минут после push)
```

### Problem: "Out of memory"
```bash
# Уменьшить лимит памяти контейнера в docker-compose.yml:
# deploy:
#   resources:
#     limits:
#       memory: 2G

# или создать swap файл:
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Problem: "Disk space full"
```bash
# Очистить старые образы Docker
docker image prune -a -f

# Очистить неиспользуемые volume
docker volume prune -f

# Проверить место на диске
df -h
```

---

## Безопасность

### Основные Меры

```bash
# 1. Смените пароль сервера
sudo passwd

# 2. Отключите SSH по паролю (используйте ключи)
sudo nano /etc/ssh/sshd_config
# Найдите: PermitRootLogin no
#          PasswordAuthentication no

sudo service ssh restart

# 3. Установите fail2ban (защита от brute-force)
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban

# 4. Обновляйте систему регулярно
sudo apt-get update && sudo apt-get upgrade -y
```

### SSL/HTTPS (Caddy автоматический)

Если используется домен, Caddy автоматически получит SSL сертификат от Let's Encrypt. Просто убедитесь что:
- Домен правильно указывает на ваш IP
- Порты 80 и 443 открыты
- DOMAIN переменная установлена в .env

---

## Логирование и Отладка

### Сохранить Логи

```bash
# Сохранить логи всех сервисов
docker-compose logs > ~/logs-$(date +%Y%m%d-%H%M%S).txt

# Сохранить только backend
docker-compose logs backend > ~/logs-backend-$(date +%Y%m%d-%H%M%S).txt
```

### Включить Debug Режим

```bash
# В .env добавьте:
DEBUG=affine:*
NODE_DEBUG=http,https

# Перезапустите
docker-compose restart backend
```

---

## Чек-Лист Для Go-Live

- [ ] Все контейнеры запущены и healthy
- [ ] Backend возвращает 200 на /api/healthz
- [ ] Frontend доступен по домену/IP
- [ ] Можно создать аккаунт и залогиниться
- [ ] Можно создать workspace и проект
- [ ] Firewall правильно настроен
- [ ] SSL сертификат активен (если домен)
- [ ] Резервная копия БД создана и протестирована
- [ ] Мониторинг настроен (по необходимости)
- [ ] Документация прочитана командой

---

## Дополнительные Ресурсы

- **GitHub Репозиторий:** https://github.com/Leonid1095/PLGames-Board
- **Docker Docs:** https://docs.docker.com
- **Caddy Docs:** https://caddyserver.com/docs
- **PostgreSQL Docs:** https://www.postgresql.org/docs
- **NestJS Docs:** https://docs.nestjs.com

---

**Готово! Ваш PLGames Board успешно развернут! 🎉**
