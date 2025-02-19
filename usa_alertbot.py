import asyncio
import requests
import pandas as pd
from io import StringIO
from telegram import Bot
import logging
import os
import base64
from cryptography.fernet import Fernet
from dotenv import load_dotenv
from pathlib import Path

# Настройка логирования
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Пути к файлам
ENV_PATH = Path(".env")
KEY_PATH = Path("secret.key")

# Функции для шифрования/дешифровки

def generate_key():
    key = Fernet.generate_key()
    with open(KEY_PATH, "wb") as key_file:
        key_file.write(key)

def load_key():
    return open(KEY_PATH, "rb").read()

def encrypt_value(value, key):
    f = Fernet(key)
    encrypted_value = f.encrypt(value.encode())
    return base64.urlsafe_b64encode(encrypted_value).decode()

def decrypt_value(encrypted_value, key):
    f = Fernet(key)
    decrypted_value = f.decrypt(base64.urlsafe_b64decode(encrypted_value.encode()))
    return decrypted_value.decode()

# Создание ключа шифрования, если его нет
if not KEY_PATH.exists():
    generate_key()
KEY = load_key()

# Загрузка .env
load_dotenv()

# Запись в .env без кавычек
def save_encrypted_env_var(key_name, value):
    encrypted_value = encrypt_value(value, KEY)
    # Убираем кавычки вручную
    encrypted_value = encrypted_value.strip("'")  # Убираем кавычки
    # Сохраняем значение без кавычек
    with open(ENV_PATH, "a") as env_file:
        env_file.write(f"{key_name}={encrypted_value}\n")
    env_file.close()  # Явно закрываем файл после записи

def load_decrypted_env_var(key_name):
    encrypted_value = os.getenv(key_name)
    if encrypted_value:
        return decrypt_value(encrypted_value, KEY)
    return None

# Запрос данных у пользователя при первом запуске
if not ENV_PATH.exists():
    logger.info("🔐 Запрашиваю учетные данные для Foreman и Telegram...")
    save_encrypted_env_var("FOREMAN_EMAIL", input("Введите Foreman Email: "))
    save_encrypted_env_var("FOREMAN_PASSWORD", input("Введите Foreman Password: "))
    save_encrypted_env_var("TELEGRAM_TOKEN", input("Введите Telegram Token: "))
    save_encrypted_env_var("CHAT_ID", input("Введите Telegram Chat ID: "))
    logger.info("📝 Данные сохранены в .env")

# Принудительное чтение .env после записи
load_dotenv()

# Загрузка расшифрованных данных
FOREMAN_EMAIL = load_decrypted_env_var("FOREMAN_EMAIL")
FOREMAN_PASSWORD = load_decrypted_env_var("FOREMAN_PASSWORD")
TELEGRAM_TOKEN = load_decrypted_env_var("TELEGRAM_TOKEN")
CHAT_ID = load_decrypted_env_var("CHAT_ID")

# Проверка, что данные загружены
if not all([FOREMAN_EMAIL, FOREMAN_PASSWORD, TELEGRAM_TOKEN, CHAT_ID]):
    logger.error("❌ Ошибка загрузки учетных данных. Перезапустите бота и введите данные заново.")
    exit(1)

FOREMAN_LOGIN_URL = "https://dashboard.foreman.mn/login/"
FOREMAN_CSV_URL = "https://dashboard.foreman.mn/dashboard/miners-csv/?search="

previous_active_miners = None

def get_foreman_session():
    session = requests.Session()
    response = session.get(FOREMAN_LOGIN_URL)
    csrftoken = session.cookies.get("csrftoken")
    if not csrftoken:
        logger.error("Не удалось получить CSRF-токен.")
        return None
    
    login_data = {
        "username": FOREMAN_EMAIL,
        "password": FOREMAN_PASSWORD,
        "csrfmiddlewaretoken": csrftoken,
    }
    headers = {"Referer": FOREMAN_LOGIN_URL, "Content-Type": "application/x-www-form-urlencoded"}
    response = session.post(FOREMAN_LOGIN_URL, data=login_data, headers=headers)
    
    if "sessionid" in session.cookies:
        logger.info("✅ Успешный вход в Foreman")
        return session
    else:
        logger.error("❌ Ошибка авторизации.")
        return None

def fetch_csv_and_filter():
    session = get_foreman_session()
    if not session:
        return None, None

    response = session.get(FOREMAN_CSV_URL)
    if response.status_code != 200:
        logger.error("Ошибка загрузки CSV: %s", response.text)
        return None, None

    df = pd.read_csv(StringIO(response.text))
    total_miners = len(df)
    zero_hashrate_miners = df[df["hash_rate"] == 0]
    zero_hashrate_count = len(zero_hashrate_miners)
    active_miners_count = total_miners - zero_hashrate_count
    
    logger.info(f"📝 Всего майнеров: {total_miners} | С хэшрейтом 0: {zero_hashrate_count} | Рабочих: {active_miners_count}")
    return active_miners_count, zero_hashrate_count

async def send_telegram_message(text):
    bot = Bot(token=TELEGRAM_TOKEN)
    await bot.send_message(chat_id=CHAT_ID, text=text)
    logger.info(f"📩 Отправлено сообщение: {text}")

async def fetch_and_send_csv():
    global previous_active_miners
    first_run = True

    while True:
        try:
            active_miners_count, zero_hashrate_count = fetch_csv_and_filter()
            if active_miners_count is None:
                continue

            if first_run:
                await send_telegram_message(f"🚀 Бот запущен. Отключенных майнеров: {zero_hashrate_count}")
                previous_active_miners = active_miners_count
                first_run = False
                continue

            if previous_active_miners != active_miners_count:
                change_percent = abs(active_miners_count - previous_active_miners) / max(previous_active_miners, 1) * 100
                logger.info(f"📊 Изменение на {change_percent:.2f}% от предыдущего значения ({previous_active_miners})")
                if change_percent >= 80:
                    status = "✅ #Включение_USA" if active_miners_count > previous_active_miners else "⚠️ #Отключение_USA"
                    await send_telegram_message(f"{status}\nОтключенных майнеров: {zero_hashrate_count}")
                    logger.info(f"📩 Отправлено уведомление. Отключенных: {zero_hashrate_count}")
            
            previous_active_miners = active_miners_count
        except Exception as e:
            logger.error("Ошибка: %s", e)
        await asyncio.sleep(60)

async def main():
    await fetch_and_send_csv()

if __name__ == "__main__":
    asyncio.run(main())
