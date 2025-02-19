#!/bin/bash

# Проверка запуска от root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Скрипт должен выполняться от root!"
   exit 1
fi

echo "🚀 Установка зависимостей..."
apt update && apt install -y python3 python3-pip python3-venv

echo "🔧 Настраиваю виртуальное окружение..."
python3 -m venv venv
source venv/bin/activate
pip3 install cryptography python-dotenv requests asyncio pandas python-telegram-bot cryptography python-dotenv

echo "🔑 Генерация секретного ключа..."
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" > secret.key

echo "🔐 Введите учетные данные для шифрования..."
read -p "Введите Foreman Email: " foreman_email
read -p "Введите Foreman Password: " foreman_password
read -p "Введите Telegram Token: " telegram_token
read -p "Введите Telegram Chat ID: " chat_id

echo "🛠️ Шифрование и сохранение в .env..."
python3 - <<EOF
from cryptography.fernet import Fernet
import os

# Читаем ключ
with open("secret.key", "rb") as key_file:
    key = key_file.read()
cipher = Fernet(key)

# Функция для шифрования
def encrypt(value):
    return cipher.encrypt(value.encode()).decode()

env_data = f"FOREMAN_EMAIL={encrypt('$foreman_email')}\n" \
           f"FOREMAN_PASSWORD={encrypt('$foreman_password')}\n" \
           f"TELEGRAM_TOKEN={encrypt('$telegram_token')}\n" \
           f"CHAT_ID={encrypt('$chat_id')}\n"

with open(".env", "w") as env_file:
    env_file.write(env_data)

print("✅ Данные успешно зашифрованы и сохранены в .env")
EOF

echo "⚙️ Настраиваю сервис systemd..."
cat <<EOT > /etc/systemd/system/usa_alertbot.service
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
EOT

echo "🔄 Перезапуск systemd и включение автозапуска..."
systemctl daemon-reload
systemctl enable usa_alertbot.service
systemctl start usa_alertbot.service

echo "🚀 Запуск usa_alertbot.py..."
./venv/bin/python3 usa_alertbot.py

echo "✅ Установка завершена!"
