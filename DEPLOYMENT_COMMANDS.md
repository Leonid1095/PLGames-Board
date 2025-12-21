# 🚀 Команды для Deployment на Production Сервере

**Дата:** 2025-12-21  
**Цель:** Применить все DI фиксы на production и протестировать

---

## 📋 Шаг 1: Проверить что GitHub Actions закончил сборку

**На локальной машине или в браузере:**

```bash
# Откройте в браузере:
https://github.com/Leonid1095/PLGames-Board/actions

# Убедитесь что последний workflow "Build Docker Images" успешен (зеленая галочка)
# Время сборки: ~10-15 минут
```

**Или проверьте через curl (на сервере):**

```bash
# Попробуйте скачать новый образ
docker pull ghcr.io/leonid1095/plgames-board-backend:latest

# Должен скачать новый образ с digest, содержащим изменения после 4b9a066b9
```

---

## 📋 Шаг 2: Подключиться к Production Серверу

```bash
# Замените на ваши данные
ssh user@your-production-server.com

# Или если используете ключ:
ssh -i ~/.ssh/your-key.pem user@your-production-server.com
```

---

## 📋 Шаг 3: Перейти в Директорию Проекта

```bash
# Обычно проект в ~/plgames-board или /home/plg/plane
cd ~/plgames-board

# Или если другая директория:
cd /home/plg/plane
```

---

## 📋 Шаг 4: Обновить Код из Git

```bash
# Получить последние изменения
git fetch origin

# Посмотреть что изменилось
git log HEAD..origin/main --oneline

# Должны увидеть 11 новых коммитов:
# 4b9a066b9 docs: update TESTING_STATUS with current session results
# d6fee5b3e docs: update README with links to all new documentation
# 99cc9ecad docs: add comprehensive AI agent README with rules and status
# 3b36f8351 docs: add navigation guide for all documentation files
# cce863759 docs: add comprehensive solution summary with all findings and guides
# a7a02fdf1 docs: add complete deployment checklist for production servers
# 918594cdd docs: comprehensive AI onboarding with DI audit details
# be427c813 fix(backend): add PrismaModule import to UserModule
# d7824ab8a fix(backend): import PrismaClient as value in user resolver
# 402cf3a9e fix(backend): use PrismaClient for CrmSprint/Comment/TimeLog resolvers
# cf6fa6055 fix(backend): use PrismaClient instead of PrismaService in CrmIssueResolver

# Применить изменения
git pull origin main
```

---

## 📋 Шаг 5: Скачать Новый Backend Образ

```bash
# Скачать последний образ из GitHub Container Registry
docker compose pull backend

# Проверить что образ обновился
docker images | grep plgames-board-backend

# Должны увидеть новый timestamp (Created: few minutes ago)
```

---

## 📋 Шаг 6: Пересоздать Backend Контейнер

```bash
# Остановить и пересоздать только backend
docker compose up -d --force-recreate backend

# Или если хотите пересоздать все сервисы:
# docker compose up -d --force-recreate
```

---

## 📋 Шаг 7: Проверить Логи Backend

```bash
# Смотрим последние 100 строк логов
docker compose logs -n 100 backend

# Или в реальном времени:
docker compose logs -f backend
```

---

## ✅ Критерии Успеха (Что Искать в Логах)

### ✅ Хорошие Логи (Успех):

```
[Nest] INFO [NestFactory] Starting Nest application...
[Nest] INFO [InstanceLoader] AppModule dependencies initialized
[Nest] INFO [InstanceLoader] PrismaModule dependencies initialized
[Nest] INFO [InstanceLoader] PermissionModule dependencies initialized
[Nest] INFO [InstanceLoader] CrmModule dependencies initialized
[Nest] INFO [InstanceLoader] UserModule dependencies initialized
[Nest] INFO [InstanceLoader] WorkspaceModule dependencies initialized
[Nest] INFO [RouterExplorer] Mapped {/graphql, POST} route
[Nest] INFO [GraphQLModule] GraphQL schema generated
[Nest] INFO [NestApplication] Nest application successfully started
[Nest] INFO Listening on http://0.0.0.0:3010
```

