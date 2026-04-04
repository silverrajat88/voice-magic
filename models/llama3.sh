LLAMA_MODEL_FILE="Llama-3.2-3B-Instruct-Q4_K_M.gguf"
LLAMA_MODEL_URL="https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"

get_prompt() {
    local mode="$1"
    local raw_text="$2"
    local translate="$3"

    if [[ "$mode" == "dev" ]]; then
        echo "You are an expert developer. The user dictated a command. Translate this command into pure code or a terminal command. Output ONLY the raw code or command. Do not use markdown backticks unless asked. Do not add any explanation. 
Text: $raw_text
Code:"
    else
        if [[ "$translate" == "true" ]]; then
            echo "Translate the following dictated text into English, fix its grammar and punctuation, and remove filler words. Output ONLY the corrected English text, nothing else. Do not add any explanation. 
Text: $raw_text
Corrected English:"
        else
            echo "Fix the grammar, punctuation, and remove filler words from the following dictated text. Maintain the original language of the text. Do not translate it. Output ONLY the corrected text, nothing else. Do not add any explanation. 
Text: $raw_text
Corrected:"
        fi
    fi
}
