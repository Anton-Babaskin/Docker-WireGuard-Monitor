# 🛡️ WireGuard Docker Monitor

<div align="center">

[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/bash-4.4%2B-orange.svg)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/docker-20.04%2B-blue.svg)](https://www.docker.com/)
[![Telegram](https://img.shields.io/badge/telegram-bot%20api-26A5E4.svg)](https://core.telegram.org/bots/api)

**Профессиональный мониторинг WireGuard серверов в Docker с умными уведомлениями в Telegram**

*Никогда больше не теряйте соединение с вашими VPN серверами*

[🚀 Быстрая установка](#-установка) • [📖 Документация](#-документация) • [💡 Примеры](#-примеры-использования) • [🤝 Поддержка](#-поддержка)

</div>

---

## 🎯 Зачем это нужно?

**Проблема:** WireGuard серверы могут "молча" ломаться - контейнеры работают, но клиенты не могут подключиться. Вы узнаете об этом только когда сами попытаетесь подключиться.

**Решение:** WireGuard Monitor автоматически проверяет ваши серверы каждые 2 минуты и мгновенно уведомляет в Telegram о любых проблемах.

### 🔍 Что мониторится:

- ✅ **Статус Docker контейнеров** - работают ли контейнеры с WireGuard
- ✅ **Состояние интерфейсов** - активны ли WireGuard интерфейсы  
- ✅ **Подключения клиентов** - свежие ли handshakes с пирами
- ✅ **Здоровье контейнеров** - Docker health checks
- ✅ **Сетевая связность** - доступность Telegram API

### 📱 Как приходят уведомления:

```
🚨 WireGuard Monitor Alert

🖥️ Host: production-server
🕐 Time: 2024-08-26 15:30:25
📊 Level: ERROR

🐳 Container `wireguard` is not running!
📊 Status: exited (Exit code: 1)
```

---

## ✨ Ключевые особенности

### 🚀 **Простота использования**
- **Установка одной командой** за 30 секунд
- **Интерактивный установщик** для новичков  
- **Автоматическое обнаружение** контейнеров
- **Готовые шаблоны** конфигураций

### 🎯 **Enterprise функции**
- **Мониторинг нескольких контейнеров** одновременно
- **Умная система алертов** с cooldown периодами
- **Детальное логирование** и диагностика
- **Health check endpoints** для внешних систем

### 🔧 **Гибкость настроек**
- **Настраиваемые пороги** для handshake мониторинга
- **Различные уровни логирования** (DEBUG, INFO, WARN, ERROR)
- **Кастомизируемые интервалы** проверок
- **Поддержка групповых чатов** в Telegram

### 🛡️ **Надежность**
- **Systemd интеграция** с автозапуском
- **Retry механизмы** для отправки сообщений
- **Graceful error handling** и восстановление
- **Lock файлы** для предотвращения конфликтов

---

## 🚀 Установка

WireGuard Monitor предлагает несколько способов установки на ваш выбор:

### 🎯 Способ 1: Интерактивная установка (Рекомендуется)

**Идеально для новичков** - установщик сам спросит все необходимые данные:

```bash
curl -fsSL https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/install-interactive.sh | sudo bash
```

**Что делает:**
- 🤖 Помогает создать Telegram бота с инструкциями
- 🔍 Автоматически найдет WireGuard контейнеры
- ⚙️ Предложит оптимальные настройки
- 🧪 Протестирует конфигурацию
- 📱 Отправит тестовое сообщение

### ⚡ Способ 2: Быстрая установка одной командой

**Для опытных пользователей** - если у вас уже есть данные:

```bash
curl -fsSL https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/quick-install.sh | \
sudo bash -s -- \
  --bot-token "123456789:ABCdefGhIjKlmnoPQRsTUVwxyz" \
  --chat-id "123456789" \
  --containers "wireguard"
```

### 📁 Способ 3: Ручная установка

**Для максимального контроля:**

```bash
git clone https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor.git
cd Docker-WireGuard-Monitor
sudo ./install-interactive.sh
```

---

## 📋 Подготовка к установке

### 🤖 Создание Telegram бота:

1. Найдите **@BotFather** в Telegram
2. Отправьте `/newbot`
3. Следуйте инструкциям
4. Скопируйте токен: `123456789:ABCdefGhIjKlmnoPQRsTUVwxyz`

### 📞 Получение Chat ID:

1. Найдите **@userinfobot** в Telegram  
2. Отправьте `/start`
3. Скопируйте ID: `123456789`

### 🐳 Проверка контейнеров:

```bash
docker ps | grep -i wire
```

---

## 🎛️ Управление

### Основные команды:

```bash
# Статус мониторинга
sudo systemctl status wg-telemon.timer

# Просмотр логов в реальном времени
sudo tail -f /var/log/wg-monitor.log

# Тестирование конфигурации
sudo /usr/local/bin/wg_telemon.sh --test

# Перезапуск сервиса
sudo systemctl restart wg-telemon.timer
```

### Конфигурация:

```bash
# Редактирование настроек
sudo nano /etc/telemon.env

# После изменений перезапустить:
sudo systemctl restart wg-telemon.timer
```

---

## 💡 Примеры использования

### 🏠 Домашний VPN:
```bash
# Простая установка для домашнего сервера
curl -fsSL https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/quick-install.sh | \
sudo bash -s -- \
  --bot-token "YOUR_TOKEN" \
  --chat-id "YOUR_ID" \
  --containers "wireguard" \
  --threshold 600
```

### 🏢 Офисный VPN:
```bash  
# Мониторинг с групповыми уведомлениями
sudo bash quick-install.sh \
  --bot-token "YOUR_TOKEN" \
  --chat-id "-GROUP_CHAT_ID" \
  --containers "wg-office wg-remote" \
  --threshold 300 \
  --log-level INFO
```

### 🏭 Production среда:
```bash
# Строгий мониторинг для критических серверов
sudo bash quick-install.sh \
  --bot-token "YOUR_TOKEN" \
  --chat-id "YOUR_ID" \
  --containers "wg-prod-1 wg-prod-2 wg-backup" \
  --threshold 180 \
  --cooldown 900 \
  --log-level WARN
```

---

## 📊 Системные требования

### Минимальные:
- 🐧 **ОС**: Linux с systemd
- 🐳 **Docker**: 20.04+
- 🔧 **Bash**: 4.4+
- 📡 **Сеть**: доступ к api.telegram.org
- 💾 **RAM**: 512MB+ свободных
- 💿 **Диск**: 100MB+ свободного места

### Рекомендуемые:
- 💾 **RAM**: 1GB+
- 💿 **Диск**: 1GB+ (для логов)
- 🔄 **CPU**: 1+ ядра

---

## 📚 Документация

- 📖 **[GUIDE.md](GUIDE.md)** - Подробный гайд установки
- 💡 **[EXAMPLES.md](EXAMPLES.md)** - Примеры конфигураций
- 🛠️ **[CONTRIBUTING.md](CONTRIBUTING.md)** - Как помочь проекту
- 🔒 **[SECURITY.md](SECURITY.md)** - Политика безопасности  
- 🗺️ **[ROADMAP.md](ROADMAP.md)** - План развития
- 📝 **[CHANGELOG.md](CHANGELOG.md)** - История изменений

---

## 🆘 Troubleshooting

### Частые проблемы:

**Тест не проходит:**
```bash
# Проверка конфигурации
sudo cat /etc/telemon.env
sudo /usr/local/bin/wg_telemon.sh --test --log-level DEBUG
```

**Сервис не запускается:**
```bash
# Просмотр ошибок
sudo journalctl -u wg-telemon.service -n 50
sudo systemctl status wg-telemon.service
```

**Не приходят уведомления:**
```bash
# Проверка контейнеров
docker ps | grep -i wire
sudo docker exec YOUR_CONTAINER wg show
```

---

## 🤝 Поддержка

### Где получить помощь:
- 🐛 **[GitHub Issues](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/issues)** - баги и проблемы
- 💬 **[GitHub Discussions](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/discussions)** - вопросы и обсуждения
- 📖 **[Wiki](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/wiki)** - подробная документация

### При обращении за помощью приложите:
- Версию ОС: `uname -a`
- Версию Docker: `docker --version`
- Логи ошибки: `sudo journalctl -u wg-telemon.service -n 20`

---

## 🤝 Contributing

Мы приветствуем вклад в развитие проекта! См. [CONTRIBUTING.md](CONTRIBUTING.md) для деталей.

### Как помочь:
- 🐛 Сообщать о багах
- ✨ Предлагать новые функции
- 📖 Улучшать документацию
- 🧪 Тестировать на разных системах
- 🌍 Переводить на другие языки

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для деталей.

---

## 🙏 Благодарности

- **WireGuard** - за отличный VPN протокол
- **Docker** - за контейнеризацию
- **Telegram** - за Bot API  
- **systemd** - за управление сервисами
- **Сообщество** - за отзывы и предложения

---

<div align="center">

**[⭐ Поставьте звезду](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor) если проект оказался полезным!**

Сделано с ❤️ для сообщества WireGuard

[![GitHub stars](https://img.shields.io/github/stars/Anton-Babaskin/Docker-WireGuard-Monitor?style=social)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor)
[![GitHub forks](https://img.shields.io/github/forks/Anton-Babaskin/Docker-WireGuard-Monitor?style=social)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor)

</div>
