#!/bin/bash
# PLGames Board - One-Click Installation Script
set -e
echo "🚀 PLGames Board Installation"
git clone https://github.com/Leonid1095/boards_plane.git ~/plgames-board
cd ~/plgames-board
sudo docker compose up -d --build
echo "✅ Done! Access at http://localhost:8080"
