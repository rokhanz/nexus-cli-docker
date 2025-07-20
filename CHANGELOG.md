# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Separate Dockerfile for better maintainability
- Docker Compose configuration for easier deployment
- Enhanced installer script with input validation and auto-update functionality
- Dedicated Nexus CLI updater script (update-nexus.sh)
- Uninstaller script for clean removal
- Comprehensive README with troubleshooting guide
- Environment template (.env.example)
- Git ignore rules (.gitignore)
- Setup permissions script with ROKHANZ branding
- Health checks in Docker Compose
- Multiple deployment options
- Better error handling and logging
- Color-coded output in scripts
- ROKHANZ ASCII art banners in all scripts
- GitHub profile link integration (www.github.com/rokhanz)
- Automatic backup and restore functionality for updates
- MIT License file
- Version tracking and changelog

### Changed
- Improved documentation structure
- Enhanced user experience with better prompts and branding
- More robust error handling
- Updated all scripts with consistent ROKHANZ branding
- Enhanced file structure documentation

### Fixed
- Wallet address validation with proper regex
- Docker daemon status checking
- Permission issues with scripts
- Auto-update logic for Nexus CLI installations
- Enhanced run-nexus.sh with better error handling and logging
- Improved user experience in original script with ROKHANZ branding

## [1.0.0] - 2024-01-XX

### Added
- Initial release with run-nexus.sh
- Docker-based Nexus node runner
- Auto-installation of Docker
- Interactive and headless modes
- Health check functionality
- Environment configuration support
- ASCII banner for better UX

### Features
- One-liner installation command
- Automatic Docker installation on Ubuntu 22.04
- Wallet registration automation
- Container lifecycle management
- Network connectivity testing
- Configuration persistence

---

## Release Notes

### Version 1.0.0
- **Initial Release**: Basic functionality with single script approach
- **Platform**: Ubuntu 22.04 LTS support
- **Docker**: Automatic installation and configuration
- **Modes**: Both interactive and headless operation

### Upcoming Features
- [ ] Multi-architecture Docker builds (ARM64 support)
- [ ] GitHub Actions CI/CD pipeline
- [ ] Automated testing suite
- [ ] Configuration backup/restore
- [ ] Monitoring dashboard
- [ ] Log rotation and management
- [ ] Performance optimization
- [ ] Windows WSL2 support
- [ ] macOS support with Docker Desktop

### Breaking Changes
None in current version.

### Migration Guide
If upgrading from a previous version:
1. Backup your `.env` file
2. Stop existing containers: `docker stop nexus-node`
3. Pull latest changes: `git pull origin main`
4. Run setup: `./install.sh`
5. Restore your configuration if needed

### Known Issues
- Network host mode may not work on all Docker configurations
- Some firewall configurations may block required ports
- ARM64 architecture not yet supported

### Support
For issues and questions:
- Check the troubleshooting section in README.md
- Open an issue on GitHub
- Review existing discussions
