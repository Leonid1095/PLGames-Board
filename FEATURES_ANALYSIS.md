# 📊 PLGames - Анализ возможностей системы

**Дата анализа:** 2024-12-01
**Версия:** 1.0.0

---

## 🎯 ОТВЕТЫ НА ВАШИ ВОПРОСЫ

### ❓ Вопрос 1: Можно ли подключить OpenRouter (AI)?

### ✅ **ДА! OpenRouter полностью поддерживается**

#### Как подключить:

1. **Получите API ключ:**
   - Зарегистрируйтесь на https://openrouter.ai/
   - Создайте API ключ
   - Пополните баланс (цены от $0.0001 за запрос)

2. **Настройте в .env файле:**
```bash
# Включите AI функции
AFFINE_COPILOT_ENABLED=true

# Добавьте API ключ
AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-v1-ваш_ключ_здесь

# Выберите модель
AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct
```

3. **Перезапустите систему:**
```bash
docker compose -f docker-compose.prod.yml restart backend
```

#### Доступные AI модели через OpenRouter:

**Топовые модели:**
- ✅ `openai/gpt-4o` - GPT-4 Omni (текст + изображения)
- ✅ `openai/gpt-4o-mini` - GPT-4 Mini (быстрее и дешевле)
- ✅ `anthropic/claude-3.5-sonnet` - Claude 3.5 Sonnet (отлично для кода)
- ✅ `anthropic/claude-3-haiku` - Claude 3 Haiku (быстро и дешево)
- ✅ `google/gemini-pro-1.5` - Gemini 1.5 Pro (текст + изображения)

**Открытые модели (дешевле):**
- ✅ `meta-llama/llama-3.1-70b-instruct` - Llama 3.1 70B
- ✅ `mistralai/mistral-7b-instruct` - Mistral 7B

**Embedding модели (для поиска):**
- ✅ `openai/text-embedding-3-large` - Большая модель
- ✅ `openai/text-embedding-3-small` - Малая модель

#### Что может AI в системе:

**✅ Встроенные функции AFFiNE:**
1. **AI Copilot** - помощник в документах:
   - Генерация текста
   - Продолжение текста
   - Улучшение текста
   - Перевод
   - Резюмирование

2. **AI Content Generation:**
   - Автоматическое создание заголовков
   - Генерация описаний
   - Создание контента по промпту

3. **AI Search:**
   - Семантический поиск по документам
   - Поиск похожих документов
   - Векторный поиск (embedding)

4. **AI Chat:**
   - Чат с документами
   - Вопросы-ответы по контенту
   - Контекстные подсказки

#### Интеграция с OpenRouter:

**Файл:** `plgames/packages/backend/server/src/plugins/copilot/providers/openrouter.ts`

**Возможности:**
- ✅ Streaming ответов (реального времени)
- ✅ Structured output (JSON ответы)
- ✅ Embeddings (векторизация текста)
- ✅ Vision (анализ изображений для GPT-4o/Gemini)
- ✅ Автоматическая обработка ошибок
- ✅ Метрики использования
- ✅ Кэширование

**Пример использования в GraphQL:**
```graphql
mutation {
  copilotChat(
    messages: [
      { role: "user", content: "Напиши план проекта для CRM" }
    ]
  ) {
    message
  }
}
```

#### Примерная стоимость:

| Модель | Цена за 1M токенов | Использование |
|--------|-------------------|---------------|
| Llama 3.1 70B | $0.88 | Рекомендуется для начала |
| GPT-4o Mini | $0.15 (input) / $0.60 (output) | Отлично для большинства задач |
| Claude 3.5 Sonnet | $3.00 (input) / $15.00 (output) | Для сложных задач |
| GPT-4o | $5.00 (input) / $15.00 (output) | Топовая модель |

**Рекомендация:** Начните с `meta-llama/llama-3.1-70b-instruct` - отличное качество за низкую цену!

---

### ❓ Вопрос 2: CRM система работает?

### ✅ **ДА! CRM полностью реализована и готова к работе**

#### Реализованные модули CRM:

### 1️⃣ **Управление проектами (CrmProject)**

**Таблица:** `crm_projects`
**GraphQL:** `CrmProjectResolver`

**Возможности:**
- ✅ Создание проектов
- ✅ Уникальный KEY для каждого проекта (например: PROJ, CRM, DEV)
- ✅ Назначение руководителя проекта (Lead)
- ✅ Привязка к Workspace
- ✅ Описание проекта
- ✅ Автоматический подсчет задач в проекте
- ✅ Статистика по проекту

