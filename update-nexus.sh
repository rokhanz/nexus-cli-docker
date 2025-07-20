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
echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                     NEXUS CLI UPDATER                        ║
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
║            Keep your Nexus CLI up to date!                   ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Configuration
NEXUS_DIR="$HOME/.nexus"
NEXUS_BIN="$NEXUS_DIR/bin/nexus-network"
BACKUP_DIR="$NEXUS_DIR.backup.$(date +%Y%m%d_%H%M%S)"

# Function to get current version
get_current_version() {
    if [[ -f "$NEXUS_BIN" ]]; then
        $NEXUS_BIN --version 2>/dev/null | head -n1 || echo "unknown"
    else
        echo "not installed"
    fi
}

# Function to backup current installation
backup_installation() {
    if [[ -d "$NEXUS_DIR" ]]; then
        log_info "Creating backup at $BACKUP_DIR"
        cp -r "$NEXUS_DIR" "$BACKUP_DIR"
        log_success "Backup created successfully"
        return 0
    else
        log_warning "No existing installation to backup"
        return 1
    fi
}

# Function to restore backup
restore_backup() {
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Restoring backup from $BACKUP_DIR"
        rm -rf "$NEXUS_DIR"
        mv "$BACKUP_DIR" "$NEXUS_DIR"
        log_success "Backup restored successfully"
    else
        log_error "No backup found to restore"
    fi
}

# Function to download and install latest Nexus CLI
install_latest() {
    log_info "Downloading latest Nexus CLI..."
    
    # Change to temp directory
    cd /tmp
    
    # Download installer
    if curl -sSf https://cli.nexus.xyz/ -o nexus-install.sh; then
        chmod +x nexus-install.sh
        log_success "Installer downloaded successfully"
    else
        log_error "Failed to download installer"
        return 1
    fi
    
    # Run installer
    log_info "Installing Nexus CLI..."
    if NONINTERACTIVE=1 ./nexus-install.sh; then
        log_success "Nexus CLI installed successfully"
        rm -f nexus-install.sh
        return 0
    else
        log_error "Installation failed"
        rm -f nexus-install.sh
        return 1
    fi
}

# Function to update Docker image
update_docker_image() {
    log_info "Updating Docker image..."
    
    if docker build --pull -t nexus-cli:latest . 2>/dev/null; then
        log_success "Docker image updated successfully"
    else
        log_warning "Failed to update Docker image (this is normal if not using Docker)"
    fi
}

# Function to restart containers
restart_containers() {
    log_info "Restarting Nexus containers..."
    
    # Stop existing containers
    docker stop nexus-node 2>/dev/null || true
    docker rm nexus-node 2>/dev/null || true
    
    # Restart with docker-compose if available
    if [[ -f "docker-compose.yml" ]]; then
        docker-compose down 2>/dev/null || true
        docker-compose up -d 2>/dev/null || true
        log_success "Containers restarted with docker-compose"
    else
        log_info "No docker-compose.yml found, manual restart may be needed"
    fi
}

# Main update process
main() {
    log_info "Starting Nexus CLI update process..."
    
    # Get current version
    CURRENT_VERSION=$(get_current_version)
    log_info "Current version: $CURRENT_VERSION"
    
    # Confirm update
    echo
    read -p "Do you want to proceed with the update? (y/n): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Update cancelled by user"
        exit 0
    fi
    
    # Create backup
    BACKUP_CREATED=false
    if backup_installation; then
        BACKUP_CREATED=true
    fi
    
    # Install latest version
    if install_latest; then
        NEW_VERSION=$(get_current_version)
        log_success "Update completed successfully!"
        log_info "Previous version: $CURRENT_VERSION"
        log_info "New version: $NEW_VERSION"
        
        # Update Docker image
        update_docker_image
        
        # Ask about restarting containers
        echo
        read -p "Restart Docker containers? (y/n): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            restart_containers
        fi
        
        # Clean up backup if successful
        if [[ $BACKUP_CREATED == true ]]; then
            read -p "Remove backup? (y/n): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$BACKUP_DIR"
                log_success "Backup removed"
            else
                log_info "Backup kept at: $BACKUP_DIR"
            fi
        fi
        
    else
        log_error "Update failed!"
        
        # Restore backup if available
        if [[ $BACKUP_CREATED == true ]]; then
            read -p "Restore backup? (y/n): " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                restore_backup
            fi
        fi
        
        exit 1
    fi
    
    echo
    log_success "Nexus CLI update process completed!"
    log_info "You can now run your Nexus node with the latest version"
}

# Run main function
main "$@"