### ❌ Плохие Логи (Ошибка DI - если видите, свяжитесь со мной):

```
❌ Error: Nest can't resolve dependencies of the CrmProjectResolver (?, CrmService, PermissionService)
❌ UnknownDependenciesException: Nest can't resolve dependencies
❌ Cannot instantiate abstract class
❌ Error: Cannot find module '@/core/lib/prisma'
```

---

## 📋 Шаг 8: Проверить Статус Всех Сервисов

```bash
# Проверить что все сервисы запущены
docker compose ps

# Все должны быть в статусе "Up" или "Up (healthy)"
```

---

## 📋 Шаг 9: Проверить API

```bash
# Проверить health endpoint
curl http://localhost:3010/api/healthz

# Должен вернуть: HTTP 200 OK

# Проверить GraphQL endpoint
curl http://localhost:3010/graphql

# Должен вернуть HTML страницу GraphQL Playground
```

---

## 📋 Шаг 10: Проверить в Браузере

```bash
# Откройте в браузере ваш домен:
https://your-domain.com

# Или если localhost:
http://localhost
```

**Должны увидеть:**
- Страницу входа/регистрации PLGames Board
- Никаких ошибок 502 Bad Gateway
- Никаких ошибок в консоли браузера (F12 → Console)

---

## 🐛 Если Что-то Пошло Не Так

### Проблема: Backend не запускается

```bash
# Смотрим полные логи
docker compose logs backend | less

# Ищем строки с ERROR или Exception
docker compose logs backend | grep -i error
docker compose logs backend | grep -i exception

# Проверяем предыдущий контейнер (если был откат)
docker ps -a | grep backend
```

### Проблема: Старый образ не обновился

```bash
# Удалить старый образ принудительно
docker rmi ghcr.io/leonid1095/plgames-board-backend:latest

# Скачать заново
docker compose pull backend

# Пересоздать контейнер
docker compose up -d --force-recreate backend
```

### Проблема: GraphQL не работает

```bash
# Проверить что backend слушает на порту 3010
docker compose exec backend netstat -tlnp | grep 3010

# Или:
docker compose exec backend curl http://localhost:3010/api/healthz
```

### Проблема: Frontend показывает 502

```bash
# Проверить Caddy gateway
docker compose logs caddy -n 50

# Проверить что Caddy видит backend
docker compose exec caddy wget -O- http://backend:3010/api/healthz
```

---

## 📊 После Успешного Запуска

### Проверьте функциональность:

1. **Регистрация нового пользователя** - должна работать
2. **Создание workspace** - должно работать
3. **Создание CRM проекта** - должно работать (раньше падало!)
4. **Создание задачи (issue)** - должно работать
5. **Добавление комментария** - должно работать
6. **Логирование времени** - должно работать

---

## 📝 Сообщите Результаты

После выполнения всех шагов, пришлите мне:

1. **Статус из Шага 7:**
   ```bash
   docker compose logs -n 100 backend | tail -20
   ```

2. **Статус из Шага 8:**
   ```bash
   docker compose ps
   ```

3. **Статус из Шага 9:**
   ```bash
   curl -I http://localhost:3010/api/healthz
   ```

4. **Скриншот браузера** (если возможно) - страница входа PLGames Board

---

## 🎯 Быстрая Версия (Все Команды Одной Строкой)

```bash
# Подключитесь к серверу и выполните:
cd ~/plgames-board && \
git pull origin main && \
docker compose pull backend && \
docker compose up -d --force-recreate backend && \
echo "Ждем 30 секунд пока backend запустится..." && \
sleep 30 && \
docker compose logs -n 100 backend && \
echo "--- Проверка health check ---" && \
curl -I http://localhost:3010/api/healthz && \
echo "--- Статус сервисов ---" && \
docker compose ps
```

---

## 📞 Если Нужна Помощь

- Пришлите логи: `docker compose logs backend > backend.log`
- Откройте GitHub Issue с приложенным файлом
- Или свяжитесь со мной напрямую

---

**Готово! Следуйте шагам по порядку и все заработает! 🚀**
