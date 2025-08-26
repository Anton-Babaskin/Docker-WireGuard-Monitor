# 📋 Пошаговый гайд по установке WireGuard Monitor

Этот гайд поможет вам установить и настроить Enhanced WireGuard Monitor с нуля. Следуйте инструкциям точно в указанном порядке.

## 🎯 Что вы получите

После установки у вас будет:
- ✅ **Автоматический мониторинг** WireGuard контейнеров каждые 2 минуты
- ✅ **Умные уведомления** в Telegram при проблемах  
- ✅ **Подробные логи** для диагностики
- ✅ **Автозапуск** после перезагрузки системы
- ✅ **Enterprise-функции** мониторинга

---

## 🔧 Шаг 1: Проверка системных требований

### **Проверьте вашу систему:**

```bash
# Проверяем ОС (должен быть Linux)
uname -a

# Проверяем, что у вас есть права root
sudo whoami

# Проверяем версию bash (нужна 4.4+)
bash --version

# Проверяем Docker
docker --version
docker ps

# Проверяем systemd
systemctl --version
```

### **Установите недостающие компоненты:**

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y curl docker.io git bash
sudo systemctl enable docker
sudo systemctl start docker
```

**CentOS/RHEL/Rocky:**
```bash
sudo yum update
sudo yum install -y curl docker git bash
# или для newer versions:
sudo dnf install -y curl docker git bash

sudo systemctl enable docker
sudo systemctl start docker
```

**Проверьте Docker работает:**
```bash
sudo docker run hello-world
```

---

## 🤖 Шаг 2: Создание Telegram бота

### **2.1. Создание бота:**

1. Откройте Telegram на телефоне или в веб-версии
2. Найдите **@BotFather**
3. Отправьте `/start`
4. Отправьте `/newbot`
5. Придумайте имя бота (например: `My WireGuard Monitor`)
6. Придумайте username бота (например: `my_wg_monitor_bot`)
7. **ВАЖНО:** Скопируйте токен вида: `123456789:ABCdefGhIjKlmnoPQRsTUVwxyz`

### **2.2. Получение Chat ID:**

**Способ 1 (простой):**
1. Найдите бота **@userinfobot** в Telegram
2. Отправьте ему `/start`
3. Скопируйте ваш **ID** (число вида: `123456789`)

**Способ 2 (для групповых чатов):**
1. Добавьте вашего бота в группу
2. Отправьте любое сообщение в группу
3. Откройте в браузере: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
4. Найдите `"chat":{"id":-987654321}` - это ваш Chat ID

### **2.3. Тестирование бота:**

```bash
# Замените YOUR_TOKEN и YOUR_CHAT_ID на реальные значения
curl -s -X POST "https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage" \
     -d "chat_id=<YOUR_CHAT_ID>" \
     -d "text=Тест! Бот работает!"
```

Если всё правильно, вы получите сообщение в Telegram.

---

## 📁 Шаг 3: Загрузка и подготовка файлов

### **3.1. Создание рабочей директории:**

```bash
# Создаем директорию для установки
sudo mkdir -p /opt/wg-monitor
cd /opt/wg-monitor

# Создаем необходимые папки
sudo mkdir -p /var/log
sudo mkdir -p /etc/systemd/system
```

### **3.2. Способы получения файлов:**

**Вариант A: Клонирование репозитория (рекомендуется):**
```bash
sudo git clone https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor.git /opt/wg-monitor
cd /opt/wg-monitor
```

**Вариант B: Ручная загрузка каждого файла:**
```bash
# Основной скрипт
sudo wget -O /usr/local/bin/wg_telemon.sh https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/wg_telemon

# Конфигурационный файл
sudo wget -O /etc/telemon.env https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/telemon.env

# Systemd файлы
sudo wget -O /etc/systemd/system/wg-telemon.service https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/wg-telemon.service
sudo wget -O /etc/systemd/system/wg-telemon.timer https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/wg-telemon.timer

