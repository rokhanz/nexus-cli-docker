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

# ROKHANZ Banner
echo -e "${BLUE}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                    NEXUS CLI DOCKER RUNNER                   ║
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
║              Original All-in-One Nexus Runner                ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ————————————————————————————————————————————— 
# 0) Pastikan .env auto‐load di ~/.bashrc
BASHRC="$HOME/.bashrc"
LOAD_SNIPPET='if [ -f "$HOME/nexus-cli-docker/.env" ]; then export $(grep -v "^\s*#" "$HOME/nexus-cli-docker/.env" | xargs); fi'
if ! grep -Fxq "$LOAD_SNIPPET" "$BASHRC"; then
  {
    echo ""
    echo "# Auto-load Nexus env"
    echo "$LOAD_SNIPPET"
  } >> "$BASHRC"
  log_success "Added auto-load of .env to $BASHRC"
fi

# 1) Direktori kerja & file env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="$SCRIPT_DIR/nexus-cli-docker"
ENV_FILE="$WORKDIR/.env"
CONFIG_DIR="$HOME/.nexus"

# 2) Load atau buat .env
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^\s*#' "$ENV_FILE" | xargs)
  log_success "Loaded env from $ENV_FILE"
else
  log_info "Setting up environment configuration..."
  
  # Validate wallet address format
  while true; do
    read -p "Masukkan WALLET_ADDRESS (0x...): " WALLET_ADDRESS
    if [[ $WALLET_ADDRESS =~ ^0x[a-fA-F0-9]{40}$ ]]; then
      break
    else
      log_error "Invalid wallet address format. Must be 40 hex characters starting with 0x"
    fi
  done
  
  read -p "Masukkan NODE_ID: " NODE_ID
  mkdir -p "$WORKDIR"
  cat > "$ENV_FILE" << EOF
# Nexus Node configuration
WALLET_ADDRESS=$WALLET_ADDRESS
NODE_ID=$NODE_ID
EOF
  chmod 600 "$ENV_FILE"
  export WALLET_ADDRESS NODE_ID
  log_success "Created $ENV_FILE"
fi

# —————————————————————————————————————————————
# 3) Install Docker & Compose plugin jika belum ada
if ! command -v docker &> /dev/null; then
  log_info "Installing Docker & compose plugin..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release
  install -m0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  log_success "Docker & compose plugin installed"
else
  log_success "Docker is already installed"
fi

# Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
  log_error "Docker daemon is not running. Please start Docker first."
  exit 1
fi

# —————————————————————————————————————————————
# 4) Stop & remove old container
docker rm -f nexus-node 2>/dev/null || true
log_success "Old nexus-node container removed"

# —————————————————————————————————————————————
# 5) Build (rebuild) image nexus-cli:latest
log_info "Building nexus-cli:latest (with --pull)..."
mkdir -p "$WORKDIR"

# Use existing Dockerfile if available, otherwise create inline
if [[ -f "$SCRIPT_DIR/Dockerfile" ]]; then
  log_info "Using existing Dockerfile from repository"
  docker build --pull -t nexus-cli:latest "$SCRIPT_DIR"
else
  log_info "Creating inline Dockerfile"
  cat > "$WORKDIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl ca-certificates && \
    curl -sSf https://cli.nexus.xyz/ -o install.sh && \
    chmod +x install.sh && \
    NONINTERACTIVE=1 ./install.sh && \
    rm install.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
ENV PATH="/root/.nexus/bin:$PATH"
ENTRYPOINT ["nexus-network"]
EOF
  docker build --pull -t nexus-cli:latest "$WORKDIR"
fi
log_success "nexus-cli:latest built successfully"

# —————————————————————————————————————————————
# 6) Setup config dir & register wallet
mkdir -p "$CONFIG_DIR"
log_info "Registering wallet $WALLET_ADDRESS..."
if ! docker run --rm -v "$CONFIG_DIR":/root/.nexus nexus-cli:latest \
     register-user --wallet-address "$WALLET_ADDRESS" 2>/dev/null; then
  log_warning "Wallet might already be registered, continuing..."
else
  log_success "Wallet registered successfully"
fi

# 7) Tulis config.json agar non-interaktif
cat > "$CONFIG_DIR/config.json" << EOF
{"node_id":"$NODE_ID"}
EOF
log_success "Configuration file created"

# —————————————————————————————————————————————
# 8) Jalankan headless node detached
log_info "Starting Nexus node in background..."
docker run -d --name nexus-node \
  --network host \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  -v "$CONFIG_DIR":/root/.nexus \
  -v /etc/resolv.conf:/etc/resolv.conf:ro \
  --restart unless-stopped \
  nexus-cli:latest start --node-id "$NODE_ID"

echo
log_success "Nexus node is now running in background (container: nexus-node)"
log_info "View logs with: docker logs -f nexus-node"
log_info "Stop node with: docker stop nexus-node"
echo

# —————————————————————————————————————————————
# 9) Jalankan debug interaktif + TUI
log_info "Starting interactive mode for debugging and monitoring..."
echo -e "${YELLOW}Press Ctrl+C to exit interactive mode${NC}"
echo

docker run --rm -it \
  --entrypoint /bin/sh \
  -v "$CONFIG_DIR":/root/.nexus \
  --network host \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --dns 8.8.8.8 \
  nexus-cli:latest -c "
    echo -e '${BLUE}→ Health-check orchestrator:${NC}' 
    curl -sS -w ' %{http_code}\\n' https://production.orchestrator.nexus.xyz/v3/health
    sleep 2
    echo -e '${BLUE}→ Ping orchestrator:${NC}' 
    ping -c3 production.orchestrator.nexus.xyz
    sleep 2
    echo -e '${BLUE}→ Configuration directory contents:${NC}' 
    ls -la /root/.nexus
    sleep 2
    echo -e '${GREEN}→ Starting Nexus CLI in interactive mode...${NC}'
    for i in 1 2 3 4 5; do
      dots=\$(printf '%*s' \"\$((i % 4))\" '' | tr ' ' '.')
      printf \"\\r${YELLOW}Loading Nexus CLI\$dots${NC}\"
      sleep 0.5
    done
    echo
    echo -e '${GREEN}✅ Ready! Starting interactive Nexus node...${NC}'
    echo
    exec nexus-network start --node-id $NODE_ID
  "

echo
log_success "Interactive session completed"
log_info "Background node is still running. Use 'docker logs -f nexus-node' to monitor"
log_info "ROKHANZ Nexus CLI Docker setup completed! 🚀"
