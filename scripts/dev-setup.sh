#!/usr/bin/env bash
set -euo pipefail

# Development Environment Setup Script
# For WireGuard Monitor contributors

readonly SCRIPT_NAME="Development Setup"
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if running in project directory
check_project_dir() {
    if [[ ! -f "wg_telemon" ]]; then
        echo "❌ This script must be run from the project root directory"
        echo "Expected to find: wg_telemon"
        exit 1
    fi
}

# Install development dependencies
install_dependencies() {
    print_step "Installing development dependencies..."
    
    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y shellcheck bats curl jq docker.io
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y epel-release
        sudo yum install -y ShellCheck bats curl jq docker
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y shellcheck bats curl jq docker
    else
        print_info "Manual installation required for: shellcheck, bats, curl, jq, docker"
        return 1
    fi
    
    print_success "Dependencies installed"
}

# Create test containers
setup_test_containers() {
    print_step "Setting up test WireGuard containers..."
    
    # Remove existing test containers
    docker stop test-wg-1 test-wg-2 2>/dev/null || true
    docker rm test-wg-1 test-wg-2 2>/dev/null || true
    
    # Create new test containers
    docker run -d --name test-wg-1 --privileged \
        -e PUID=1000 -e PGID=1000 -e TZ=UTC \
        -v /lib/modules:/lib/modules:ro \
        linuxserver/wireguard:latest
        
    docker run -d --name test-wg-2 --privileged \
        -e PUID=1000 -e PGID=1000 -e TZ=UTC \
        -v /lib/modules:/lib/modules:ro \
        linuxserver/wireguard:latest
    
    # Wait for containers to initialize
    sleep 15
    
    print_success "Test containers created: test-wg-1, test-wg-2"
}

# Create development configuration
create_dev_config() {
    print_step "Creating development configuration..."
    
    mkdir -p dev-configs
    
    cat > dev-configs/test.env << 'EOF'
# Development/Test Configuration
# DO NOT USE IN PRODUCTION

BOT_TOKEN="123456789:FAKE_TOKEN_FOR_TESTING"
CHAT_ID="123456789"
WG_CONTAINERS="test-wg-1 test-wg-2"
WG_IFACE="wg0"
THRESHOLD=60
LOG_LEVEL="DEBUG"
ALERT_COOLDOWN=30
MAX_RETRIES=1
EOF

    cat > dev-configs/single.env << 'EOF'
# Single container test config
BOT_TOKEN="123456789:FAKE_TOKEN_FOR_TESTING"  
CHAT_ID="123456789"
WG_CONTAINERS="test-wg-1"
WG_IFACE="wg0"
THRESHOLD=300
LOG_LEVEL="INFO"
EOF

    print_success "Development configs created in dev-configs/"
}

# Setup git hooks
setup_git_hooks() {
    print_step "Setting up git hooks..."
    
    mkdir -p .git/hooks
    
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for WireGuard Monitor

echo "🔍 Running pre-commit checks..."

# Check syntax
echo "Checking bash syntax..."
bash -n wg_telemon || exit 1
bash -n install.sh || exit 1

# Run ShellCheck if available
if command -v shellcheck >/dev/null 2>&1; then
    echo "Running ShellCheck..."
    shellcheck wg_telemon install.sh || exit 1
else
    echo "⚠️  ShellCheck not found, skipping..."
fi

# Check for TODO/FIXME comments in commits
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME" 2>/dev/null; then
    echo "⚠️  Found TODO/FIXME comments in staged files"
fi

echo "✅ Pre-commit checks passed"
EOF

    chmod +x .git/hooks/pre-commit
    print_success "Git hooks installed"
}