**GraphQL примеры:**
```graphql
# Создать проект
mutation {
  createCrmProject(input: {
    name: "Новая CRM система"
    key: "CRM"
    description: "Разработка CRM для управления клиентами"
    workspaceId: "workspace-id"
    leadId: "user-id"
  }) {
    id
    name
    key
    lead {
      name
      email
    }
  }
}

# Получить все проекты в workspace
query {
  crmProjectsByWorkspace(workspaceId: "workspace-id") {
    id
    name
    key
    issuesCount
    lead {
      name
    }
  }
}

# Обновить проект
mutation {
  updateCrmProject(
    id: "project-id"
    input: {
      name: "Обновленное название"
      leadId: "new-lead-id"
    }
  ) {
    id
    name
  }
}
```

### 2️⃣ **Управление задачами (CrmIssue)**

**Таблица:** `crm_issues`
**GraphQL:** `CrmIssueResolver`

**Поля задачи:**
- ✅ **title** - Название задачи
- ✅ **description** - Подробное описание
- ✅ **status** - Статус (BACKLOG, TODO, IN_PROGRESS, IN_REVIEW, DONE, CANCELLED)
- ✅ **priority** - Приоритет (LOWEST, LOW, MEDIUM, HIGH, HIGHEST)
- ✅ **type** - Тип (TASK, BUG, STORY, EPIC, SUBTASK)
- ✅ **assignee** - Исполнитель (кому назначена)
- ✅ **reporter** - Автор (кто создал)
- ✅ **sprint** - Спринт (если используется Agile)
- ✅ **parent** - Родительская задача (для подзадач)
- ✅ **storyPoints** - Story points (для оценки)
- ✅ **dueDate** - ⭐ **ДЕДЛАЙН ЗАДАЧИ** ⭐
- ✅ **comments[]** - Комментарии к задаче
- ✅ **timeLogs[]** - Учет времени

**Типы задач:**
1. **TASK** - Обычная задача
2. **BUG** - Баг/ошибка
3. **STORY** - User Story (Agile)
4. **EPIC** - Большая задача (набор Stories)
5. **SUBTASK** - Подзадача (child task)

**Статусы:**
```
BACKLOG → TODO → IN_PROGRESS → IN_REVIEW → DONE
                                         ↓
                                    CANCELLED
```

**Приоритеты:**
```
HIGHEST (Критично!)
  ↓
HIGH (Высокий)
  ↓
MEDIUM (Средний)
  ↓
LOW (Низкий)
  ↓
LOWEST (Минимальный)
```

**GraphQL примеры:**
```graphql
# Создать задачу с дедлайном
mutation {
  createCrmIssue(input: {
    title: "Реализовать авторизацию"
    description: "Нужно добавить OAuth через Yandex"
    projectId: "project-id"
    reporterId: "user-id"
    assigneeId: "developer-id"
    type: TASK
    priority: HIGH
    status: TODO
    dueDate: "2024-12-15T23:59:59Z"  # ⭐ ДЕДЛАЙН
    storyPoints: 8
  }) {
    id
    title
    dueDate
    assignee {
      name
      email
    }
  }
}

# Получить задачи со статусом IN_PROGRESS
query {
  crmIssuesByProject(
    projectId: "project-id"
    status: IN_PROGRESS
  ) {
    id
    title
    priority
    dueDate  # ⭐ ДЕДЛАЙН
    assignee {
      name
    }
  }
}

# Создать подзадачу
mutation {
  createCrmIssue(input: {
    title: "Написать тесты для OAuth"
    projectId: "project-id"
    reporterId: "user-id"
    type: SUBTASK
    parentId: "parent-task-id"  # Родительская задача
  }) {
    id
    title
    parent {
      title
    }
  }
}

# Обновить статус задачи
mutation {
  updateCrmIssue(
    id: "issue-id"
    input: {
      status: IN_REVIEW
    }
  ) {
    id
    status
  }
}
```

### 3️⃣ **Спринты (CrmSprint)** - Agile/Scrum

**Таблица:** `crm_sprints`
**GraphQL:** `CrmSprintResolver`

**Возможности:**
- ✅ Создание спринтов
- ✅ Установка даты начала и конца (startDate, endDate)
- ✅ Цель спринта (goal)
- ✅ Активный/завершенный спринт (isActive)
- ✅ Привязка задач к спринту
- ✅ Автоматический подсчет задач в спринте

