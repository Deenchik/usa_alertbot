module.exports = {
  apps: [{
    name: "usa_alertbot",   // Имя процесса
    script: "./usa_alertbot.py", // Путь к вашему скрипту
    interpreter: "python3",  // Убедитесь, что используете правильный интерпретатор Python
    instances: 1,            // Запуск только одного экземпляра
    autorestart: true,       // Автоперезапуск
    watch: false,            // Отключаем слежение за изменениями файлов
    max_memory_restart: "200M" // Устанавливаем лимит по памяти
  }]
}