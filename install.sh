#!/bin/bash

# Проверка на наличие Python3 и pip
echo "🔍 Проверка наличия Python3 и pip..."
if ! command -v python3 &>/dev/null; then
    echo "❌ Python3 не установлен. Установите Python3 и повторите попытку."
    exit 1
fi

if ! command -v pip3 &>/dev/null; then
    echo "❌ pip3 не установлен. Установите pip3 и повторите попытку."
    exit 1
fi

# Установка зависимостей
echo "📦 Установка зависимостей..."
pip3 install cryptography requests pandas python-telegram-bot python-dotenv

# Генерация ключа шифрования, если он не существует
if [ ! -f secret.key ]; then
    echo "🔑 Генерация ключа шифрования..."
    python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" > secret.key
    echo "✅ Ключ шифрования успешно сгенерирован."
else
    echo "✅ Ключ шифрования уже существует."
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

# Проверка наличия файла .env
if [ ! -f .env ]; then
    echo "❌ Ошибка: .env не был создан."
    exit 1
else
    echo "✅ Данные успешно сохранены в .env."
fi

# Настройка автозагрузки (создание сервиса для systemd)
echo "🛠 Настройка автозагрузки..."
SERVICE_PATH="/etc/systemd/system/usa_alertbot.service"

# Проверка существования сервиса
if [ ! -f "$SERVICE_PATH" ]; then
    echo "[Unit]
Description=USA Alert Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /path/to/your/usa_alertbot.py
WorkingDirectory=/path/to/your/directory
Restart=always
User=$(whoami)
Group=$(whoami)
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target" | sudo tee "$SERVICE_PATH" > /dev/null

    # Перезагрузка systemd и запуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl enable usa_alertbot.service
    sudo systemctl start usa_alertbot.service

    echo "✅ Сервис для автозагрузки настроен. Бот будет запускаться автоматически."
else
    echo "✅ Сервис уже настроен."
fi

echo "✅ Установка завершена!"
