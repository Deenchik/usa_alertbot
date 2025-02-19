#!/bin/bash

# Установка зависимостей
echo "Установка зависимостей..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv npm
sudo npm install -g pm2
pip3 install cryptography requests pandas python-telegram-bot python-dotenv

# Установка ключа шифрования, если он еще не существует
if [ ! -f "secret.key" ]; then
    echo "🔐 Генерация ключа шифрования..."
    python3 -c "
from cryptography.fernet import Fernet
key = Fernet.generate_key()
with open('secret.key', 'wb') as key_file:
    key_file.write(key)
    "
fi

# Запрашиваем данные у пользователя
echo "Введите Foreman Email:"
read FOREMAN_EMAIL

echo "Введите Foreman Password:"
read FOREMAN_PASSWORD

echo "Введите Telegram Token:"
read TELEGRAM_TOKEN

echo "Введите Telegram Chat ID:"
read CHAT_ID

# Шифруем данные и записываем их в .env
python3 -c "
from cryptography.fernet import Fernet
import base64
import os

# Загружаем ключ
with open('secret.key', 'rb') as key_file:
    key = key_file.read()

cipher = Fernet(key)

# Функция шифрования
def encrypt_value(value):
    encrypted_value = cipher.encrypt(value.encode())
    return base64.urlsafe_b64encode(encrypted_value).decode()

# Запись зашифрованных данных в .env
with open('.env', 'a') as env_file:
    env_file.write(f'FOREMAN_EMAIL={encrypt_value(\"$FOREMAN_EMAIL\")}\n')
    env_file.write(f'FOREMAN_PASSWORD={encrypt_value(\"$FOREMAN_PASSWORD\")}\n')
    env_file.write(f'TELEGRAM_TOKEN={encrypt_value(\"$TELEGRAM_TOKEN\")}\n')
    env_file.write(f'CHAT_ID={encrypt_value(\"$CHAT_ID\")}\n')

print('📝 Данные сохранены в .env в зашифрованном виде.')
"

# Запуск PM2 и добавление скрипта в автозагрузку
echo "Настройка автозагрузки через PM2..."

# Создаем виртуальное окружение и активируем его
python3 -m venv venv
source venv/bin/activate

# Запускаем программу usa_alertbot.py с помощью PM2
pm2 start ecosystem.config.js

# Устанавливаем автозагрузку для PM2
pm2 startup
pm2 save

echo "✅ Скрипт добавлен в автозагрузку через PM2."
echo "💻 Ваш бот теперь будет запускаться при старте системы."
