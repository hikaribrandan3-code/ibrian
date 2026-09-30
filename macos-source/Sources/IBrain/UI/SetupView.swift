// Shown instead of the chat when Ollama is missing, stopped, or model-less.
import SwiftUI

struct SetupView: View {
    @ObservedObject var store: ChatStore
    let language: Language
    @State private var starting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            BrainBadge(size: 56)
                .padding(.bottom, 18)

            switch store.serverStatus {
            case .notInstalled:
                Text(Strings.get("setup.notInstalled.title", lang: language))
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.bottom, 5)
                Text(Strings.get("setup.notInstalled.subtitle", lang: language))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .padding(.bottom, 16)
                commandCard("brew install ollama\nollama pull llama3.2")

            case .stopped, .checking:
                Text(Strings.get("setup.title", lang: language))
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.bottom, 5)
                Text(Strings.get("setup.subtitle", lang: language))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .padding(.bottom, 18)
                Button {
                    starting = true
                    Task {
                        await store.refreshServer(autoStart: true)
                        starting = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        if starting || store.serverStatus == .checking {
                            ProgressView().controlSize(.small)
                            Text(Strings.get("setup.starting", lang: language))
                        } else {
                            Image(systemName: "play.fill").font(.system(size: 11))
                            Text(Strings.get("setup.start", lang: language))
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(starting)

            case .running:
                // Running but zero models
                if let progress = store.downloadProgress {
                    Text(Strings.get("setup.downloading.title", lang: language))
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.bottom, 5)
                    Text(Strings.get("setup.downloading.subtitle", lang: language))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                        .padding(.bottom, 18)
                    ProgressView(value: progress)
                        .frame(width: 220)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                } else {
                    Text(Strings.get("setup.noModels.title", lang: language))
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.bottom, 5)
                    Text(Strings.get("setup.noModels.ask", lang: language))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                        .padding(.bottom, 4)
                    Text(OllamaClient.recommendedModel)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 18)

                    if store.downloadFailed {
                        Text(Strings.get("setup.noModels.failed", lang: language))
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                            .padding(.bottom, 10)
                        commandCard("ollama pull \(OllamaClient.recommendedModel)")
                    } else {
                        HStack(spacing: 10) {
                            Button {
                                Task { await store.downloadRecommendedModel() }
                            } label: {
                                Text(Strings.get("setup.noModels.yes", lang: language))
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.downloadFailed = true
                            } label: {
                                Text(Strings.get("setup.noModels.no", lang: language))
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button {
                Task { await store.refreshServer(autoStart: false) }
            } label: {
                Text(Strings.get("setup.retry", lang: language))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func commandCard(_ command: String) -> some View {
        HStack(spacing: 10) {
            Text(command)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(white: 0.9))
                .multilineTextAlignment(.leading)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
