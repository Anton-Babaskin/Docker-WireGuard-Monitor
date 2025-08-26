# 📚 Configuration Examples

This document provides various configuration examples for different use cases of the WireGuard Monitor.

## 🏠 Basic Home Setup

Perfect for home users monitoring a single WireGuard container:

```bash
# /etc/telemon.env - Basic home configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="123456789"
WG_CONTAINERS="wireguard"
WG_IFACE="wg0"
THRESHOLD=600
LOG_LEVEL="INFO"
```

**Monitoring frequency**: Every 2 minutes  
**Alert threshold**: 10 minutes of no handshake  
**Use case**: Home VPN server with occasional disconnections acceptable

---

## 🏢 Small Business Setup

For small businesses requiring more responsive monitoring:

```bash
# /etc/telemon.env - Small business configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="-987654321"  # Group chat
WG_CONTAINERS="wg-office wg-remote"
WG_IFACE="wg0"
THRESHOLD=300
LOG_LEVEL="INFO"
ALERT_COOLDOWN=1800
MAX_RETRIES=3
```

**Features**:
- Multiple container monitoring
- Group notifications
- 5-minute alert threshold
- 30-minute cooldown to prevent spam

---

## 🏭 Enterprise Production Setup

High-availability setup with comprehensive monitoring:

```bash
# /etc/telemon.env - Enterprise configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="-123456789"
WG_CONTAINERS="wg-primary wg-secondary wg-backup"
WG_IFACE="wg0"
THRESHOLD=180
LOG_LEVEL="WARN"
ALERT_COOLDOWN=900
MAX_RETRIES=5
```

**Features**:
- Multiple redundant containers
- Very strict 3-minute threshold
- Reduced logging for performance
- 15-minute cooldown
- Enhanced retry mechanism

---

## 🌐 Multi-Site Setup

For organizations with multiple locations:

```bash
# /etc/telemon.env - Multi-site configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="-555666777"
WG_CONTAINERS="wg-site-ny wg-site-la wg-site-chicago"
WG_IFACE="wg0"
THRESHOLD=240
LOG_LEVEL="INFO"
ALERT_COOLDOWN=2700
```

**Features**:
- Site-specific container naming
- 4-minute threshold for inter-site connectivity
- 45-minute cooldown for distributed alerts

---

## 🧪 Development/Testing Setup

For development environments with detailed logging:

```bash
# /etc/telemon.env - Development configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="123456789"
WG_CONTAINERS="wg-dev wg-test wg-staging"
WG_IFACE="wg0"
THRESHOLD=120
LOG_LEVEL="DEBUG"
ALERT_COOLDOWN=300
MAX_RETRIES=1
```

**Features**:
- Very aggressive 2-minute threshold
- Debug logging for troubleshooting
- Short cooldown for rapid feedback
- Minimal retries for fast failure detection

---

## 🔧 Custom Interface Setup

For non-standard WireGuard interface configurations:

```bash
# /etc/telemon.env - Custom interface configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="123456789"
WG_CONTAINERS="wg-vpn"
WG_IFACE="vpn0"  # Custom interface name
THRESHOLD=300
LOG_LEVEL="INFO"
```

**Use case**: Systems using custom interface naming schemes

---

## 🔄 High-Frequency Monitoring

For critical systems requiring very frequent checks:

### systemd Timer Override

Create `/etc/systemd/system/wg-telemon.timer.d/override.conf`:

```ini
[Timer]
# Override default timing
OnBootSec=30s
OnUnitActiveSec=30s
AccuracySec=5s
```

### Configuration

```bash
# /etc/telemon.env - High-frequency configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="-111222333"
WG_CONTAINERS="wg-critical"
WG_IFACE="wg0"
THRESHOLD=90
LOG_LEVEL="WARN"
ALERT_COOLDOWN=600
```

**Features**:
- 30-second monitoring interval
- 90-second handshake threshold
- 10-minute alert cooldown

---

## 📱 Mobile Client Monitoring

Optimized for monitoring mobile WireGuard clients:

```bash
# /etc/telemon.env - Mobile client configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="123456789"
WG_CONTAINERS="wg-mobile"
WG_IFACE="wg0"
THRESHOLD=1800  # 30 minutes
LOG_LEVEL="INFO"
ALERT_COOLDOWN=7200  # 2 hours
```

**Rationale**: Mobile devices frequently disconnect, so longer thresholds prevent false alarms.

---

## 🏥 Healthcare/Critical Infrastructure

For environments requiring immediate alerting:

```bash
# /etc/telemon.env - Critical infrastructure configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="-444555666"
WG_CONTAINERS="wg-critical-1 wg-critical-2"
WG_IFACE="wg0"
THRESHOLD=60  # 1 minute
LOG_LEVEL="INFO"
ALERT_COOLDOWN=300  # 5 minutes
MAX_RETRIES=10
```

