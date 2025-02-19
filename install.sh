#!/bin/bash

# Убедимся, что мы запускаем скрипт от имени root
if [ "$(id -u)" -ne 0 ]; then
  echo "Пожалуйста, запустите этот скрипт с правами суперпользователя (root)."
  exit 1
fi

# Обновление и установка необходимых пакетов
echo "Обновляем систему и устанавливаем необходимые пакеты..."
apt update && apt upgrade -y
apt install -y \
    python3 python3-pip python3-venv \
    git curl

# Клонируем репозиторий с GitHub
echo "Клонируем репозиторий с GitHub..."
cd /opt
git clone https://github.com/Denchete/usa_alertbot.git usa_alertbot
cd usa_alertbot

# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Устанавливаем зависимости
pip install requests pandas python-telegram-bot cryptography python-dotenv

# Добавляем скрипт в автозагрузку (systemd)
echo "Настроим автозагрузку..."
cat > /etc/systemd/system/usa_alertbot.service <<EOL
[Unit]
Description=USA Alertbot
After=network.target

[Service]
ExecStart=/opt/usa_alertbot/venv/bin/python /opt/usa_alertbot/usa_alertbot.py
WorkingDirectory=/opt/usa_alertbot
Environment=PATH=/opt/usa_alertbot/venv/bin:/usr/bin:/bin
Environment=VIRTUAL_ENV=/opt/usa_alertbot/venv
User=root
Group=root
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Перезагружаем systemd и активируем сервис
echo "Перезагружаем systemd и активируем сервис..."
systemctl daemon-reload
systemctl enable usa_alertbot.service
systemctl start usa_alertbot.service

# Проверяем статус сервиса
echo "Проверим статус сервиса..."
systemctl status usa_alertbot.service

echo "Установка завершена! Бот будет автоматически запускаться при старте системы."
