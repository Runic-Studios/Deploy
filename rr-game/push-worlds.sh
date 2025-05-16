#!/usr/bin/env bash
set -euxo pipefail

TARGET="/mnt/world/worlds.zip"
SOURCE="./worlds.zip"

# Copy the file
sudo mkdir $(dirname "$TARGET")
echo "Copying $SOURCE to $TARGET"
sudo cp "$SOURCE" "$TARGET"
echo "Done."
