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

echo ">> Generating Native macOS App Installer Wrapper..."
APP_SCRIPT="$TEMP_DIR/Voice Magic/Install Voice Magic.scpt"
cat << 'EOF' > "$APP_SCRIPT"
set appPath to POSIX path of (path to me)
if appPath ends with "/" then
    set appPath to text 1 thru -2 of appPath
end if
set currentDir to do shell script "dirname " & quoted form of appPath
set targetFolder to POSIX path of (path to documents folder) & "VoiceMagic"
tell application "Terminal"
    activate
    do script "echo '🚀 Bootstrapping Voice Magic into Documents folder...' && mkdir -p " & quoted form of targetFolder & " && ditto " & quoted form of currentDir & " " & quoted form of targetFolder & " && cd " & quoted form of targetFolder & " && chmod +x install.sh && ./install.sh"
end tell
EOF

osacompile -o "$TEMP_DIR/Voice Magic/Install Voice Magic.app" "$APP_SCRIPT"
rm "$APP_SCRIPT"

echo ">> Compiling .dmg image natively via hdiutil..."
hdiutil create -volname "$APP_NAME Installation" -srcfolder "$TEMP_DIR/Voice Magic" -ov -format UDZO "dist/$DMG_NAME"

rm -rf "$TEMP_DIR"

echo "✅ DMG beautifully compiled at $SCRIPT_DIR/dist/$DMG_NAME"
