#!/bin/bash
set -e

build_and_push() {
    local dockerfile="$1"
    local image_tag="$2"
    echo "Building image ${image_tag} using ${dockerfile}..."
    docker build --no-cache -f "$dockerfile" -t "$image_tag" .
    echo "Pushing image ${image_tag}..."
    docker push "$image_tag"
    echo "Done: ${image_tag}"
    echo "-----------------------------"
}

build_and_push base.Dockerfile registry.runicrealms.com/agents/agent-base:latest
build_and_push java-21.Dockerfile registry.runicrealms.com/agents/agent-java-21:latest
build_and_push go.Dockerfile registry.runicrealms.com/agents/agent-go:latest
build_and_push go-protoc.Dockerfile registry.runicrealms.com/agents/agent-go-protoc:latest
