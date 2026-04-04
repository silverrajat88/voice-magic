LLAMA_MODEL_FILE="qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"
LLAMA_MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"

get_prompt() {
    local mode="$1"
    local raw_text="$2"
    local translate="$3"

    if [[ "$mode" == "dev" ]]; then
        echo "You are Qwen, a brilliant programmer. Write code that perfectly fulfills the user's spoken command. Output ONLY the raw executable code. No markdown formatting, no explanations, no text.
Command: $raw_text
Code:"
    else
        if [[ "$translate" == "true" ]]; then
            echo "You are an expert transcriber. Translate the text directly to fluent English and correct all grammar faults. Output ONLY the corrected text.
Text: $raw_text
Output:"
        else
            echo "You are an expert transcriber. Correct the grammar and remove filler words from the text in its native language. Output ONLY the corrected text.
Text: $raw_text
Output:"
        fi
    fi
}
