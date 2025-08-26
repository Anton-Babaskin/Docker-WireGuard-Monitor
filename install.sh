#!/usr/bin/env bash
set -euo pipefail

# WireGuard Monitor - Automated Installation Script
# Version 2.0

readonly SCRIPT_NAME="WireGuard Monitor Installer"
readonly SCRIPT_VERSION="2.0"
readonly REPO_URL="https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Installation paths
readonly INSTALL_DIR="/opt/wg-monitor"
readonly CONFIG_FILE="/etc/telemon.env"
readonly SCRIPT_PATH="/usr/local/bin/wg_telemon.sh"
readonly SERVICE_FILE="/etc/systemd/system/wg-telemon.service"
readonly TIMER_FILE="/etc/systemd/system/wg-telemon.timer"
readonly LOG_FILE="/var/log/wg-monitor.log"

# Print functions
print_header() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    🛡️  WireGuard Monitor Installer                          ║
║                                                                              ║
║  Enhanced monitoring solution for WireGuard Docker containers               ║
║  with intelligent Telegram alerting and enterprise features                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Version: $SCRIPT_VERSION${NC}"
    echo
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

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_info "Please run: sudo $0"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    local missing_deps=()
    
    # Check for required commands
    local required_commands=("curl" "docker" "systemctl" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install missing dependencies and run again"
        
        # Provide installation hints
        if command -v apt-get >/dev/null 2>&1; then
            print_info "Ubuntu/Debian: sudo apt-get update && sudo apt-get install ${missing_deps[*]}"
        elif command -v yum >/dev/null 2>&1; then
            print_info "CentOS/RHEL: sudo yum install ${missing_deps[*]}"
        elif command -v dnf >/dev/null 2>&1; then
            print_info "Fedora: sudo dnf install ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker version >/dev/null 2>&1; then
        print_error "Docker daemon is not running"
        print_info "Please start Docker: sudo systemctl start docker"
        exit 1
    fi
    
    # Check systemd
    if ! systemctl --version >/dev/null 2>&1; then
        print_error "systemd is not available"
        exit 1
    fi
    
    print_success "All requirements satisfied"
}

# Download or update repository
setup_repository() {
    print_step "Setting up repository..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        print_info "Directory $INSTALL_DIR already exists"
        cd "$INSTALL_DIR"
        
        if [[ -d ".git" ]]; then
            print_step "Updating existing installation..."
            git pull origin main || {
                print_warning "Failed to update repository, continuing with existing files"
            }
        else
            print_warning "Directory exists but is not a git repository"
        fi
    else
        print_step "Cloning repository..."
        git clone "$REPO_URL" "$INSTALL_DIR" || {
            print_error "Failed to clone repository"
            exit 1
        }
        cd "$INSTALL_DIR"
    fi
    
    print_success "Repository setup completed"
}

