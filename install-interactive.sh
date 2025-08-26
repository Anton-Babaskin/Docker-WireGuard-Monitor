#!/usr/bin/env bash
set -euo pipefail

# WireGuard Monitor - Interactive Installer
# Полностью автоматическая установка с интерактивными вопросами

readonly SCRIPT_NAME="WireGuard Monitor Interactive Installer"
readonly SCRIPT_VERSION="2.0"
readonly REPO_URL="https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor"

# Цвета для красивого вывода
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Пути установки
readonly INSTALL_DIR="/opt/wg-monitor"
readonly CONFIG_FILE="/etc/telemon.env"
readonly SCRIPT_PATH="/usr/local/bin/wg_telemon.sh"
readonly SERVICE_FILE="/etc/systemd/system/wg-telemon.service"
readonly TIMER_FILE="/etc/systemd/system/wg-telemon.timer"
readonly LOG_FILE="/var/log/wg-monitor.log"

# Глобальные переменные для конфигурации
declare BOT_TOKEN=""
declare CHAT_ID=""
declare WG_CONTAINERS=""
declare WG_IFACE="wg0"
declare THRESHOLD="300"
declare LOG_LEVEL="INFO"
declare ALERT_COOLDOWN="3600"
declare MAX_RETRIES="3"

# Функции для красивого вывода
print_header() {
    clear
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    🛡️  WireGuard Monitor Installer                          ║
║                          ИНТЕРАКТИВНАЯ УСТАНОВКА                            ║
║                                                                              ║
║  Этот установщик поможет вам настроить мониторинг WireGuard контейнеров    ║
║  с уведомлениями в Telegram. Просто отвечайте на вопросы!                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Версия: $SCRIPT_VERSION${NC}"
    echo
}

print_step() {
    echo -e "\n${PURPLE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_question() {
    echo -e "${WHITE}❓ $1${NC}"
}

# Функция для безопасного ввода
read_input() {
    local prompt="$1"
    local default="${2:-}"
    local secret="${3:-false}"
    local result=""
    
    if [[ "$secret" == "true" ]]; then
        echo -n -e "${WHITE}$prompt${NC}"
        read -s result
        echo
    else
        if [[ -n "$default" ]]; then
            echo -n -e "${WHITE}$prompt [$default]: ${NC}"
        else
            echo -n -e "${WHITE}$prompt: ${NC}"
        fi
        read -r result
    fi
    
    # Если ввод пустой, используем default
    if [[ -z "$result" && -n "$default" ]]; then
        result="$default"
    fi
    
    echo "$result"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Для установки нужны права администратора"
        print_info "Запустите: ${YELLOW}sudo $0${NC}"
        exit 1
    fi
}

