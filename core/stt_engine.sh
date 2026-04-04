#!/bin/bash
# ============================================================================
#  Voice Magic — Speech To Text Engine (STT Router)
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

STT_ENGINE="${STT_ENGINE:-whisper}"

if [[ "$STT_ENGINE" == "parakeet" ]]; then
    # ── Parakeet (via parakeet-mlx, Apple MLX) ────────────────────────────
    "$SCRIPT_DIR/core/stt_parakeet.sh" "$AUDIO_FILE" "$RAW_TEXT_FILE"
else
    # ── Whisper (via whisper.cpp, Metal GPU) ──────────────────────────────
    WHISPER_CLI="$SCRIPT_DIR/whisper.cpp/build/bin/whisper-cli"
    WHISPER_MODEL="$SCRIPT_DIR/whisper.cpp/models/ggml-large-v3-turbo.bin"

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
fi
