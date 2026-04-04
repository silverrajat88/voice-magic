#!/bin/bash
set -euo pipefail

# ============================================================================
#  Voice Magic — One-Script Installer
#  Local AI dictation: whisper.cpp (speech-to-text) + llama.cpp (text cleanup)
#  Everything installs into this directory. No global pollution.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
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

# ── Detect architecture ──────────────────────────────────────────────────────
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

BREW_DEPS=(cmake sox wget)
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
    else
        info "whisper.cpp directory exists, skipping clone"
    fi

    info "Building whisper.cpp with Metal (GPU) support..."
    cd "$WHISPER_DIR"
    cmake -B build -DGGML_METAL=ON
    cmake --build build -j "$(sysctl -n hw.logicalcpu)" --config Release
    cd "$SCRIPT_DIR"

    if [[ -f "$WHISPER_DIR/build/bin/whisper-cli" ]]; then
        success "whisper.cpp built successfully"
    else
        error "whisper.cpp build failed"
    fi
fi

# ── Step 3: Whisper model ────────────────────────────────────────────────────
step "Step 3/8: Downloading Whisper model (large-v3-turbo, ~1.6 GB)"

WHISPER_MODEL_DIR="$WHISPER_DIR/models"
WHISPER_MODEL="$WHISPER_MODEL_DIR/ggml-large-v3-turbo.bin"

if [[ -f "$WHISPER_MODEL" ]]; then
    success "Whisper model already downloaded — skipping"
else
    info "Downloading ggml-large-v3-turbo model..."
    mkdir -p "$WHISPER_MODEL_DIR"
    wget -q --show-progress -O "$WHISPER_MODEL" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
    success "Whisper model downloaded"
fi

# ── Step 4: llama.cpp ────────────────────────────────────────────────────────
step "Step 4/8: Setting up llama.cpp (text refinement engine)"

LLAMA_DIR="$SCRIPT_DIR/llama.cpp"

if [[ -f "$LLAMA_DIR/build/bin/llama-cli" ]]; then
    success "llama.cpp already built — skipping"
else
    if [[ ! -d "$LLAMA_DIR" ]]; then
        info "Cloning llama.cpp..."
        git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
    else
        info "llama.cpp directory exists, skipping clone"
    fi

    info "Building llama.cpp with Metal (GPU) support..."
    cd "$LLAMA_DIR"
    cmake -B build -DGGML_METAL=ON
    cmake --build build -j "$(sysctl -n hw.logicalcpu)" --config Release
    cd "$SCRIPT_DIR"

    if [[ -f "$LLAMA_DIR/build/bin/llama-cli" ]]; then
        success "llama.cpp built successfully"
    else
        error "llama.cpp build failed"
    fi
fi

# ── Step 5: Llama model ──────────────────────────────────────────────────────
step "Step 5/8: Downloading Llama model (3.2-3B-Instruct, ~2 GB)"

LLAMA_MODEL_DIR="$LLAMA_DIR/models"
LLAMA_MODEL="$LLAMA_MODEL_DIR/Llama-3.2-3B-Instruct-Q4_K_M.gguf"

if [[ -f "$LLAMA_MODEL" ]]; then
    success "Llama model already downloaded — skipping"
else
    info "Downloading Llama-3.2-3B-Instruct-Q4_K_M model..."
    mkdir -p "$LLAMA_MODEL_DIR"
    wget -q --show-progress -O "$LLAMA_MODEL" \
        "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    success "Llama model downloaded"
fi

# ── Step 6: Config Generator ─────────────────────────────────────────────────
step "Step 6/8: Setting up voice-magic.conf"

CONF_FILE="$SCRIPT_DIR/voice-magic.conf"
if [[ ! -f "$CONF_FILE" ]]; then
cat > "$CONF_FILE" << 'CONF_EOF'
# ============================================================================
#  Voice Magic — Configuration
# ============================================================================

# The language to dictate in. 
# Defaults to 'auto' to automatically detect the language (English, Hindi, etc.)
# If you dictate predominantly in one language, set it to the language code 
# to improve accuracy and speed: e.g. 'en', 'hi', 'es'
LANGUAGE="auto"

# Set to 'true' to seamlessly translate all spoken languages (e.g., Hindi)
# into beautifully polished English text before pasting.
TRANSLATE_TO_ENGLISH="false"
CONF_EOF
    success "voice-magic.conf created"
else
    success "voice-magic.conf already exists — skipping"
fi

# ── Step 7: Create scripts ───────────────────────────────────────────────────
step "Step 7/8: Creating runner scripts"

DICTATE_SCRIPT="$SCRIPT_DIR/dictate.sh"
cat > "$DICTATE_SCRIPT" << 'DICTATE_EOF'
#!/bin/bash
# ============================================================================
#  Voice Magic — Dictation Runner (Terminal Mode)
#  Records your voice → transcribes with Whisper → refines with Llama → clipboard
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"

WHISPER_CLI="$SCRIPT_DIR/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL="$SCRIPT_DIR/whisper.cpp/models/ggml-large-v3-turbo.bin"
LLAMA_CLI="$SCRIPT_DIR/llama.cpp/build/bin/llama-completion"
LLAMA_MODEL="$SCRIPT_DIR/llama.cpp/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf"

