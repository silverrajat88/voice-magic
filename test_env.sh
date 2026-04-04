source ./voice-magic.conf
echo "Lang: $LANGUAGE"
echo "Translate: $TRANSLATE_TO_ENGLISH"
if [[ "${TRANSLATE_TO_ENGLISH:-false}" == "true" ]]; then
    echo "Flag active!"
fi
