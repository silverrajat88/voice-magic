# Acknowledgements & Credits

**Voice Magic** stands on the shoulders of giants. This macOS utility would not be possible without the profound contributions of the open-source community and the incredible researchers democratizing artificial intelligence.

We formally acknowledge, credit, and pay tribute to the following projects, models, and teams:

### 1. The Inference Engines
* **[whisper.cpp](https://github.com/ggerganov/whisper.cpp) & [llama.cpp](https://github.com/ggerganov/llama.cpp)**: Created by Georgi Gerganov and the immense open-source community. These projects are the absolute backbone of Voice Magic, enabling heavy AI models to run blazingly fast on Apple Silicon via Metal (GPU) acceleration.

### 2. The Speech-to-Text (STT) Models
* **[Whisper](https://openai.com/index/whisper/) by OpenAI**: Used as our highly accurate default audio transcription model (`large-v3-turbo`).
* **[Parakeet](https://github.com/ml-explore/mlx-examples/tree/main/parakeet) by NVIDIA (via Apple MLX)**: Used as our ultra-fast secondary acoustic transcription model (`parakeet-tdt-0.6b-v3`), specifically ported by the Apple Machine Learning team to run natively on Mac architecture.

### 3. The Large Language Models (LLMs)
* **[Llama 3](https://llama.meta.com/) by Meta**: The foundational model powering our language grammar correction and translation feature (`Llama-3.2-3B-Instruct`).
* **[DeepSeek Coder](https://github.com/deepseek-ai/DeepSeek-Coder)**: Providing world-class intelligence for dictating developer terminology (`deepseek-coder-1.3b-instruct`).
* **[Qwen](https://github.com/QwenLM/Qwen2.5-Coder) by Alibaba Cloud**: A tremendously efficient model for rapid, small-footprint code completions (`Qwen2.5-Coder-1.5B`).

### 4. System Automation
* **[Hammerspoon](https://www.hammerspoon.org/)**: The phenomenal open-source macOS automation engine allowing Voice Magic to listen to the hold-to-record global hotkeys seamlessly.

---

*Thank you to everyone who opens their weights and source code to the world!*
