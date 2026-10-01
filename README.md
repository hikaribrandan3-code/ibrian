# iBrain

iBrain is a small macOS chat app built around local Ollama models. I built it as a focused personal AI utility and have used it successfully. It is intentionally simple: conversations, streaming responses, model selection, search, and optional bring-your-own-key cloud providers.

## What it does and how it is built

The native app uses Swift 6.1, SwiftUI/AppKit, Foundation `URLSession` streaming, macOS Keychain, and local JSON persistence. `ChatStore` coordinates conversations; `OllamaClient` talks to a separate local Ollama server; `OpenAIClient` and `AnthropicClient` are optional HTTPS paths. The UI has English, Spanish, and Portuguese strings. Source and build instructions are in [`macos-source/`](macos-source/README.md).

On first run, iBrain may start an installed Ollama server, but **does not download a model without a click**. If no model exists, setup offers the recommended `llama3.2` download and shows progress. Ollama and the model are separate downloads and are not bundled with this repository. Local chat works offline after those are installed.

## Local and cloud privacy

Local mode sends prompts to Ollama on `localhost:11434`. Conversations are saved as plain JSON in the user's Application Support folder. Cloud mode is optional: choosing OpenAI or Anthropic sends the selected conversation history and system instruction to that provider over HTTPS and may incur charges on the user's account. Cloud API keys are saved in macOS Keychain only when the user presses **Save key changes**; leaving cloud mode on without a saved key shows an explicit setup state. Clearing the field and saving removes the key. A key test sends a small request to the selected provider and reports success only for an HTTP 200 response.

The Anthropic implementation currently uses `claude-sonnet-5`; OpenAI uses `gpt-4o`. Model availability, provider policies, billing, and rate limits can change. There is no cloud relay or account owned by this project. The app does not encrypt its local chat JSON; anyone with access to the Mac user account's files may read it.

## Build and status

Requires macOS 14 or later and Xcode 16 with a Swift 6.1 compatible toolchain. Run `make app` or `make dmg` from `macos-source/`. The app is ad-hoc signed and not notarized. A 1.0.1 Apple Silicon build is staged for the creator's smoke test before public release. Intel compatibility is unverified. See [development notes](DEVELOPMENT_NOTES.md).

AI coding tools assisted the original app and this cleanup. I chose its scope, tested it on my Mac, reviewed the source, and recorded the changes and limits here. Licensed under MIT.
