LLAMA_MODEL_FILE="deepseek-coder-1.3b-instruct.Q4_K_M.gguf"
LLAMA_MODEL_URL="https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF/resolve/main/deepseek-coder-1.3b-instruct.Q4_K_M.gguf"

get_prompt() {
    local mode="$1"
    local raw_text="$2"
    local translate="$3"

    if [[ "$mode" == "dev" ]]; then
        echo "### Instruction:
You are an elite developer. Formulate the following dictation into precise, accurate code. Output ONLY the exact raw code. Do not output markdown code blocks. Do not append any trailing text.

Dictation: $raw_text

### Response:"
    else
        if [[ "$translate" == "true" ]]; then
            echo "### Instruction:
You are a transcriber. Translate the following text into English, fixing grammatical errors. Do NOT write any code! Do NOT write python or explanations! Output ONLY the corrected text.

Text: $raw_text

### Response:"
        else
            echo "### Instruction:
You are a transcriber. Fix the grammar of the following text while retaining the exact original language. Do NOT write any code! Output ONLY the corrected text with no extra commentary.

Text: $raw_text

### Response:"
        fi
    fi
}
