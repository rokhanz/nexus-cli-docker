# Nexus Node Runner (Docker + Interactive)

A complete solution to run your Nexus prover node via Docker—avoiding the native‐CLI crash on Ubuntu 22.04:

```bash
$ nexus-network start --node-id 12345678
Floating point exception (core dumped)
```
To work around this, we provide the Docker‐based runner script below.
---

#🚀 Quick Start
##1. Clone this repo
```bash
git clone https://github.com/rokhanz/nexus-cli-docker.git
cd nexus-cli-docker
chmod +x run-nexus.sh
```

##2. create .env in terminal nexus-cli-docker/.env
```bash
nano nexus-cli-docker/.env
```

##3.fill in .env
```env
WALLET_ADDRESS=0Xyourwalletaddress
NODE_ID=123456789
```
ctrl +x then y, enter

##4.Run the wrapper
interactive (in screen)
```bash
screen -S nexus
bash run-nexus.sh
# → Watch health-checks, ping, ls, then the Nexus TUI appears.
# Press 'q' to exit the UI (node keeps running inside screen).
# Detach: Ctrl-A D
```