**Features**:
- Ultra-strict 1-minute threshold
- Short cooldown for rapid re-alerting
- Maximum retry attempts
- Multiple redundant containers

---

## 🌙 Low-Maintenance Setup

For systems with minimal administrative attention:

```bash
# /etc/telemon.env - Low-maintenance configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="123456789"
WG_CONTAINERS="wireguard"
WG_IFACE="wg0"
THRESHOLD=3600  # 1 hour
LOG_LEVEL="WARN"  # Only warnings and errors
ALERT_COOLDOWN=14400  # 4 hours
```

**Features**:
- Very relaxed threshold
- Minimal logging
- Long cooldown to reduce notification frequency

---

## 🔐 Security-Focused Setup

Enhanced monitoring with security considerations:

```bash
# /etc/telemon.env - Security-focused configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="-777888999"
WG_CONTAINERS="wg-secure"
WG_IFACE="wg0"
THRESHOLD=300
LOG_LEVEL="INFO"
ALERT_COOLDOWN=1800
MAX_RETRIES=3

# Security enhancements
EXTENDED_PEER_INFO="false"  # Don't expose peer details
STARTUP_NOTIFICATION="false"  # Silent startup
```

**File Permissions**:
```bash
# Secure the configuration file
sudo chmod 600 /etc/telemon.env
sudo chown root:root /etc/telemon.env

# Secure log file
sudo chmod 640 /var/log/wg-monitor.log
sudo chown root:adm /var/log/wg-monitor.log
```

---

## 🎯 Troubleshooting Configuration

For debugging connectivity issues:

```bash
# /etc/telemon.env - Troubleshooting configuration
BOT_TOKEN="123456789:ABCdefGhIjKlmnoPQRsTUVwxyz"
CHAT_ID="123456789"
WG_CONTAINERS="wg-debug"
WG_IFACE="wg0"
THRESHOLD=60
LOG_LEVEL="DEBUG"
ALERT_COOLDOWN=60  # Very short for testing
MAX_RETRIES=1

# Enable additional diagnostics
EXTENDED_PEER_INFO="true"
STARTUP_NOTIFICATION="true"
```

**Commands for debugging**:
```bash
# Test configuration
sudo /usr/local/bin/wg_telemon.sh --test

# Run with debug output
sudo /usr/local/bin/wg_telemon.sh --log-level DEBUG

# Monitor logs in real-time
sudo tail -f /var/log/wg-monitor.log

# Check systemd status
sudo systemctl status wg-telemon.service
```

---

## 🏗️ Template for New Installations

Copy and customize this template:

```bash
# /etc/telemon.env - Template configuration
# Replace values with your specific settings

# === REQUIRED SETTINGS ===
BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
CHAT_ID="YOUR_CHAT_ID_HERE"
WG_CONTAINERS="YOUR_CONTAINER_NAME_HERE"

# === BASIC SETTINGS ===
WG_IFACE="wg0"
THRESHOLD=300

# === OPTIONAL SETTINGS ===
LOG_LEVEL="INFO"
ALERT_COOLDOWN=3600
MAX_RETRIES=3

# === ADVANCED SETTINGS (uncomment if needed) ===
# EXTENDED_PEER_INFO="false"
# STARTUP_NOTIFICATION="false"
# RECOVERY_NOTIFICATION="true"
```

---

## 📋 Configuration Validation Checklist

Before deploying any configuration:

- [ ] **Bot Token**: Valid format with correct permissions
- [ ] **Chat ID**: Numeric and accessible by the bot
- [ ] **Container Names**: Match actual Docker container names
- [ ] **Interface**: Correct WireGuard interface name
- [ ] **Threshold**: Appropriate for your use case
- [ ] **Permissions**: Configuration file is secured (600 permissions)
- [ ] **Testing**: Run test command successfully
- [ ] **Monitoring**: Service starts and runs without errors

---

## 🔄 Migration Guide

### From Version 1.x to 2.x

1. **Backup existing configuration**:
   ```bash
   sudo cp /etc/telemon.env /etc/telemon.env.v1.backup
   ```

2. **Update container specification**:
   ```bash
   # Old format (still supported)
   WG_CONTAINER="wireguard"
   
   # New format (preferred)
   WG_CONTAINERS="wireguard"
   ```

3. **Test new configuration**:
   ```bash
   sudo /usr/local/bin/wg_telemon.sh --test
   ```

4. **Restart service**:
   ```bash
   sudo systemctl restart wg-telemon.timer
   ```

---

## 📞 Support

If you need help with configuration:

1. **Check the logs**: `sudo journalctl -u wg-telemon.service -n 50`
2. **Test your config**: `sudo /usr/local/bin/wg_telemon.sh --test`
3. **Validate syntax**: `sudo bash -n /etc/telemon.env`
4. **Open an issue**: [GitHub Issues](https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor/issues)

Remember to remove sensitive information (tokens, chat IDs) when sharing configurations for support!
