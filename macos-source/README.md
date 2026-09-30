# iBrain for macOS

iBrain is a native SwiftUI chat app for macOS. It uses a local Ollama server by default and can optionally call OpenAI or Anthropic with an API key supplied by the user.

## What it includes

- Streaming local chat, model selection, chat search, and saved conversations
- First-run Ollama and model setup, including a guided download of the recommended model
- Optional OpenAI and Anthropic API modes (bring your own key; keys are stored in macOS Keychain)
- Custom system instructions, appearance controls, and English, Spanish, and Portuguese UI strings
- macOS 14 or later; Swift and SwiftUI, packaged with Swift Package Manager

Local conversations are stored in the user's Application Support folder. When cloud mode is enabled, prompts are sent to the selected provider.

## Build

Open this folder in Terminal and run:

```sh
swift build -c release
```

To package a `.app` bundle with the included Makefile, run `make app`. A full Xcode installation is the standard build setup. If SwiftPM fails with the affected Command Line Tools installation used during development, run `Packaging/setup-toolchain-fix.sh` and rerun the build.

Ollama is a separate local runtime. If it is not installed, the app displays setup instructions. The source repository does not include a compiled app or Ollama binary.
