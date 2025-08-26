# 🔧 Установка

WireGuard Monitor предлагает несколько способов установки на ваш выбор:

## 🎯 Способ 1: Интерактивная установка (Рекомендуется)

**Идеально для новичков** - установщик сам спросит все необходимые данные:

```bash
# Скачать и запустить интерактивный установщик
curl -fsSL https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/install-interactive.sh -o install-interactive.sh
sudo bash install-interactive.sh
```

**Что делает интерактивный установщик:**
- 🤖 Помогает создать Telegram бота с пошаговыми инструкциями
- 🔍 Автоматически найдет ваши WireGuard контейнеры
- ⚙️ Предложит оптимальные настройки мониторинга  
- 🧪 Протестирует всю конфигурацию перед установкой
- 📱 Отправит тестовое сообщение в Telegram
- 🚀 Настроит автозапуск и systemd интеграцию

## ⚡ Способ 2: Быстрая установка одной командой

**Для опытных пользователей** - если у вас уже есть все данные:

```bash
# Установка одной командой
curl -fsSL https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/quick-install.sh | \
sudo bash -s -- \
  --bot-token "123456789:ABCdefGhIjKlmnoPQRsTUVwxyz" \
  --chat-id "123456789" \
  --containers "wireguard"
```

**Дополнительные параметры:**
```bash
# Полная настройка с дополнительными параметрами
sudo bash quick-install.sh \
  --bot-token "123456789:ABCdefGhIjKlmnoPQRsTUVwxyz" \
  --chat-id "-987654321" \
  --containers "wg-server-1 wg-server-2" \
  --interface "wg0" \
  --threshold 180 \
  --log-level DEBUG \
  --cooldown 1800 \
  --max-retries 5
```

**Тестирование без установки:**
```bash
# Только проверить параметры, не устанавливать
sudo bash quick-install.sh \
  --bot-token "your-token" \
  --chat-id "your-chat-id" \
  --containers "wireguard" \
  --test
```

## 📁 Способ 3: Ручная установка

**Для максимального контроля** - установка файлов по отдельности:

### 3.1. Клонирование репозитория

```bash
# Клонируем репозиторий
git clone https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor.git /opt/wg-monitor
cd /opt/wg-monitor
```

### 3.2. Установка файлов

```bash
# Основной скрипт
sudo cp wg_telemon /usr/local/bin/wg_telemon.sh
sudo chmod +x /usr/local/bin/wg_telemon.sh

# Systemd файлы
sudo cp wg-telemon.service /etc/systemd/system/
sudo cp wg-telemon.timer /etc/systemd/system/
sudo systemctl daemon-reload

# Конфигурационный файл
