FROM ubuntu:22.04

USER root

ARG ORAS_VERSION=1.2.2

# Install common packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    bash \
    jq \
    less \
    unzip \
    passwd \
    docker.io \
    openssh-client && \
    rm -rf /var/lib/apt/lists/*

# Ensure wget is installed
RUN if ! command -v wget >/dev/null; then \
      apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*; \
    fi

# Set up GitHub CLI repository and install gh
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install yq
RUN curl -sLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Install ORAS
RUN curl -LOs https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz && \
    tar -xzf oras_${ORAS_VERSION}_linux_amd64.tar.gz && \
    mv oras /usr/local/bin/oras && \
    chmod +x /usr/local/bin/oras && \
    rm -f oras_${ORAS_VERSION}_linux_amd64.tar.gz && \
    oras version

WORKDIR /workspace
