#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"
echo "Conf says translation is: $TRANSLATE_TO_ENGLISH"
TRANSLATE_FLAG=""
if [[ "${TRANSLATE_TO_ENGLISH:-false}" == "true" ]]; then
    TRANSLATE_FLAG="-tr"
fi
echo "Flag passed to whisper: $TRANSLATE_FLAG"