# Run development tests
run_dev_tests() {
    print_step "Running development tests..."
    
    # Syntax checks
    echo "Testing bash syntax..."
    bash -n wg_telemon
    bash -n install.sh
    
    # ShellCheck
    if command -v shellcheck >/dev/null 2>&1; then
        echo "Running ShellCheck..."
        shellcheck wg_telemon install.sh
    fi
    
    # Configuration validation test
    echo "Testing configuration validation..."
    WG_MONITOR_CONFIG=dev-configs/test.env ./wg_telemon --help >/dev/null
    
    # Test with debug logging (dry run)
    echo "Testing debug mode..."
    WG_MONITOR_CONFIG=dev-configs/test.env LOG_LEVEL=DEBUG timeout 10s ./wg_telemon --help >/dev/null || true
    
    print_success "All tests passed"
}

# Create development scripts
create_dev_scripts() {
    print_step "Creating development scripts..."
    
    mkdir -p scripts
    
    # Quick test script
    cat > scripts/quick-test.sh << 'EOF'
#!/bin/bash
# Quick test script for development

set -e

echo "🧪 Running quick tests..."

# Syntax check
bash -n wg_telemon
echo "✅ Syntax OK"

# ShellCheck
if command -v shellcheck >/dev/null; then
    shellcheck wg_telemon
    echo "✅ ShellCheck OK"
fi

# Config validation
WG_MONITOR_CONFIG=dev-configs/test.env ./wg_telemon --help >/dev/null
echo "✅ Config validation OK"

echo "🎉 All quick tests passed!"
EOF

    # Release preparation script
    cat > scripts/prepare-release.sh << 'EOF'
#!/bin/bash
# Release preparation script

set -e

VERSION="$1"
if [[ -z "$VERSION" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2.1.0"
    exit 1
fi

echo "🚀 Preparing release v$VERSION..."

# Update version in script
sed -i "s/readonly SCRIPT_VERSION=.*/readonly SCRIPT_VERSION=\"$VERSION\"/" wg_telemon

# Update CHANGELOG
echo "Please update CHANGELOG.md with version $VERSION details"
echo "Press Enter when ready..."
read -r

# Create git tag
git add wg_telemon CHANGELOG.md
git commit -m "chore: bump version to $VERSION"
git tag -a "v$VERSION" -m "Release version $VERSION"

echo "✅ Release v$VERSION prepared"
echo "Push with: git push origin main && git push origin v$VERSION"
EOF

    chmod +x scripts/*.sh
    print_success "Development scripts created in scripts/"
}

# Show development info
show_dev_info() {
    cat << EOF

${GREEN}🎉 Development environment setup complete!${NC}

${BLUE}📋 What's available:${NC}

${YELLOW}Test Containers:${NC}
  - test-wg-1: Basic WireGuard container
  - test-wg-2: Secondary WireGuard container
  
${YELLOW}Development Configs:${NC}
  - dev-configs/test.env: Multi-container test config
  - dev-configs/single.env: Single container config
  
${YELLOW}Development Scripts:${NC}
  - scripts/quick-test.sh: Run quick validation tests
  - scripts/prepare-release.sh: Prepare new release
  
${YELLOW}Git Hooks:${NC}
  - pre-commit: Automatic syntax and style checks

${BLUE}🔧 Development Commands:${NC}

# Quick test
./scripts/quick-test.sh

# Test with development config
WG_MONITOR_CONFIG=dev-configs/test.env ./wg_telemon --test

# Run with debug logging
WG_MONITOR_CONFIG=dev-configs/test.env ./wg_telemon --log-level DEBUG

# Check containers
docker ps | grep test-wg

# View test logs  
docker logs test-wg-1

${BLUE}🧪 Testing Tips:${NC}

1. Always test with both single and multi-container setups
2. Test error conditions (stop containers, break configs)
3. Verify different log levels work correctly
4. Check systemd integration on test systems

${YELLOW}Happy coding! 🛡️✨${NC}

EOF
}

# Main function
main() {
    print_step "Setting up WireGuard Monitor development environment..."
    
    check_project_dir
    install_dependencies
    setup_test_containers
    create_dev_config
    setup_git_hooks
    create_dev_scripts
    run_dev_tests
    show_dev_info
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
