#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ -f /tmp/parakeet_server.pid ]]; then
    kill $(cat /tmp/parakeet_server.pid) 2>/dev/null || true
    rm -f /tmp/parakeet_server.pid
fi
if [[ -f /tmp/whisper_server.pid ]]; then
    kill $(cat /tmp/whisper_server.pid) 2>/dev/null || true
    rm -f /tmp/whisper_server.pid
fi
if [[ -f /tmp/llama_server.pid ]]; then
    kill $(cat /tmp/llama_server.pid) 2>/dev/null || true
    rm -f /tmp/llama_server.pid
fi

# Fallback rigorous kill just in case process IDs shuffled
pkill -f "server_parakeet.py" 2>/dev/null || true
pkill -f "whisper-server" 2>/dev/null || true
pkill -f "llama-server" 2>/dev/null || true
