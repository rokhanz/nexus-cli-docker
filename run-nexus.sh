#!/usr/bin/env bash
set -euo pipefail

# ASCII Banner
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
# 0) Tentukan direktori kerja & file .env
#    Skrip diasumsikan di ~/run-nexus.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="$SCRIPT_DIR/nexus-cli-docker"
ENV_FILE="$WORKDIR/.env"
CONFIG_DIR="$HOME/.nexus"

# —————————————————————————————————————————————
# 1) Load .env jika ada dan valid, atau prompt jika belum
if [[ -f "$ENV_FILE" ]]; then
  # Cek apakah variabel penting ada di file
  if grep -q '^WALLET_ADDRESS=' "$ENV_FILE" && grep -q '^NODE_ID=' "$ENV_FILE"; then
    # Export semua baris KEY=VALUE yang bukan komentar
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
    echo "🗸 Loaded environment from $ENV_FILE"
  else
    echo "⚠️ .env ditemukan tapi tidak berisi WALLET_ADDRESS atau NODE_ID."
    echo "   Silakan perbaiki $ENV_FILE atau hapus supaya skrip prompt ulang."
    exit 1
  fi
else
  # Kalau belum ada .env, prompt kedua variabel dan simpan
  read -p "Masukkan WALLET_ADDRESS: " WALLET_ADDRESS
  read -p "Masukkan NODE_ID       : " NODE_ID
  mkdir -p "$WORKDIR"
  cat > "$ENV_FILE" << EOF
# Nexus Node configuration
WALLET_ADDRESS=$WALLET_ADDRESS
NODE_ID=$NODE_ID
EOF
  chmod 600 "$ENV_FILE"
  echo "✅ Created .env at $ENV_FILE"
  # Export langsung untuk run sekarang
  export WALLET_ADDRESS NODE_ID
fi

# —————————————————————————————————————————————
# 2) Install Docker jika belum ada
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
# 3) Stop & remove old container (jika ada)
docker rm -f nexus-node 2>/dev/null || true
echo "🗸 Old nexus-node container removed"

# —————————————————————————————————————————————
# 4) Build/rebuild image nexus-cli:latest
echo "📦 Building nexus-cli:latest (with --pull)…"
mkdir -p "$WORKDIR"
cat > "$WORKDIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl ca-certificates && \
    curl -sSf https://cli.nexus.xyz/ -o install.sh && \
    chmod +x install.sh && \
    NONINTERACTIVE=1 ./install.sh && \
    rm install.sh && apt-get clean && rm -rf /var/lib/apt/lists/*
ENV PATH="/root/.nexus/bin:$PATH"
ENTRYPOINT ["nexus-network"]
EOF
docker build --pull -t nexus-cli:latest "$WORKDIR"
echo "🗸 nexus-cli:latest built"

# —————————————————————————————————————————————
# 5) Setup config dir & register wallet
mkdir -p "$CONFIG_DIR"
echo "🔑 Registering wallet $WALLET_ADDRESS…"
if ! docker run --rm -v "$CONFIG_DIR":/root/.nexus nexus-cli:latest \
     register-user --wallet-address "$WALLET_ADDRESS"; then
  echo "⚠️ Wallet mungkin sudah terdaftar, lanjut…"
else
  echo "🗸 register-user OK"
fi

# —————————————————————————————————————————————
# 6) Tulis config.json agar non-interaktif
cat > "$CONFIG_DIR/config.json" << EOF
{"node_id":"$NODE_ID"}
EOF

# —————————————————————————————————————————————
# 7) Jalankan headless node detached
docker run -d --name nexus-node \
  --network host \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  -v "$CONFIG_DIR":/root/.nexus \
  -v /etc/resolv.conf:/etc/resolv.conf:ro \
  --restart unless-stopped \
  nexus-cli:latest start --node-id "$NODE_ID"

echo
echo "✅ Node Nexus berjalan di container 'nexus-node' (detached)."
echo "   Pantau log: docker logs -f nexus-node"

# —————————————————————————————————————————————
# 8) Jalankan debug interaktif + TUI
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
    exec nexus-network start --node-id \$NODE_ID
  "
