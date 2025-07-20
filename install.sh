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
║                    NEXUS CLI DOCKER INSTALLER                ║
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
║  This installer will help you set up Nexus node with Docker  ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root for Docker installation
if [[ $EUID -eq 0 ]]; then
    log_warning "Running as root. This is fine for Docker installation."
fi

# Check if .env exists
if [[ ! -f ".env" ]]; then
    log_info "Setting up environment configuration..."
    
    # Validate wallet address format
    while true; do
        read -p "Enter your WALLET_ADDRESS (0x...): " WALLET_ADDRESS
        if [[ $WALLET_ADDRESS =~ ^0x[a-fA-F0-9]{40}$ ]]; then
            break
        else
            log_error "Invalid wallet address format. Must be 40 hex characters starting with 0x"
        fi
    done
    
    # Get node ID
    read -p "Enter your NODE_ID: " NODE_ID
    
    # Create .env file
    cat > .env << EOF
# Nexus Node Configuration
WALLET_ADDRESS=$WALLET_ADDRESS
NODE_ID=$NODE_ID
EOF
    
    chmod 600 .env
    log_success "Environment configuration saved to .env"
else
    log_info "Using existing .env configuration"
    source .env
fi

# Check Docker installation
if ! command -v docker &> /dev/null; then
    log_info "Docker not found. Installing Docker..."
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Update package index
        apt-get update
        
        # Install dependencies
        apt-get install -y ca-certificates curl gnupg lsb-release
        
        # Add Docker GPG key
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        
        # Install Docker
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        log_success "Docker installed successfully"
    else
        log_error "Unsupported OS. Please install Docker manually."
        exit 1
    fi
else
    log_success "Docker is already installed"
fi

# Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    log_error "Docker daemon is not running. Please start Docker first."
    exit 1
fi

# Function to check and update Nexus CLI
update_nexus_cli() {
    log_info "Checking for Nexus CLI updates..."
    
    NEXUS_DIR="$HOME/.nexus"
    NEXUS_BIN="$NEXUS_DIR/bin/nexus-network"
    
    if [[ -f "$NEXUS_BIN" ]]; then
        log_info "Existing Nexus CLI found, checking version..."
        
        # Get current version (if available)
        CURRENT_VERSION=$($NEXUS_BIN --version 2>/dev/null | head -n1 || echo "unknown")
        log_info "Current version: $CURRENT_VERSION"
        
        # Check if update is available by trying to download latest
        log_info "Downloading latest Nexus CLI..."
        
        # Backup current installation
        if [[ -d "$NEXUS_DIR" ]]; then
            BACKUP_DIR="$NEXUS_DIR.backup.$(date +%Y%m%d_%H%M%S)"
            log_info "Creating backup at $BACKUP_DIR"
            cp -r "$NEXUS_DIR" "$BACKUP_DIR"
        fi
        
        # Download and install latest version
        cd /tmp
        curl -sSf https://cli.nexus.xyz/ -o nexus-install.sh
        chmod +x nexus-install.sh
        
        if NONINTERACTIVE=1 ./nexus-install.sh; then
            NEW_VERSION=$($NEXUS_BIN --version 2>/dev/null | head -n1 || echo "updated")
            log_success "Nexus CLI updated successfully to: $NEW_VERSION"
            rm -f nexus-install.sh
        else
            log_warning "Update failed, restoring backup..."
            if [[ -d "$BACKUP_DIR" ]]; then
                rm -rf "$NEXUS_DIR"
                mv "$BACKUP_DIR" "$NEXUS_DIR"
                log_info "Backup restored successfully"
            fi
            rm -f nexus-install.sh
        fi
    else
        log_info "No existing Nexus CLI found, will install fresh version"
    fi
}

# Check for updates
read -p "Check for Nexus CLI updates? (y/n): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    update_nexus_cli
else
    log_info "Skipping Nexus CLI update check"
fi

# Build Docker image
log_info "Building Nexus CLI Docker image..."
docker build -t nexus-cli:latest .
log_success "Docker image built successfully"

# Setup configuration directory
CONFIG_DIR="$HOME/.nexus"
mkdir -p "$CONFIG_DIR"

# Register wallet
log_info "Registering wallet..."
if docker run --rm -v "$CONFIG_DIR":/root/.nexus nexus-cli:latest register-user --wallet-address "$WALLET_ADDRESS" 2>/dev/null; then
    log_success "Wallet registered successfully"
else
    log_warning "Wallet might already be registered, continuing..."
fi

# Create config.json
cat > "$CONFIG_DIR/config.json" << EOF
{"node_id":"$NODE_ID"}
EOF

log_success "Installation completed!"
echo
log_info "You can now run:"
echo "  • ./run-nexus.sh          - Run with original script"
echo "  • docker-compose up -d    - Run in background"
echo "  • docker-compose --profile interactive up  - Run interactively"
echo
log_info "To check logs: docker logs -f nexus-node"
