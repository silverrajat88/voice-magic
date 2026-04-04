#!/bin/bash
set -euo pipefail

# ============================================================================
#  Voice Magic — One-Script Installer (v2.0)
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
error()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }
step()    { echo -e "\n${BOLD}━━━ $* ━━━${NC}\n"; }

ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
    info "Apple Silicon detected — Metal GPU acceleration will be enabled"
else
    warn "Intel Mac detected — builds will work but may be slower without Metal"
fi

# ── Step 1: Prerequisites ────────────────────────────────────────────────────
step "Step 1/8: Checking prerequisites"

if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "⏳ Please complete the Xcode CLI tools installation popup, then re-run this script."
    exit 0
else
    success "Xcode Command Line Tools found"
fi

if ! command -v brew &>/dev/null; then
    error "Homebrew is not installed. Install it from https://brew.sh and re-run this script."
fi
success "Homebrew found"

BREW_DEPS=(cmake sox wget ffmpeg)
for dep in "${BREW_DEPS[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        info "Installing $dep..."
        brew install "$dep"
        success "$dep installed"
    else
        success "$dep already installed"
    fi
done

# ── Step 2: whisper.cpp ──────────────────────────────────────────────────────
step "Step 2/8: Setting up whisper.cpp (speech-to-text engine)"

WHISPER_DIR="$SCRIPT_DIR/whisper.cpp"
if [[ -f "$WHISPER_DIR/build/bin/whisper-cli" ]]; then
    success "whisper.cpp already built — skipping"
else
    if [[ ! -d "$WHISPER_DIR" ]]; then
        info "Cloning whisper.cpp..."
        git clone https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
    fi
    info "Building whisper.cpp with Metal (GPU) support..."
    cd "$WHISPER_DIR"
    cmake -B build -DGGML_METAL=ON
    cmake --build build -j "$(sysctl -n hw.logicalcpu)" --config Release
    cd "$SCRIPT_DIR"
    if [[ ! -f "$WHISPER_DIR/build/bin/whisper-cli" ]]; then error "whisper.cpp build failed"; fi
    success "whisper.cpp built successfully"
fi

# ── Step 3: Whisper model ────────────────────────────────────────────────────
step "Step 3/8: Downloading STT Whisper model (~1.6 GB)"

WHISPER_MODEL_DIR="$WHISPER_DIR/models"
WHISPER_MODEL="$WHISPER_MODEL_DIR/ggml-large-v3-turbo.bin"
if [[ -f "$WHISPER_MODEL" ]]; then
    success "Whisper model already downloaded — skipping"
else
    info "Downloading ggml-large-v3-turbo model..."
    mkdir -p "$WHISPER_MODEL_DIR"
    wget -q --show-progress -O "$WHISPER_MODEL" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
    success "Whisper model downloaded"
fi

# ── Step 4: llama.cpp ────────────────────────────────────────────────────────
step "Step 4/8: Setting up llama.cpp (text refinement engine)"

LLAMA_DIR="$SCRIPT_DIR/llama.cpp"
if [[ -f "$LLAMA_DIR/build/bin/llama-completion" ]]; then
    success "llama.cpp already built — skipping"
else
    if [[ ! -d "$LLAMA_DIR" ]]; then
        info "Cloning llama.cpp..."
        git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
    fi
    info "Building llama.cpp with Metal (GPU) support..."
    cd "$LLAMA_DIR"
    cmake -B build -DGGML_METAL=ON
    cmake --build build -j "$(sysctl -n hw.logicalcpu)" --config Release
    cd "$SCRIPT_DIR"
    if [[ ! -f "$LLAMA_DIR/build/bin/llama-completion" ]]; then error "llama.cpp build failed"; fi
    success "llama.cpp built successfully"
fi

# ── Step 5: Setup voice-magic.conf ───────────────────────────────────────────
step "Step 5/8: Loading Configuration"

CONF_FILE="$SCRIPT_DIR/voice-magic.conf"
if [[ ! -f "$CONF_FILE" ]]; then
    error "voice-magic.conf strictly required but missing."
fi

source "$CONF_FILE"
ACTIVE_MODEL="${ACTIVE_MODEL:-llama3}"
success "Loaded config for active model: $ACTIVE_MODEL"

# ── Step 6: Llama model (from Config) ────────────────────────────────────────
step "Step 6/8: Downloading selected LLM model"

MODEL_DEF_PATH="$SCRIPT_DIR/models/${ACTIVE_MODEL}.sh"
if [[ ! -f "$MODEL_DEF_PATH" ]]; then
    error "Model definition $ACTIVE_MODEL not found in models/"
fi
source "$MODEL_DEF_PATH"

