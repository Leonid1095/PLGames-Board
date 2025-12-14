# PLGames Board - Архитектура и структура проекта

**Для новых сессий с AI:** Этот файл описывает структуру проекта, назначение файлов и как всё работает вместе.

---

## Обзор проекта

**PLGames Board** - форк AFFiNE, адаптированный для российского рынка как система управления проектами и CRM.

**GitHub:** https://github.com/Leonid1095/PLGames-Board

---

## Ключевые файлы конфигурации

### Docker и развертывание

| Файл | Назначение |
|------|-----------|
| `docker-compose.yml` | Оркестрация всех сервисов (backend, frontend, gateway, postgres, redis) |
| `plgames/Dockerfile` | Multi-stage сборка: builder → backend → frontend |
| `Caddyfile` | Конфигурация Caddy gateway для HTTPS и reverse proxy |
| `.env.example` | Шаблон переменных окружения |
| `install.sh` | Интерактивный установщик для новых серверов |

### Документация

| Файл | Назначение |
|------|-----------|
| `ROADMAP.md` | Дорожная карта, текущий статус, российские зеркала |
| `ARCHITECTURE.md` | Этот файл - структура проекта |
| `README.md` | Общее описание и быстрый старт |
| `INSTALL_RU.md` | Подробная инструкция установки на русском |
| `FEATURES_ANALYSIS.md` | Анализ функций CRM и AI |

---

## Архитектура Docker

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    GATEWAY (Caddy)                           │
│                    Порты: 80, 443                            │
│                    - Автоматический HTTPS (Let's Encrypt)    │
│                    - Reverse proxy на frontend               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Caddy)                          │
│                    Внутренний порт: 80                       │
│                    - Статические файлы React                 │
│                    - Проксирует /api/* на backend            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (Node.js)                         │
│                    Порт: 3010                                │
│                    - GraphQL API                             │
│                    - REST API                                │
│                    - WebSocket                               │
└─────────────────────────────────────────────────────────────┘
                    │                   │
                    ▼                   ▼
┌─────────────────────────┐   ┌─────────────────────────┐
│   POSTGRESQL (pgvector) │   │         REDIS           │
│   Порт: 5432 (внутр.)   │   │   Порт: 6379 (внутр.)   │
│   - Данные              │   │   - Кэш                 │
│   - Векторный поиск     │   │   - Сессии              │
└─────────────────────────┘   └─────────────────────────┘
```

---

## Структура Dockerfile (plgames/Dockerfile)

```dockerfile
# Stage 1: BUILDER
FROM node:22-bookworm AS builder
# - Устанавливает системные зависимости (git, python3, build-essential)
# - Устанавливает Rust через rsproxy.cn (для России)
# - Конфигурирует Cargo на USTC mirror
# - Собирает все workspace пакеты

# Stage 2: BACKEND
FROM node:22-bookworm-slim AS backend
# - Копирует собранный backend из builder
# - Включает jemalloc для оптимизации памяти
# - Порт 3010

# Stage 3: FRONTEND
FROM caddy:2-alpine AS frontend
# - Копирует собранные статические файлы
# - Использует Caddyfile для reverse proxy
# - Порт 80
```

### Российские зеркала в Dockerfile

```dockerfile
# Rust установка
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"

# Cargo crates
[source.crates-io]
replace-with = "ustc"
[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
```

**Почему:** sh.rustup.rs и crates.io недоступны/медленны в России.

---

## Сервисы в docker-compose.yml

| Сервис | Образ | Порты | Назначение |
|--------|-------|-------|-----------|
| `gateway` | caddy:2-alpine | 80, 443 | HTTPS терминация, Let's Encrypt |
| `frontend` | plgames-board-frontend | внутр. 80 | Статические файлы React |
| `backend` | plgames-board-backend | 3010 | API сервер |
| `postgres` | pgvector/pgvector:pg16 | внутр. 5432 | База данных |
| `redis` | redis:alpine | внутр. 6379 | Кэш и сессии |

**Важно:** PostgreSQL и Redis не экспонируются наружу - доступны только внутри Docker сети.

---

## Переменные окружения (.env)

### Обязательные:
```env
DOMAIN=your-domain.com          # Домен для Caddy
BASE_URL=https://your-domain.com
DB_PASSWORD=secure_password     # Пароль PostgreSQL
```

### Опциональные:
```env
# AI (OpenRouter)
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-...

# OAuth (Yandex)
OIDC_CLIENT_ID=...
OIDC_CLIENT_SECRET=...
```

---

## Структура исходного кода

```
plgames/
├── packages/
│   ├── backend/
│   │   ├── server/           # Основной backend (NestJS)
│   │   │   ├── src/
│   │   │   │   ├── core/
│   │   │   │   │   ├── crm/  # CRM модуль (Projects, Issues, Sprints)
│   │   │   │   │   └── ...
│   │   │   │   └── ...
│   │   │   └── schema.prisma # Схема базы данных
│   │   └── native/           # Нативные модули (Rust/NAPI)
│   │
│   ├── frontend/
│   │   └── apps/
│   │       └── web/          # React приложение
│   │           ├── dist/     # Собранные файлы (после build)
│   │           └── Caddyfile # Конфиг для frontend Caddy
│   │
│   └── common/
│       └── reader/           # Общие утилиты
│
├── Dockerfile                # Multi-stage сборка
└── ...
```

---

## Порядок сборки в Docker

1. `@affine/templates` - Шаблоны
2. `@affine/reader` - Утилиты чтения
3. `@affine/server-native` - Нативные модули (требует Rust 1.82+)
4. `@affine/server` - Backend сервер
5. `@affine/web` - Frontend приложение

**Время сборки:** ~15-25 минут (холодный старт)

---

## Типичные проблемы и решения

### 1. Rust не устанавливается (timeout)
**Причина:** sh.rustup.rs недоступен в России
**Решение:** Используем rsproxy.cn зеркало (уже настроено)

### 2. Cargo crates не скачиваются
**Причина:** crates.io недоступен через git
**Решение:** USTC mirror с sparse протоколом (уже настроено)

### 3. Порты 80/443 заняты
**Причина:** Системный Caddy или Nginx уже запущен
**Решение:**
- Вариант A: Использовать системный Caddy, добавить конфиг для PLGames
- Вариант B: Остановить системный веб-сервер

### 4. PostgreSQL порт занят
**Причина:** Другой PostgreSQL на сервере
**Решение:** PostgreSQL не экспонируется наружу (уже исправлено)

---

## Команды для работы

### Сборка и запуск:
```bash
docker compose build --no-cache   # Полная пересборка
docker compose up -d              # Запуск в фоне
docker compose down               # Остановка
```

### Логи:
```bash
docker compose logs -f            # Все логи
docker compose logs backend -f    # Только backend
docker compose logs frontend -f   # Только frontend
```

### Статус:
```bash
docker compose ps                 # Статус контейнеров
docker compose exec backend curl localhost:3010/api/healthz  # Health check
```

### Обновление:
```bash
git pull origin main
docker compose build --no-cache
docker compose up -d
```

---

## Первый запуск

1. Приложение доступно по адресу домена
2. **Первый зарегистрированный пользователь становится администратором**
3. После регистрации можно приглашать других пользователей

---

## Дальнейшее развитие

См. `ROADMAP.md` для полной дорожной карты.

**Ближайшие задачи:**
- [ ] Настройка домена
- [ ] Полный ребрендинг (убрать упоминания AFFiNE)
- [ ] CRM Frontend UI (Kanban, дашборды)
- [ ] Автоматические напоминания

---

**Последнее обновление:** 2024-12-14
