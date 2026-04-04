#!/bin/bash
# ============================================================================
#  Voice Magic — Parakeet STT Engine (parakeet-mlx wrapper)
# ============================================================================
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"

AUDIO_FILE="$1"
RAW_TEXT_FILE="$2"

if [[ ! -f "$AUDIO_FILE" ]]; then
    echo "Error: Audio file not found at $AUDIO_FILE"
    exit 1
fi

# parakeet-mlx outputs transcribed text to stdout
# It auto-downloads the model on first run (~600MB)
PARAKEET_BIN="$SCRIPT_DIR/venv/bin/parakeet-mlx"

if [[ ! -x "$PARAKEET_BIN" ]]; then
    echo "Error: parakeet-mlx is not installed in the local venv. Run ./install.sh again."
    exit 1
fi

"$PARAKEET_BIN" "$AUDIO_FILE" 2>/dev/null | sed '/^$/d' > "$RAW_TEXT_FILE"
