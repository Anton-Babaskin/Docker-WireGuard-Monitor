#!/usr/bin/env bash
set -euo pipefail

# WireGuard Monitor - Quick Installer
# Быстрая установка одной командой для продвинутых пользователей

readonly SCRIPT_NAME="WireGuard Monitor Quick Installer"
readonly SCRIPT_VERSION="2.0"

# Цвета
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

show_usage() {
    cat << 'EOF'
🚀 WireGuard Monitor - Quick Install

Быстрая установка с параметрами командной строки для автоматизации.

ИСПОЛЬЗОВАНИЕ:
  curl -fsSL https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/quick-install.sh | sudo bash -s -- [ПАРАМЕТРЫ]
  
  или скачать и запустить:
  wget https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/quick-install.sh
  sudo bash quick-install.sh [ПАРАМЕТРЫ]

ОБЯЗАТЕЛЬНЫЕ ПАРАМЕТРЫ:
  --bot-token TOKEN        Токен Telegram бота
  --chat-id ID            Chat ID для уведомлений
  --containers "NAMES"    Имена контейнеров через пробел

ОПЦИОНАЛЬНЫЕ ПАРАМЕТРЫ:
  --interface IFACE       WireGuard интерфейс (по умолчанию: wg0)
  --threshold SECONDS     Порог handshake в секундах (по умолчанию: 300)
  --log-level LEVEL       Уровень логов: DEBUG,INFO,WARN,ERROR (по умолчанию: INFO)
  --cooldown SECONDS      Cooldown между алертами (по умолчанию: 3600)
  --max-retries NUM       Максимум попыток отправки (по умолчанию: 3)
  --test                  Только протестировать, не устанавливать
  --uninstall             Удалить WireGuard Monitor

ПРИМЕРЫ:

1. Базовая установка:
   sudo bash quick-install.sh \
     --bot-token "123456789:ABCdefGhIjKlmnoPQRsTUVwxyz" \
     --chat-id "123456789" \
     --containers "wireguard"

2. Установка с несколькими контейнерами:
   sudo bash quick-install.sh \
     --bot-token "123456789:ABCdefGhIjKlmnoPQRsTUVwxyz" \
     --chat-id "-987654321" \
     --containers "wg-server-1 wg-server-2" \
     --threshold 180 \
     --log-level DEBUG

3. Тест конфигурации без установки:
   sudo bash quick-install.sh \
     --bot-token "123456789:ABCdefGhIjKlmnoPQRsTUVwxyz" \
     --chat-id "123456789" \
     --containers "wireguard" \
     --test

4. Установка одной командой:
   curl -fsSL https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/quick-install.sh | \
   sudo bash -s -- \
     --bot-token "123456789:ABCdefGhIjKlmnoPQRsTUVwxyz" \
     --chat-id "123456789" \
     --containers "wireguard"

ПОЛУЧЕНИЕ ДАННЫХ:
• Создайте бота: @BotFather в Telegram (/newbot)
• Получите Chat ID: @userinfobot в Telegram (/start)
• Найдите контейнеры: docker ps | grep -i wire

EOF
}

# Парсинг аргументов
parse_arguments() {
    BOT_TOKEN=""
    CHAT_ID=""
    WG_CONTAINERS=""
    WG_IFACE="wg0"
    THRESHOLD="300"
    LOG_LEVEL="INFO"
    ALERT_COOLDOWN="3600"
    MAX_RETRIES="3"
    TEST_ONLY="false"
    UNINSTALL="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --bot-token)
                BOT_TOKEN="$2"
                shift 2
                ;;
            --chat-id)
                CHAT_ID="$2"
                shift 2
                ;;
            --containers)
                WG_CONTAINERS="$2"
                shift 2
                ;;
            --interface)
                WG_IFACE="$2"
                shift 2
                ;;
            --threshold)
                THRESHOLD="$2"
                shift 2
                ;;
            --log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            --cooldown)
                ALERT_COOLDOWN="$2"
                shift 2
                ;;
            --max-retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --test)
                TEST_ONLY="true"
                shift
                ;;
            --uninstall)
                UNINSTALL="true"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Неизвестный параметр: $1"
                echo "Используйте --help для справки"
                exit 1
                ;;
        esac
    done
}

