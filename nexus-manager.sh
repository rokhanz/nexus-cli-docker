#!/usr/bin/env bash
set -euo pipefail

# Colors untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${YELLOW}🐛 DEBUG: $1${NC}"
    fi
}

# Function untuk retry dengan backoff
retry_with_backoff() {
    local max_attempts=$1
    local delay=$2
    local command="${@:3}"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_debug "Percobaan $attempt dari $max_attempts: $command"
        if eval "$command"; then
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log_warning "Percobaan $attempt gagal, menunggu ${delay}s sebelum mencoba lagi..."
            sleep $delay
            delay=$((delay * 2))  # Exponential backoff
        fi
        attempt=$((attempt + 1))
    done
    
    log_error "Semua percobaan gagal untuk: $command"
    return 1
}

# Function untuk validasi sistem
validate_system() {
    log_info "Memvalidasi sistem..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Tidak dapat mendeteksi OS. Script ini membutuhkan Linux."
        exit 1
    fi
    
    source /etc/os-release
    log_info "Terdeteksi OS: $PRETTY_NAME"
    
    # Check available space (minimal 10GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=$((10 * 1024 * 1024))  # 10GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_error "Ruang disk tidak cukup. Dibutuhkan minimal 10GB, tersedia: $((available_space / 1024 / 1024))GB"
        exit 1
    fi
    
    # Check memory (minimal 2GB)
    local available_memory=$(free -k | awk 'NR==2{print $2}')
    local required_memory=$((2 * 1024 * 1024))  # 2GB in KB
    
    if [[ $available_memory -lt $required_memory ]]; then
        log_warning "Memory kurang dari 2GB. Performa mungkin terdampak."
    fi
    
    log_success "Validasi sistem berhasil"
}

# Function untuk cleanup saat error
cleanup_on_error() {
    log_warning "Membersihkan resources karena error..."
    docker rm -f nexus-node 2>/dev/null || true
    screen -S nexus -X quit 2>/dev/null || true
}

# Trap untuk cleanup
trap cleanup_on_error ERR

# Banner
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                NEXUS CLI DOCKER MANAGER                       ║
║                                                               ║
║  ██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗ ║
║  ██╔══██╗██╔═══██╗██║ ██╔╝██║  ██║██╔══██╗████╗  ██║╚══███╔╝ ║
║  ██████╔╝██║   ██║█████╔╝ ███████║███████║██╔██╗ ██║  ███╔╝  ║
║  ██╔══██╗██║   ██║██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║ ███╔╝   ║
║  ██║  ██║╚██████╔╝██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗ ║
║  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝ ║
║                                                               ║
║                🚀 ALL-IN-ONE NEXUS MANAGER 🚀                ║
║                                                               ║
║              Install | Uninstall | Manage | Monitor          ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Setup direktori dan variabel
setup_environment() {
    WORKDIR="$HOME/nexus-cli-docker"
    ENV_FILE="$WORKDIR/.env"
    CONFIG_DIR="$HOME/.nexus"
    BASHRC="$HOME/.bashrc"
    SCREEN_SESSION="nexus"
    
    log_info "Direktori kerja: $WORKDIR"
    log_info "File environment: $ENV_FILE"
    log_info "Direktori config: $CONFIG_DIR"
    log_info "Screen session: $SCREEN_SESSION"
    
    # Buat direktori jika belum ada
    mkdir -p "$WORKDIR"
    mkdir -p "$CONFIG_DIR"
}

# Install screen jika belum ada
install_screen() {
    if ! command -v screen &> /dev/null; then
        log_info "Installing screen..."
        
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y screen
        elif command -v yum &> /dev/null; then
            yum install -y screen
        elif command -v dnf &> /dev/null; then
            dnf install -y screen
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm screen
        else
            log_error "Tidak dapat menginstall screen. Silakan install manual."
            exit 1
        fi
        
        log_success "Screen berhasil diinstall"
    else
        log_success "Screen sudah terinstall"
    fi
}

# Install Docker
install_docker() {
    log_info "🐳 Menginstall Docker secara otomatis..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        log_info "Terdeteksi sistem berbasis Debian/Ubuntu"
        retry_with_backoff 3 5 "apt-get update"
        apt-get install -y ca-certificates curl gnupg lsb-release
        
        install -m 0755 -d /etc/apt/keyrings
        retry_with_backoff 3 5 "curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.gpg"
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
            > /etc/apt/sources.list.d/docker.list
        
        retry_with_backoff 3 5 "apt-get update"
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        log_info "Terdeteksi sistem berbasis RedHat/CentOS"
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif command -v dnf &> /dev/null; then
        # Fedora
        log_info "Terdeteksi Fedora"
        dnf install -y dnf-plugins-core
        dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        log_info "Terdeteksi Arch Linux"
        pacman -Sy --noconfirm docker docker-compose
        
    else
        log_error "Package manager tidak didukung."
        exit 1
    fi
    
    # Start dan enable Docker service
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [[ $EUID -ne 0 ]]; then
        usermod -aG docker $USER
        log_warning "Logout dan login kembali untuk menggunakan Docker tanpa sudo"
    fi
    
    log_success "✅ Docker berhasil diinstall"
}

