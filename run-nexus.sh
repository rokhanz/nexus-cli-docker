#!/usr/bin/env bash
set -euo pipefail

# ASCII Banner
echo -e ""
echo -e "$(cat << 'EOF'
\033[90m$$$$$$$\   $$$$$$\  $$\   $$\ $$\   $$\  $$$$$$\  $$\   $$\ $$$$$$$$\\
\033[90m$$  __$$\ $$  __$$\ $$ | $$  |$$ |  $$ |$$  __$$\ $$$\  $$ |\____$$  |
\033[37m$$ |  $$ |$$ /  $$ |$$ |$$  / $$ |  $$ |$$ /  $$ |$$$$\ $$ |    $$  / 
\033[37m$$$$$$$  |$$ |  $$ |$$$$$  /  $$$$$$$$ |$$$$$$$$ |$$ $$\$$ |   $$  /  
\033[97m$$  __$$< $$ |  $$ |$$  $$<   $$  __$$ |$$  __$$ |$$ \$$$$ |  $$  /   
\033[97m$$ |  $$ |$$ |  $$ |$$ |\\$$\  $$ |  $$ |$$ |  $$ |$$ |\$$$ | $$  /    
\033[97m$$ |  $$ | $$$$$$  |$$ | \\$$\ $$ |  $$ |$$ |  $$ |$$ | \\$$ |$$$$$$$$\\
\033[0m\\__|  \\__| \\______/ \\__|  \\__|\\__|  \\__|\\__|  \\__|\\__|  \\__|\\________|
EOF
)"

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
  echo "🗸 Added auto-load of .env to $BASHRC"
fi

# 1) Direktori kerja & file env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="$SCRIPT_DIR/nexus-cli-docker"
ENV_FILE="$WORKDIR/.env"
CONFIG_DIR="$HOME/.nexus"

# 2) Load atau buat .env
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^\s*#' "$ENV_FILE" | xargs)
  echo "🗸 Loaded env from $ENV_FILE"
else
  read -p "Masukkan WALLET_ADDRESS: " WALLET_ADDRESS
  read -p "Masukkan NODE_ID       : " NODE_ID
  mkdir -p "$WORKDIR"
  cat > "$ENV_FILE" << EOF
# Nexus Node configuration
WALLET_ADDRESS=$WALLET_ADDRESS
NODE_ID=$NODE_ID
EOF
  chmod 600 "$ENV_FILE"
  export WALLET_ADDRESS NODE_ID
  echo "✅ Created $ENV_FILE"
fi

# —————————————————————————————————————————————
# 3) Install Docker & Compose plugin jika belum ada
if ! command -v docker &> /dev/null; then
  echo "🔧 Installing Docker & compose plugin..."
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
  echo "🗸 Docker & compose plugin installed"
fi

# —————————————————————————————————————————————
# 4) Stop & remove old container
docker rm -f nexus-node 2>/dev/null || true
echo "🗸 Old nexus-node container removed"

# —————————————————————————————————————————————
# 5) Build (rebuild) image nexus-cli:latest
echo "📦 Building nexus-cli:latest (with --pull)..."
mkdir -p "$WORKDIR"
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
echo "🗸 nexus-cli:latest built"

# —————————————————————————————————————————————
# 6) Setup config dir & register wallet
mkdir -p "$CONFIG_DIR"
echo "🔑 Registering wallet $WALLET_ADDRESS..."
if ! docker run --rm -v "$CONFIG_DIR":/root/.nexus nexus-cli:latest \
     register-user --wallet-address "$WALLET_ADDRESS"; then
  echo "⚠️ Wallet mungkin sudah terdaftar, lanjutkan..."
else
  echo "🗸 register-user OK"
fi

# 7) Tulis config.json agar non-interaktif
cat > "$CONFIG_DIR/config.json" << EOF
{"node_id":"$NODE_ID"}
EOF

# —————————————————————————————————————————————
# 8) Jalankan headless node detached
docker run -d --name nexus-node \
  --network host \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  -v "$CONFIG_DIR":/root/.nexus \
  -v /etc/resolv.conf:/etc/resolv.conf:ro \
  --restart unless-stopped \
  nexus-cli:latest start --node-id "$NODE_ID"
echo
echo "✅ Node Nexus running in 'nexus-node' (detached)."
echo "   Logs: docker logs -f nexus-node"

# —————————————————————————————————————————————
# 9) Jalankan debug interaktif + TUI
docker run --rm -it \
  --entrypoint /bin/sh \
  -v "$CONFIG_DIR":/root/.nexus \
  --network host \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --dns 8.8.8.8 \
  nexus-cli:latest -c "
    sleep 3
    echo '→ Health-check orchestrator:' 
    curl -sS -w ' %{http_code}\\n' https://production.orchestrator.nexus.xyz/v3/health
    sleep 3
    echo '→ Ping orchestrator:' 
    ping -c3 production.orchestrator.nexus.xyz
    sleep 3
    echo '→ Isi /root/.nexus:' 
    ls -l /root/.nexus
    sleep 3
    echo -n 'Proses menjalankan nexus cli'
    for i in 1 2 3 4 5 6 7 8; do
      dots=\$(printf '%*s' \"\$((i % 4))\" '' | tr ' ' '.')
      printf \"\\rProses menjalankan nexus cli\$dots\"
      sleep 0.5
    done
    echo
    exec nexus-network start --node-id $NODE_ID
  "
