# ⚡ Быстрое исправление для AI на uwow-guide.online

**Для:** AI-ассистента на сервере uwow-guide.online
**Проблема:** Backend не запущен, сайт отдает 502
**Решение:** Пошаговая инструкция (10 минут)

---

## 📋 Текущая ситуация

### Что работает ✅:
- PostgreSQL запущен
- Redis запущен
- Caddy запущен
- .env файл настроен
- Код скачан

### Что НЕ работает ❌:
- Backend сервер (порт 3010)
- Сайт uwow-guide.online (502 ошибка)

---

## 🚀 БЫСТРОЕ ИСПРАВЛЕНИЕ (выполни по порядку)

### ШАГ 1: Перейди в директорию проекта

```bash
cd /home/plgames/boards_plane
pwd  # Должно показать: /home/plgames/boards_plane
```

### ШАГ 2: Проверь статус контейнеров

```bash
docker compose -f docker-compose.prod.yml ps
```

**Ищи строку с backend:**
```
boards_plane-backend-1    Restarting (1)    # ❌ ПРОБЛЕМА: постоянно перезапускается
# или
boards_plane-backend-1    Exited (1)        # ❌ ПРОБЛЕМА: упал и не запускается
```

### ШАГ 3: Посмотри логи backend (найди ошибку)

```bash
docker compose -f docker-compose.prod.yml logs backend --tail=50
```

**Ищи в логах:**
- `Error: Could not find Prisma Schema` → Решение A
- `Error: P3009: migrate found failed` → Решение B
- `Cannot reach database server` → Решение C
- Любая другая ошибка → Решение D (полная пересборка)

---

## 🔧 РЕШЕНИЯ

### Решение A: Schema не найден (быстрое - 5 минут)

```bash
# 1. Остановить
docker compose -f docker-compose.prod.yml down

# 2. Пересобрать backend БЕЗ кэша
docker compose -f docker-compose.prod.yml build --no-cache backend

# 3. Запустить
docker compose -f docker-compose.prod.yml up -d

# 4. Подождать 30 секунд
sleep 30

# 5. Проверить логи (должно быть "successfully started")
docker compose -f docker-compose.prod.yml logs backend | grep "successfully"

# 6. Проверить что работает
curl -I http://localhost:3010/graphql
# Должно быть HTTP/1.1 400 или 200
```

**Если получил 400 или 200 - ГОТОВО! Переходи к Финальной проверке.**

---

### Решение B: Проблема с миграциями (5 минут)

```bash
# 1. Запусти только базы данных
docker compose -f docker-compose.prod.yml up -d postgres redis

# 2. Подождать 20 секунд
sleep 20

# 3. Выполни миграции вручную
docker compose -f docker-compose.prod.yml run --rm backend sh -c "npx prisma migrate deploy"

# Должно быть:
# ✓ All migrations have been successfully applied

# 4. Запусти backend
docker compose -f docker-compose.prod.yml up -d backend

# 5. Подождать 10 секунд
sleep 10

# 6. Проверить
curl -I http://localhost:3010/graphql
```

**Если получил 400 или 200 - ГОТОВО! Переходи к Финальной проверке.**

---

### Решение C: Проблема с сетью (3 минуты)

```bash
# 1. Проверь что network существует
docker network ls | grep plgames

# Если нет - создай
docker network create boards_plane_plgames-network

# 2. Перезапусти всё
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# 3. Подождать 30 секунд
sleep 30

# 4. Проверить
curl -I http://localhost:3010/graphql
```

---

### Решение D: Полная пересборка (15-20 минут)

**Используй это если ничего выше не помогло:**

```bash
# 1. Остановить всё
docker compose -f docker-compose.prod.yml down

# 2. Удалить образы
docker compose -f docker-compose.prod.yml rm -f
docker rmi boards_plane-backend boards_plane-frontend || true

# 3. Собрать заново БЕЗ кэша
docker compose -f docker-compose.prod.yml build --no-cache

# ⏰ Это займет 15-20 минут. Жди завершения.

# 4. Запустить
docker compose -f docker-compose.prod.yml up -d

# 5. Подождать 60 секунд
sleep 60

# 6. Выполнить миграции
docker compose -f docker-compose.prod.yml exec backend sh -c "npx prisma migrate deploy"

# 7. Проверить
curl -I http://localhost:3010/graphql
```

---

### Решение E: УПРОЩЕННАЯ ВЕРСИЯ (только backend - 10 минут)

**Используй если frontend не нужен или не собирается:**

```bash
# 1. Переключись на упрощенную версию
docker compose -f docker-compose.simple.yml down
docker compose -f docker-compose.prod.yml down

# 2. Собери только backend
docker compose -f docker-compose.simple.yml build --no-cache

# 3. Запусти
docker compose -f docker-compose.simple.yml up -d

# 4. Подождать 30 секунд
sleep 30

# 5. Выполни миграции
docker compose -f docker-compose.simple.yml exec backend sh -c "npx prisma migrate deploy"

# 6. Проверить
curl -I http://localhost:3010/graphql
```

**Эта версия запустит только backend + базы данных. Frontend нужно будет настроить отдельно.**