# Установщик
sudo wget -O /opt/wg-monitor/install.sh https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/install.sh
```

---

## ⚙️ Шаг 4: Установка файлов

### **4.1. Установка основного скрипта:**

```bash
# Копируем скрипт в системную папку
sudo cp wg_telemon /usr/local/bin/wg_telemon.sh

# Делаем исполняемым
sudo chmod +x /usr/local/bin/wg_telemon.sh

# Устанавливаем права
sudo chown root:root /usr/local/bin/wg_telemon.sh

# Проверяем
ls -la /usr/local/bin/wg_telemon.sh
```

### **4.2. Установка systemd файлов:**

```bash
# Копируем systemd файлы
sudo cp wg-telemon.service /etc/systemd/system/
sudo cp wg-telemon.timer /etc/systemd/system/

# Устанавливаем права
sudo chown root:root /etc/systemd/system/wg-telemon.*

# Перезагружаем systemd
sudo systemctl daemon-reload

# Проверяем
sudo systemctl list-unit-files | grep wg-telemon
```

---

## 📝 Шаг 5: Настройка конфигурации

### **5.1. Определение имени вашего WireGuard контейнера:**

```bash
# Посмотрите все запущенные контейнеры
sudo docker ps

# Или найдите WireGuard контейнеры
sudo docker ps | grep -i wire
sudo docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

**Пример вывода:**
```
NAMES               IMAGE                           STATUS
wireguard           linuxserver/wireguard:latest    Up 2 days
my-vpn-server       wg-easy:latest                  Up 1 hour
```

Запишите **точное имя** вашего контейнера (например: `wireguard`).

### **5.2. Создание конфигурационного файла:**

```bash
# Создаем конфиг из шаблона
sudo cp telemon.env /etc/telemon.env

# Редактируем конфигурацию
sudo nano /etc/telemon.env
```

### **5.3. Заполнение обязательных параметров:**

В файле `/etc/telemon.env` найдите и замените:

```bash
# === ОБЯЗАТЕЛЬНЫЕ НАСТРОЙКИ ===

# Замените на ваш токен бота
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"

# Замените на ваш Chat ID  
CHAT_ID="123456789"

# Замените на имя вашего контейнера
WG_CONTAINERS="wireguard"

# === ОСНОВНЫЕ НАСТРОЙКИ ===
WG_IFACE="wg0"        # Обычно не нужно менять
THRESHOLD=300         # 5 минут до алерта (можете настроить)
```

**Для нескольких контейнеров:**
```bash
# Если у вас несколько WireGuard контейнеров
WG_CONTAINERS="wireguard wg-server-2 my-vpn"
```

### **5.4. Защита конфигурационного файла:**

```bash
# Устанавливаем безопасные права (важно!)
sudo chmod 600 /etc/telemon.env
sudo chown root:root /etc/telemon.env

# Проверяем права
ls -la /etc/telemon.env
# Должно показать: -rw------- 1 root root
```

---

## 🧪 Шаг 6: Тестирование

### **6.1. Проверка синтаксиса:**

```bash
# Проверяем, что скрипт корректный
sudo bash -n /usr/local/bin/wg_telemon.sh
echo "Синтаксис OK"

# Проверяем конфигурацию
sudo bash -n /etc/telemon.env
echo "Конфиг OK"
```

### **6.2. Тестовый запуск:**

```bash
# Запускаем тест конфигурации (отправит тестовое сообщение в Telegram)
sudo /usr/local/bin/wg_telemon.sh --test
```

**Ожидаемый результат:**
- ✅ В консоли: "Test message sent successfully"
- ✅ В Telegram: Получите красивое тестовое сообщение с информацией о системе

**Если тест не прошел:**
```bash
# Запускаем с отладкой
sudo /usr/local/bin/wg_telemon.sh --test --log-level DEBUG

# Проверяем логи
sudo tail -f /var/log/wg-monitor.log
```

### **6.3. Проверка доступа к контейнерам:**