LLAMA_MODEL_DIR="$LLAMA_DIR/models"
LLAMA_MODEL_PATH="$LLAMA_MODEL_DIR/$LLAMA_MODEL_FILE"

if [[ -f "$LLAMA_MODEL_PATH" ]]; then
    success "Model '$LLAMA_MODEL_FILE' already downloaded — skipping"
else
    info "Downloading $LLAMA_MODEL_FILE..."
    mkdir -p "$LLAMA_MODEL_DIR"
    wget -q --show-progress -O "$LLAMA_MODEL_PATH" "$LLAMA_MODEL_URL"
    success "Llama model downloaded"
fi

# ── Step 7: Parakeet STT (if selected) ───────────────────────────────────────
step "Step 7/9: Setting up Parakeet STT engine"

STT_ENGINE="${STT_ENGINE:-whisper}"
if [[ "$STT_ENGINE" == "parakeet" ]]; then
    if ! command -v python3 &>/dev/null; then
        error "Python 3 is required for Parakeet but not found. Install it via: brew install python3"
    fi
    if [[ -x "$SCRIPT_DIR/venv/bin/parakeet-mlx" ]]; then
        success "parakeet-mlx already installed in venv — skipping"
    else
        info "Installing parakeet-mlx (NVIDIA Parakeet for Apple Silicon)..."
        
        VENV_DIR="$SCRIPT_DIR/venv"
        if [[ ! -d "$VENV_DIR" ]]; then
            python3 -m venv "$VENV_DIR"
        fi
        
        "$VENV_DIR/bin/pip" install -U parakeet-mlx
        
        if [[ -x "$VENV_DIR/bin/parakeet-mlx" ]]; then
            success "parakeet-mlx installed securely in local venv"
        else
            error "parakeet-mlx installation failed inside venv"
        fi
    fi
    info "Note: The Parakeet model (~600MB) will auto-download on first use."
else
    success "STT engine is 'whisper' — Parakeet setup skipped"
fi

# ── Step 8: Finalize Scripts ─────────────────────────────────────────────────
step "Step 8/9: Enabling execution modes"

chmod +x "$SCRIPT_DIR/dictate.sh"
chmod +x "$SCRIPT_DIR/process.sh"
chmod +x "$SCRIPT_DIR/core/stt_engine.sh"
chmod +x "$SCRIPT_DIR/core/stt_parakeet.sh"
chmod +x "$SCRIPT_DIR/core/llm_engine.sh"
success "Scripts marked executable natively"

# ── Step 8: Hammerspoon (Hold-to-Record) ─────────────────────────────────────
step "Step 9/9: Setting up Hammerspoon (hold-to-record hotkey)"

if ! brew list --cask hammerspoon &>/dev/null; then
    info "Installing Hammerspoon..."
    brew install --cask hammerspoon
    success "Hammerspoon installed"
else
    success "Hammerspoon already installed"
fi

HAMMERSPOON_DIR="$HOME/.hammerspoon"
mkdir -p "$HAMMERSPOON_DIR"

INIT_LUA="$HAMMERSPOON_DIR/init.lua"
REQUIRE_LINE="dofile(\"$SCRIPT_DIR/voice-magic.lua\")"

if [[ -f "$INIT_LUA" ]]; then
    if ! grep -qF "$REQUIRE_LINE" "$INIT_LUA"; then
        echo "" >> "$INIT_LUA"
        echo "-- Voice Magic: hold-to-record dictation" >> "$INIT_LUA"
        echo "$REQUIRE_LINE" >> "$INIT_LUA"
        success "Added Voice Magic to Hammerspoon init.lua"
    else
        success "Voice Magic already in Hammerspoon init.lua"
    fi
else
    echo "-- Voice Magic: hold-to-record dictation" > "$INIT_LUA"
    echo "$REQUIRE_LINE" >> "$INIT_LUA"
    success "Created Hammerspoon init.lua with Voice Magic"
fi

# ── Done! ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✅ Voice Magic 2.0 installed successfully!${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${YELLOW}Current Model:${NC} $ACTIVE_MODEL"
echo -e "  To change models, edit ${BOLD}voice-magic.conf${NC} and re-run this install script."
echo ""
echo -e "  ${BOLD}Option 1 — Terminal:${NC}"
echo -e "    cd $(pwd)"
echo -e "    ./dictate.sh"
echo ""
echo -e "  ${BOLD}Option 2 — Hold-to-Record (recommended):${NC}"
echo -e "    1. Open ${BLUE}Hammerspoon${NC} from Applications"
echo -e "    2. Grant ${BLUE}Accessibility${NC} permission when prompted"
echo -e "    3. ${BOLD}Hold ⌥D${NC} (Option+D) to record, release to transcribe + paste"
echo ""
