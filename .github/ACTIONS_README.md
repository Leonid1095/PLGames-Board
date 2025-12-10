# GitHub Actions Workflows

## Docker Build Pipeline

Автоматическая сборка и публикация Docker образов в GitHub Container Registry (ghcr.io).

### Как это работает

1. **Trigger**: Запускается при push в `main` если изменились файлы в `plgames/` или конфиги
2. **Build**: Собирает backend и frontend параллельно на GitHub Runners
3. **Publish**: Публикует образы в `ghcr.io/leonid1095/boards_plane-backend:latest` и `-frontend:latest`
4. **Usage**: Пользователи могут использовать `install-prebuilt.sh` для быстрой установки (2-3 минуты)

### Как включить

GitHub Actions автоматически запускается, но нужно **разрешить публикацию пакетов**:

#### Шаг 1: Настройки репозитория

1. Откройте https://github.com/Leonid1095/boards_plane/settings
2. В левом меню: **Actions** → **General**
3. Прокрутите до **Workflow permissions**
4. Выберите: **Read and write permissions**
5. Включите: **Allow GitHub Actions to create and approve pull requests**
6. Нажмите **Save**

#### Шаг 2: Первый запуск

1. Откройте https://github.com/Leonid1095/boards_plane/actions
2. Выберите **Build and Push Docker Images**
3. Нажмите **Run workflow** → **Run workflow**

#### Шаг 3: Сделать образы публичными

После первой сборки:

1. Откройте https://github.com/Leonid1095?tab=packages
2. Найдите `boards_plane-backend` и `boards_plane-frontend`
3. Для каждого:
   - Кликните на пакет
   - **Package settings** (справа)
   - **Change visibility** → **Public**
   - Подтвердите

### Результат

После этого пользователи смогут установить PLGames Board **за 2-3 минуты**:

```bash
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-prebuilt.sh | bash
```

Вместо 20-30 минут сборки на сервере!

### Мониторинг

- **Actions**: https://github.com/Leonid1095/boards_plane/actions
- **Packages**: https://github.com/Leonid1095?tab=packages
- **Logs**: Кликните на любой workflow run для просмотра логов

### Troubleshooting

**Ошибка: "Resource not accessible by integration"**
- Решение: Включите "Read and write permissions" в настройках

**Ошибка: "Permission denied"**
- Решение: Убедитесь что workflow запущен с правами GITHUB_TOKEN

**Образы не загружаются**
- Решение: Сделайте пакеты публичными в настройках

### Автоматические обновления

При каждом push в `main`:
1. ✅ Собираются новые образы
2. ✅ Публикуются с тегом `latest`
3. ✅ Пользователи обновляются командой: `docker compose pull && docker compose up -d`
