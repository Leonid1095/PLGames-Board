# AI Onboarding (First Run)

Эта шпаргалка для любого ИИ-агента при первом запуске в репозитории **PLGames-Board**.

## Что прочитать сначала
- `QUICK_AI_INSTRUCTIONS.txt` — краткое поручение для развертывания.
- `AI_DEPLOYMENT_GUIDE.md` — пошаговый гайд по деплойменту (если нужен CI/CD).
- `ARCHITECTURE.md` — общая архитектура системы и сервисов.
- `ROADMAP.md` — текущие приоритеты и принятые решения (читать первым для актуального статуса).
- `README.md`, `INSTALLATION_GUIDE.md`, `QUICK_START.md` — базовая установка.

## Карта репозитория (упрощенно)
- `packages/backend/server` — NestJS backend (API, Prisma, CRM/permission).
- `packages/frontend` — веб-клиент.
- `packages/common` — общие модули/типы.
- `blocksuite/` — редактор и связанные пакеты.
- `scripts/` — вспомогательные скрипты (deploy/test/build).
- `docs/` — документация для разработчиков и админов.
- `tests/` — e2e/интеграционные сценарии.

## Известные проблемы и решения

### Backend DI (NestJS Dependency Injection)
- `CrmModule` требует `PermissionModule` (для `PermissionService`)
- Всегда инжектируй `PrismaClient` (не `PrismaService`), он глобальный из `PrismaModule`
- Пример из `CrmIssueResolver`:
  ```typescript
  import { PrismaClient } from '@prisma/client';
  constructor(
    private readonly crmService: CrmService,
    private readonly permission: PermissionService,
    private readonly prisma: PrismaClient  // <- правильно
  ) {}
  ```

### Docker образы и деплой
- Образы собираются GitHub Actions и публикуются в GHCR
- Теги: `latest` (последний main), `main-<commit_sha>` (конкретный коммит)
- После пуша в main ждать ~5-10 минут пока CI соберёт образ
- На production сервере:
  ```bash
  git pull
  docker compose pull backend   # или указать конкретный тег
  docker compose up -d --force-recreate backend
  docker compose logs -n 50 backend
  ```

## Базовый алгоритм для ИИ
1) Прочитать `ROADMAP.md` для актуального статуса проекта.
2) Прочитать файлы из раздела «Что прочитать сначала».
3) Уточнить задачу у пользователя, если не ясна.
4) Проверить окружение: Docker + Compose, Node/Yarn (для локальной сборки), Prisma.
5) Для деплоя использовать Docker Compose + GHCR образы; при необходимости пересобрать через CI.
6) Перед изменениями просмотреть `ARCHITECTURE.md` и соответствующие `README.md` в пакетах.
7) После работы — записать итог/URL/статус в `STATUS_REPORT.md` или отчёт, который попросит пользователь.

## Ожидаемый результат от агента
- Чёткий план действий и проверок.
- Минимальные изменения в коде (только по необходимости).
- Отчёт о проделанных шагах и статусе сервисов/деплоя.

## Примечания
- Если репозиторий приватный, запросить токен у пользователя.
- По умолчанию использовать HTTP и IP, если домен/HTTPS не указан.
- AI-функции (OpenRouter/OAuth) оставлять выключенными, если не попросили явно.
