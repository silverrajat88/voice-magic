# 🎙️ Voice Magic

**Fully offline, privacy-first voice dictation for macOS.**

Speak into your mic → get clean, punctuated text. Everything runs locally — no cloud, no API keys, no subscriptions.

---

## How It Works

```
🎤 Your Voice → [STT Engine] → Raw Text → [LLM Engine] → Clean Text → 📋 Clipboard/Paste
```

| Component | What it does | Analogy |
|-----------|-------------|---------|
| **STT Engine** | Converts speech to text (Whisper or Parakeet) | The "ears" — listens and transcribes |
| **LLM Engine** | Cleans up text using AI (Llama, DeepSeek, or Qwen) | The "brain" — fixes grammar, translates, outputs code |
| **sox** | Records audio from your microphone | The "microphone cable" |
| **Hammerspoon** | Global hotkey listener for hold-to-record | The "trigger" — hold ⌥D from any app |

### Jargon Buster

| Term | Plain English |
|------|--------------|
| **Whisper** | OpenAI's AI model that converts spoken words into text. Highly accurate and natively supports translating to English. |
| **Parakeet** | NVIDIA's incredibly fast STT model (`parakeet-tdt-0.6b-v3`), heavily optimized for Apple Silicon via Apple MLX. Extremely speedy (~600MB footprint) but does not natively translate speech in real-time. |
| **Llama** | Meta's AI model for generating and refining text. Excellent for general grammar correction and creative prose. |
| **DeepSeek / Qwen** | Highly optimized coding AI models. Perfect for dictating shell commands or programming tasks. Might lack the casual prose nuance of Llama. |
| **whisper.cpp / llama.cpp** | C++ ports that run right on your Mac using GPU acceleration without heavy python setups. |
| **GGML / GGUF** | File formats for AI models optimized to run on regular computers ("MP3 for AI"). |
| **Quantization** | A compression technique that shrinks AI models by ~4x while keeping quality. |
| **Hammerspoon** | A free macOS automation tool for listening to hotkeys. |

---

## System Requirements

