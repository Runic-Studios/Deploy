#!/usr/bin/env bash
set -euo pipefail

TARGET="/mnt/world/worlds.zip"
SOURCE="./worlds.zip"

# Copy the file
sudo mkdir -p $(dirname "$TARGET")
echo "Copying $SOURCE to $TARGET"
sudo cp "$SOURCE" "$TARGET"
echo "Done."
