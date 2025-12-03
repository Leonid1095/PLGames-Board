if ([string]::IsNullOrWhiteSpace($DOMAIN)) { $DOMAIN = "localhost" }

$DB_USER = Read-Host "Введите имя пользователя БД [plgames]"
if ([string]::IsNullOrWhiteSpace($DB_USER)) { $DB_USER = "plgames" }

$DB_PASSWORD = Read-Host "Введите пароль БД [plgames]"
if ([string]::IsNullOrWhiteSpace($DB_PASSWORD)) { $DB_PASSWORD = "plgames" }

$DB_NAME = Read-Host "Введите имя базы данных [plgames]"
if ([string]::IsNullOrWhiteSpace($DB_NAME)) { $DB_NAME = "plgames" }

if ($DOMAIN -eq "localhost") {
    $BASE_URL = "http://localhost:8080"
}
else {
    $BASE_URL = "https://$DOMAIN"
}

$EnvContent = @"
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
"@

Set-Content -Path .env -Value $EnvContent
Write-Host "Файл .env успешно создан." -ForegroundColor Green

# Запуск Docker Compose
Write-Host "Запуск сервисов (это может занять несколько минут)..." -ForegroundColor Yellow
docker compose -f docker-compose.prod.yml up -d --build

Write-Host "=========================================" -ForegroundColor Green
Write-Host "   Установка успешно завершена! 🚀" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
# Получаем IP адрес (для Windows нужна другая команда)
$SERVER_IP = (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing).Content.Trim()
Write-Host "Фронтенд доступен по адресу: http://${SERVER_IP}:8080"
Write-Host "Бэкенд API доступен по адресу: http://${SERVER_IP}:3010"
Write-Host "⚠️  Для доступа через домен ($DOMAIN) настройте Nginx/Caddy (см. INSTALL.md)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Полезные команды:" -ForegroundColor Yellow
Write-Host "  Просмотр логов: docker compose -f docker-compose.prod.yml logs -f"
Write-Host "  Остановка:      docker compose -f docker-compose.prod.yml down"
