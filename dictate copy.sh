#!/bin/bash
# ============================================================================
#  Voice Magic — Dictation Runner
#  Records your voice → transcribes with Whisper → refines with Llama → clipboard
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WHISPER_CLI="$SCRIPT_DIR/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL="$SCRIPT_DIR/whisper.cpp/models/ggml-large-v3-turbo.bin"
LLAMA_CLI="$SCRIPT_DIR/llama.cpp/build/bin/llama-completion"
LLAMA_MODEL="$SCRIPT_DIR/llama.cpp/models/Llama-3.2-3B-Instruct-Q4_K_M.gguf"

AUDIO_FILE="/tmp/voice_magic_recording.wav"
RAW_TEXT_FILE="/tmp/voice_magic_raw.txt"

# Verify binaries exist
for bin in "$WHISPER_CLI" "$LLAMA_CLI"; do
    if [[ ! -f "$bin" ]]; then
        echo "Error: $bin not found. Run install.sh first."
        exit 1
    fi
done

# ── Record ────────────────────────────────────────────────────────────────────
# Play a "start recording" sound
afplay /System/Library/Sounds/Tink.aiff &

echo "🎙️  Listening... (speak now, stops after 1.5s of silence)"
sox -d -r 16000 -c 1 -b 16 "$AUDIO_FILE" silence 1 0.1 1% 1 1.5 1%

# Play a "done recording" sound
afplay /System/Library/Sounds/Pop.aiff &

echo "🔄 Transcribing with Whisper..."

# ── Transcribe ────────────────────────────────────────────────────────────────
"$WHISPER_CLI" \
    -m "$WHISPER_MODEL" \
    -f "$AUDIO_FILE" \
    --no-timestamps \
    -t 4 \
    2>/dev/null | sed '/^$/d' > "$RAW_TEXT_FILE"

RAW_TEXT="$(cat "$RAW_TEXT_FILE")"

if [[ -z "$RAW_TEXT" ]]; then
    echo "⚠️  No speech detected."
    exit 0
fi

echo "📝 Raw transcription: $RAW_TEXT"
echo "✨ Refining with Llama..."

# ── Refine ────────────────────────────────────────────────────────────────────
PROMPT="Fix the grammar, punctuation, and remove filler words from the following dictated text. Output ONLY the corrected text, nothing else. Do not add any explanation.

Text: $RAW_TEXT

Corrected:"

REFINED_TEXT_FILE="/tmp/voice_magic_refined.txt"

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
    # Fallback to raw text if refinement fails
    REFINED_TEXT="$RAW_TEXT"
    echo "⚠️  Llama refinement failed — using raw transcription"
fi

# ── Clipboard ─────────────────────────────────────────────────────────────────
echo -n "$REFINED_TEXT" | pbcopy

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Copied to clipboard:"
echo "$REFINED_TEXT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Cleanup temp files
rm -f "$AUDIO_FILE" "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"






