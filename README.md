# 🛡️ WireGuard Docker Monitor - Enhanced

[![CI](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/actions)
[![Security](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/workflows/Security%20Scan/badge.svg)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/security)
[![Release](https://img.shields.io/github/v/release/Anton-Babaskin/Docker-WireGuard-Monitor)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/releases)
[![Downloads](https://img.shields.io/github/downloads/Anton-Babaskin/Docker-WireGuard-Monitor/total)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/releases)



[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.4%2B-orange.svg)](https://www.gnu.org/software/bash/)

A comprehensive monitoring solution for WireGuard servers running in Docker containers with intelligent Telegram alerting, advanced diagnostics, and enterprise-grade features.

## 🚀 Features

### Core Monitoring
- 🐳 **Multi-container support** - Monitor multiple WireGuard containers simultaneously
- 🔍 **Comprehensive health checks** - Container status, interface state, and peer connectivity
- ⏱️ **Configurable handshake monitoring** - Alert on stale or missing peer handshakes
- 🩺 **Docker health check integration** - Monitor container health status

### Advanced Alerting
- 📱 **Smart Telegram notifications** - Rich formatted messages with markdown support
- 🔄 **Alert cooldown system** - Prevents notification spam with configurable intervals
- 🎯 **Severity levels** - Different alert types (ERROR, WARN, INFO) with appropriate icons
- 🔁 **Retry mechanism** - Automatic retry for failed Telegram deliveries

### Enterprise Features
- 📊 **Detailed logging** - Structured logging with rotation and multiple levels
- 🔒 **Security hardened** - Runs with minimal privileges and secure systemd configuration
- 🏥 **Health check endpoint** - External monitoring system integration
- 📈 **Statistics tracking** - Alert counters and performance metrics

### Operational Excellence
- 🧪 **Configuration testing** - Validate setup before deployment
- 🛠️ **Advanced debugging** - Comprehensive diagnostic information
- 📝 **Template system** - Customizable alert message formats
- 🔧 **Flexible configuration** - Environment-based configuration with validation

## 📋 Requirements

- **Operating System**: Linux with systemd support
- **Docker**: Version 20.04+ with running daemon
- **Bash**: Version 4.4 or higher
- **Network**: Internet access for Telegram API
- **Privileges**: Root access for systemd integration

### Dependencies
- `curl` - For Telegram API communication
- `docker` - Container management
- `systemd` - Service scheduling and management

## 🔧 Installation

### 1. Clone Repository

```bash
git clone https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor.git /opt/wg-monitor
cd /opt/wg-monitor
```

### 2. Create Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` and follow the instructions
3. Save the bot token (format: `123456789:ABCdefGhIjKlmnoPQRsTUVwxyz`)
4. Get your chat ID from `@userinfobot` or add bot to group

### 3. Configure Environment

```bash
# Copy configuration template
sudo cp telemon.env /etc/telemon.env

# Edit configuration
sudo nano /etc/telemon.env

# Set secure permissions
sudo chmod 600 /etc/telemon.env
sudo chown root:root /etc/telemon.env
```

**Minimum required configuration:**
```bash
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="123456789"
WG_CONTAINERS="wireguard"
THRESHOLD=300
```

### 4. Install Script

```bash
# Copy script to system location
sudo cp wg_telemon.sh /usr/local/bin/wg_telemon.sh
sudo chmod +x /usr/local/bin/wg_telemon.sh

# Create log directory
sudo mkdir -p /var/log
sudo touch /var/log/wg-monitor.log
```

### 5. Install Systemd Units

```bash
# Copy systemd files
sudo cp wg-telemon.service /etc/systemd/system/
sudo cp wg-telemon.timer /etc/systemd/system/

# Reload systemd and enable
sudo systemctl daemon-reload
sudo systemctl enable wg-telemon.timer
sudo systemctl start wg-telemon.timer
```

### 6. Verify Installation

```bash
# Test configuration
sudo /usr/local/bin/wg_telemon.sh --test

# Check systemd status
sudo systemctl status wg-telemon.timer
sudo systemctl status wg-telemon.service

# View logs
sudo journalctl -u wg-telemon.service -f
```

## ⚙️ Configuration

### Basic Configuration

The `/etc/telemon.env` file contains all configuration options:

```bash
# Essential settings
BOT_TOKEN="your-telegram-bot-token"
CHAT_ID="your-chat-id"
WG_CONTAINERS="container1 container2"  # Space-separated
WG_IFACE="wg0"                          # Interface name
THRESHOLD=300                           # Seconds before alert

# Advanced settings
LOG_LEVEL="INFO"                        # DEBUG, INFO, WARN, ERROR
ALERT_COOLDOWN=3600                     # Seconds between repeat alerts
MAX_RETRIES=3                           # Telegram delivery retries
```

### Multi-Container Setup

Monitor multiple WireGuard containers:

```bash
WG_CONTAINERS="wg-server-1 wg-server-2 wg-client-mobile"
THRESHOLD=300
ALERT_COOLDOWN=1800
```

### Advanced Monitoring

Configure strict monitoring for production:

```bash
WG_CONTAINERS="wg-production"
THRESHOLD=180                           # 3-minute threshold
LOG_LEVEL="DEBUG"                       # Detailed logging
ALERT_COOLDOWN=900                      # 15-minute cooldown
MAX_RETRIES=5                           # More retry attempts
```

## 🎯 Usage

### Manual Execution

```bash
# Run with default configuration
sudo /usr/local/bin/wg_telemon.sh

# Run with debug logging
sudo /usr/local/bin/wg_telemon.sh --log-level DEBUG

# Test configuration and send test message
sudo /usr/local/bin/wg_telemon.sh --test

# Health check
sudo /usr/local/bin/wg_telemon.sh --health
```

### Systemd Management

```bash
# Start monitoring
sudo systemctl start wg-telemon.timer

# Stop monitoring
sudo systemctl stop wg-telemon.timer

# Check status
sudo systemctl status wg-telemon.timer

# View recent logs
sudo journalctl -u wg-telemon.service -n 50

# Follow logs in real-time
sudo journalctl -u wg-telemon.service -f
```

### Command Line Options

```bash
Usage: wg_telemon.sh [OPTIONS]

OPTIONS:
    -c, --config FILE     Configuration file (default: /etc/telemon.env)
    -l, --log-level LEVEL Log level: DEBUG, INFO, WARN, ERROR
    -h, --health          Run health check and exit
    -t, --test            Test configuration and send test message
    -v, --version         Show version information
    --help                Show detailed help message
```

## 📊 Alert Types

### Container Alerts 🐳
- **Container not running**: Critical alert when container is stopped or crashed
- **Container health failure**: Warning when health checks fail
- **Container missing**: Error when specified container doesn't exist

### Interface Alerts 🌐
- **Interface down**: Critical alert when WireGuard interface is not UP
- **Interface missing**: Error when WireGuard interface doesn't exist
- **Configuration issues**: Warning for interface configuration problems

### Peer Alerts 🔒
- **Stale handshakes**: Warning when peer handshakes exceed threshold
- **Never connected**: Info about peers that have never established connection
- **Connection statistics**: Summary of peer connectivity status

### Example Alert Messages

```
🚨 WireGuard Monitor Alert

🖥️ Host: production-server
🕐 Time: 2024-08-26 15:30:25
📊 Level: ERROR

🐳 Container `wireguard` is not running!
📊 Status: exited (Exit code: 1)
```

```
⚠️ WireGuard Monitor Alert

🖥️ Host: production-server
🕐 Time: 2024-08-26 15:35:10
📊 Level: WARN

🔒 WireGuard handshake issues in `wireguard/wg0`:

⏰ Stale handshakes: 2 peer(s)

📊 Summary:
• Total peers: 5
• Active peers: 3
• Threshold: 300s
```

## 🔧 Troubleshooting

### Common Issues

**1. Permission Denied**
```bash
# Fix script permissions
sudo chmod +x /usr/local/bin/wg_telemon.sh

# Fix config permissions
sudo chmod 600 /etc/telemon.env
sudo chown root:root /etc/telemon.env
```

**2. Docker Connection Issues**
```bash
# Verify Docker is running
sudo systemctl status docker

# Check Docker socket permissions
sudo ls -la /var/run/docker.sock

# Test Docker access
sudo docker ps
```

**3. Telegram Bot Issues**
```bash
# Test bot token manually
curl -s "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"

# Test message sending
curl -s -X POST "https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage" \
     -d "chat_id=<YOUR_CHAT_ID>" \
     -d "text=Test message"
```

**4. Configuration Validation**
```bash
# Run configuration test
sudo /usr/local/bin/wg_telemon.sh --test

# Check configuration syntax
sudo bash -n /etc/telemon.env

# View current configuration
sudo cat /etc/telemon.env
```

### Log Analysis

```bash
# View systemd logs
sudo journalctl -u wg-telemon.service --since "1 hour ago"

# View application logs
sudo tail -f /var/log/wg-monitor.log

# Check for errors only
sudo grep ERROR /var/log/wg-monitor.log

# Monitor in real-time with filtering
sudo journalctl -u wg-telemon.service -f | grep -E "(ERROR|WARN)"
```

### Debugging Steps

1. **Verify basic functionality**:
   ```bash
   sudo /usr/local/bin/wg_telemon.sh --test
   ```

2. **Enable debug logging**:
   ```bash
   sudo /usr/local/bin/wg_telemon.sh --log-level DEBUG
   ```

3. **Check container access**:
   ```bash
   sudo docker exec your-container wg show
   ```

4. **Validate network connectivity**:
   ```bash
   curl -I https://api.telegram.org
   ```

## 📈 Monitoring Integration

### External Health Checks

The monitor creates a health check file that external systems can monitor:

```bash
# Check health file
cat /tmp/wg-monitor-health

# Integration example (monitoring script)
if [[ $(find /tmp/wg-monitor-health -mmin -5 2>/dev/null) ]]; then
    echo "WireGuard monitor is healthy"
else
    echo "WireGuard monitor may be down"
fi
```

### Prometheus Integration

Example Prometheus configuration for systemd monitoring:

```yaml
- job_name: 'systemd-wg-monitor'
  static_configs:
    - targets: ['localhost:9100']
  params:
    collect[]:
      - systemd
  relabel_configs:
    - source_labels: [__name__]
      regex: 'node_systemd_unit_state'
      target_label: __name__
      replacement: 'systemd_unit_state'
    - source_labels: [name]
      regex: 'wg-telemon.*'
      action: keep
```

### Grafana Dashboard

Key metrics to monitor:
- Timer execution frequency
- Service success/failure rate
- Alert delivery status
- Container health status
- Peer connectivity statistics

## 🔄 Maintenance

### Log Rotation

The script automatically manages log rotation, keeping the last 1000 entries. For manual log management:

```bash
# Manual log rotation
sudo logrotate -f /etc/logrotate.d/wg-monitor

# Example logrotate configuration
cat << EOF | sudo tee /etc/logrotate.d/wg-monitor
/var/log/wg-monitor.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
```

### Updates

```bash
# Update from repository
cd /opt/wg-monitor
git pull origin main

# Update script
sudo cp wg_telemon.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/wg_telemon.sh

# Update systemd files if changed
sudo cp *.service *.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart wg-telemon.timer
```

### Backup Configuration

```bash
# Create configuration backup
sudo cp /etc/telemon.env /etc/telemon.env.backup

# Include in system backup
sudo tar -czf /backup/wg-monitor-config.tar.gz \
    /etc/telemon.env \
    /etc/systemd/system/wg-telemon.* \
    /usr/local/bin/wg_telemon.sh
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone for development
git clone https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor.git
cd Docker-WireGuard-Monitor

# Install development dependencies
sudo apt-get install shellcheck bats

# Run tests
bats tests/

# Lint code
shellcheck wg_telemon.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Original WireGuard project by Jason A. Donenfeld
- Docker community for containerization best practices
- Telegram Bot API documentation and community
- systemd documentation and examples

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/discussions)
- **Email**: [support@example.com](mailto:me@fy-consulting.com)

---

<div align="center">

**[⭐ Star this repository](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor) if you find it useful!**

Made with ❤️ for the WireGuard community

</div>
