FROM registry.runicrealms.com/agents/agent-base:latest

# Install Go 1.24.2
RUN curl -LO https://go.dev/dl/go1.24.2.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz && \
    rm go1.24.2.linux-amd64.tar.gz

# Ensure go binary is in PATH
ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /workspace