AUDIO_FILE="/tmp/voice_magic_recording.wav"
RAW_TEXT_FILE="/tmp/voice_magic_raw.txt"
REFINED_TEXT_FILE="/tmp/voice_magic_refined.txt"

for bin in "$WHISPER_CLI" "$LLAMA_CLI"; do
    if [[ ! -f "$bin" ]]; then
        echo "Error: $bin not found. Run install.sh first."
        exit 1
    fi
done

afplay /System/Library/Sounds/Tink.aiff &
echo "🎙️  Listening... (speak now, stops after 1.5s of silence)"
sox -d -r 16000 -c 1 -b 16 "$AUDIO_FILE" silence 1 0.1 1% 1 1.5 1%
afplay /System/Library/Sounds/Pop.aiff &
echo "🔄 Transcribing with Whisper..."

TRANSLATE_FLAG=""
if [[ "${TRANSLATE_TO_ENGLISH:-false}" == "true" ]]; then
    TRANSLATE_FLAG="-tr"
fi

"$WHISPER_CLI" \
    -m "$WHISPER_MODEL" \
    -f "$AUDIO_FILE" \
    -l "$LANGUAGE" \
    $TRANSLATE_FLAG \
    --no-timestamps \
    -t 4 \
    2>/dev/null | sed '/^$/d' > "$RAW_TEXT_FILE"

RAW_TEXT="$(cat "$RAW_TEXT_FILE")"

if [[ -z "$RAW_TEXT" ]]; then
    echo "⚠️  No speech detected."
    exit 0
fi

echo "📝 Raw transcription ($LANGUAGE): $RAW_TEXT"
echo "✨ Refining with Llama..."

if [[ "${TRANSLATE_TO_ENGLISH:-false}" == "true" ]]; then
    PROMPT="Fix the grammar, punctuation, and remove filler words from the following dictated text. Output ONLY the corrected text, nothing else. Do not add any explanation.

Text: $RAW_TEXT

Corrected:"
else
    PROMPT="Fix the grammar, punctuation, and remove filler words from the following dictated text. Maintain the original language of the text. Do not translate it. Output ONLY the corrected text, nothing else. Do not add any explanation.

Text: $RAW_TEXT

Corrected:"
fi

"$LLAMA_CLI" \
    -m "$LLAMA_MODEL" \
    -p "$PROMPT" \
    -n 256 \
    --temp 0.1 \
    --no-display-prompt \
    -t 4 \
    < /dev/null \
    2>/dev/null | grep -v '^>' | sed '/^$/d' | head -5 > "$REFINED_TEXT_FILE"

REFINED_TEXT="$(cat "$REFINED_TEXT_FILE")"

if [[ -z "$REFINED_TEXT" ]]; then
    REFINED_TEXT="$RAW_TEXT"
    echo "⚠️  Llama refinement failed — using raw transcription"
fi

echo -n "$REFINED_TEXT" | pbcopy
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Copied to clipboard:"
echo "$REFINED_TEXT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
rm -f "$AUDIO_FILE" "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
DICTATE_EOF
chmod +x "$DICTATE_SCRIPT"
success "dictate.sh created"

PROCESS_SCRIPT="$SCRIPT_DIR/process.sh"
cat > "$PROCESS_SCRIPT" << 'PROCESS_EOF'
#!/bin/bash
# ============================================================================
#  Voice Magic — Audio Processor (used by Hammerspoon hold-to-record)
#  Takes a recorded audio file → transcribes → refines → clipboard → paste
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"

WHISPER_CLI="$SCRIPT_DIR/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL="$SCRIPT_DIR/whisper.cpp/models/ggml-large-v3-turbo.bin"
LLAMA_CLI="$SCRIPT_DIR/llama.cpp/build/bin/llama-completion"
LLAMA_MODEL="$SCRIPT_DIR/llama.cpp/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf"

AUDIO_FILE="${1:-/tmp/voice_magic_recording.wav}"
RAW_TEXT_FILE="/tmp/voice_magic_raw.txt"
REFINED_TEXT_FILE="/tmp/voice_magic_refined.txt"

if [[ ! -f "$AUDIO_FILE" ]]; then exit 1; fi

for bin in "$WHISPER_CLI" "$LLAMA_CLI"; do
    if [[ ! -f "$bin" ]]; then exit 1; fi
done

TRANSLATE_FLAG=""
if [[ "${TRANSLATE_TO_ENGLISH:-false}" == "true" ]]; then
    TRANSLATE_FLAG="-tr"
fi

"$WHISPER_CLI" \
    -m "$WHISPER_MODEL" \
    -f "$AUDIO_FILE" \
    -l "$LANGUAGE" \
    $TRANSLATE_FLAG \
    --no-timestamps \
    -t 4 \
    2>/dev/null | sed '/^$/d' > "$RAW_TEXT_FILE"

RAW_TEXT="$(cat "$RAW_TEXT_FILE")"