- **macOS** 12+ (Monterey or later)
- **Apple Silicon** recommended (M1/M2/M3/M4) — Needed to fully leverage Parakeet via MLX
- **~4-5 GB** free disk space (depends on the AI models chosen)
- **Xcode Command Line Tools** (the installer prompts you if missing)
- **Homebrew** — install from [brew.sh](https://brew.sh) if you don't have it

---

## Installation

```bash
chmod +x install.sh
./install.sh
```

**What happens behind the scenes:**
1. Installs build tools (`cmake`, `sox`, `wget`)
2. Compiles `whisper.cpp` & `llama.cpp` with Metal (GPU) support
3. Downloads your configured models (Whisper, Llama/DeepSeek/Qwen)
4. Initiates a local Python environment for Parakeet (if selected in config)
5. Installs Hammerspoon and configures the hotkey listener

Takes **10-20 minutes** (mostly downloading models depending on internet). _Tip: The installer is idempotent and skips completed tasks!_

### Creating a Release (.dmg)
Voice Magic includes an automated DMG compiler so you can package changes beautifully without needing any Apple Developer licenses.
1. Make your code changes.
2. Run `./build_dmg.sh` in your terminal. 
3. A lightweight installation payload `VoiceMagic.dmg` will dynamically generate inside a new `dist/` folder, completely stripped of heavy caches and strictly containing your updated core files, ready to be uploaded to GitHub Releases!

---

## Configuration (`voice-magic.conf`)

Before or after installing, open `voice-magic.conf` to perfectly tailor Voice Magic to your workflow:

### 1. The Ears (Speech-to-Text)
- `STT_ENGINE="whisper"`: High accuracy, native translation ability.
- `STT_ENGINE="parakeet"`: **Ultra-fast** transcription (NVIDIA/Apple MLX). _Caveat: Parakeet supports 17 languages but cannot natively translate them across to English on the fly like Whisper. It will transcribe in the spoken language, leaving translation to the LLM step._

### 2. The Brain (Refinement Models)
- `ACTIVE_MODEL="llama3"`: General-purpose language refinement ([Llama 3.2 3B Instruct](https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF)).
- `ACTIVE_MODEL="deepseek"`: Exceptional for coding and terminal commands ([DeepSeek Coder 1.3B](https://huggingface.co/TheBloke/deepseek-coder-1.3b-instruct-GGUF)). _Caveat: Best suited for developers; general prose might be rigid._
- `ACTIVE_MODEL="qwencoder"`: Blistering fast code completion logic ([Qwen 2.5 Coder 1.5B](https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF)). _Caveat: Similar to DeepSeek, heavily code biased._

### 3. Hyper-Speed Modes
- `SKIP_LLM_PROCESSING="true"`: Turn off the LLM ("The Brain") altogether. Voice Magic will drop raw transcribed text into your clipboard in under a second!

### 4. Persistent Memory Servers
Voice Magic supports ultra-low latency model processing by invisibly keeping the models loaded directly in your macOS unified memory.
- `AUTO_START_SERVERS="true"`: Dictates whether these servers turn on automatically when Hammerspoon boots. Set to `false` to manually boot them via the macOS Menu bar dropdown.
- `LLM_PORT`, `WHISPER_PORT`, `PARAKEET_PORT`: Expose standard HTTP ports locally on `127.0.0.1` allowing deep configuration avoiding conflicts with other software.

---

## Usage

### 🎯 Hold-to-Record (Recommended)

Works dynamically across **any app** and feels just like an integrated OS feature!

1. **Open Hammerspoon** from Applications.
2. Grant permissions: **Privacy & Security → Accessibility & Microphone**.
3. **Hold ⌥D** (Option+D) to start recording. You'll hear a system "tink".
4. **Release ⌥D** when done.
5. Watch the magically corrected text paste seamlessly into your active application.

### 🌍 Multilingual vs Translation

Voice Magic natively supports languages like Hindi!
- To type exactly in the spoken language (e.g. Hindi, Spanish), set `LANGUAGE="hi"` or leave `LANGUAGE="auto"`.
- If using **Whisper**, you can enable `TRANSLATE_TO_ENGLISH="true"` in the config to cleanly transcribe your spoken Hindi seamlessly into polished English inline!

### 💻 Terminal Mode

```bash
./dictate.sh
```

Stops recording at 1.5 seconds of silence, dropping text right onto your clipboard.

---

## File Structure

```
voice-magic/
├── install.sh          ← Setup application
├── uninstall.sh        ← Remove application and dependencies
├── voice-magic.conf    ← Configuration hub (Models, Languages, Translations)
├── dictate.sh          ← Terminal mode CLI script
├── process.sh          ← Hammerspoon processing handler
├── core/               ← Engine routing logic (STT & LLM loaders)
├── models/             ← Prompt/URL configurations for Llama/DeepSeek/Qwen
├── venv/               ← Python environment containing parakeet-mlx
├── whisper.cpp/        ← C++ Speech-to-text binaries and models
└── llama.cpp/          ← C++ LLM binaries and models
```

---

## Troubleshooting

### Checking Server Status
If you are utilizing the Persistent Memory Servers (via Hammerspoon) and want to verify if they are running in the background, run this command in your terminal:
```bash
# Show active memory servers bound to their respective ports
lsof -iTCP -sTCP:LISTEN -P | grep -E '8080|8081|8082'

# See how much Unified Memory (in MB) each server is aggressively consuming
ps -eo rss,command | awk '/whisper-server|llama-server|server_parakeet/ && !/awk/ {printf "%.2f MB  %s\n", $1/1024, $2}'

# Or view their live event logs
tail -n 15 /tmp/*_server.log
```

- **"No speech detected"**: Ensure Terminal or Hammerspoon has Microphone permission in Privacy & Security settings.
- **Dictation slowness**: Apple Silicon Macs will process text gracefully under 2-3 seconds. Non-Apple Silicon Intel Macs will see delays ranging from 10-20 seconds. If necessary, toggle `SKIP_LLM_PROCESSING="true"` in the config.
- **Missing Models**: Restart `./install.sh`. Interrupted downloads will pick up where they broke off.
- **Empty Clipboard in Terminal**: Check `/tmp/voice_magic_raw.txt`. If empty, the mic isn't bridging properly inside `sox`.

---

## Credits

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) & [llama.cpp](https://github.com/ggerganov/llama.cpp) by Georgi Gerganov.
- [Hammerspoon](https://www.hammerspoon.org/) — Global macOS automation.
- [Parakeet-MLX](https://github.com/ml-explore/mlx-examples/tree/main/parakeet) — NVIDIA's Parakeet port for Apple Silicon MLX by Apple.
- [Qwen](https://github.com/QwenLM/Qwen2.5-Coder) — Qwen Coder variants.
- [DeepSeek](https://github.com/deepseek-ai/DeepSeek-Coder) — DeepSeek Coder AI.
