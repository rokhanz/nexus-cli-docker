FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.nexus/bin:$PATH"

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        curl \
        ca-certificates \
        wget \
        gnupg \
        lsb-release && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install Nexus CLI
RUN curl -sSf https://cli.nexus.xyz/ -o install.sh && \
    chmod +x install.sh && \
    NONINTERACTIVE=1 ./install.sh && \
    rm install.sh

# Create nexus directory
RUN mkdir -p /root/.nexus

# Set working directory
WORKDIR /root

# Default entrypoint
ENTRYPOINT ["nexus-network"]

# Default command
CMD ["--help"]
