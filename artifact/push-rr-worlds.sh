#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <registry-username> <registry-password>"
  exit 1
fi

REGISTRY_USER="$1"
REGISTRY_PASSWORD="$2"

echo 'Logging into registry...'
oras login registry.runicrealms.com -u "$REGISTRY_USER" -p "$REGISTRY_PASSWORD"

echo 'Pushing Alterra.slime'
oras push "registry.runicrealms.com/world/alterra-slime:latest" Alterra.slime

echo 'Pushing dungeons.slime'
oras push "registry.runicrealms.com/world/dungeons-slime:latest" dungeons.slime
