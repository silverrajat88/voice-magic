#!/bin/bash
set -euo pipefail

# ============================================================================
#  Voice Magic — Uninstaller
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }

echo -e "\n${BOLD}━━━ Voice Magic Uninstaller ━━━${NC}\n"

# ── 1. Hammerspoon Cleanup ───────────────────────────────────────────────────
HAMMERSPOON_DIR="$HOME/.hammerspoon"
INIT_LUA="$HAMMERSPOON_DIR/init.lua"
REQUIRE_LINE="dofile(\"$SCRIPT_DIR/voice-magic.lua\")"

if [[ -f "$INIT_LUA" ]]; then
    if grep -qF "$REQUIRE_LINE" "$INIT_LUA"; then
        TEMP_LUA=$(mktemp)
        # Remove the require line and the comment above it
        grep -vF "$REQUIRE_LINE" "$INIT_LUA" | grep -vF "-- Voice Magic: hold-to-record dictation" > "$TEMP_LUA"
        mv "$TEMP_LUA" "$INIT_LUA"
        success "Removed Voice Magic from Hammerspoon init.lua"
    else
        info "Voice Magic not found in Hammerspoon init.lua"
    fi
fi

# ── 2. Local Cleanup ─────────────────────────────────────────────────────────

if [[ -d "$SCRIPT_DIR/whisper.cpp" ]]; then
    rm -rf "$SCRIPT_DIR/whisper.cpp"
    success "Removed whisper.cpp/"
fi

if [[ -d "$SCRIPT_DIR/llama.cpp" ]]; then
    rm -rf "$SCRIPT_DIR/llama.cpp"
    success "Removed llama.cpp/"
fi

# We don't remove model configurations, dictate.sh, or process.sh since they are natively checked into git now.
# But we can remove the downloaded GGUF bins entirely if we want, but removing llama.cpp/ already did that.

# ── 3. Homebrew Cleanup (Optional) ───────────────────────────────────────────
echo ""
echo -e "${YELLOW}Voice Magic installed the following Homebrew dependencies:${NC}"
echo " - cmake"
echo " - sox"
echo " - wget"
echo " - hammerspoon (cask)"
echo ""
read -p "Do you want to uninstall these dependencies? [y/N]: " REMOVE_DEPS

if [[ "$REMOVE_DEPS" =~ ^[Yy]$ ]]; then
    for dep in cmake sox wget; do
        if brew list "$dep" &>/dev/null; then
            info "Uninstalling $dep..."
            brew uninstall "$dep"
        fi
    done
    
    if brew list --cask hammerspoon &>/dev/null; then
        info "Uninstalling Hammerspoon..."
        brew uninstall --cask hammerspoon
    fi
    success "Dependencies removed."
else
    info "Keeping dependencies installed."
fi

echo ""
echo -e "${GREEN}${BOLD}Voice Magic successfully uninstalled!${NC}"
echo -e "You can now safely delete this folder: ${YELLOW}$SCRIPT_DIR${NC}"
echo ""
