#!/bin/bash
# Build script for PLGames Board
# Run this BEFORE docker-compose up
# Requires: 8GB RAM minimum (will use swap if needed)

set -e

echo "🏗️  Сборка PLGames Board..."
echo ""

# Check available memory
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
echo "💾 Доступно RAM: ${TOTAL_MEM}GB"

if [ "$TOTAL_MEM" -lt 8 ]; then
    echo "⚠️  Внимание: Рекомендуется минимум 8GB RAM"
    echo "   Проверьте swap: $(free -h | grep Swap)"
fi

cd plgames

echo ""
echo "📦 Установка зависимостей (может занять 10-15 минут)..."
# Ограничиваем потребление памяти Node.js
export NODE_OPTIONS="--max-old-space-size=6144"

# Устанавливаем без сборки нативных модулей (Yarn 4 синтаксис)
yarn install --mode=skip-build

echo ""
echo "🔧 Генерация Prisma клиента..."
# Теперь генерируем Prisma клиент отдельно
yarn workspace @affine/server exec prisma generate || true

echo ""
echo "🔨 Сборка backend (@affine/reader + server)..."
echo "   Сборка @affine/reader..."
yarn workspace @affine/reader build

echo "   Сборка server..."
yarn workspace @affine/server build

echo ""
echo "🎨 Сборка frontend (@affine/web, 5-10 минут)..."
yarn plgames build -p @affine/web

echo ""
echo "✅ Сборка завершена!"
echo ""
echo "📊 Размер собранных файлов:"
du -sh packages/backend/server/dist 2>/dev/null || echo "  backend/dist: не найден"
du -sh packages/frontend/apps/web/dist 2>/dev/null || echo "  frontend/dist: не найден"
echo ""
echo "Теперь запустите:"
echo "  cd .. && sudo docker-compose -f docker-compose.simple.yml up -d --build"
