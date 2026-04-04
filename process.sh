#!/bin/bash
# ============================================================================
#  Voice Magic — Audio Processor (used by Hammerspoon hold-to-record)
#  Takes a recorded audio file → transcribes → refines → clipboard → paste
# ============================================================================
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"

CURRENT_APP="${1:-normal}"
AUDIO_FILE="${2:-/tmp/voice_magic_recording.wav}"
RAW_TEXT_FILE="/tmp/voice_magic_raw.txt"
REFINED_TEXT_FILE="/tmp/voice_magic_refined.txt"

# Resolve mode based on application
MODE="normal"
for app in "${DEV_APPS[@]}"; do
    if [[ "$CURRENT_APP" == "$app" ]]; then
        MODE="dev"
        break
    fi
done

if [[ ! -f "$AUDIO_FILE" ]]; then exit 1; fi

"$SCRIPT_DIR/core/stt_engine.sh" "$AUDIO_FILE" "$RAW_TEXT_FILE"

if [[ ! -f "$RAW_TEXT_FILE" || ! -s "$RAW_TEXT_FILE" ]]; then
    osascript -e 'display notification "No speech detected" with title "Voice Magic"'
    exit 0
fi

if [[ "${SKIP_LLM_PROCESSING:-false}" == "true" ]]; then
    cp "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
else
    "$SCRIPT_DIR/core/llm_engine.sh" "$MODE" "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
fi

REFINED_TEXT="$(cat "$REFINED_TEXT_FILE")"

# Safe paste (Backup clipboard, set clipboard, paste, restore clipboard)
OLD_CLIPBOARD=$(pbpaste)

echo -n "$REFINED_TEXT" | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'
osascript -e "display notification \"$(echo "$REFINED_TEXT" | head -1)\" with title \"Voice Magic\" subtitle \"Pasted to cursor\""

sleep 0.5
echo -n "$OLD_CLIPBOARD" | pbcopy

rm -f "$AUDIO_FILE" "$RAW_TEXT_FILE" "$REFINED_TEXT_FILE"
