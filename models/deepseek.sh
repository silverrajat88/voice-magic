LLAMA_MODEL_FILE="deepseek-coder-1.3b-instruct.Q4_K_M.gguf"
LLAMA_MODEL_URL="https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF/resolve/main/deepseek-coder-1.3b-instruct.Q4_K_M.gguf"

get_prompt() {
    local mode="$1"
    local raw_text="$2"
    local translate="$3"

    if [[ "$mode" == "dev" ]]; then
        echo "You are an elite developer. Formulate the following dictation into precise, accurate code. Output ONLY the exact raw code. Do not output markdown code blocks. Do not append any trailing text. 
User: $raw_text
Code Output:"
    else
        if [[ "$translate" == "true" ]]; then
            echo "You are a professional editor. Translate the following text into perfect English, fixing any grammatical errors. Output ONLY the raw corrected text with no extra commentary. 
Text: $raw_text
Corrected:"
        else
            echo "You are a professional editor. Fix the grammar of the following text while retaining the exact original language. Output ONLY the raw corrected text with no extra commentary.
Text: $raw_text
Corrected:"
        fi
    fi
}
