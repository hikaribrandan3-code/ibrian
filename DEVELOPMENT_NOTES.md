# iBrain development notes — 30 September 2026

## Project origin and initial development

iBrain is a deliberately small personal Mac AI chat utility, built with AI-assisted coding. The existing source already included SwiftUI chat, Ollama streaming, local persistence, optional cloud clients, onboarding, and a packaging target. This pass refined onboarding, key handling, and privacy boundaries rather than adding a new feature set.

## Hands-on usage

The creator used iBrain and found it functional and responsive. Its simplicity is intentional. No broader usage, security certification, or production service claim is made.

## Source audit: 30 September 2026

First launch could trigger an automatic `llama3.2` pull even though the setup screen had an explicit download button. API keys were deleted and re-added to Keychain on every typed character, with errors ignored. Cloud mode with no key silently resolved to local behavior. Key validation treated most non-401 HTTP responses as “Working.” Welcome and packaging text said conversations never leave the Mac even though cloud mode exists. A legacy Ollama download helper was unused after the first-run path was removed. The Anthropic model identifier was checked against current provider documentation during the prior audit and left unchanged.

## Improvements made

- Removed the automatic first-run model pull and kept the guided, explicit download path.
- Updated Keychain entries in place and saved only on user action, reporting failure to the UI.
- Gave cloud mode without a key a clear setup state and blocked sends until a key is saved.
- Required HTTP 200 for a positive key test and clarified that provider errors may have several causes.
- Corrected local/cloud privacy copy and unnotarized-install guidance; removed the unused download helper and stale “100% local” claims.

## Verification performed

The release app compiled locally. The packaged app and disk image were checked for code-signing/integrity; no real provider key or model download was used for automated tests. The creator still needs to smoke-test Ollama startup, a consented model pull, saved-key behavior, and cloud/no-key UI before a draft binary becomes public.

## Known limitations and current status

Ollama and a local model must be installed separately. Cloud providers may change model access or reject a key due to billing, permissions, or rate limits; a failed check is not proof the key is malformed. Local chats are readable JSON in Application Support. The app is an ad-hoc signed, unnotarized Apple Silicon build with unverified Intel support. This is a credible small utility, not a hardened enterprise chat client.