**GraphQL примеры:**
```graphql
# Создать спринт
mutation {
  createCrmSprint(input: {
    name: "Спринт 1"
    goal: "Реализовать базовую авторизацию"
    projectId: "project-id"
    startDate: "2024-12-01T00:00:00Z"
    endDate: "2024-12-14T23:59:59Z"
    isActive: true
  }) {
    id
    name
    goal
    startDate
    endDate
  }
}

# Получить активный спринт
query {
  crmSprintsByProject(
    projectId: "project-id"
    isActive: true
  ) {
    id
    name
    goal
    issuesCount
    issues {
      title
      status
    }
  }
}
```

### 4️⃣ **Комментарии (CrmComment)**

**Таблица:** `crm_comments`
**GraphQL:** `CrmCommentResolver`

**Возможности:**
- ✅ Добавление комментариев к задачам
- ✅ Автор комментария
- ✅ Временные метки
- ✅ Редактирование комментариев

**GraphQL примеры:**
```graphql
# Добавить комментарий к задаче
mutation {
  createCrmComment(input: {
    content: "Начал работу над задачей, сделаю к вечеру"
    issueId: "issue-id"
    authorId: "user-id"
  }) {
    id
    content
    author {
      name
    }
    createdAt
  }
}

# Получить комментарии задачи
query {
  crmCommentsByIssue(issueId: "issue-id") {
    id
    content
    author {
      name
      email
    }
    createdAt
  }
}
```

### 5️⃣ **Учет времени (CrmTimeLog)**

**Таблица:** `crm_time_logs`
**GraphQL:** `CrmTimeLogResolver`

**Возможности:**
- ✅ Логирование времени по задачам
- ✅ Время в минутах (timeSpent)
- ✅ Описание работы
- ✅ Дата логирования
- ✅ Привязка к пользователю
- ✅ Автоматический подсчет общего времени

**GraphQL примеры:**
```graphql
# Залогировать время работы
mutation {
  createCrmTimeLog(input: {
    issueId: "issue-id"
    userId: "user-id"
    timeSpent: 120  # 2 часа = 120 минут
    description: "Реализовал OAuth интеграцию"
    loggedAt: "2024-12-01T18:00:00Z"
  }) {
    id
    timeSpent
    description
  }
}

# Получить все логи времени по задаче
query {
  crmTimeLogsByIssue(issueId: "issue-id") {
    id
    timeSpent
    description
    user {
      name
    }
    loggedAt
  }
}

# Получить общее время по задаче
query {
  crmIssue(id: "issue-id") {
    id
    title
    timeLogs {
      timeSpent
    }
  }
}
```

#### Статистика и агрегация:

**CrmService предоставляет:**
- ✅ `countIssuesByProject()` - Количество задач в проекте
- ✅ `countIssuesByStatus()` - Количество задач по статусам
- ✅ `getTotalTimeSpent()` - Общее время по задаче
- ✅ Фильтрация по статусу, исполнителю, спринту
- ✅ Сортировка и пагинация

#### Безопасность:

- ✅ **Workspace-based permissions** - доступ только к своему workspace
- ✅ **User authentication** - требуется авторизация
- ✅ **GraphQL Guards** - проверка прав на каждом запросе
- ✅ **Input validation** - валидация всех входных данных

---

### ❓ Вопрос 3: Можно ли устанавливать таймеры/напоминания?

### ⚠️ **ЧАСТИЧНО - Есть база, нужна доработка**

#### Что УЖЕ есть в системе:

### 1️⃣ **dueDate (Дедлайн) - РАБОТАЕТ ✅**

**В задачах CRM:**
```graphql
mutation {
  createCrmIssue(input: {
    title: "Загрузить ТЗ на сайт"
    dueDate: "2024-12-15T23:59:59Z"  # Дедлайн
    # ... другие поля
  }) {
    id
    title
    dueDate
  }
}
```

**Можно:**
- ✅ Установить дедлайн для задачи
- ✅ Видеть дедлайн в GraphQL API
- ✅ Фильтровать задачи по дедлайну
- ✅ Сортировать по дедлайну

**НЕ работает автоматически:**
- ❌ Автоматические напоминания за N дней до дедлайна
- ❌ Email уведомления о приближающемся дедлайне
- ❌ Push уведомления
- ❌ Автоматическая смена статуса при просрочке

