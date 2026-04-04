#!/bin/bash
# ============================================================================
#  Voice Magic — LLM Engine (llama.cpp wrapper)
# ============================================================================
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"

# Default to llama3 if unset
ACTIVE_MODEL="${ACTIVE_MODEL:-llama3}"

# Load the model-specific functions
if [[ -f "$SCRIPT_DIR/models/${ACTIVE_MODEL}.sh" ]]; then
    source "$SCRIPT_DIR/models/${ACTIVE_MODEL}.sh"
else
    echo "Error: Model definition $ACTIVE_MODEL not found in models/"
    exit 1
fi

LLAMA_CLI="$SCRIPT_DIR/llama.cpp/build/bin/llama-completion"
LLAMA_MODEL_PATH="$SCRIPT_DIR/llama.cpp/models/$LLAMA_MODEL_FILE"

MODE="${1:-normal}"
RAW_TEXT_FILE="$2"
REFINED_TEXT_FILE="$3"

RAW_TEXT="$(cat "$RAW_TEXT_FILE")"

if [[ -z "$RAW_TEXT" ]]; then
    exit 0
fi

# Fetch the prompt from the active model configurations
PROMPT="$(get_prompt "$MODE" "$RAW_TEXT" "${TRANSLATE_TO_ENGLISH:-false}")"

"$LLAMA_CLI" \
    -m "$LLAMA_MODEL_PATH" \
    -p "$PROMPT" \
    -n 512 \
    --temp 0.0 \
    --no-display-prompt \
    -t 4 \
    -r "User:" \
    -r "Text:" \
    -r "###" \
    -r "<jupyter_text>" \
    -r " [end of text]" \
    < /dev/null \
    2>/dev/null | grep -v '^>' | sed '/^$/d' | grep -v '```' | \
    sed -e '/^Text:$/d' -e '/^User:$/d' -e '/^Code Output:$/d' -e '/^Corrected:$/d' -e '/^Code:$/d' -e '/^Output:$/d' -e '/^Corrected English:$/d' \
    | head -25 > "$REFINED_TEXT_FILE"

REFINED_TEXT="$(cat "$REFINED_TEXT_FILE")"

# Fallback in case LLM bugs out
if [[ -z "$REFINED_TEXT" ]]; then
    REFINED_TEXT="$RAW_TEXT"
fi

echo -n "$REFINED_TEXT" > "$REFINED_TEXT_FILE"