# Проверка системных требований
check_system() {
    print_step "Проверка системы..."
    
    local errors=0
    local warnings=0
    
    # Проверка ОС
    if ! grep -qi linux /proc/version 2>/dev/null; then
        print_error "Поддерживается только Linux"
        ((errors++))
    fi
    
    # Проверка команд
    local required_commands=("curl" "docker" "systemctl")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Отсутствуют команды: ${missing_commands[*]}"
        print_info "Установите их командой:"
        
        if command -v apt-get >/dev/null 2>&1; then
            echo "  sudo apt-get update && sudo apt-get install -y ${missing_commands[*]}"
        elif command -v yum >/dev/null 2>&1; then
            echo "  sudo yum install -y ${missing_commands[*]}"
        elif command -v dnf >/dev/null 2>&1; then
            echo "  sudo dnf install -y ${missing_commands[*]}"
        fi
        
        ((errors++))
    fi
    
    # Проверка Docker
    if command -v docker >/dev/null 2>&1; then
        if ! docker version >/dev/null 2>&1; then
            print_warning "Docker установлен, но демон не запущен"
            print_info "Запустите: sudo systemctl start docker"
            ((warnings++))
        fi
    fi
    
    # Проверка версии Bash
    if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
        print_warning "Рекомендуется Bash 4.0+"
        ((warnings++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        print_error "Обнаружено $errors критических ошибок. Исправьте их и запустите снова."
        exit 1
    fi
    
    if [[ $warnings -gt 0 ]]; then
        print_warning "Обнаружено $warnings предупреждений"
        echo -n "Продолжить установку? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy] ]]; then
            exit 0
        fi
    fi
    
    print_success "Система готова к установке"
}

# Инструкции по созданию Telegram бота
show_telegram_instructions() {
    print_step "Настройка Telegram бота"
    
    cat << EOF
${CYAN}📱 Создание Telegram бота:${NC}

1️⃣  Откройте Telegram
2️⃣  Найдите бота ${YELLOW}@BotFather${NC}
3️⃣  Отправьте команду: ${YELLOW}/start${NC}
4️⃣  Отправьте команду: ${YELLOW}/newbot${NC}
5️⃣  Придумайте имя бота: ${GREEN}My WireGuard Monitor${NC}
6️⃣  Придумайте username: ${GREEN}my_wg_monitor_bot${NC}
7️⃣  Скопируйте токен (формат: ${GREEN}123456789:ABCdefGhIjKlmnoPQRsTUVwxyz${NC})

${CYAN}📞 Получение Chat ID:${NC}

Способ 1 (для личных сообщений):
• Найдите бота ${YELLOW}@userinfobot${NC}
• Отправьте команду: ${YELLOW}/start${NC}
• Скопируйте ваш ID (число типа: ${GREEN}123456789${NC})

Способ 2 (для групповых чатов):
• Добавьте вашего бота в группу
• Дайте ему права администратора (для отправки сообщений)
• Chat ID группы будет отрицательным числом (типа: ${GREEN}-987654321${NC})

EOF

    echo -n "Когда создадите бота и получите данные, нажмите Enter..."
    read -r
}

# Ввод и проверка Telegram данных
configure_telegram() {
    show_telegram_instructions
    
    # Ввод Bot Token
    while true; do
        BOT_TOKEN=$(read_input "Введите токен бота" "" "true")
        
        if [[ -z "$BOT_TOKEN" ]]; then
            print_error "Токен не может быть пустым"
            continue
        fi
        
        if [[ ! "$BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
            print_error "Неверный формат токена. Должен быть: 123456789:ABCdef..."
            echo "Ваш токен: ${BOT_TOKEN:0:20}..."
            continue
        fi
        
        # Проверяем токен через Telegram API
        print_step "Проверка токена бота..."
        local bot_info
        if bot_info=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getMe" 2>/dev/null); then
            if echo "$bot_info" | grep -q '"ok":true'; then
                local bot_name=$(echo "$bot_info" | grep -o '"first_name":"[^"]*"' | cut -d'"' -f4)
                print_success "Токен работает! Бот: $bot_name"
                break
            else
                print_error "Токен недействителен"
                continue
            fi
        else
            print_error "Не удается проверить токен. Проверьте интернет-соединение."
            continue
        fi
    done
    
    # Ввод Chat ID
    while true; do
        CHAT_ID=$(read_input "Введите Chat ID")
        
        if [[ -z "$CHAT_ID" ]]; then
            print_error "Chat ID не может быть пустым"
            continue
        fi
        
        if [[ ! "$CHAT_ID" =~ ^-?[0-9]+$ ]]; then
            print_error "Chat ID должен быть числом (например: 123456789 или -987654321)"
            continue
        fi
        
        # Тестируем отправку сообщения
        print_step "Проверка Chat ID..."
        local test_message="🧪 Тест подключения к WireGuard Monitor
        
🖥️ Хост: $(hostname)
🕐 Время: $(date)
        
Если вы видите это сообщение, настройка прошла успешно! ✅"
        
        local response
        if response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID" \
            -d "text=$test_message" 2>/dev/null); then
            
            if echo "$response" | grep -q '"ok":true'; then
                print_success "Тестовое сообщение отправлено!"
                print_info "Проверьте Telegram - должно прийти сообщение"
                break
            else
                print_error "Ошибка отправки сообщения"
                echo "Ответ API: $response"
                continue
            fi
        else
            print_error "Не удается отправить сообщение. Проверьте Chat ID."
            continue
        fi
    done
}

# Определение WireGuard контейнеров
detect_containers() {
    print_step "Поиск WireGuard контейнеров..."
    
    # Получаем список всех контейнеров
    local all_containers
    if ! all_containers=$(docker ps --format "{{.Names}}" 2>/dev/null); then
        print_error "Не удается получить список Docker контейнеров"
        print_info "Убедитесь, что Docker запущен: sudo systemctl start docker"
        exit 1
    fi
    
    if [[ -z "$all_containers" ]]; then
        print_warning "Не найдено запущенных контейнеров"
        print_info "Вы можете указать имя контейнера вручную"
    else
        print_info "Найденные контейнеры:"
        local i=1
        declare -a container_list=()
        
        while IFS= read -r container; do
            # Проверяем, может ли это быть WireGuard контейнер
            local image
            image=$(docker inspect --format='{{.Config.Image}}' "$container" 2>/dev/null || echo "unknown")
            
            local is_wg=""
            if [[ "$container" =~ (wire|wg|vpn) ]] || [[ "$image" =~ (wire|wg) ]]; then
                is_wg=" ${GREEN}(возможно WireGuard)${NC}"
            fi
            
            echo -e "  ${YELLOW}$i${NC}. $container - $image$is_wg"
            container_list+=("$container")
            ((i++))
        done <<< "$all_containers"
    fi
    
    echo
    print_question "Как выбрать контейнеры для мониторинга?"
    echo "1. Выбрать из списка по номерам (например: 1,3)"
    echo "2. Ввести имена вручную"
    echo "3. Автоматически найти WireGuard контейнеры"
    
    local choice
    choice=$(read_input "Ваш выбор [3]" "3")
    
    case $choice in
        1)
            if [[ ${#container_list[@]} -eq 0 ]]; then
                print_error "Нет доступных контейнеров"
                exit 1
            fi
            
            local selected_nums
            selected_nums=$(read_input "Введите номера через запятую (например: 1,2)")
            
            local selected_containers=()
            IFS=',' read -ra nums <<< "$selected_nums"
            for num in "${nums[@]}"; do
                num=$(echo "$num" | tr -d ' ')
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#container_list[@]} ]]; then
                    selected_containers+=("${container_list[$((num-1))]}")
                fi
            done
            
            if [[ ${#selected_containers[@]} -eq 0 ]]; then
                print_error "Не выбрано ни одного контейнера"
                exit 1
            fi
            
            WG_CONTAINERS="${selected_containers[*]}"
            ;;
            
        2)
            WG_CONTAINERS=$(read_input "Введите имена контейнеров через пробел" "wireguard")
            ;;
            
        3)
            print_step "Автоматический поиск WireGuard контейнеров..."
            local found_containers=()
            
            while IFS= read -r container; do
                local image
                image=$(docker inspect --format='{{.Config.Image}}' "$container" 2>/dev/null || echo "")
                
                # Проверяем имя и образ контейнера
                if [[ "$container" =~ (wire|wg|vpn) ]] || [[ "$image" =~ (wire|wg) ]]; then
                    # Дополнительная проверка - есть ли WireGuard внутри
                    if docker exec "$container" which wg >/dev/null 2>&1 || \
                       docker exec "$container" ls /etc/wireguard >/dev/null 2>&1; then
                        found_containers+=("$container")
                        print_success "Найден WireGuard контейнер: $container"
                    fi
                fi
            done <<< "$all_containers"
            
            if [[ ${#found_containers[@]} -eq 0 ]]; then
                print_warning "Автоматически не найдено WireGuard контейнеров"
                WG_CONTAINERS=$(read_input "Введите имя контейнера вручную" "wireguard")
            else
                WG_CONTAINERS="${found_containers[*]}"
                print_success "Выбраны контейнеры: $WG_CONTAINERS"
            fi
            ;;
            
        *)
            print_error "Неверный выбор"
            exit 1
            ;;
    esac
    
    # Проверяем, что контейнеры существуют
    local invalid_containers=()
    for container in $WG_CONTAINERS; do
        if ! docker inspect "$container" >/dev/null 2>&1; then
            invalid_containers+=("$container")
        fi
    done
    
    if [[ ${#invalid_containers[@]} -gt 0 ]]; then
        print_error "Контейнеры не найдены: ${invalid_containers[*]}"
        exit 1
    fi
    
    print_success "Выбраны контейнеры: $WG_CONTAINERS"
}

# Дополнительные настройки
configure_advanced() {
    print_step "Дополнительные настройки"
    
    echo -e "${CYAN}Хотите настроить дополнительные параметры? (по умолчанию подходят большинству)${NC}"
    local advanced
    advanced=$(read_input "Расширенная настройка? (y/N)" "N")
    
    if [[ "$advanced" =~ ^[Yy] ]]; then
        # WireGuard интерфейс
        echo -e "\n${CYAN}🌐 Настройка интерфейса WireGuard:${NC}"
        WG_IFACE=$(read_input "Имя интерфейса WireGuard" "$WG_IFACE")
        
        # Threshold
        echo -e "\n${CYAN}⏰ Настройка времени ожидания:${NC}"
        echo "Через сколько секунд без handshake отправлять алерт?"
        echo "• 60 (1 минута) - очень строго"
        echo "• 300 (5 минут) - рекомендуется"
        echo "• 600 (10 минут) - нормально"
        echo "• 1800 (30 минут) - мягко"
        THRESHOLD=$(read_input "Время в секундах" "$THRESHOLD")
        
        # Log level
        echo -e "\n${CYAN}📊 Уровень логирования:${NC}"
        echo "• DEBUG - очень подробно (для отладки)"
        echo "• INFO - нормально (рекомендуется)"
        echo "• WARN - только предупреждения"
        echo "• ERROR - только ошибки"
        LOG_LEVEL=$(read_input "Уровень логов" "$LOG_LEVEL")
        
        # Alert cooldown
        echo -e "\n${CYAN}🔄 Настройка повторных алертов:${NC}"
        echo "Через сколько секунд можно повторить тот же алерт?"
        echo "• 300 (5 минут) - часто"
        echo "• 1800 (30 минут) - нормально"
        echo "• 3600 (1 час) - рекомендуется"
        echo "• 7200 (2 часа) - редко"
        ALERT_COOLDOWN=$(read_input "Cooldown в секундах" "$ALERT_COOLDOWN")
        
        # Max retries
        echo -e "\n${CYAN}🔁 Количество попыток отправки:${NC}"
        MAX_RETRIES=$(read_input "Максимум попыток отправки в Telegram [1-10]" "$MAX_RETRIES")
    else
        print_info "Используются настройки по умолчанию"
    fi
}

# Показ итоговой конфигурации
show_configuration_summary() {
    print_step "Итоговая конфигурация"
    
    cat << EOF
${CYAN}📋 Конфигурация WireGuard Monitor:${NC}

${YELLOW}Telegram:${NC}
• Бот токен: ${BOT_TOKEN:0:20}...
• Chat ID: $CHAT_ID

${YELLOW}Мониторинг:${NC}  
• Контейнеры: $WG_CONTAINERS
• Интерфейс: $WG_IFACE
• Порог handshake: $THRESHOLD секунд ($((THRESHOLD / 60)) мин)

${YELLOW}Логирование:${NC}
• Уровень: $LOG_LEVEL
• Cooldown алертов: $ALERT_COOLDOWN секунд ($((ALERT_COOLDOWN / 60)) мин)
• Попытки отправки: $MAX_RETRIES

${YELLOW}Файлы:${NC}
• Скрипт: $SCRIPT_PATH
• Конфиг: $CONFIG_FILE
• Логи: $LOG_FILE

${YELLOW}Мониторинг:${NC}
• Частота проверок: каждые 2 минуты
• Автозапуск: да (systemd)

EOF

    local confirm
    confirm=$(read_input "Всё правильно? Начать установку? (Y/n)" "Y")
    
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        print_info "Установка отменена"
        exit 0
    fi
}

# Создание конфигурационного файла
create_config_file() {
    print_step "Создание конфигурационного файла..."
    
    cat > "$CONFIG_FILE" << EOF
# WireGuard Monitor Configuration
# Создано автоматически: $(date)
# Хост: $(hostname)

# =============================================================================
# TELEGRAM SETTINGS (Required)
# =============================================================================

# Telegram Bot Token
BOT_TOKEN="$BOT_TOKEN"

# Telegram Chat ID  
CHAT_ID="$CHAT_ID"

# =============================================================================
# CONTAINER SETTINGS (Required)
# =============================================================================

# WireGuard container names (space-separated for multiple)
WG_CONTAINERS="$WG_CONTAINERS"

# WireGuard interface name inside the container
WG_IFACE="$WG_IFACE"

# Handshake age threshold in seconds
THRESHOLD=$THRESHOLD

# =============================================================================
# MONITORING BEHAVIOR
# =============================================================================

# Logging level: DEBUG, INFO, WARN, ERROR
LOG_LEVEL="$LOG_LEVEL"

# Alert cooldown period in seconds
ALERT_COOLDOWN=$ALERT_COOLDOWN

# Maximum retry attempts for Telegram messages
MAX_RETRIES=$MAX_RETRIES

# =============================================================================
# ADVANCED SETTINGS (Optional)
# =============================================================================

# Custom log file path
# WG_MONITOR_LOG="/var/log/wg-monitor.log"

# Enable extended peer information in alerts
# EXTENDED_PEER_INFO="false"

# Custom message format for alerts  
# ALERT_FORMAT="🚨 WireGuard Alert on {hostname}"

# Enable recovery notifications
RECOVERY_NOTIFICATION="true"

# Enable startup notification
STARTUP_NOTIFICATION="false"
EOF

    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    
    print_success "Конфигурация создана: $CONFIG_FILE"
}

# Загрузка файлов скрипта
download_files() {
    print_step "Загрузка файлов WireGuard Monitor..."
    
    # Создаем временную директорию
    local temp_dir="/tmp/wg-monitor-install-$$"
    mkdir -p "$temp_dir"
    
    # Список файлов для загрузки
    local files=(
        "wg_telemon"
        "wg-telemon.service"
        "wg-telemon.timer"
        "README.md"
    )
    
    print_info "Скачиваем файлы из GitHub..."
    
    for file in "${files[@]}"; do
        local url="https://raw.githubusercontent.com/Anton-Babaskin/Docker-WireGuard-Monitor/main/$file"
        print_info "Скачиваем $file..."
        
        if ! curl -fsSL "$url" -o "$temp_dir/$file"; then
            print_error "Не удалось скачать $file"
            rm -rf "$temp_dir"
            exit 1
        fi
    done
    
    # Установка файлов
    print_step "Установка файлов..."
    
    # Основной скрипт
    cp "$temp_dir/wg_telemon" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    chown root:root "$SCRIPT_PATH"
    
    # Systemd файлы
    cp "$temp_dir/wg-telemon.service" "$SERVICE_FILE"
    cp "$temp_dir/wg-telemon.timer" "$TIMER_FILE"
    chown root:root "$SERVICE_FILE" "$TIMER_FILE"
    
    # Документация (опционально)
    mkdir -p "$INSTALL_DIR"
    cp "$temp_dir/README.md" "$INSTALL_DIR/" 2>/dev/null || true
    
    # Создание лог файла
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    chown root:root "$LOG_FILE"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    print_success "Файлы установлены"
}

# Настройка systemd
setup_systemd() {
    print_step "Настройка systemd сервиса..."
    
    # Перезагружаем systemd
    systemctl daemon-reload
    
    # Включаем автозапуск таймера
    systemctl enable wg-telemon.timer
    
    print_success "Systemd настроен"
}

# Финальное тестирование
final_test() {
    print_step "Финальное тестирование установки..."
    
    # Тест конфигурации
    print_info "Проверка конфигурации..."
    if "$SCRIPT_PATH" --test; then
        print_success "Тест конфигурации пройден"
    else
        print_error "Тест конфигурации провален"
        return 1
    fi
    
    # Запуск сервиса
    print_info "Запуск мониторинга..."
    systemctl start wg-telemon.timer
    
    if systemctl is-active --quiet wg-telemon.timer; then
        print_success "Сервис запущен и работает"
    else
        print_error "Сервис не запустился"
        systemctl status wg-telemon.timer --no-pager
        return 1
    fi
    
    # Проверка следующего запуска
    print_info "Информация о расписании:"
    systemctl list-timers wg-telemon.timer --no-pager
    
    return 0
}

# Показ информации о завершении
show_completion_info() {
    print_success "🎉 Установка завершена успешно!"
    
    cat << EOF

${GREEN}✅ WireGuard Monitor установлен и настроен!${NC}

${CYAN}📊 Что происходит сейчас:${NC}
• Мониторинг запущен и работает
• Проверки происходят каждые 2 минуты  
• Уведомления отправляются в Telegram при проблемах
• Автозапуск после перезагрузки настроен

${CYAN}📋 Полезные команды:${NC}

${YELLOW}Просмотр статуса:${NC}
  sudo systemctl status wg-telemon.timer
  sudo systemctl status wg-telemon.service

${YELLOW}Просмотр логов:${NC}
  sudo journalctl -u wg-telemon.service -f
  sudo tail -f $LOG_FILE

${YELLOW}Управление сервисом:${NC}
  sudo systemctl stop wg-telemon.timer    # остановить
  sudo systemctl start wg-telemon.timer   # запустить
  sudo systemctl restart wg-telemon.timer # перезапустить

${YELLOW}Тестирование:${NC}
  sudo $SCRIPT_PATH --test           # тест конфигурации
  sudo $SCRIPT_PATH --health         # проверка здоровья
  sudo $SCRIPT_PATH --log-level DEBUG # отладка

${YELLOW}Редактирование конфигурации:${NC}
  sudo nano $CONFIG_FILE
  # После изменений перезапустите сервис

${CYAN}🧪 Тестирование алертов:${NC}

Чтобы проверить, что алерты работают:

1️⃣  Остановить контейнер: ${YELLOW}sudo docker stop wireguard${NC}
   Должен прийти алерт через 2-4 минуты

2️⃣  Запустить контейнер: ${YELLOW}sudo docker start wireguard${NC}

3️⃣  Посмотреть логи: ${YELLOW}sudo tail -f $LOG_FILE${NC}

${CYAN}📞 Поддержка:${NC}
• GitHub: https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor
• Issues: https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/issues

${GREEN}Счастливого мониторинга! 🛡️✨${NC}

EOF
}

# Обработка ошибок
handle_error() {
    local line_number=$1
    print_error "Ошибка установки на строке $line_number"
    
    cat << EOF

${RED}💥 Установка прервана из-за ошибки${NC}

${YELLOW}Что можно сделать:${NC}
1. Проверьте сообщения об ошибках выше
2. Исправьте проблемы и запустите установщик снова
3. Если нужна помощь, откройте issue на GitHub

${YELLOW}Для отладки запустите:${NC}
  bash -x $0

${YELLOW}Логи установки:${NC}
  Проверьте вывод команд выше

EOF
    
    # Очистка при ошибке
    cleanup_on_error
    
    exit 1
}

# Очистка при ошибке
cleanup_on_error() {
    print_info "Очистка временных файлов..."
    
    # Удаляем файлы если установка не завершена
    [[ -f "$CONFIG_FILE" ]] && rm -f "$CONFIG_FILE" 2>/dev/null || true
    [[ -f "$SCRIPT_PATH" ]] && rm -f "$SCRIPT_PATH" 2>/dev/null || true
    [[ -f "$SERVICE_FILE" ]] && rm -f "$SERVICE_FILE" 2>/dev/null || true
    [[ -f "$TIMER_FILE" ]] && rm -f "$TIMER_FILE" 2>/dev/null || true
    
    # Перезагружаем systemd
    systemctl daemon-reload 2>/dev/null || true
}

# Функция деинсталляции
uninstall() {
    print_header
    print_step "Деинсталляция WireGuard Monitor"
    
    local confirm
    confirm=$(read_input "Вы уверены, что хотите удалить WireGuard Monitor? (y/N)" "N")
    
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        print_info "Деинсталляция отменена"
        exit 0
    fi
    
    print_step "Остановка и отключение сервисов..."
    systemctl stop wg-telemon.timer 2>/dev/null || true
    systemctl disable wg-telemon.timer 2>/dev/null || true
    
    print_step "Удаление файлов..."
    rm -f "$SCRIPT_PATH"
    rm -f "$SERVICE_FILE"  
    rm -f "$TIMER_FILE"
    
    systemctl daemon-reload
    
    # Спрашиваем о конфигурации
    local remove_config
    remove_config=$(read_input "Удалить конфигурационный файл $CONFIG_FILE? (y/N)" "N")
    if [[ "$remove_config" =~ ^[Yy] ]]; then
        rm -f "$CONFIG_FILE"
        print_info "Конфигурация удалена"
    fi
    
    # Спрашиваем о логах
    local remove_logs
    remove_logs=$(read_input "Удалить лог файл $LOG_FILE? (y/N)" "N")
    if [[ "$remove_logs" =~ ^[Yy] ]]; then
        rm -f "$LOG_FILE"
        print_info "Логи удалены"
    fi
    
    # Спрашиваем об установочной директории
    if [[ -d "$INSTALL_DIR" ]]; then
        local remove_dir
        remove_dir=$(read_input "Удалить директорию $INSTALL_DIR? (y/N)" "N")
        if [[ "$remove_dir" =~ ^[Yy] ]]; then
            rm -rf "$INSTALL_DIR"
            print_info "Директория удалена"
        fi
    fi
    
    print_success "Деинсталляция завершена"
}

# Показ справки
show_help() {
    cat << EOF
${BLUE}WireGuard Monitor Interactive Installer v$SCRIPT_VERSION${NC}

${YELLOW}Использование:${NC}
  $0 [ОПЦИИ]

${YELLOW}Опции:${NC}
  --install, -i     Запустить интерактивную установку (по умолчанию)
  --uninstall, -u   Удалить WireGuard Monitor
  --help, -h        Показать эту справку
  --version, -v     Показать версию

${YELLOW}Примеры:${NC}
  $0                # Интерактивная установка
  $0 --install      # То же самое
  $0 --uninstall    # Удаление
  
${YELLOW}Описание:${NC}
  Этот скрипт автоматически установит и настроит WireGuard Monitor
  с интерактивными вопросами. Он поможет:
  
  • Создать и проверить Telegram бота
  • Найти WireGuard контейнеры
  • Настроить мониторинг и уведомления
  • Установить systemd сервис для автозапуска
  • Протестировать всю конфигурацию

${YELLOW}Требования:${NC}
  • Linux с systemd
  • Docker (запущенный)
  • curl, bash 4.0+
  • Права root (sudo)

${YELLOW}GitHub:${NC} https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor

EOF
}

# Главная функция установки
main_install() {
    # Установка обработчика ошибок
    trap 'handle_error $LINENO' ERR
    
    print_header
    
    print_step "Начинаем интерактивную установку WireGuard Monitor"
    
    # Основные проверки
    check_root
    check_system
    
    # Интерактивная настройка
    configure_telegram
    detect_containers
    configure_advanced
    
    # Показываем итоговую конфигурацию
    show_configuration_summary
    
    # Установка
    create_config_file
    download_files
    setup_systemd
    
    # Тестирование
    if final_test; then
        show_completion_info
    else
        print_error "Тестирование не прошло. Проверьте настройки."
        print_info "Конфигурация сохранена в $CONFIG_FILE"
        print_info "Попробуйте: sudo $SCRIPT_PATH --test"
        exit 1
    fi
}

# Обработка аргументов командной строки
case "${1:-}" in
    --install|-i|"")
        main_install
        ;;
    --uninstall|-u)
        check_root
        uninstall
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    --version|-v)
        echo "$SCRIPT_NAME v$SCRIPT_VERSION"
        exit 0
        ;;
    *)
        print_error "Неизвестный параметр: $1"
        echo "Используйте --help для справки"
        exit 1
        ;;
esac