### 2️⃣ **Notification System - РАБОТАЕТ ✅**

**Таблица:** `notifications`
**Модель:** `NotificationModel`

**Типы уведомлений:**
- ✅ `Mention` - Упоминание в документе
- ✅ `Invitation` - Приглашение в workspace
- ✅ `Comment` - Комментарий
- ✅ `CommentMention` - Упоминание в комментарии

**Возможности:**
- ✅ Создание уведомлений
- ✅ Отметка как прочитанное
- ✅ Фильтр прочитанных/непрочитанных
- ✅ Автоматическая очистка старых (>1 года)

**Что НЕ работает:**
- ❌ Уведомления для CRM задач (только для документов)
- ❌ Напоминания по времени/дате
- ❌ Повторяющиеся напоминания

### 3️⃣ **Cron Jobs / Schedule - РАБОТАЕТ ✅**

**Система использует:** `@nestjs/schedule`

**Файлы с Cron:**
- `plgames/packages/backend/server/src/core/auth/job.ts`
- `plgames/packages/backend/server/src/core/doc/job.ts`
- `plgames/packages/backend/server/src/core/notification/job.ts`
- `plgames/packages/backend/server/src/core/mail/job.ts`

**Примеры существующих Cron задач:**
```typescript
@Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
async cleanExpiredNotifications() {
  // Очистка старых уведомлений
}

@Cron(CronExpression.EVERY_HOUR)
async sendScheduledEmails() {
  // Отправка отложенных email
}
```

**Можно добавить свои Cron для CRM!**

---

## 💡 ЧТО НУЖНО ДОДЕЛАТЬ ДЛЯ ПОЛНОЦЕННЫХ НАПОМИНАНИЙ

### Сценарий использования (ваш пример):

> "Я загрузил ТЗ, хочу знать когда его реализуют"

### Решение 1: Использовать существующий dueDate ✅

**Что делаем:**
1. Создаем задачу "Реализовать ТЗ"
2. Устанавливаем `dueDate` (например, через 7 дней)
3. Назначаем исполнителя
4. Отслеживаем статус вручную или через API

**Пример:**
```graphql
mutation {
  createCrmIssue(input: {
    title: "Реализовать ТЗ от клиента XYZ"
    description: "ТЗ загружено в документ doc-123"
    projectId: "project-id"
    reporterId: "manager-id"
    assigneeId: "developer-id"
    type: TASK
    priority: HIGH
    dueDate: "2024-12-08T17:00:00Z"  # Дедлайн - 8 декабря
    storyPoints: 13
  }) {
    id
    title
    dueDate
  }
}
```

**Как отслеживать:**
```graphql
# Получить задачи с дедлайном сегодня или раньше
query {
  crmIssuesByProject(projectId: "project-id") {
    id
    title
    status
    dueDate
    assignee {
      name
    }
  }
}
```

**Минус:** Нужно проверять вручную или писать скрипт

### Решение 2: Добавить Cron для напоминаний (требует доработки)

**Что нужно реализовать:**

#### Файл: `plgames/packages/backend/server/src/core/crm/crm-notifications.job.ts`

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { CrmService } from './crm.service';
import { NotificationModel } from '../../models/notification';
import { MailService } from '../mail';

@Injectable()
export class CrmNotificationJob {
  private readonly logger = new Logger(CrmNotificationJob.name);

  constructor(
    private readonly crmService: CrmService,
    private readonly notification: NotificationModel,
    private readonly mail: MailService
  ) {}

  // Проверяет каждый час
  @Cron(CronExpression.EVERY_HOUR)
  async checkUpcomingDeadlines() {
    this.logger.log('Checking upcoming deadlines...');

    // Получить задачи с дедлайном в ближайшие 24 часа
    const tomorrow = new Date();
    tomorrow.setHours(tomorrow.getHours() + 24);

    const issues = await this.crmService.getIssuesWithUpcomingDeadline(tomorrow);

    for (const issue of issues) {
      // Создать уведомление для исполнителя
      if (issue.assigneeId) {
        await this.notification.create({
          userId: issue.assigneeId,
          type: 'CRM_DEADLINE_REMINDER',
          body: {
            issueId: issue.id,
            issueTitle: issue.title,
            dueDate: issue.dueDate,
            projectId: issue.projectId
          }
        });

        // Отправить email
        await this.mail.sendDeadlineReminder(
          issue.assignee.email,
          issue.title,
          issue.dueDate
        );
      }

      // Уведомить автора задачи
      if (issue.reporterId && issue.reporterId !== issue.assigneeId) {
        await this.notification.create({
          userId: issue.reporterId,
          type: 'CRM_DEADLINE_REMINDER',
          body: {
            issueId: issue.id,
            issueTitle: issue.title,
            dueDate: issue.dueDate
          }
        });
      }
    }

    this.logger.log(`Sent ${issues.length} deadline reminders`);
  }

