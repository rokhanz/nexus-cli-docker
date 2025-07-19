# Nexus Node Runner (Docker + Interactive)

A complete solution to run your Nexus prover node via Docker—avoiding the native‐CLI crash on Ubuntu 22.04:

```bash
$ nexus-network start --node-id 12345678
Floating point exception (core dumped)
```
To work around this, we provide the Docker‐based runner script below.
---

#🚀 Quick Start
##1. run in screen
```bash
screen -S nexus
```

##2. Clone this repo
```bash
wget -O ~/run-nexus.sh \
  https://raw.githubusercontent.com/rokhanz/nexus-cli-docker/main/run-nexus.sh &&
chmod +x run-nexus.sh && ./run-nexus.sh
```