if [[ -z "$RAW_TEXT" ]]; then
    osascript -e 'display notification "No speech detected" with title "Voice Magic"'
    exit 0
fi

if [[ "${TRANSLATE_TO_ENGLISH:-false}" == "true" ]]; then
    PROMPT="Fix the grammar, punctuation, and remove filler words from the following dictated text. Output ONLY the corrected text, nothing else. Do not add any explanation.

Text: $RAW_TEXT

Corrected:"
else
    PROMPT="Fix the grammar, punctuation, and remove filler words from the following dictated text. Maintain the original language of the text. Do not translate it. Output ONLY the corrected text, nothing else. Do not add any explanation.

Text: $RAW_TEXT

Corrected:"
fi

"$LLAMA_CLI" \
    -m "$LLAMA_MODEL" \
    -p "$PROMPT" \
    -n 256 \
    --temp 0.1 \
    --no-display-prompt \
    -t 4 \
    < /dev/null \
    2>/dev/null | grep -v '^>' | sed '/^$/d' | head -5 > "$REFINED_TEXT_FILE"

REFINED_TEXT="$(cat "$REFINED_TEXT_FILE")"
if [[ -z "$REFINED_TEXT" ]]; then
    REFINED_TEXT="$RAW_TEXT"
fi

echo -n "$REFINED_TEXT" | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'
osascript -e "display notification \"$(echo "$REFINED_TEXT" | head -1)\" with title \"Voice Magic\" subtitle \"Pasted to cursor\""

rm -f "$AUDIO_FILE" "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
PROCESS_EOF
chmod +x "$PROCESS_SCRIPT"
success "process.sh created"

# ── Step 8: Hammerspoon (Hold-to-Record) ─────────────────────────────────────
step "Step 8/8: Setting up Hammerspoon (hold-to-record hotkey)"

if ! brew list --cask hammerspoon &>/dev/null; then
    info "Installing Hammerspoon..."
    brew install --cask hammerspoon
    success "Hammerspoon installed"
else
    success "Hammerspoon already installed"
fi

SOX_PATH="$(which sox)"
HAMMERSPOON_DIR="$HOME/.hammerspoon"
mkdir -p "$HAMMERSPOON_DIR"

VOICE_MAGIC_LUA="$SCRIPT_DIR/voice-magic.lua"
cat > "$VOICE_MAGIC_LUA" << LUAEOF
-- Voice Magic — Hammerspoon Config
local VOICE_MAGIC_DIR = "$SCRIPT_DIR"
local AUDIO_FILE = "/tmp/voice_magic_recording.wav"
local PROCESS_SCRIPT = VOICE_MAGIC_DIR .. "/process.sh"
local SOX_PATH = "$SOX_PATH"

local recording = false
local soxTask = nil
local processingAlert = nil

hs.hotkey.bind({"alt"}, "d",
    function()
        if recording then return end
        recording = true
        hs.sound.getByFile("/System/Library/Sounds/Tink.aiff"):play()
        processingAlert = hs.alert.show("🎙️ Recording...", hs.alert.defaultStyle, hs.screen.mainScreen(), "forever")
        soxTask = hs.task.new(SOX_PATH, nil, {
            "-d", "-r", "16000", "-c", "1", "-b", "16", AUDIO_FILE
        })
        soxTask:start()
    end,
    function()
        if not recording then return end
        recording = false
        if processingAlert then hs.alert.closeSpecific(processingAlert) end
        if soxTask and soxTask:isRunning() then
            soxTask:terminate()
            hs.timer.usleep(300000)
        end
        hs.sound.getByFile("/System/Library/Sounds/Pop.aiff"):play()
        processingAlert = hs.alert.show("✨ Processing...", hs.alert.defaultStyle, hs.screen.mainScreen(), 30)
        hs.task.new("/bin/bash", function(exitCode)
            if processingAlert then hs.alert.closeSpecific(processingAlert) end
            if exitCode ~= 0 then hs.alert.show("⚠️ Voice Magic failed", 3) end
        end, {PROCESS_SCRIPT, AUDIO_FILE}):start()
    end
)

local menubar = hs.menubar.new()
if menubar then
    menubar:setTitle("🎙️")
    menubar:setMenu({
        { title = "Voice Magic Active", disabled = true },
        { title = "-" },
        { title = "Hold ⌥D to dictate", disabled = true },
        { title = "-" },
        { title = "Open Folder", fn = function() hs.execute("open " .. VOICE_MAGIC_DIR) end },
        { title = "Reload", fn = function() hs.reload() end },
    })
end

hs.alert.show("🎙️ Voice Magic loaded — Hold ⌥D to dictate", 3)
LUAEOF
success "voice-magic.lua created"

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
echo -e "${GREEN}${BOLD}  ✅ Voice Magic installed successfully!${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
echo -e "  ${BOLD}Permissions needed:${NC}"
echo -e "    ${BLUE}System Settings → Privacy & Security → Accessibility${NC} → enable Hammerspoon"
echo -e "    ${BLUE}System Settings → Privacy & Security → Microphone${NC} → enable Hammerspoon"
echo ""
