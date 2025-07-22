# 🚀 Nexus CLI Docker Manager

## All-in-One Solution for Running Nexus Network Prover with Docker & Screen Monitoring

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Usage](#-usage)
- [Commands](#-commands)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## ✨ Features

### 🔧 Core Features

- **One-Click Installation**: Automated Docker & dependency setup
- **Smart Environment Management**: Secure wallet & node configuration
- **Screen Session Monitoring**: Background monitoring with easy attach/detach
- **Enhanced Docker Integration**: Optimized networking with `--network host`
- **Robust Error Handling**: Automatic retry mechanisms & graceful recovery

### 🛡️ Security & Reliability

- **Input Validation**: Wallet address format verification
- **Secure Configuration**: Environment file with proper permissions (600)
- **Clean Shutdown**: Proper container & session cleanup
- **Health Monitoring**: Container status & resource usage tracking

### 🎯 User Experience

- **Rich Logging**: Color-coded output with emojis for easy reading
- **Debug Mode**: Comprehensive system diagnostics
- **Multi-OS Support**: Ubuntu, Debian, CentOS, Fedora, Arch Linux
- **Interactive Setup**: Guided configuration process

## 🚀 Quick Start

```bash
# Download the script
curl -sSL https://raw.githubusercontent.com/rokhanz/nexus-cli-docker/main/nexus-manager.sh -o nexus-manager.sh

# Make it executable
chmod +x nexus-manager.sh

# Install and setup
./nexus-manager.sh install

# Start the Nexus node
./nexus-manager.sh start
```

## 💻 Installation

### Prerequisites

- **OS**: Linux (Ubuntu/Debian/CentOS/Fedora/Arch)
- **RAM**: Minimum 2GB (recommended 4GB+)
- **Storage**: 10GB free space
- **Network**: Stable internet connection

### Automated Installation

The script automatically handles:

- ✅ Docker installation and configuration
- ✅ Screen utility setup
- ✅ System validation
- ✅ Image building and optimization
- ✅ Network configuration

```bash
./nexus-manager.sh install
```

During installation you'll be prompted for:

- **Wallet Address**: Your Ethereum wallet (0x format, 40 characters)
- **Node ID**: Unique identifier for your node (minimum 3 characters)

## 📖 Usage

### Basic Workflow

1. **Install**: `./nexus-manager.sh install`
2. **Start**: `./nexus-manager.sh start`
3. **Monitor**: `./nexus-manager.sh status` or `screen -r nexus`
4. **Stop**: `./nexus-manager.sh stop`

## 🎮 Commands

| Command | Description | Example |
|---------|-------------|---------|
| `install` | Complete setup and installation | `./nexus-manager.sh install` |
| `start` | Start Nexus node with monitoring | `./nexus-manager.sh start` |
| `stop` | Stop node and cleanup | `./nexus-manager.sh stop` |
| `restart` | Restart the node | `./nexus-manager.sh restart` |
| `status` | Show current status | `./nexus-manager.sh status` |
| `info` | Detailed container information | `./nexus-manager.sh info` |
| `debug` | System diagnostics | `./nexus-manager.sh debug` |
| `logs` | View container logs | `./nexus-manager.sh logs` |
| `attach` | Attach to screen session | `./nexus-manager.sh attach` |
| `uninstall` | Complete removal | `./nexus-manager.sh uninstall` |
| `help` | Show help information | `./nexus-manager.sh help` |

### Advanced Usage

```bash
# Check detailed container info (ports, network, resources)
./nexus-manager.sh info

# Debug system issues
./nexus-manager.sh debug

# Monitor real-time logs
./nexus-manager.sh logs

# Quick status check
./nexus-manager.sh status
```

## 📊 Monitoring

### Screen Session Management

The script creates a dedicated screen session for monitoring:

```bash
# Attach to monitor
screen -r nexus

# Detach (keep running)
Ctrl+A, D

# List all sessions
screen -list
```

### Container Monitoring

```bash
# Quick status
docker ps | grep nexus-node

# Resource usage
docker stats nexus-node

# Live logs
docker logs -f nexus-node
```

### Status Output Example

```text
📊 Status Nexus Node:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Docker Container:
NAMES        STATUS         PORTS     IMAGE
nexus-node   Up 10 minutes            nexus-cli:latest

✅ Screen Session: Aktif (nexus)
🔵 Gunakan 'screen -r nexus' untuk attach

Environment:
WALLET_ADDRESS=0x1234567890123456789012345678901234567890
NODE_ID=my-node-001
DEBUG=false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔧 Troubleshooting

### Common Issues

#### "docker ps -a tidak menampilkan port"

This is **NORMAL** when using `--network host`. The container uses all host ports directly for optimal performance.

#### Container restart loops

```bash
# Debug the issue
./nexus-manager.sh debug

# Check logs
./nexus-manager.sh logs

# Restart cleanly
./nexus-manager.sh restart
```

#### Screen session issues

```bash
# Check screen installation
screen -v

# Manual cleanup
screen -S nexus -X quit

# Restart
./nexus-manager.sh start
```

#### Network connectivity issues

```bash
# Check TUN device
ls -la /dev/net/tun

# Verify network interfaces
ip link show

# Debug system
./nexus-manager.sh debug
```

### Debug Information

Use the built-in debug command for comprehensive diagnostics:

```bash
./nexus-manager.sh debug
```

This provides:

- Screen session status
- Docker container details
- Environment configuration
- Network interface information
- System resource usage

### Error Codes

- **Exit 1**: System validation failed
- **Exit 1**: Docker issues
- **Exit 1**: Environment setup problems

## 📁 File Structure

```text
~/nexus-cli-docker/
├── .env                    # Environment configuration
├── Dockerfile             # Docker image definition
└── config/
    └── config.json        # Node configuration

~/.nexus/                  # Nexus configuration directory
```

## 🔒 Security Notes

- Environment file (`.env`) has restricted permissions (600)
- Wallet address validation ensures proper format
- Container runs with minimal required privileges
- No sensitive data exposed in logs

## 🚀 Performance Optimization

### Network Configuration

- Uses `--network host` for optimal performance
- TUN device support for VPN capabilities
- DNS configuration passthrough

### Resource Management

- Automatic restart policy: `unless-stopped`
- Memory-efficient Docker image
- Background processing with screen

## 🛠️ Development

### Prerequisites for Development

- Docker installed
- Bash 4.0+
- Linux environment

### Testing

```bash
# Syntax check
bash -n nexus-manager.sh

# Enable debug mode
export DEBUG=true
./nexus-manager.sh start
```

## 📞 Support

### Getting Help

1. **Check Status**: `./nexus-manager.sh status`
2. **Debug System**: `./nexus-manager.sh debug`
3. **View Logs**: `./nexus-manager.sh logs`
4. **Check Issues**: [GitHub Issues](https://github.com/rokhanz/nexus-cli-docker/issues)

### Common Solutions

- **Port not showing**: Normal with `--network host`
- **Container restarting**: Check debug output
- **Screen not working**: Reinstall with `./nexus-manager.sh install`

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Nexus Network](https://nexus.xyz/) for the innovative prover network
- Docker community for containerization standards
- Screen maintainers for session management

---

**⭐ Star this repository if it helped you!**

**🐛 Found a bug? [Report it](https://github.com/rokhanz/nexus-cli-docker/issues)**

**💡 Have a suggestion? [Let us know](https://github.com/rokhanz/nexus-cli-docker/discussions)**