# Setup environment variables
setup_env() {
    # Setup auto-load .env di ~/.bashrc
    LOAD_SNIPPET="# Auto-load Nexus env
if [ -f \"$ENV_FILE\" ]; then 
    set -a
    source \"$ENV_FILE\"
    set +a
fi"

    if ! grep -q "Auto-load Nexus env" "$BASHRC" 2>/dev/null; then
        echo "" >> "$BASHRC"
        echo "$LOAD_SNIPPET" >> "$BASHRC"
        log_success "Menambahkan auto-load .env ke $BASHRC"
    fi

    # Load atau buat .env
    if [ -f "$ENV_FILE" ]; then
        log_info "Memuat environment dari $ENV_FILE"
        set -a
        source "$ENV_FILE"
        set +a
        
        # Validasi ulang environment variables
        if [[ -z "${WALLET_ADDRESS:-}" ]] || [[ -z "${NODE_ID:-}" ]]; then
            log_warning "Environment variables tidak lengkap, akan setup ulang..."
            rm -f "$ENV_FILE"
        fi
    fi

    if [ ! -f "$ENV_FILE" ]; then
        log_info "Setup konfigurasi environment..."
        
        # Validasi wallet address
        while true; do
            read -p "Masukkan WALLET_ADDRESS (0x...): " WALLET_ADDRESS
            if [[ $WALLET_ADDRESS =~ ^0x[a-fA-F0-9]{40}$ ]]; then
                log_success "Format wallet address valid"
                break
            else
                log_error "Format wallet address tidak valid. Harus 40 karakter hex dimulai dengan 0x"
            fi
        done
        
        # Input NODE_ID
        while true; do
            read -p "Masukkan NODE_ID: " NODE_ID
            if [[ -n "$NODE_ID" ]] && [[ ${#NODE_ID} -ge 3 ]]; then
                log_success "NODE_ID valid"
                break
            else
                log_error "NODE_ID harus minimal 3 karakter"
            fi
        done
        
        # Buat file .env
        cat > "$ENV_FILE" << EOF
# Nexus Node configuration - Generated $(date)
WALLET_ADDRESS=$WALLET_ADDRESS
NODE_ID=$NODE_ID
DEBUG=false
EOF
        chmod 600 "$ENV_FILE"
        
        # Export variables
        export WALLET_ADDRESS NODE_ID
        log_success "File $ENV_FILE berhasil dibuat"
    fi
}

# Build Docker image
build_docker_image() {
    log_info "Building nexus-cli:latest..."
    
    # Download Dockerfile dari repository atau buat inline
    DOCKERFILE_URL="https://raw.githubusercontent.com/rokhanz/nexus-cli-docker/main/Dockerfile"
    if retry_with_backoff 3 5 "curl -sf $DOCKERFILE_URL -o $WORKDIR/Dockerfile"; then
        log_success "Dockerfile berhasil didownload"
    else
        log_warning "Menggunakan inline Dockerfile"
        cat > "$WORKDIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.nexus/bin:$PATH"

RUN apt-get update && \
    apt-get install -y \
        curl \
        ca-certificates \
        wget \
        gnupg \
        lsb-release \
        iputils-ping \
        dnsutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN for i in 1 2 3; do \
        curl -sSf https://cli.nexus.xyz/ -o install.sh && break || sleep 10; \
    done && \
    chmod +x install.sh && \
    NONINTERACTIVE=1 ./install.sh && \
    rm install.sh

RUN mkdir -p /root/.nexus

WORKDIR /root

ENTRYPOINT ["nexus-network"]
CMD ["--help"]
EOF
    fi
    
    # Build image
    if ! retry_with_backoff 3 10 "docker build --pull --no-cache -t nexus-cli:latest $WORKDIR"; then
        log_error "Gagal build Docker image"
        exit 1
    fi
    
    log_success "nexus-cli:latest berhasil dibuild"
}

# Install Nexus
install_nexus() {
    show_banner
    log_info "🚀 Memulai instalasi Nexus CLI Docker..."
    
    validate_system
    setup_environment
    
    # Install dependencies
    install_screen
    
    # Check Docker installation
    if ! command -v docker &> /dev/null; then
        log_warning "Docker tidak terinstall, akan diinstall secara otomatis..."
        install_docker
    else
        log_success "Docker sudah terinstall"
    fi
    
    # Check Docker daemon
    if ! retry_with_backoff 5 3 "docker info >/dev/null 2>&1"; then
        log_error "Docker daemon tidak berjalan. Mencoba start Docker..."
        systemctl start docker
        sleep 5
        
        if ! docker info >/dev/null 2>&1; then
            log_error "Gagal menjalankan Docker daemon."
            exit 1
        fi
    fi
    
    # Setup environment
    setup_env
    
    # Clean up old containers
    log_info "🧹 Membersihkan container lama..."
    docker rm -f nexus-node 2>/dev/null || true
    screen -S $SCREEN_SESSION -X quit 2>/dev/null || true
    
    # Build Docker image
    build_docker_image
    
    # Register wallet
    log_info "Registering wallet $WALLET_ADDRESS..."
    docker run --rm -v "$CONFIG_DIR":/root/.nexus nexus-cli:latest \
        register-user --wallet-address "$WALLET_ADDRESS" 2>/dev/null || \
        log_warning "Wallet mungkin sudah terdaftar"
    
    # Setup config.json
    cat > "$CONFIG_DIR/config.json" << EOF
{
    "node_id": "$NODE_ID",
    "created_at": "$(date -Iseconds)",
    "wallet_address": "$WALLET_ADDRESS"
}
EOF
    
    log_success "✅ Instalasi Nexus CLI Docker berhasil!"
    log_info "Gunakan '$0 start' untuk menjalankan node"
}

# Start Nexus dalam screen session
start_nexus() {
    log_info "🚀 Memulai Nexus node dalam screen session..."
    
    # Load environment
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
    else
        log_error "File .env tidak ditemukan. Jalankan '$0 install' terlebih dahulu."
        exit 1
    fi
    
    # Check jika screen session sudah ada
    if screen -list | grep -q "$SCREEN_SESSION"; then
        log_warning "Screen session '$SCREEN_SESSION' sudah ada"
        read -p "Apakah ingin menghentikan session yang ada dan membuat yang baru? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            screen -S $SCREEN_SESSION -X quit 2>/dev/null || true
            log_info "Session lama dihentikan"
        else
            log_info "Gunakan 'screen -r $SCREEN_SESSION' untuk attach ke session yang ada"
            return 0
        fi
    fi
    
    # Stop container lama jika ada
    docker rm -f nexus-node 2>/dev/null || true
    
    # Start container dalam screen session
    log_info "Membuat screen session '$SCREEN_SESSION'..."
    screen -dmS $SCREEN_SESSION bash -c "
        echo 'Starting Nexus node in Docker container...'
        docker run --name nexus-node \
            --network host \
            --device /dev/net/tun \
            --cap-add NET_ADMIN \
            -v '$CONFIG_DIR':/root/.nexus \
            -v /etc/resolv.conf:/etc/resolv.conf:ro \
            --restart unless-stopped \
            nexus-cli:latest start --node-id '$NODE_ID'
    "
    
    sleep 3
    
    # Check status
    if screen -list | grep -q "$SCREEN_SESSION"; then
        log_success "✅ Nexus node berhasil dimulai dalam screen session '$SCREEN_SESSION'"
        log_info "📊 Gunakan 'screen -r $SCREEN_SESSION' untuk melihat output"
        log_info "📋 Gunakan '$0 status' untuk melihat status"
        log_info "⏹️  Gunakan '$0 stop' untuk menghentikan"
    else
        log_error "Gagal membuat screen session"
        exit 1
    fi
}

# Stop Nexus
stop_nexus() {
    log_info "⏹️  Menghentikan Nexus node..."
    
    # Stop Docker container
    if docker ps --filter "name=nexus-node" --filter "status=running" | grep -q nexus-node; then
        docker stop nexus-node
        log_success "Container nexus-node dihentikan"
    fi
    
    # Quit screen session
    if screen -list | grep -q "$SCREEN_SESSION"; then
        screen -S $SCREEN_SESSION -X quit
        log_success "Screen session '$SCREEN_SESSION' dihentikan"
    fi
    
    log_success "✅ Nexus node berhasil dihentikan"
}

# Show status
show_status() {
    log_info "📊 Status Nexus Node:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Docker container status
    if docker ps -a --filter "name=nexus-node" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -q nexus-node; then
        echo -e "${BLUE}Docker Container:${NC}"
        docker ps -a --filter "name=nexus-node" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    else
        echo -e "${YELLOW}Docker Container: Tidak ditemukan${NC}"
    fi
    
    echo
    
    # Screen session status
    if screen -list | grep -q "$SCREEN_SESSION"; then
        echo -e "${GREEN}Screen Session: Aktif ($SCREEN_SESSION)${NC}"
        echo -e "${BLUE}Gunakan 'screen -r $SCREEN_SESSION' untuk attach${NC}"
    else
        echo -e "${YELLOW}Screen Session: Tidak aktif${NC}"
    fi
    
    echo
    
    # Environment info
    if [ -f "$ENV_FILE" ]; then
        echo -e "${BLUE}Environment:${NC}"
        cat "$ENV_FILE" | grep -v "^#" | grep -v "^$"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Show logs
show_logs() {
    if docker ps --filter "name=nexus-node" | grep -q nexus-node; then
        log_info "📋 Menampilkan logs container nexus-node..."
        docker logs -f nexus-node
    else
        log_warning "Container nexus-node tidak berjalan"
        
        if screen -list | grep -q "$SCREEN_SESSION"; then
            log_info "Attach ke screen session untuk melihat output:"
            echo "screen -r $SCREEN_SESSION"
        fi
    fi
}

# Attach to screen session
attach_screen() {
    if screen -list | grep -q "$SCREEN_SESSION"; then
        log_info "Attaching ke screen session '$SCREEN_SESSION'..."
        log_info "Gunakan Ctrl+A+D untuk detach"
        screen -r $SCREEN_SESSION
    else
        log_warning "Screen session '$SCREEN_SESSION' tidak ditemukan"
        log_info "Gunakan '$0 start' untuk memulai node"
    fi
}

# Uninstall Nexus
uninstall_nexus() {
    log_warning "🗑️  Memulai uninstall Nexus CLI Docker..."
    
    read -p "Apakah Anda yakin ingin menghapus semua data Nexus? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall dibatalkan"
        return 0
    fi
    
    # Stop services
    stop_nexus
    
    # Remove Docker containers and images
    log_info "Menghapus Docker containers dan images..."
    docker rm -f nexus-node 2>/dev/null || true
    docker rmi nexus-cli:latest 2>/dev/null || true
    
    # Remove directories
    log_info "Menghapus direktori konfigurasi..."
    rm -rf "$WORKDIR" 2>/dev/null || true
    rm -rf "$CONFIG_DIR" 2>/dev/null || true
    
    # Remove auto-load from bashrc
    if grep -q "Auto-load Nexus env" "$BASHRC" 2>/dev/null; then
        log_info "Menghapus auto-load dari $BASHRC..."
        sed -i '/# Auto-load Nexus env/,+4d' "$BASHRC"
    fi
    
    # Clean up Docker system
    docker system prune -f 2>/dev/null || true
    
    log_success "✅ Uninstall Nexus CLI Docker berhasil!"
}

# Show help
show_help() {
    show_banner
    echo -e "${CYAN}PENGGUNAAN:${NC}"
    echo "  $0 [COMMAND]"
    echo
    echo -e "${CYAN}COMMANDS:${NC}"
    echo -e "  ${GREEN}install${NC}     - Install Nexus CLI Docker"
    echo -e "  ${GREEN}start${NC}       - Start Nexus node dalam screen session"
    echo -e "  ${GREEN}stop${NC}        - Stop Nexus node dan screen session"
    echo -e "  ${GREEN}restart${NC}     - Restart Nexus node"
    echo -e "  ${GREEN}status${NC}      - Tampilkan status Nexus node"
    echo -e "  ${GREEN}logs${NC}        - Tampilkan logs Nexus node"
    echo -e "  ${GREEN}attach${NC}      - Attach ke screen session"
    echo -e "  ${GREEN}uninstall${NC}   - Uninstall Nexus CLI Docker"
    echo -e "  ${GREEN}help${NC}        - Tampilkan help ini"
    echo
    echo -e "${CYAN}CONTOH:${NC}"
    echo "  $0 install      # Install Nexus"
    echo "  $0 start        # Start node"
    echo "  $0 status       # Lihat status"
    echo "  screen -r nexus # Attach ke screen session"
    echo "  $0 stop         # Stop node"
    echo
}

# Main function
main() {
    # Setup environment variables
    setup_environment
    
    case "${1:-help}" in
        "install")
            install_nexus
            ;;
        "start")
            start_nexus
            ;;
        "stop")
            stop_nexus
            ;;
        "restart")
            stop_nexus
            sleep 2
            start_nexus
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "attach")
            attach_screen
            ;;
        "uninstall")
            uninstall_nexus
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Command tidak dikenal: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