---

## ✅ ФИНАЛЬНАЯ ПРОВЕРКА

### 1. Проверь что backend запущен

```bash
# Статус контейнеров
docker compose -f docker-compose.prod.yml ps

# Должно быть:
# boards_plane-backend-1    Up (healthy)    ✅
```

### 2. Проверь логи backend

```bash
docker compose -f docker-compose.prod.yml logs backend --tail=20
```

**ОБЯЗАТЕЛЬНО должно быть:**
```
[Nest] ... INFO [NestApplication] Nest application successfully started
```

**Если этой строки НЕТ - backend НЕ запущен!**

### 3. Проверь что порт 3010 отвечает

```bash
curl -I http://localhost:3010/graphql
```

**Ожидаемый результат:**
```
HTTP/1.1 400 Bad Request
# или
HTTP/1.1 200 OK
```

**Если "Connection refused" - backend НЕ работает, вернись к Решению D.**

### 4. Проверь сайт снаружи

```bash
curl -I https://uwow-guide.online
```

**Ожидаемый результат:**
```
HTTP/2 200 OK
```

**Если 502 Bad Gateway:**
- Backend не запущен (вернись к ШАГ 2)
- Или Caddy настроен неправильно (проверь конфиг Caddy)

---

## 🎯 СООБЩИ ПОЛЬЗОВАТЕЛЮ

### Если всё работает ✅:

```
✅ PLGames Board успешно запущен!

Статус:
- Backend: Running на порту 3010 ✅
- Frontend: Running на порту 8080 ✅
- PostgreSQL: Running ✅
- Redis: Running ✅

Сайт доступен по адресу: https://uwow-guide.online

GraphQL Playground: https://uwow-guide.online:3010/graphql
(или http://uwow-guide.online:3010/graphql если HTTPS не настроен для порта 3010)

Все миграции базы данных выполнены успешно.
```

### Если НЕ работает ❌:

```
❌ Backend не удалось запустить.

Пожалуйста, проверьте:
1. Логи backend контейнера - есть ли ошибки?
2. PostgreSQL доступен и запущен?
3. .env файл содержит все нужные переменные?

Отправляю диагностическую информацию...
```

**Собери диагностику:**
```bash
cd /home/plgames/boards_plane

# Статус
docker compose -f docker-compose.prod.yml ps > status.txt

# Логи backend
docker compose -f docker-compose.prod.yml logs backend --tail=200 > backend_logs.txt

# Конфигурация
docker compose -f docker-compose.prod.yml config > config.txt

# Отправь пользователю эти 3 файла
cat status.txt
cat backend_logs.txt | tail -50
```

---

## 🚨 ВАЖНО: Типичные ошибки

### ❌ НЕ ДЕЛАЙ ТАК:

1. **Не проверил логи:**
```bash
docker compose up -d
# ❌ Сразу сказал "работает" не проверив логи!
```

**Правильно:**
```bash
docker compose up -d
sleep 10
docker compose logs backend | grep "successfully started"
# ✅ Проверил что backend действительно запустился
```

2. **Не дождался инициализации PostgreSQL:**
```bash
docker compose up -d
docker compose exec backend npx prisma migrate deploy
# ❌ PostgreSQL еще не готов!
```

**Правильно:**
```bash
docker compose up -d
sleep 30  # ✅ Дождаться healthcheck PostgreSQL
docker compose exec backend npx prisma migrate deploy
```

3. **Забыл проверить порт 3010:**
```bash
# ❌ Просто запустил и не проверил что порт отвечает
```

**Правильно:**
```bash
curl -I http://localhost:3010/graphql
# ✅ Убедился что backend отвечает
```

---

## 📊 Диагностические команды

Если ничего не помогло, выполни по порядку:

```bash
# 1. Версии
docker --version
docker compose version

# 2. Статус контейнеров
docker compose -f docker-compose.prod.yml ps

# 3. Логи backend (последние 100 строк)
docker compose -f docker-compose.prod.yml logs backend --tail=100

# 4. Проверка сети
docker network inspect boards_plane_plgames-network

# 5. Проверка подключения к PostgreSQL из backend
docker compose -f docker-compose.prod.yml exec backend sh -c "apt-get update && apt-get install -y postgresql-client && psql \$DATABASE_URL -c 'SELECT version();'"

# 6. Проверка портов
netstat -tlnp | grep -E "3010|5432"

# 7. .env файл (БЕЗ ПАРОЛЕЙ!)
grep -v PASSWORD /home/plgames/boards_plane/.env
```

Отправь результаты пользователю.

---

## 📞 Дополнительные ресурсы

Если нужна более подробная информация:
- [DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md) - полное руководство по устранению проблем
- [DEPLOYMENT_FIX.md](DEPLOYMENT_FIX.md) - альтернативные варианты развертывания
- [AI_DEPLOYMENT_GUIDE.md](AI_DEPLOYMENT_GUIDE.md) - пошаговая инструкция для AI

---

**Последнее обновление:** 2024-12-02
**Для сервера:** uwow-guide.online
**Проект:** PLGames Board v1.0.0