# Валидация параметров
validate_arguments() {
    local errors=0
    
    if [[ "$UNINSTALL" == "true" ]]; then
        return 0  # Для деинсталляции не нужна валидация
    fi
    
    # Проверяем обязательные параметры
    if [[ -z "$BOT_TOKEN" ]]; then
        print_error "Требуется --bot-token"
        ((errors++))
    elif [[ ! "$BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
        print_error "Неверный формат bot-token"
        ((errors++))
    fi
    
    if [[ -z "$CHAT_ID" ]]; then
        print_error "Требуется --chat-id"
        ((errors++))
    elif [[ ! "$CHAT_ID" =~ ^-?[0-9]+$ ]]; then
        print_error "Chat ID должен быть числом"
        ((errors++))
    fi
    
    if [[ -z "$WG_CONTAINERS" ]]; then
        print_error "Требуется --containers"
        ((errors++))
    fi
    
    # Проверяем опциональные параметры
    if [[ ! "$THRESHOLD" =~ ^[0-9]+$ ]]; then
        print_error "Threshold должен быть числом"
        ((errors++))
    fi
    
    if [[ ! "$LOG_LEVEL" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
        print_error "Log level должен быть: DEBUG, INFO, WARN или ERROR"
        ((errors++))
    fi
    
    if [[ ! "$ALERT_COOLDOWN" =~ ^[0-9]+$ ]]; then
        print_error "Alert cooldown должен быть числом"
        ((errors++))
    fi
    
    if [[ ! "$MAX_RETRIES" =~ ^[0-9]+$ ]] || [[ "$MAX_RETRIES" -lt 1 ]] || [[ "$MAX_RETRIES" -gt 10 ]]; then
        print_error "Max retries должен быть числом от 1 до 10"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo
        show_usage
        exit 1
    fi
}

# Проверка системы
check_system() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Скрипт должен запускаться от root"
        print_info "Используйте: sudo $0"
        exit 1
    fi
    
    # Проверяем команды
    local missing=()
    for cmd in curl docker systemctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Отсутствуют команды: ${missing[*]}"
        exit 1
    fi
    
    # Проверяем Docker
    if ! docker version >/dev/null 2>&1; then
        print_error "Docker не запущен"
        print_info "Запустите: sudo systemctl start docker"
        exit 1
    fi
}

# Проверка контейнеров
check_containers() {
    print_info "Проверка контейнеров: $WG_CONTAINERS"
    
    for container in $WG_CONTAINERS; do
        if ! docker inspect "$container" >/dev/null 2>&1; then
            print_error "Контейнер не найден: $container"
            print_info "Доступные контейнеры:"
            docker ps --format "{{.Names}}"
            exit 1
        fi
    done
    
    print_success "Все контейнеры найдены"
}

# Тест Telegram
test_telegram() {
    print_info "Проверка Telegram бота..."
    
    # Проверяем токен
    local bot_info
    if ! bot_info=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe" 2>/dev/null); then
        print_error "Не удается подключиться к Telegram API"
        exit 1
    fi
    
    if ! echo "$bot_info" | grep -q '"ok":true'; then
        print_error "Неверный bot token"
        exit 1
    fi
    
    local bot_name
    bot_name=$(echo "$bot_info" | grep -o '"first_name":"[^"]*"' | cut -d'"' -f4)
    print_success "Бот найден: $bot_name"
    
    # Тест отправки сообщения
    local test_message="🧪 Quick Install Test

🖥️ Хост: $(hostname)
🕐 Время: $(date)
📦 Контейнеры: $WG_CONTAINERS

Быстрая установка работает! ✅"
    
    print_info "Отправка тестового сообщения..."
    local response
    if response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$test_message" 2>/dev/null); then
        
        if echo "$response" | grep -q '"ok":true'; then
            print_success "Тестовое сообщение отправлено"
        else
            print_error "Ошибка отправки сообщения"
            echo "Ответ API: $response"
            exit 1
        fi
    else
        print_error "Не удается отправить сообщение"
        exit 1
    fi
}

# Создание конфигурации
create_config() {
    local config_file="/etc/telemon.env"
    
    print_info "Создание конфигурации: $config_file"
    
    cat > "$config_file" << EOF
# WireGuard Monitor Configuration
# Создано Quick Installer: $(date)

# Telegram settings
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"

# Container settings
WG_CONTAINERS="$WG_CONTAINERS"
WG_IFACE="$WG_IFACE"
THRESHOLD=$THRESHOLD

# Advanced settings
LOG_LEVEL="$LOG_LEVEL"
ALERT_COOLDOWN=$ALERT_COOLDOWN
MAX_RETRIES=$MAX_RETRIES

# Quick install defaults
RECOVERY_NOTIFICATION="true"
STARTUP_NOTIFICATION="false"
EOF

    chmod 600 "$config_file"
    chown root:root "$config_file"
    
    print_success "Конфигурация создана"
}

# Установка файлов
install_files() {
    print_info "Скачивание и установка файлов..."
    
    local base_url="https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main"
    
    # Скачиваем основной скрипт
    if ! curl -fsSL "$base_url/wg_telemon" -o "/usr/local/bin/wg_telemon.sh"; then
        print_error "Не удалось скачать основной скрипт"
        exit 1
    fi
    
    chmod +x "/usr/local/bin/wg_telemon.sh"
    chown root:root "/usr/local/bin/wg_telemon.sh"
    
    # Скачиваем systemd файлы
    if ! curl -fsSL "$base_url/wg-telemon.service" -o "/etc/systemd/system/wg-telemon.service"; then
        print_error "Не удалось скачать service файл"
        exit 1
    fi
    
    if ! curl -fsSL "$base_url/wg-telemon.timer" -o "/etc/systemd/system/wg-telemon.timer"; then
        print_error "Не удалось скачать timer файл"
        exit 1
    fi
    
    chown root:root "/etc/systemd/system/wg-telemon."*
    
    # Создаем лог файл
    touch "/var/log/wg-monitor.log"
    chmod 644 "/var/log/wg-monitor.log"
    
    # Перезагружаем systemd
    systemctl daemon-reload
    
    print_success "Файлы установлены"
}

# Запуск сервиса
start_service() {
    print_info "Запуск сервиса..."
    
    systemctl enable wg-telemon.timer
    systemctl start wg-telemon.timer
    
    if systemctl is-active --quiet wg-telemon.timer; then
        print_success "Сервис запущен"
    else
        print_error "Сервис не запустился"
        systemctl status wg-telemon.timer --no-pager
        exit 1
    fi
}

# Финальный тест
final_test() {
    print_info "Финальное тестирование..."
    
    if /usr/local/bin/wg_telemon.sh --test >/dev/null 2>&1; then
        print_success "Тест пройден"
    else
        print_error "Тест не пройден"
        print_info "Запустите для диагностики: sudo /usr/local/bin/wg_telemon.sh --test"
        exit 1
    fi
}

# Деинсталляция
uninstall() {
    print_info "Деинсталляция WireGuard Monitor..."
    
    # Останавливаем сервисы
    systemctl stop wg-telemon.timer 2>/dev/null || true
    systemctl disable wg-telemon.timer 2>/dev/null || true
    
    # Удаляем файлы
    rm -f "/usr/local/bin/wg_telemon.sh"
    rm -f "/etc/systemd/system/wg-telemon.service"
    rm -f "/etc/systemd/system/wg-telemon.timer"
    rm -f "/etc/telemon.env"
    rm -f "/var/log/wg-monitor.log"
    
    systemctl daemon-reload
    
    print_success "Деинсталляция завершена"
}

# Показать результат
show_result() {
    cat << EOF

${GREEN}🎉 Quick Install завершён успешно!${NC}

${BLUE}📊 Статус:${NC}
• Мониторинг: $(systemctl is-active wg-telemon.timer)
• Контейнеры: $WG_CONTAINERS  
• Интерфейс: $WG_IFACE
• Порог: $THRESHOLD сек ($((THRESHOLD / 60)) мин)

${BLUE}📋 Управление:${NC}
• Статус: sudo systemctl status wg-telemon.timer
• Логи: sudo tail -f /var/log/wg-monitor.log  
• Тест: sudo /usr/local/bin/wg_telemon.sh --test
• Стоп: sudo systemctl stop wg-telemon.timer

${BLUE}📱 Telegram:${NC}
Уведомления будут приходить при проблемах с WireGuard.

${BLUE}🔧 Конфигурация:${NC}
Файл: /etc/telemon.env (можно редактировать)

EOF
}

# Основная функция
main() {
    echo -e "${BLUE}🚀 $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo
    
    parse_arguments "$@"
    validate_arguments
    check_system
    
    if [[ "$UNINSTALL" == "true" ]]; then
        uninstall
        exit 0
    fi
    
    check_containers
    test_telegram
    
    if [[ "$TEST_ONLY" == "true" ]]; then
        print_success "Тест завершён успешно. Все параметры корректны."
        print_info "Для установки запустите без --test"
        exit 0
    fi
    
    create_config
    install_files
    start_service
    final_test
    show_result
}

# Запуск
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