```bash
# Проверяем, что скрипт видит ваши контейнеры
sudo docker ps
sudo docker exec wireguard wg show
```

---

## 🚀 Шаг 7: Запуск системного сервиса

### **7.1. Включение и запуск таймера:**

```bash
# Включаем автозапуск таймера
sudo systemctl enable wg-telemon.timer

# Запускаем таймер
sudo systemctl start wg-telemon.timer

# Проверяем статус
sudo systemctl status wg-telemon.timer
```

**Ожидаемый вывод:**
```
● wg-telemon.timer - Run WireGuard Telegram Monitor periodically
     Loaded: loaded (/etc/systemd/system/wg-telemon.timer; enabled; vendor preset: enabled)
     Active: active (waiting)
```

### **7.2. Проверка расписания:**

```bash
# Смотрим, когда следующий запуск
sudo systemctl list-timers wg-telemon.timer
```

### **7.3. Тестовый запуск сервиса:**

```bash
# Запускаем сервис вручную для теста
sudo systemctl start wg-telemon.service

# Смотрим статус
sudo systemctl status wg-telemon.service

# Проверяем логи
sudo journalctl -u wg-telemon.service -n 20
```

---

## 📊 Шаг 8: Мониторинг и логи

### **8.1. Просмотр логов в реальном времени:**

```bash
# Системные логи
sudo journalctl -u wg-telemon.service -f

# Логи приложения  
sudo tail -f /var/log/wg-monitor.log

# Логи с фильтром только ошибок
sudo grep ERROR /var/log/wg-monitor.log
```

### **8.2. Проверка работы мониторинга:**

```bash
# Статус таймера
sudo systemctl is-active wg-telemon.timer

# Последние запуски
sudo journalctl -u wg-telemon.service --since "1 hour ago"

# Статистика запусков
sudo systemctl list-timers | grep wg-telemon
```

---

## 🔧 Шаг 9: Тестирование алертов

### **9.1. Тест остановки контейнера:**

```bash
# Остановим контейнер для теста (ОСТОРОЖНО!)
sudo docker stop wireguard

# Ждем 2-3 минуты, должен прийти алерт в Telegram
# Запускаем обратно
sudo docker start wireguard
```

### **9.2. Тест сетевых проблем:**

```bash
# Временно заблокируем WireGuard порт
sudo iptables -I INPUT -p udp --dport 51820 -j DROP

# Подождите несколько минут - должен прийти алерт о старых handshakes
# Разблокируем
sudo iptables -D INPUT -p udp --dport 51820 -j DROP
```

### **9.3. Тест недоступного интерфейса:**

```bash
# Опустим интерфейс внутри контейнера (ОСТОРОЖНО!)
sudo docker exec wireguard ip link set wg0 down

# Должен прийти алерт об интерфейсе
# Поднимаем обратно
sudo docker exec wireguard ip link set wg0 up
```

---

## ✅ Шаг 10: Финальная проверка

### **10.1. Чек-лист успешной установки:**

Проверьте каждый пункт:

```bash
# ✅ Файлы на месте
ls -la /usr/local/bin/wg_telemon.sh
ls -la /etc/telemon.env  
ls -la /etc/systemd/system/wg-telemon.*

# ✅ Права файлов корректные
ls -la /etc/telemon.env | grep "rw-------"

# ✅ Сервис активен
sudo systemctl is-active wg-telemon.timer

# ✅ Тест проходит
sudo /usr/local/bin/wg_telemon.sh --test

# ✅ Логи пишутся
sudo tail -5 /var/log/wg-monitor.log

# ✅ Контейнеры доступны
sudo docker exec wireguard wg show
```

### **10.2. Тестирование всех функций:**

```bash
# Health check
sudo /usr/local/bin/wg_telemon.sh --health

# Проверка с debug логированием
sudo /usr/local/bin/wg_telemon.sh --log-level DEBUG

# Проверка версии
sudo /usr/local/bin/wg_telemon.sh --version
```

