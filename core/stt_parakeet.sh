#!/bin/bash
set -euo pipefail
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
PYTHON_BIN="$SCRIPT_DIR/venv/bin/python"

if [[ ! -x "$PYTHON_BIN" ]]; then
    echo "Error: Python environment for parakeet not found. Run ./install.sh again."
    exit 1
fi

"$PYTHON_BIN" -c "
import sys, warnings
warnings.filterwarnings('ignore')
from parakeet_mlx import from_pretrained
model = from_pretrained('mlx-community/parakeet-tdt-0.6b-v3')
res = model.transcribe(sys.argv[1])
print(res.text)
" "$AUDIO_FILE" 2>/dev/null | sed '/^$/d' > "$RAW_TEXT_FILE"