# Interactive configuration
configure_interactive() {
    print_step "Starting interactive configuration..."
    echo
    
    # Telegram Bot Token
    echo -e "${CYAN}📱 Telegram Configuration${NC}"
    echo "You need to create a Telegram bot and get the bot token."
    echo "1. Open Telegram and search for @BotFather"
    echo "2. Send /newbot and follow instructions"
    echo "3. Copy the bot token (format: 123456789:ABCdefGhIjKlmnoPQRsTUVwxyz)"
    echo
    
    local bot_token
    while true; do
        read -rp "Enter your Telegram Bot Token: " bot_token
        if [[ "$bot_token" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
            break
        else
            print_error "Invalid bot token format. Please try again."
        fi
    done
    
    # Chat ID
    echo
    echo "Get your Chat ID:"
    echo "• For personal chat: send a message to @userinfobot"
    echo "• For group chat: add bot to group and use negative ID"
    echo
    
    local chat_id
    while true; do
        read -rp "Enter your Chat ID: " chat_id
        if [[ "$chat_id" =~ ^-?[0-9]+$ ]]; then
            break
        else
            print_error "Chat ID must be numeric. Please try again."
        fi
    done
    
    # Container configuration
    echo
    echo -e "${CYAN}🐳 Container Configuration${NC}"
    
    # Show available containers
    print_info "Available Docker containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -E "(wireguard|wg)" || {
        print_warning "No WireGuard containers found running"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    }
    echo
    
    local containers
    read -rp "Enter container name(s) (space-separated for multiple): " containers
    [[ -z "$containers" ]] && containers="wireguard"
    
    # Interface configuration
    local interface
    read -rp "Enter WireGuard interface name [wg0]: " interface
    [[ -z "$interface" ]] && interface="wg0"
    
    # Threshold configuration
    echo
    echo "Handshake threshold options:"
    echo "• 180 (3 minutes) - Very strict monitoring"
    echo "• 300 (5 minutes) - Strict monitoring (recommended)"
    echo "• 600 (10 minutes) - Normal monitoring"
    echo "• 1800 (30 minutes) - Relaxed monitoring"
    
    local threshold
    read -rp "Enter handshake threshold in seconds [300]: " threshold
    [[ -z "$threshold" ]] && threshold="300"
    
    # Advanced options
    echo
    read -rp "Do you want to configure advanced options? (y/N): " advanced
    
    local log_level="INFO"
    local alert_cooldown="3600"
    local max_retries="3"
    
    if [[ "$advanced" =~ ^[Yy] ]]; then
        echo
        echo "Log levels: DEBUG, INFO, WARN, ERROR"
        read -rp "Enter log level [INFO]: " log_level
        [[ -z "$log_level" ]] && log_level="INFO"
        
        read -rp "Enter alert cooldown in seconds [3600]: " alert_cooldown
        [[ -z "$alert_cooldown" ]] && alert_cooldown="3600"
        
        read -rp "Enter max retries for Telegram [3]: " max_retries
        [[ -z "$max_retries" ]] && max_retries="3"
    fi
    
    # Create configuration file
    print_step "Creating configuration file..."
    
    cat > "$CONFIG_FILE" << EOF
# WireGuard Monitor Configuration
# Generated by installer on $(date)

# Telegram settings
BOT_TOKEN="$bot_token"
CHAT_ID="$chat_id"

# Container settings
WG_CONTAINERS="$containers"
WG_IFACE="$interface"
THRESHOLD=$threshold

# Advanced settings
LOG_LEVEL="$log_level"
ALERT_COOLDOWN=$alert_cooldown
MAX_RETRIES=$max_retries

# Additional settings can be configured manually
# See telemon.env.example for all available options
EOF
    
    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    
    print_success "Configuration file created: $CONFIG_FILE"
}

# Install files
install_files() {
    print_step "Installing script and systemd files..."
    
    # Install main script
    cp wg_telemon.sh "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    chown root:root "$SCRIPT_PATH"
    
    # Install systemd files
    cp wg-telemon.service "$SERVICE_FILE"
    cp wg-telemon.timer "$TIMER_FILE"
    chown root:root "$SERVICE_FILE" "$TIMER_FILE"
    
    # Create log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    chown root:root "$LOG_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    print_success "Files installed successfully"
}

# Test configuration
test_configuration() {
    print_step "Testing configuration..."
    
    # Test script execution
    if "$SCRIPT_PATH" --test; then
        print_success "Configuration test passed"
    else
        print_error "Configuration test failed"
        print_info "Please check your configuration in $CONFIG_FILE"
        return 1
    fi
    
    return 0
}

# Enable and start service
enable_service() {
    print_step "Enabling and starting service..."
    
    # Enable timer
    systemctl enable wg-telemon.timer
    systemctl start wg-telemon.timer
    
    # Check status
    if systemctl is-active --quiet wg-telemon.timer; then
        print_success "Service enabled and started successfully"
    else
        print_error "Failed to start service"
        systemctl status wg-telemon.timer --no-pager
        return 1
    fi
    
    return 0
}

# Show post-installation info
show_completion() {
    echo
    print_success "Installation completed successfully!"
    echo
    echo -e "${CYAN}📋 What's next?${NC}"
    echo
    echo "1. 📊 Check service status:"
    echo "   sudo systemctl status wg-telemon.timer"
    echo
    echo "2. 📝 View logs:"
    echo "   sudo journalctl -u wg-telemon.service -f"
    echo
    echo "3. 🔧 Manual test run:"
    echo "   sudo $SCRIPT_PATH --test"
    echo
    echo "4. ⚙️ Edit configuration:"
    echo "   sudo nano $CONFIG_FILE"
    echo
    echo "5. 📖 View documentation:"
    echo "   less $INSTALL_DIR/README.md"
    echo
    
    print_info "Service runs every 2 minutes and will monitor your WireGuard containers"
    print_info "You should receive a test message in Telegram shortly"
    echo
    
    echo -e "${GREEN}🎉 Happy monitoring!${NC}"
}

# Handle errors
handle_error() {
    local line_number=$1
    print_error "Installation failed at line $line_number"
    print_info "Check the error messages above for details"
    print_info "You can run the installer again after fixing any issues"
    exit 1
}

# Main installation function
main() {
    # Set error trap
    trap 'handle_error $LINENO' ERR
    
    print_header
    
    print_step "Starting installation process..."
    echo
    
    check_root
    check_requirements
    setup_repository
    
    # Check if this is an update
    if [[ -f "$CONFIG_FILE" ]]; then
        print_info "Existing configuration found"
        read -rp "Do you want to reconfigure? (y/N): " reconfigure
        
        if [[ "$reconfigure" =~ ^[Yy] ]]; then
            configure_interactive
        else
            print_info "Using existing configuration"
        fi
    else
        configure_interactive
    fi
    
    install_files
    
    if test_configuration; then
        enable_service
        show_completion
    else
        print_error "Installation completed but configuration test failed"
        print_info "Please check your configuration and run: sudo $SCRIPT_PATH --test"
        exit 1
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Enhanced WireGuard Monitor Installer v$SCRIPT_VERSION"
    echo
    echo "OPTIONS:"
    echo "  --help, -h    Show this help message"
    echo "  --version     Show version information"
    echo "  --uninstall   Uninstall the monitor"
    echo
    echo "The installer will guide you through the setup process interactively."
}

# Uninstall function
uninstall() {
    print_step "Uninstalling WireGuard Monitor..."
    
    # Stop and disable service
    systemctl stop wg-telemon.timer 2>/dev/null || true
    systemctl disable wg-telemon.timer 2>/dev/null || true
    
    # Remove files
    rm -f "$SCRIPT_PATH" "$SERVICE_FILE" "$TIMER_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Ask about configuration and logs
    read -rp "Remove configuration file $CONFIG_FILE? (y/N): " remove_config
    if [[ "$remove_config" =~ ^[Yy] ]]; then
        rm -f "$CONFIG_FILE"
        print_info "Configuration file removed"
    fi
    
    read -rp "Remove log file $LOG_FILE? (y/N): " remove_logs
    if [[ "$remove_logs" =~ ^[Yy] ]]; then
        rm -f "$LOG_FILE"
        print_info "Log file removed"
    fi
    
    read -rp "Remove installation directory $INSTALL_DIR? (y/N): " remove_dir
    if [[ "$remove_dir" =~ ^[Yy] ]]; then
        rm -rf "$INSTALL_DIR"
        print_info "Installation directory removed"
    fi
    
    print_success "Uninstallation completed"
}

# Parse arguments
case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    --version)
        echo "$SCRIPT_NAME v$SCRIPT_VERSION"
        exit 0
        ;;
    --uninstall)
        check_root
        uninstall
        exit 0
        ;;
    "")
        # No arguments, run main installation
        main
        ;;
    *)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
esac
