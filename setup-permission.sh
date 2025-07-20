#!/usr/bin/env bash

# ROKHANZ Banner
echo -e "\033[0;34m"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║  ██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗ ║
║  ██╔══██╗██╔═══██╗██║ ██╔╝██║  ██║██╔══██╗████╗  ██║╚══███╔╝ ║
║  ██████╔╝██║   ██║█████╔╝ ███████║███████║██╔██╗ ██║  ███╔╝  ║
║  ██╔══██╗██║   ██║██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║ ███╔╝   ║
║  ██║  ██║╚██████╔╝██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗ ║
║  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝ ║
║                                                               ║
║                    🚀 www.github.com/rokhanz 🚀              ║
║                                                               ║
║                    SETUP PERMISSIONS                         ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "\033[0m"

# Make all shell scripts executable
chmod +x run-nexus.sh
chmod +x install.sh
chmod +x uninstall.sh
chmod +x update-nexus.sh
chmod +x setup-permissions.sh

echo "✅ All scripts are now executable"
echo "📋 Available scripts:"
echo "  • ./run-nexus.sh     - Original all-in-one script"
echo "  • ./install.sh       - Enhanced installer with validation & auto-update"
echo "  • ./update-nexus.sh  - Dedicated Nexus CLI updater"
echo "  • ./uninstall.sh     - Clean removal script"
echo "  • ./setup-permissions.sh - This script"
echo ""
echo "🚀 Quick start:"
echo "  ./install.sh         - For new installation"
echo "  ./update-nexus.sh    - To update existing installation"
echo "  docker-compose up -d - To run with Docker Compose"