  // Проверяет просроченные задачи каждый день в 9:00
  @Cron('0 9 * * *')
  async checkOverdueIssues() {
    this.logger.log('Checking overdue issues...');

    const now = new Date();
    const overdueIssues = await this.crmService.getOverdueIssues(now);

    for (const issue of overdueIssues) {
      // Уведомить исполнителя о просрочке
      if (issue.assigneeId) {
        await this.notification.create({
          userId: issue.assigneeId,
          level: 'URGENT',
          type: 'CRM_OVERDUE',
          body: {
            issueId: issue.id,
            issueTitle: issue.title,
            dueDate: issue.dueDate,
            daysOverdue: Math.floor((now - issue.dueDate) / (1000 * 60 * 60 * 24))
          }
        });
      }
    }

    this.logger.log(`Found ${overdueIssues.length} overdue issues`);
  }
}
```

**Добавить методы в CrmService:**

```typescript
// В plgames/packages/backend/server/src/core/crm/crm.service.ts

async getIssuesWithUpcomingDeadline(beforeDate: Date) {
  return this.issueModel.findMany({
    where: {
      dueDate: {
        lte: beforeDate,
        gte: new Date()
      },
      status: {
        notIn: ['DONE', 'CANCELLED']
      }
    },
    include: {
      assignee: true,
      reporter: true,
      project: true
    }
  });
}

async getOverdueIssues(now: Date) {
  return this.issueModel.findMany({
    where: {
      dueDate: {
        lt: now
      },
      status: {
        notIn: ['DONE', 'CANCELLED']
      }
    },
    include: {
      assignee: true,
      project: true
    }
  });
}
```

**Зарегистрировать в CrmModule:**

```typescript
// В plgames/packages/backend/server/src/core/crm/crm.module.ts

import { CrmNotificationJob } from './crm-notifications.job';

