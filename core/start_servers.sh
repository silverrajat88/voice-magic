#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/voice-magic.conf"

"$SCRIPT_DIR/core/stop_servers.sh"

echo "Booting Voice Magic Servers..."

STT_ENGINE="${STT_ENGINE:-whisper}"
if [[ "$STT_ENGINE" == "parakeet" ]]; then
    PYTHON_BIN="$SCRIPT_DIR/venv/bin/python"
    nohup "$PYTHON_BIN" "$SCRIPT_DIR/core/server_parakeet.py" "${PARAKEET_PORT:-8082}" > /tmp/parakeet_server.log 2>&1 &
    echo $! > /tmp/parakeet_server.pid
else
    WHISPER_SRV="$SCRIPT_DIR/whisper.cpp/build/bin/whisper-server"
    WHISPER_MODEL="$SCRIPT_DIR/whisper.cpp/models/ggml-large-v3-turbo.bin"
    nohup "$WHISPER_SRV" -m "$WHISPER_MODEL" --host 127.0.0.1 --port "${WHISPER_PORT:-8081}" > /tmp/whisper_server.log 2>&1 &
    echo $! > /tmp/whisper_server.pid
fi

if [[ "${SKIP_LLM_PROCESSING:-false}" != "true" ]]; then
    ACTIVE_MODEL="${ACTIVE_MODEL:-llama3}"
    source "$SCRIPT_DIR/models/${ACTIVE_MODEL}.sh"
    LLAMA_SRV="$SCRIPT_DIR/llama.cpp/build/bin/llama-server"
    LLAMA_MODEL_PATH="$SCRIPT_DIR/llama.cpp/models/$LLAMA_MODEL_FILE"
    
    nohup "$LLAMA_SRV" -m "$LLAMA_MODEL_PATH" -c 1024 --host 127.0.0.1 --port "${LLM_PORT:-8080}" > /tmp/llama_server.log 2>&1 &
    echo $! > /tmp/llama_server.pid
fi

# Hammerspoon Monitor Daemon
nohup bash -c "while pgrep -x Hammerspoon > /dev/null; do sleep 5; done; $SCRIPT_DIR/core/stop_servers.sh" > /dev/null 2>&1 &
