# 🚀 NEXUS MANAGER - ALL-IN-ONE SCRIPT GUIDE

![GitHub stars](https://img.shields.io/github/stars/rokhanz/nexus-multi-docker?style=flat)
![GitHub forks](https://img.shields.io/github/forks/rokhanz/nexus-multi-docker?style=flat)
![GitHub issues](https://img.shields.io/github/issues/rokhanz/nexus-multi-docker)
![GitHub license](https://img.shields.io/github/license/rokhanz/nexus-multi-docker)
![Bash](https://img.shields.io/badge/Bash-4.0%2B-green)
![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)

## 📋 OVERVIEW

**nexus-manager.sh** adalah script all-in-one yang menggabungkan semua fungsi untuk mengelola Nexus CLI Docker dalam satu file. Script ini mencakup instalasi, uninstall, dan manajemen node dengan menggunakan screen session.

---

## ✨ FITUR UTAMA

### 🔧 **All-in-One Management**
- ✅ Install Nexus CLI Docker
- ✅ Uninstall lengkap dengan cleanup
- ✅ Start/Stop/Restart node
- ✅ Status monitoring
- ✅ Log viewing
- ✅ Screen session management

### 🐳 **Auto Docker Installation**
- ✅ Support 6 OS: Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux
- ✅ Auto-detect package manager
- ✅ Install Docker otomatis jika belum ada

### 📺 **Screen Session Integration**
- ✅ Jalankan Nexus dalam screen session bernama "nexus"
- ✅ Background execution yang persistent
- ✅ Easy attach/detach functionality

### 🛡️ **Robust Error Handling**
- ✅ Retry mechanism dengan exponential backoff
- ✅ Auto-cleanup saat error
- ✅ System validation
- ✅ Graceful error recovery

---

## 🚀 QUICK START

### **Download & Setup**
```bash
# Download script
wget -O ~/nexus-manager.sh https://raw.githubusercontent.com/rokhanz/nexus-cli-docker/main/nexus-manager.sh

# Make executable
chmod +x ~/nexus-manager.sh

# Show help
~/nexus-manager.sh help
```

### **Basic Usage**
```bash
# Install Nexus
~/nexus-manager.sh install

# Start node
~/nexus-manager.sh start

# Check status
~/nexus-manager.sh status

# View logs
~/nexus-manager.sh logs

# Attach to screen session
~/nexus-manager.sh attach
# atau langsung: screen -r nexus

# Stop node
~/nexus-manager.sh stop
```

---

## 📚 COMMAND REFERENCE

### **install**
Menginstall Nexus CLI Docker lengkap dengan dependencies.

```bash
~/nexus-manager.sh install
```

**Yang dilakukan:**
- ✅ Validasi sistem (OS, memory, disk space)
- ✅ Install screen jika belum ada
- ✅ Install Docker jika belum ada (auto-detect OS)
- ✅ Setup environment variables (.env file)
- ✅ Build Docker image nexus-cli:latest
- ✅ Register wallet address
- ✅ Setup konfigurasi

**Input yang diperlukan:**
- `WALLET_ADDRESS`: Alamat wallet Ethereum (format: 0x...)
- `NODE_ID`: ID unik untuk node Anda

### **start**
Memulai Nexus node dalam screen session.

```bash
~/nexus-manager.sh start
```

**Yang dilakukan:**
- ✅ Load environment variables
- ✅ Check dan stop container lama jika ada
- ✅ Buat screen session bernama "nexus"
- ✅ Jalankan Docker container dalam screen session
- ✅ Verifikasi status startup

**Screen Session:**
- Nama session: `nexus`
- Attach: `screen -r nexus`
- Detach: `Ctrl+A+D`

### **stop**
Menghentikan Nexus node dan screen session.

```bash
~/nexus-manager.sh stop
```

**Yang dilakukan:**
- ✅ Stop Docker container nexus-node
- ✅ Quit screen session "nexus"
- ✅ Cleanup resources

### **restart**
Restart Nexus node (stop + start).

```bash
~/nexus-manager.sh restart
```

### **status**
Menampilkan status lengkap Nexus node.

```bash
~/nexus-manager.sh status
```

**Informasi yang ditampilkan:**
- 🐳 Status Docker container
- 📺 Status screen session
- ⚙️ Environment variables
- 📊 Resource usage

### **logs**
Menampilkan logs Nexus node.

```bash
~/nexus-manager.sh logs
```

**Opsi viewing:**
- Jika container berjalan: `docker logs -f nexus-node`
- Jika hanya screen session: instruksi attach ke screen

### **attach**
Attach ke screen session untuk melihat output real-time.

```bash
~/nexus-manager.sh attach
```

**Keyboard shortcuts dalam screen:**
- `Ctrl+A+D`: Detach dari session
- `Ctrl+A+K`: Kill session
- `Ctrl+A+?`: Help

### **uninstall**
Uninstall lengkap Nexus CLI Docker.

```bash
~/nexus-manager.sh uninstall
```

**Yang dihapus:**
- ✅ Stop semua services
- ✅ Remove Docker containers dan images
- ✅ Hapus direktori konfigurasi (~/.nexus)
- ✅ Hapus working directory (~/nexus-cli-docker)
- ✅ Remove auto-load dari ~/.bashrc
- ✅ Docker system cleanup

**⚠️ WARNING:** Semua data dan konfigurasi akan dihapus permanen!

---

## 📁 FILE STRUCTURE

```
~/nexus-cli-docker/
├── .env                    # Environment variables
├── Dockerfile             # Docker image definition
└── config/

~/.nexus/
├── config.json            # Node configuration
└── [nexus-cli files]      # Nexus CLI installation

~/.bashrc
└── [auto-load .env]       # Environment auto-loading
```

---

## 🔧 CONFIGURATION

### **Environment Variables (.env)**
```bash
# Nexus Node configuration
WALLET_ADDRESS=0x1234567890123456789012345678901234567890
NODE_ID=your-unique-node-id
DEBUG=false
```

### **Node Configuration (config.json)**
```json
{
    "node_id": "your-unique-node-id",
    "created_at": "2024-01-01T00:00:00Z",
    "wallet_address": "0x1234567890123456789012345678901234567890"
}
```

---

## 🐛 TROUBLESHOOTING

### **Common Issues**

#### 1. **Screen session tidak ditemukan**
```bash
# Check active sessions
screen -list

# Jika tidak ada, start ulang
~/nexus-manager.sh start
```

#### 2. **Docker container tidak berjalan**
```bash
# Check container status
docker ps -a

# Check logs
docker logs nexus-node

# Restart jika perlu
~/nexus-manager.sh restart
```

#### 3. **Permission denied**
```bash
# Make sure script executable
chmod +x ~/nexus-manager.sh

# Check Docker permissions
sudo usermod -aG docker $USER
# Logout dan login kembali
```

#### 4. **Environment variables tidak loaded**
```bash
# Check .env file
cat ~/nexus-cli-docker/.env

# Reload bashrc
source ~/.bashrc

# Atau reinstall
~/nexus-manager.sh uninstall
~/nexus-manager.sh install
```

### **Debug Mode**
```bash
# Enable debug mode
export DEBUG=true
~/nexus-manager.sh [command]

# Atau edit .env file
echo "DEBUG=true" >> ~/nexus-cli-docker/.env
```

---

## 📊 MONITORING

### **Real-time Monitoring**
```bash
# Attach ke screen session
screen -r nexus

# Atau view logs
~/nexus-manager.sh logs

# Check resource usage
docker stats nexus-node
```

### **Status Checks**
```bash
# Full status
~/nexus-manager.sh status

# Quick container check
docker ps | grep nexus-node

# Quick screen check
screen -list | grep nexus
```

### **Health Checks**
```bash
# Test network connectivity
curl -s https://production.orchestrator.nexus.xyz/v3/health

# Check Docker daemon
docker info

# Check system resources
df -h
free -h
```

---

## 🔄 MAINTENANCE

### **Regular Tasks**
```bash
# Check status
~/nexus-manager.sh status

# View logs untuk errors
~/nexus-manager.sh logs

# Restart jika diperlukan
~/nexus-manager.sh restart
```

### **Updates**
```bash
# Download script terbaru
wget -O ~/nexus-manager.sh https://raw.githubusercontent.com/rokhanz/nexus-cli-docker/main/nexus-manager.sh
chmod +x ~/nexus-manager.sh

# Rebuild image dengan update terbaru
~/nexus-manager.sh stop
docker rmi nexus-cli:latest
~/nexus-manager.sh start
```

### **Backup Configuration**
```bash
# Backup environment
cp ~/nexus-cli-docker/.env ~/nexus-env-backup.env

# Backup node config
cp ~/.nexus/config.json ~/nexus-config-backup.json
```

---

## 🎯 BEST PRACTICES

### **Security**
- ✅ Jangan share WALLET_ADDRESS dan NODE_ID
- ✅ Backup file .env di tempat aman
- ✅ Gunakan strong NODE_ID yang unik
- ✅ Monitor logs secara berkala

### **Performance**
- ✅ Pastikan sistem memiliki minimal 2GB RAM
- ✅ Monitor disk space (minimal 10GB free)
- ✅ Restart node secara berkala jika diperlukan
- ✅ Clean up Docker resources: `docker system prune`

### **Reliability**
- ✅ Gunakan screen session untuk persistence
- ✅ Monitor status node secara berkala
- ✅ Setup monitoring alerts jika diperlukan
- ✅ Backup konfigurasi secara berkala

---

## 🆘 SUPPORT

### **Getting Help**
```bash
# Show help
~/nexus-manager.sh help

# Check version info
~/nexus-manager.sh status

# Debug mode
DEBUG=true ~/nexus-manager.sh [command]
```

### **Common Commands**
```bash
# Quick status check
~/nexus-manager.sh status

# Restart if issues
~/nexus-manager.sh restart

# View real-time output
screen -r nexus

# Emergency stop
~/nexus-manager.sh stop
```

---

## 📝 CHANGELOG

### **Version 2.0 (All-in-One)**
- ✅ Unified script dengan semua fungsi
- ✅ Screen session integration
- ✅ Auto Docker installation
- ✅ Comprehensive error handling
- ✅ Multi-OS support
- ✅ Enhanced monitoring dan logging

### **Key Improvements dari Original**
- 🔧 Path resolution bug fixed
- 🐳 Auto Docker installation
- 📺 Screen session management
- 🛡️ Robust error handling
- 🌐 Network resilience
- 📊 Enhanced monitoring

---

**Generated by:** ROKHANZ Nexus CLI Docker Team  
**Date:** $(date)  
**Version:** 2.0 (All-in-One Manager)  
**Status:** ✅ Production Ready
