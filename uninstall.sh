#!/bin/bash
set -euo pipefail

# ============================================================================
#  Voice Magic — Uninstaller
#  Removes everything installed by install.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "  $*"; }
success() { echo -e "  ${GREEN}✓${NC} $*"; }
warn()    { echo -e "  ${YELLOW}!${NC} $*"; }

echo ""
echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}${BOLD}  Voice Magic — Uninstaller${NC}"
echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── Show what will be removed ─────────────────────────────────────────────────
echo -e "This will remove the following from ${BOLD}$SCRIPT_DIR${NC}:"
echo ""
[[ -d "$SCRIPT_DIR/whisper.cpp" ]] && info "📁 whisper.cpp/  (source, binaries, and models)"
[[ -d "$SCRIPT_DIR/llama.cpp" ]]   && info "📁 llama.cpp/    (source, binaries, and models)"
[[ -f "$SCRIPT_DIR/dictate.sh" ]]  && info "📄 dictate.sh    (terminal runner)"
[[ -f "$SCRIPT_DIR/process.sh" ]]  && info "📄 process.sh    (Hammerspoon processor)"
[[ -f "$SCRIPT_DIR/voice-magic.lua" ]] && info "📄 voice-magic.lua (Hammerspoon config)"
echo ""

read -p "Proceed with uninstall? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# ── Remove project files ─────────────────────────────────────────────────────
if [[ -d "$SCRIPT_DIR/whisper.cpp" ]]; then
    rm -rf "$SCRIPT_DIR/whisper.cpp"
    success "Removed whisper.cpp/"
fi

if [[ -d "$SCRIPT_DIR/llama.cpp" ]]; then
    rm -rf "$SCRIPT_DIR/llama.cpp"
    success "Removed llama.cpp/"
fi

for file in dictate.sh process.sh voice-magic.lua; do
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        rm -f "$SCRIPT_DIR/$file"
        success "Removed $file"
    fi
done

# ── Clean up temp files ──────────────────────────────────────────────────────
rm -f /tmp/voice_magic_recording.wav /tmp/voice_magic_raw.txt /tmp/voice_magic_refined.txt
success "Cleaned up temp files"

# ── Remove Hammerspoon config ────────────────────────────────────────────────
HAMMERSPOON_INIT="$HOME/.hammerspoon/init.lua"
if [[ -f "$HAMMERSPOON_INIT" ]]; then
    # Remove the dofile line and comment from init.lua
    if grep -qF "voice-magic.lua" "$HAMMERSPOON_INIT"; then
        sed -i '' '/Voice Magic/d' "$HAMMERSPOON_INIT"
        sed -i '' '/voice-magic\.lua/d' "$HAMMERSPOON_INIT"
        success "Removed Voice Magic from Hammerspoon init.lua"
    fi
    # Remove init.lua if it's now empty
    if [[ ! -s "$HAMMERSPOON_INIT" ]]; then
        rm -f "$HAMMERSPOON_INIT"
        success "Removed empty Hammerspoon init.lua"
    fi
fi

# ── Optionally remove Homebrew packages ──────────────────────────────────────
echo ""
echo -e "${YELLOW}The installer may have added these Homebrew packages:${NC}"
echo "  • sox  (audio recording)"
echo "  • cmake (build tool)"
echo "  • wget (file downloader)"
echo "  • hammerspoon (hotkey automation)"
echo ""
read -p "Remove these Homebrew packages too? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    for pkg in sox cmake wget; do
        if brew list "$pkg" &>/dev/null; then
            brew uninstall "$pkg"
            success "Uninstalled $pkg"
        fi
    done
    if brew list --cask hammerspoon &>/dev/null; then
        brew uninstall --cask hammerspoon
        success "Uninstalled Hammerspoon"
    fi
else
    info "Kept Homebrew packages"
fi

echo ""
echo -e "${GREEN}${BOLD}  ✅ Voice Magic uninstalled.${NC}"
echo ""
echo -e "  The ${BOLD}install.sh${NC}, ${BOLD}uninstall.sh${NC}, and ${BOLD}README.md${NC} files remain."
echo -e "  Delete this folder manually if you want to remove everything:"
echo -e "  ${YELLOW}rm -rf $SCRIPT_DIR${NC}"
echo ""
