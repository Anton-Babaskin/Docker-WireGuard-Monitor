# 🤝 Contributing to WireGuard Monitor

First off, thanks for taking the time to contribute! 🎉

This document provides guidelines and information about contributing to the WireGuard Docker Monitor project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## 📜 Code of Conduct

This project and everyone participating in it is governed by our commitment to creating a welcoming and inclusive environment. By participating, you are expected to uphold this standard.

### Our Standards

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome newcomers and help them get started
- **Be collaborative**: Work together and share knowledge
- **Be patient**: Help others learn and grow

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Linux environment** (Ubuntu 20.04+, CentOS 8+, or Debian 11+)
- **Bash 4.4+** - `bash --version`
- **Docker 20.04+** - `docker --version`
- **Git** - `git --version`
- **Basic shell scripting knowledge**

### Development Tools

Install these tools for development:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y shellcheck bats curl jq

# CentOS/RHEL
sudo yum install -y epel-release
sudo yum install -y ShellCheck bats curl jq
```

## 🛠️ How to Contribute

### 🐛 Reporting Bugs

1. **Check existing issues** first to avoid duplicates
2. **Use the bug report template** when creating new issues
3. **Provide detailed information**:
   - OS and version
   - Docker version
   - WireGuard container details
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs

### ✨ Suggesting Features

1. **Check the roadmap** in GitHub Projects
2. **Use the feature request template**
3. **Explain the use case** and benefits
4. **Provide examples** if possible

### 📚 Improving Documentation

Documentation improvements are always welcome:

- Fix typos and grammar
- Add examples and use cases
- Improve clarity and organization
- Add translations (future)

## 💻 Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/Docker-WireGuard-Monitor.git
cd Docker-WireGuard-Monitor

# Add upstream remote
git remote add upstream https://github.com/Anton-Babaskin/Docker-WireGuard-Monitor.git
```

### 2. Set Up Development Environment

```bash
# Create test containers
docker run -d --name test-wg-1 --privileged linuxserver/wireguard:latest
docker run -d --name test-wg-2 --privileged linuxserver/wireguard:latest

# Create test configuration
cat > /tmp/test-telemon.env << EOF
BOT_TOKEN="123456789:TEST_TOKEN_FOR_DEVELOPMENT"
CHAT_ID="123456789"
WG_CONTAINERS="test-wg-1 test-wg-2"
WG_IFACE="wg0"
THRESHOLD=300
LOG_LEVEL="DEBUG"
EOF
```

### 3. Run Tests

```bash
# Syntax check
bash -n wg_telemon
bash -n install.sh

# Code quality
shellcheck wg_telemon install.sh

# Functional test (without Telegram)
WG_MONITOR_CONFIG=/tmp/test-telemon.env ./wg_telemon --help
```

## 📝 Coding Standards

### Bash Scripting Standards

1. **Follow ShellCheck recommendations** - Zero warnings required
2. **Use `set -euo pipefail`** at script beginning
3. **Quote variables** - Use `"$variable"` not `$variable`
4. **Use functions** for code organization
5. **Add error handling** for all operations
6. **Document functions** with comments

### Code Style

```bash
# ✅ Good
local container_name="$1"
if [[ -n "$container_name" ]]; then
    log "INFO" "Processing container: $container_name"
fi

# ❌ Bad  
container_name=$1
if [ ! -z $container_name ]; then
    echo Processing container: $container_name
fi
```

### Documentation Standards

1. **Use clear, concise language**
2. **Include examples** for complex concepts
3. **Update CHANGELOG.md** for all changes
4. **Add inline comments** for complex logic
5. **Use emoji consistently** in documentation

## 🧪 Testing

### Manual Testing

Before submitting changes:

```bash
# Test configuration validation
./wg_telemon --test

# Test with debug logging
./wg_telemon --log-level DEBUG

# Test different scenarios
# - Container down
# - Interface issues
# - Network problems
```

### Test Scenarios

Ensure your changes work with:

- ✅ Single container setup
- ✅ Multiple containers
- ✅ Different WireGuard interfaces
- ✅ Various threshold values
- ✅ Network connectivity issues
- ✅ Docker daemon restarts
- ✅ Invalid configurations

## 📤 Submitting Changes

### 1. Create Feature Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 2. Make Changes

- **Follow coding standards**
- **Add tests** for new functionality
- **Update documentation** as needed
- **Update CHANGELOG.md**

### 3. Commit Guidelines

Use conventional commit messages:

```bash
# Feature
git commit -m "feat: add multi-interface support"

# Bug fix
git commit -m "fix: handle docker daemon restart properly"

# Documentation
git commit -m "docs: update installation guide with troubleshooting"

# Refactor
git commit -m "refactor: improve error handling in telegram sender"
```

### 4. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create Pull Request on GitHub
# Use the PR template and fill in all sections
```

## 🔄 Pull Request Process

### PR Requirements

- [ ] **All tests pass** (will be checked by CI)
- [ ] **Code follows style guidelines**
- [ ] **Documentation is updated**
- [ ] **CHANGELOG.md is updated**
- [ ] **No breaking changes** (or clearly documented)

### Review Process

1. **Automated checks** run first (CI/CD)
2. **Maintainer review** for code quality and design
3. **Testing** in different environments
4. **Approval and merge**

## 🎯 Development Priorities

### High Priority

- 🐛 **Bug fixes** - Always highest priority
- 🔒 **Security issues** - Critical fixes
- 📊 **Performance improvements** - Resource optimization
- 📚 **Documentation** - Clarity and completeness

### Medium Priority

- ✨ **New features** - Enhance functionality
- 🔧 **Code improvements** - Refactoring and cleanup
- 🧪 **Test coverage** - Improve reliability

### Future Goals

- 🌐 **Web dashboard** - Visual monitoring interface
- 📊 **Metrics export** - Prometheus integration  
- 🔌 **Plugin system** - Extensible architecture
- 🌍 **Internationalization** - Multi-language support

## 📞 Getting Help

### Communication Channels

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Questions and community support
- **Pull Requests** - Code reviews and collaboration

### Maintainer Contact

- **GitHub**: @Anton-Babaskin
- **Response time**: Usually within 48 hours

## 🏆 Recognition

Contributors will be:

- **Listed in CONTRIBUTORS.md** (coming soon)
- **Mentioned in release notes** for significant contributions
- **Invited as collaborators** for sustained contributions

## 📚 Resources

### Learning Resources

- [Advanced Bash Scripting Guide](https://tldp.org/LDP/abs/html/)
- [ShellCheck Documentation](https://github.com/koalaman/shellcheck/wiki)
- [Docker Documentation](https://docs.docker.com/)
- [WireGuard Documentation](https://www.wireguard.com/quickstart/)

### Development Tools

- **ShellCheck** - Bash linting
- **BATS** - Bash testing framework
- **GitHub CLI** - Command-line GitHub integration
- **VSCode** - Recommended editor with bash extensions

---

Thank you for contributing to WireGuard Monitor! 🛡️✨

Your contributions help make WireGuard monitoring better for everyone in the community.
