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
# 0) Tentukan WORKDIR berdasarkan lokasi eksekusi
# Jika ada Dockerfile & .env di cwd, gunakan cwd
if [[ -f "./Dockerfile" && -f "./.env" ]]; then
  WORKDIR="$(pwd)"
# Jika ada subfolder nexus-cli-docker, gunakan itu
elif [[ -d "./nexus-cli-docker" ]]; then
  WORKDIR="$(pwd)/nexus-cli-docker"
else
  # fallback: skrip mungkin di home
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  WORKDIR="$SCRIPT_DIR/nexus-cli-docker"
fi

ENV_FILE="$WORKDIR/.env"
CONFIG_DIR="$HOME/.nexus"

echo "ℹ️  Using WORKDIR: $WORKDIR"
echo "ℹ️  Loading ENV from : $ENV_FILE"

# —————————————————————————————————————————————
# 1) Load .env jika ada, atau prompt & buat
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  if [[ -z "${WALLET_ADDRESS:-}" || -z "${NODE_ID:-}" ]]; then
    echo "⚠️  $ENV_FILE ditemukan tapi isinya belum lengkap."
    exit 1
  fi
  echo "🗸 Loaded env: WALLET_ADDRESS=$WALLET_ADDRESS NODE_ID=$NODE_ID"
else
  read -p "Masukkan WALLET_ADDRESS: " WALLET_ADDRESS
  read -p "Masukkan NODE_ID       : " NODE_ID
  mkdir -p "$WORKDIR"
  cat > "$ENV_FILE" << EOF
WALLET_ADDRESS=$WALLET_ADDRESS
NODE_ID=$NODE_ID
EOF
  chmod 600 "$ENV_FILE"
  echo "✅ Created $ENV_FILE"
  export WALLET_ADDRESS NODE_ID
fi

# —————————————————————————————————————————————
# (Langkah selanjutnya sama seperti skrip lama,
# hanya mengganti $WORKDIR di mana perlu)

# 2) Install Docker jika belum ada
if ! command -v docker &> /dev/null; then
  echo "🔧 Installing Docker..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  echo "🗸 Docker installed"
fi

# 3) Stop & remove old container
docker rm -f nexus-node 2>/dev/null || true
echo "🗸 Removed old nexus-node"

# 4) Build latest image
echo "📦 Building nexus-cli:latest..."
cat > "$WORKDIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl ca-certificates && \
    curl -sSf https://cli.nexus.xyz/ -o install.sh && chmod +x install.sh && \
    NONINTERACTIVE=1 ./install.sh && rm install.sh && apt-get clean && rm -rf /var/lib/apt/lists/*
ENV PATH="/root/.nexus/bin:$PATH"
ENTRYPOINT ["nexus-network"]
EOF
docker build --pull -t nexus-cli:latest "$WORKDIR"
echo "🗸 Image built"

# 5) Register wallet
mkdir -p "$CONFIG_DIR"
echo "🔑 Registering $WALLET_ADDRESS..."
docker run --rm -v "$CONFIG_DIR":/root/.nexus nexus-cli:latest \
  register-user --wallet-address "$WALLET_ADDRESS" \
  || echo "⚠️ Already registered, continuing..."

# 6) Write config.json
cat > "$CONFIG_DIR/config.json" << EOF
{"node_id":"$NODE_ID"}
EOF

# 7) Headless start
docker run -d --name nexus-node \
  --network host \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  -v "$CONFIG_DIR":/root/.nexus \
  -v /etc/resolv.conf:/etc/resolv.conf:ro \
  --restart unless-stopped \
  nexus-cli:latest start --node-id "$NODE_ID"

echo "✅ Node started (detached). Use: docker logs -f nexus-node"

# 8) Debug + Interactive
docker run --rm -it \
  --entrypoint /bin/sh \
  -v "$CONFIG_DIR":/root/.nexus \
  --network host --device /dev/net/tun --cap-add NET_ADMIN \
  nexus-cli:latest -c "
    sleep 2; echo '→ Health:'; curl -sS -w ' %{http_code}\\n' https://production.orchestrator.nexus.xyz/v3/health
    sleep 2; echo '→ Ping:'; ping -c3 production.orchestrator.nexus.xyz
    sleep 2; echo '→ Listing ~/.nexus:'; ls -l /root/.nexus
    sleep 2; echo -n 'Starting Nexus CLI'; for i in {1..6}; do printf '.'; sleep 0.5; done; echo
    exec nexus-network start --node-id \$NODE_ID
  "
