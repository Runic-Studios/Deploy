FROM registry.runicrealms.com/agents/agent-go:latest

# Install protoc (v29.4) and required tools
RUN apt-get update && apt-get install -y --no-install-recommends unzip curl git && \
    rm -rf /var/lib/apt/lists/* && \
    curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v29.4/protoc-29.4-linux-x86_64.zip && \
    unzip protoc-29.4-linux-x86_64.zip -d /usr/local && \
    rm protoc-29.4-linux-x86_64.zip

# Install Go protobuf plugins to global path
ENV GOBIN=/usr/local/bin
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

WORKDIR /workspace