@Module({
  imports: [PermissionModule],
  providers: [
    CrmService,
    CrmProjectModel,
    CrmIssueModel,
    CrmProjectResolver,
    CrmIssueResolver,
    CrmSprintResolver,
    CrmCommentResolver,
    CrmTimeLogResolver,
    CrmNotificationJob,  // ← Добавить
  ],
  exports: [CrmService],
})
export class CrmModule {}
```

### Решение 3: Email напоминания (требует настройки SMTP)

**Настройте SMTP в .env:**
```bash
# SMTP для отправки email
MAILER_HOST=smtp.yandex.ru
MAILER_PORT=465
MAILER_USER=your-email@yandex.ru
MAILER_PASSWORD=your-app-password
MAILER_SENDER=noreply@your-domain.com
```

**После настройки Cron будет отправлять email:**
- ⏰ За 24 часа до дедлайна
- ⏰ В день дедлайна
- ⏰ При просрочке (каждый день в 9:00)

---

## 📊 СВОДНАЯ ТАБЛИЦА ВОЗМОЖНОСТЕЙ

| Функция | Статус | Как использовать |
|---------|--------|------------------|
| **OpenRouter AI** | ✅ Работает | Настроить в .env, добавить API ключ |
| **CRM Projects** | ✅ Работает | GraphQL API готов |
| **CRM Issues** | ✅ Работает | GraphQL API готов |
| **CRM Sprints** | ✅ Работает | GraphQL API готов |
| **CRM Comments** | ✅ Работает | GraphQL API готов |
| **CRM Time Logs** | ✅ Работает | GraphQL API готов |
| **Due Date (дедлайн)** | ✅ Работает | Поле dueDate в задачах |
| **Notifications** | ✅ Работает | Только для документов/комментариев |
| **Cron Jobs** | ✅ Работает | @nestjs/schedule готов |
| **Email отправка** | ✅ Работает | Нужна настройка SMTP |
| **Автоматические напоминания по CRM** | ❌ НЕТ | Нужна доработка (см. Решение 2) |
| **Push уведомления** | ❌ НЕТ | Требует frontend интеграции |
| **Webhook напоминания** | ❌ НЕТ | Можно добавить |

---

## 🎯 РЕКОМЕНДАЦИИ

### Для вашего сценария ("загрузил ТЗ, хочу знать когда реализуют"):

#### Вариант A: Минимальный (без доработок) ✅

1. **Создайте задачу с дедлайном:**
```graphql
mutation {
  createCrmIssue(input: {
    title: "Реализовать ТЗ-2024-12-001"
    description: "ТЗ загружено: [ссылка на документ]"
    projectId: "your-project-id"
    reporterId: "your-user-id"
    assigneeId: "developer-id"
    type: TASK
    priority: HIGH
    dueDate: "2024-12-15T17:00:00Z"
    storyPoints: 13
  }) {
    id
  }
}
```

2. **Отслеживайте через GraphQL:**
```graphql
query {
  crmIssue(id: "issue-id") {
    id
    title
    status
    dueDate
    assignee {
      name
    }
    timeLogs {
      timeSpent
    }
  }
}
```

3. **Вручную проверяйте статус** или настройте дашборд

#### Вариант B: С автоматическими напоминаниями (требует доработки) 🔧

1. **Реализуйте Cron Job** (код выше в Решении 2)
2. **Настройте SMTP** для email уведомлений
3. **Получайте автоматические напоминания:**
   - За 24 часа до дедлайна
   - В день дедлайна
   - При просрочке

**Время на доработку:** 2-4 часа разработки

#### Вариант C: Полноценная система напоминаний (максимум) 🚀

**Что можно добавить:**
1. ✅ Настраиваемые интервалы напоминаний (за 3 дня, за 1 день, за 1 час)
2. ✅ Повторяющиеся напоминания
3. ✅ Webhook уведомления в Telegram/Slack
4. ✅ Push уведомления на frontend
5. ✅ SMS уведомления (через API)
6. ✅ Эскалация (уведомить менеджера если задача просрочена >2 дней)

**Время на доработку:** 1-2 недели разработки

---

## 📝 ВЫВОДЫ

### ✅ Что работает СЕЙЧАС:

1. **OpenRouter AI** - полностью готов, нужен только API ключ
2. **CRM система** - полностью работает (проекты, задачи, спринты, комментарии, время)
3. **Due Date** - можно устанавливать дедлайны для задач
4. **Notifications** - система уведомлений работает (для документов)
5. **Cron Jobs** - система фоновых задач готова

### ⚠️ Что нужно доработать:

1. **Автоматические напоминания по CRM задачам** - нужна реализация (2-4 часа)
2. **Email уведомления о дедлайнах** - нужна настройка SMTP + Cron Job
3. **Frontend для уведомлений** - нужна интеграция на UI

### 🎯 Ответ на ваш вопрос:

**"Можно ли устанавливать таймеры для напоминания?"**

✅ **ДА, можно!**

- **Прямо сейчас:** Используйте `dueDate` в задачах, отслеживайте вручную
- **С небольшой доработкой (2-4 часа):** Автоматические email напоминания по Cron
- **С полной доработкой (1-2 недели):** Полноценная система напоминаний с настройками

---

## 🚀 БЫСТРЫЙ СТАРТ С AI И CRM

### Шаг 1: Подключите OpenRouter

```bash
# Отредактируйте .env
nano .env

# Добавьте:
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=sk-or-v1-ваш_ключ
AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct

# Перезапустите
docker compose -f docker-compose.prod.yml restart backend
```

### Шаг 2: Создайте первый проект

```graphql
mutation {
  createCrmProject(input: {
    name: "Мой первый проект"
    key: "PROJ1"
    workspaceId: "your-workspace-id"
  }) {
    id
    name
  }
}
```

### Шаг 3: Создайте задачу с дедлайном

```graphql
mutation {
  createCrmIssue(input: {
    title: "Тестовая задача"
    projectId: "project-id"
    reporterId: "your-user-id"
    dueDate: "2024-12-10T17:00:00Z"
  }) {
    id
    title
    dueDate
  }
}
```

### Шаг 4: Отслеживайте прогресс

```graphql
query {
  crmIssuesByProject(projectId: "project-id") {
    id
    title
    status
    dueDate
  }
}
```

---

**Нужна помощь с доработкой автоматических напоминаний?** Могу помочь реализовать! 🤖
