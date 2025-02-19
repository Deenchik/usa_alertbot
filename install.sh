#!/bin/bash

# Выход при ошибке
set -e

# Проверка на запуск от root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Скрипт должен быть запущен от root! Используйте: sudo ./install.sh"
    exit 1
fi

echo "🚀 Установка зависимостей..."

# Обновление пакетов и установка Python, pip, virtualenv
apt update && apt upgrade -y
apt install -y python3 python3-pip python3-venv

# Создание виртуального окружения (если его нет)
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Активация виртуального окружения
source venv/bin/activate

# Установка зависимостей
pip install --upgrade pip
pip install asyncio requests pandas python-telegram-bot cryptography python-dotenv

echo "✅ Установка завершена."

# Создание systemd-сервиса для автозапуска
SERVICE_PATH="/etc/systemd/system/usa_alertbot.service"

echo "🛠️ Настройка автозапуска..."

cat <<EOF > $SERVICE_PATH
[Unit]
Description=USA Alert Bot
After=network.target

[Service]
ExecStart=$(pwd)/venv/bin/python3 $(pwd)/usa_alertbot.py
WorkingDirectory=$(pwd)
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка systemd и запуск сервиса
systemctl daemon-reload
systemctl enable usa_alertbot.service
systemctl start usa_alertbot.service

echo "✅ Бот добавлен в автозапуск и запущен!"