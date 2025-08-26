---
name: 🐛 Bug Report
about: Create a report to help us improve WireGuard Monitor
title: '[BUG] '
labels: 'bug'
assignees: ''

---

## 🐛 Bug Description
A clear and concise description of what the bug is.

## 📋 Environment
- **OS**: [e.g. Ubuntu 22.04, CentOS 8]
- **Docker Version**: [e.g. 20.10.21]  
- **Bash Version**: [run `bash --version`]
- **WireGuard Monitor Version**: [e.g. 2.0.0]
- **WireGuard Container**: [container name and image]

## 🔄 Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Run command '....'
4. See error

## ✅ Expected Behavior
A clear and concise description of what you expected to happen.

## ❌ Actual Behavior  
A clear and concise description of what actually happened.

## 📸 Screenshots/Logs
If applicable, add screenshots or log output to help explain your problem.

```bash
# Add relevant log output here
sudo journalctl -u wg-telemon.service -n 50
```

## ⚙️ Configuration
Please provide your configuration (remove sensitive data like bot tokens):

```bash
# /etc/telemon.env (redacted)
WG_CONTAINERS="your-container"
WG_IFACE="wg0"
THRESHOLD=300
LOG_LEVEL="INFO"
```

## 🔍 Additional Context
Add any other context about the problem here.

## ✨ Possible Solution
If you have ideas on how to fix this, please describe them here.
