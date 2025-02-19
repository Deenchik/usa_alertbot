# usa_alertbot

**Alert bot for Foreman**  
This bot monitors the status of miners from Foreman and sends alerts to a Telegram channel when there are significant changes (e.g., when miners turn off or on).

---

## LINUX INSTALLATION

To install and set up `usa_alertbot` on your Linux system, follow these steps:

### 1. Clone the repository

```bash
git clone https://github.com/Denchete/usa_alertbot.git
cd usa_alertbot
```

### 2. Give executable permissions to the installation script

```bash
chmod +x install.sh
```

### 3. Run the installation script

```bash
./install.sh
```

The script will:
- Install required dependencies.
- Set up your environment.
- Ask for your Foreman and Telegram credentials.
- Automatically set up the bot to run on startup via `pm2`.

---

## Configuration

When you run the installation script, it will prompt you for the following credentials:
- **Foreman Email:** Your Foreman login email.
- **Foreman Password:** Your Foreman password.
- **Telegram Token:** Your Telegram bot token.
- **Chat ID:** The Telegram chat ID where alerts will be sent.

These credentials will be securely stored in an encrypted `.env` file.

---

## Running the bot

After installation, the bot will run in the background as a service. It will check the status of miners every minute and send notifications to Telegram when needed.

If you ever need to stop or restart the bot, you can use `pm2`:

```bash
# To restart the bot
pm2 restart usa_alertbot

# To stop the bot
pm2 stop usa_alertbot
```

---

## Logs

You can check the bot logs using:

```bash
pm2 logs usa_alertbot
```

---

## Dependencies

- Python 3.x
- `cryptography` library
- `requests` library
- `pandas` library
- `python-dotenv`
- `python-telegram-bot`
- `pm2` for process management

These dependencies will be installed automatically by the `install.sh` script.
