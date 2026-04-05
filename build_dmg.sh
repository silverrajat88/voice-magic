#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ">> Checking for create-dmg dependency..."
if ! command -v create-dmg &>/dev/null; then
    echo ">> Installing create-dmg via Homebrew..."
    brew install create-dmg
fi

echo ">> Purging old builds..."
rm -rf dist
mkdir -p dist

APP_NAME="Voice Magic"
DMG_NAME="VoiceMagic.dmg"

# We must strip all heavy compiled binaries AND venv caches from the DMG so it is lightweight
# The installer process inherently rebuilds these on the target machine!
echo ">> Setting up clean export payload..."
TEMP_DIR=$(mktemp -d)
cp -R . "$TEMP_DIR/Voice Magic"
rm -rf "$TEMP_DIR/Voice Magic/.git" "$TEMP_DIR/Voice Magic/venv" "$TEMP_DIR/Voice Magic/whisper.cpp/models" "$TEMP_DIR/Voice Magic/llama.cpp/models" "$TEMP_DIR/Voice Magic/whisper.cpp/build" "$TEMP_DIR/Voice Magic/llama.cpp/build" 2>/dev/null || true

echo ">> Compiling .dmg image natively..."
create-dmg \
  --volname "$APP_NAME Install Payload" \
  --window-pos 200 120 \
  --window-size 500 300 \
  --icon-size 100 \
  "dist/$DMG_NAME" \
  "$TEMP_DIR/Voice Magic"

rm -rf "$TEMP_DIR"

echo "✅ DMG beautifully compiled at $SCRIPT_DIR/dist/$DMG_NAME"
