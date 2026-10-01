# iBrain for macOS

iBrain is a small native SwiftUI chat app for macOS. It uses a separate local Ollama server by default and can optionally call OpenAI or Anthropic with a user-supplied API key.

## What it includes

- Streaming local chat, model selection, chat search, and saved conversations
- First-run Ollama and model setup; the recommended model downloads only after the user chooses it
- Optional OpenAI and Anthropic API modes (bring your own key; keys are stored in macOS Keychain)
- Custom system instructions, appearance controls, and English, Spanish, and Portuguese UI strings
- macOS 14 or later; Swift and SwiftUI, packaged with Swift Package Manager

Conversations are stored as plain JSON in the user's Application Support folder. Local mode talks to Ollama on `localhost:11434`. Cloud mode sends the selected conversation history and system instruction to the chosen provider over HTTPS and may be billed. Keys are saved to Keychain on an explicit button press; a missing key leaves cloud mode in a setup state instead of silently falling back. The test-key action makes a small provider request.

## Build

Open this folder in Terminal and run:

```sh
make app
```

The app bundle is written to `dist/iBrain.app`; `make dmg` packages it. Standard Xcode builds need no local workaround. `USE_TOOLCHAIN_FIX=1` is only for a machine where the separate Command Line Tools workaround is already installed. The build is ad-hoc signed and unnotarized, so macOS may show a first-open prompt.

Ollama is a separate local runtime. If it is not installed, the app displays setup instructions. No Ollama binary or model is included. The 1.0.1 app is staged for smoke testing; the public download is not yet updated. The current cloud model identifiers are `claude-sonnet-5` and `gpt-4o`; provider access can change. See [development notes](../DEVELOPMENT_NOTES.md).
