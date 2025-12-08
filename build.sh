#!/bin/bash
# Build script for PLGames Board
# Run this BEFORE docker-compose up

set -e

echo "🏗️  Сборка PLGames Board..."
echo ""

cd plgames

echo "📦 Установка зависимостей..."
yarn install

echo ""
echo "🔨 Сборка backend (@affine/reader + server)..."
yarn workspace @affine/reader build
yarn workspace @affine/server build

echo ""
echo "🎨 Сборка frontend (@affine/web)..."
yarn plgames build -p @affine/web

echo ""
echo "✅ Сборка завершена!"
echo ""
echo "Теперь запустите:"
echo "  docker-compose -f docker-compose.simple.yml up -d"
