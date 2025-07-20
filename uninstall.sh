#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Banner
echo -e "${RED}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                   NEXUS CLI DOCKER UNINSTALLER               ║
║                                                               ║
║  ██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗ ║
║  ██╔══██╗██╔═══██╗██║ ██╔╝██║  ██║██╔══██╗████╗  ██║╚══███╔╝ ║
║  ██████╔╝██║   ██║█████╔╝ ███████║███████║██╔██╗ ██║  ███╔╝  ║
║  ██╔══██╗██║   ██║██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║ ███╔╝   ║
║  ██║  ██║╚██████╔╝██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗ ║
║  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝ ║
║                                                               ║
║                    🚀 www.github.com/rokhanz 🚀              ║
║                                                               ║
║              ⚠️  This will remove all Nexus data  ⚠️          ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Confirmation
echo -e "${YELLOW}This will remove:${NC}"
echo "  • All Nexus Docker containers"
echo "  • Nexus Docker images"
echo "  • Nexus configuration directory (~/.nexus)"
echo "  • Environment files (.env)"
echo

read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log_info "Uninstallation cancelled."
    exit 0
fi

echo

# Stop and remove containers
log_info "Stopping and removing Nexus containers..."
docker stop nexus-node nexus-interactive 2>/dev/null || true
docker rm nexus-node nexus-interactive 2>/dev/null || true
docker-compose down 2>/dev/null || true
log_success "Containers removed"

# Remove Docker images
log_info "Removing Nexus Docker images..."
docker rmi nexus-cli:latest 2>/dev/null || true
log_success "Docker images removed"

# Remove configuration directory
if [[ -d "$HOME/.nexus" ]]; then
    log_info "Removing Nexus configuration directory..."
    rm -rf "$HOME/.nexus"
    log_success "Configuration directory removed"
fi

# Remove work directory
if [[ -d "nexus-cli-docker" ]]; then
    log_info "Removing work directory..."
    rm -rf nexus-cli-docker
    log_success "Work directory removed"
fi

# Remove environment file (with confirmation)
if [[ -f ".env" ]]; then
    read -p "Remove .env file? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm .env
        log_success "Environment file removed"
    else
        log_info "Environment file kept"
    fi
fi

# Remove auto-load from bashrc
BASHRC="$HOME/.bashrc"
if [[ -f "$BASHRC" ]]; then
    log_info "Removing auto-load from ~/.bashrc..."
    sed -i '/# Auto-load Nexus env/,+1d' "$BASHRC" 2>/dev/null || true
    log_success "Auto-load removed from ~/.bashrc"
fi

# Clean up Docker system (optional)
read -p "Run Docker system cleanup? (y/n): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Running Docker system cleanup..."
    docker system prune -f
    log_success "Docker system cleaned"
fi

echo
log_success "Nexus CLI Docker has been completely uninstalled!"
log_info "You may need to restart your terminal for bashrc changes to take effect."
