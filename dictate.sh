#!/bin/bash
# ============================================================================
#  Voice Magic — Dictation Runner (Terminal Mode)
#  Records your voice → transcribes with Whisper → refines with Llama → clipboard
# ============================================================================
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"

AUDIO_FILE="/tmp/voice_magic_recording.wav"
RAW_TEXT_FILE="/tmp/voice_magic_raw.txt"
REFINED_TEXT_FILE="/tmp/voice_magic_refined.txt"

afplay /System/Library/Sounds/Tink.aiff &
echo "🎙️  Listening... (speak now, stops after 1.5s of silence)"
sox -d -r 16000 -c 1 -b 16 "$AUDIO_FILE" silence 1 0.1 1% 1 1.5 1%
afplay /System/Library/Sounds/Pop.aiff &

echo "🔄 Transcribing with Whisper..."
"$SCRIPT_DIR/core/stt_engine.sh" "$AUDIO_FILE" "$RAW_TEXT_FILE"

if [[ ! -f "$RAW_TEXT_FILE" || ! -s "$RAW_TEXT_FILE" ]]; then
    echo "⚠️  No speech detected."
    exit 0
fi

RAW_TEXT="$(cat "$RAW_TEXT_FILE")"
echo "📝 Raw transcription: $RAW_TEXT"

if [[ "${SKIP_LLM_PROCESSING:-false}" == "true" ]]; then
    echo "⚡ Skipping LLM refinement..."
    cp "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
else
    echo "✨ Refining with AI..."
    "$SCRIPT_DIR/core/llm_engine.sh" "normal" "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
fi

REFINED_TEXT="$(cat "$REFINED_TEXT_FILE")"

echo -n "$REFINED_TEXT" | pbcopy
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Copied to clipboard:"
echo "$REFINED_TEXT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

rm -f "$AUDIO_FILE" "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
