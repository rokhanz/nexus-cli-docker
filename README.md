# Nexus Testnet III Node Runner (Docker + Interactive)

A complete solution to run your Nexus prover node via Docker—avoiding the native-CLI crash on Ubuntu 22.04.

[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🚀 Quick Start

### Option 1: One-liner Installation (Recommended)
```bash
wget -O ~/run-nexus.sh https://raw.githubusercontent.com/rokhanz/nexus-cli-docker/main/run-nexus.sh && chmod +x ~/run-nexus.sh && ~/run-nexus.sh
```

### Option 2: Manual Installation
```bash
# Clone the repository
git clone https://github.com/rokhanz/nexus-cli-docker.git
cd nexus-cli-docker

# Run the installer
chmod +x install.sh
./install.sh

# Start the node
docker-compose up -d
```

## 📋 Prerequisites

- **Operating System**: Ubuntu 22.04 LTS (recommended)
- **Docker**: Version 20.10+ with Docker Compose
- **Memory**: At least 2GB RAM
- **Storage**: At least 10GB free space
- **Network**: Stable internet connection
- **Privileges**: Root access for Docker installation

## 🛠️ Installation Methods

### Method 1: Using the Original Script
```bash
./run-nexus.sh
```
This script will:
- Install Docker if not present
- Build the Nexus CLI image
- Set up configuration
- Run both headless and interactive modes

### Method 2: Using Docker Compose
```bash
# Background mode
docker-compose up -d

# Interactive mode
docker-compose --profile interactive up
```

### Method 3: Using the New Installer
```bash
./install.sh
```
Enhanced installer with better validation, error handling, and auto-update functionality.

### Method 4: Update Existing Installation
```bash
./update-nexus.sh
```
Dedicated script to update Nexus CLI to the latest version with backup and restore functionality.

## ⚙️ Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Required variables:
- `WALLET_ADDRESS`: Your Ethereum wallet address (0x...)
- `NODE_ID`: Your unique node identifier

Optional variables:
- `CONFIG_DIR`: Custom configuration directory (default: ~/.nexus)
- `NETWORK_MODE`: Docker network mode (default: host)
- `DEBUG`: Enable debug mode (default: false)

### Wallet Address Format
Your wallet address must:
- Start with `0x`
- Be exactly 42 characters long
- Contain only hexadecimal characters (0-9, a-f, A-F)

Example: `0x1234567890123456789012345678901234567890`

## 🐳 Docker Commands

### Basic Operations
```bash
# Check running containers
docker ps

# View logs
docker logs -f nexus-node

# Stop the node
docker stop nexus-node

# Restart the node
docker restart nexus-node

# Remove container
docker rm nexus-node
```

### Troubleshooting Commands
```bash
# Check Docker daemon status
docker info

# Test network connectivity
docker run --rm nexus-cli:latest ping -c3 production.orchestrator.nexus.xyz

# Check health
curl -s https://production.orchestrator.nexus.xyz/v3/health

# Interactive shell
docker run --rm -it nexus-cli:latest /bin/sh
```

## 📊 Monitoring

### Health Checks
The Docker Compose setup includes automatic health checks:
- Endpoint: `https://production.orchestrator.nexus.xyz/v3/health`
- Interval: 30 seconds
- Timeout: 10 seconds
- Retries: 3

### Log Monitoring
```bash
# Follow logs in real-time
docker logs -f nexus-node

# View last 100 lines
docker logs --tail 100 nexus-node

# View logs with timestamps
docker logs -t nexus-node
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

#### 2. Port Already in Use
```bash
# Check what's using the port
sudo netstat -tulpn | grep :PORT_NUMBER
# Kill the process or change port
```

#### 3. Network Issues
```bash
# Test connectivity
ping production.orchestrator.nexus.xyz
# Check DNS resolution
nslookup production.orchestrator.nexus.xyz
```

#### 4. Container Won't Start
```bash
# Check container logs
docker logs nexus-node
# Check system resources
docker system df
# Clean up unused resources
docker system prune
```

#### 5. Wallet Registration Failed
```bash
# Verify wallet address format
echo $WALLET_ADDRESS | grep -E '^0x[a-fA-F0-9]{40}$'
# Try manual registration
docker run --rm -v ~/.nexus:/root/.nexus nexus-cli:latest register-user --wallet-address $WALLET_ADDRESS
```

### Performance Issues

#### High CPU Usage
- Check if multiple instances are running
- Monitor with `docker stats nexus-node`
- Consider resource limits in docker-compose.yml

#### Memory Issues
- Monitor memory usage: `docker stats --no-stream nexus-node`
- Check available system memory: `free -h`
- Add swap if needed: `sudo fallocate -l 2G /swapfile`

### Network Troubleshooting

#### Connection Timeouts
```bash
# Test orchestrator connectivity
curl -v https://production.orchestrator.nexus.xyz/v3/health

# Check DNS resolution
dig production.orchestrator.nexus.xyz

# Test with different DNS
docker run --rm --dns 8.8.8.8 nexus-cli:latest ping -c3 production.orchestrator.nexus.xyz
```

## 🔄 Updates

### Updating the Node
```bash
# Pull latest changes
git pull origin main

# Rebuild image
docker build -t nexus-cli:latest .

# Restart with new image
docker-compose down
docker-compose up -d
```

### Updating Docker
```bash
# Update Docker
sudo apt update && sudo apt upgrade docker-ce docker-ce-cli containerd.io
```

## 🗑️ Uninstallation

To completely remove Nexus CLI Docker:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This will remove:
- All containers and images
- Configuration directory (~/.nexus)
- Environment files
- Auto-load from ~/.bashrc

## 📁 File Structure

```
nexus-cli-docker/
├── run-nexus.sh          # Original all-in-one script
├── install.sh            # Enhanced installer with auto-update
├── update-nexus.sh       # Dedicated Nexus CLI updater
├── uninstall.sh          # Clean removal script
├── setup-permissions.sh  # Script permissions setup
├── Dockerfile            # Docker image definition
├── docker-compose.yml    # Docker Compose configuration
├── .env.example          # Environment template
├── .gitignore           # Git ignore rules
├── LICENSE              # MIT license
├── CHANGELOG.md         # Version history
└── README.md            # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/rokhanz/nexus-cli-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/rokhanz/nexus-cli-docker/discussions)
- **Documentation**: This README and inline comments

## 🔗 Links

- [Nexus Network](https://nexus.xyz/)
- [Docker Documentation](https://docs.docker.com/)
- [Ubuntu 22.04 LTS](https://ubuntu.com/download/desktop)

---

**⚠️ Disclaimer**: This is an unofficial Docker wrapper for Nexus CLI. Use at your own risk and always backup your configuration before making changes.