---

## 🎉 Готово! Что дальше?

### **Вы успешно установили WireGuard Monitor!**

Теперь у вас:
- 🔄 **Каждые 2 минуты** система проверяет ваши WireGuard контейнеры
- 📱 **Автоматические уведомления** в Telegram при проблемах
- 📊 **Подробные логи** всех проверок
- 🔄 **Автозапуск** после перезагрузки сервера

### **Что можно настроить дополнительно:**

1. **Изменить частоту проверок** (по умолчанию каждые 2 минуты):
   ```bash
   sudo systemctl edit wg-telemon.timer
   # Добавить:
   [Timer]
   OnUnitActiveSec=1min  # Каждую минуту
   ```

2. **Настроить более строгий мониторинг:**
   ```bash
   sudo nano /etc/telemon.env
   # Изменить:
   THRESHOLD=60          # 1 минута до алерта
   ALERT_COOLDOWN=300    # 5 минут между повторными алертами
   ```

3. **Добавить debug логирование:**
   ```bash
   sudo nano /etc/telemon.env
   # Изменить:
   LOG_LEVEL="DEBUG"
   ```

### **Полезные команды для повседневного использования:**

```bash
# Посмотреть статус
sudo systemctl status wg-telemon.timer

# Посмотреть последние логи
sudo journalctl -u wg-telemon.service -n 50

# Перезапустить после изменения конфига
sudo systemctl restart wg-telemon.timer

# Остановить мониторинг
sudo systemctl stop wg-telemon.timer

# Запустить мониторинг
sudo systemctl start wg-telemon.timer
```

---

## 🆘 Troubleshooting - Решение проблем

### **Проблема: Тест не проходит**

```bash
# Проверьте конфигурацию
sudo cat /etc/telemon.env | grep -v '^#'

# Проверьте токен бота
curl -s "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"

# Проверьте соединение с Telegram
curl -I https://api.telegram.org
```

### **Проблема: Сервис не запускается**

```bash
# Смотрим детальные ошибки
sudo journalctl -u wg-telemon.service -n 50

# Проверяем синтаксис скрипта
sudo bash -n /usr/local/bin/wg_telemon.sh

# Проверяем права доступа
ls -la /usr/local/bin/wg_telemon.sh
ls -la /etc/telemon.env
```

### **Проблема: Не приходят уведомления**

```bash
# Проверяем, что контейнеры найдены
sudo docker ps | grep -i wire

# Запускаем с отладкой
sudo /usr/local/bin/wg_telemon.sh --log-level DEBUG

# Проверяем логи Telegram API
sudo grep "telegram" /var/log/wg-monitor.log
```

### **Проблема: Ложные срабатывания**

```bash
# Увеличьте threshold для менее частых алертов
sudo nano /etc/telemon.env
# THRESHOLD=600  # 10 минут

# Увеличьте cooldown между алертами  
# ALERT_COOLDOWN=3600  # 1 час

# Перезапустите
sudo systemctl restart wg-telemon.timer
```

---

## 📞 Получить помощь

Если что-то не работает:

1. **Проверьте логи**: `sudo journalctl -u wg-telemon.service -n 50`
2. **Запустите отладку**: `sudo /usr/local/bin/wg_telemon.sh --test --log-level DEBUG`
3. **Откройте issue**: [GitHub Issues](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/issues)
4. **Читайте документацию**: [README.md](README.md) и [EXAMPLES.md](EXAMPLES.md)

**При обращении за помощью приложите:**
- Версию ОС: `uname -a`
- Версию Docker: `docker --version`  
- Логи ошибки: `sudo journalctl -u wg-telemon.service -n 20`
- Конфигурацию (без токенов): `sudo cat /etc/telemon.env | grep -v TOKEN`

---

**🎉 Поздравляем! Ваш WireGuard Monitor готов к работе!**

Теперь вы всегда будете знать о состоянии ваших WireGuard серверов! 🛡️✨
