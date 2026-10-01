// iBrain Settings — model, language, system prompt, launch at login,
// delete all chats, version footer.
import SwiftUI
import ServiceManagement

enum Prefs {
    static let defaultModel = "defaultModel"
    static let language = "language"
    static let systemPrompt = "systemPrompt"
    static let useCloudAPI = "useCloudAPI"
    static let cloudProvider = "cloudProvider"
    static let appearance = "appearance"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            language: "en",
            systemPrompt: "",
            useCloudAPI: false,
            cloudProvider: CloudProvider.anthropic.rawValue,
            appearance: Appearance.system.rawValue,
        ])
    }
}

struct SettingsView: View {
    @ObservedObject var store: ChatStore
    @AppStorage(Prefs.language) private var languageRaw = "en"
    @AppStorage(Prefs.defaultModel) private var defaultModel = ""
    @AppStorage(Prefs.systemPrompt) private var systemPrompt = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var confirmingDelete = false
    @AppStorage(Prefs.useCloudAPI) private var useCloudAPI = false
    @AppStorage(Prefs.cloudProvider) private var cloudProviderRaw = CloudProvider.anthropic.rawValue
    @AppStorage(Prefs.appearance) private var appearanceRaw = Appearance.system.rawValue
    @State private var apiKeyInput = ""
    @State private var savedKey = ""
    @State private var keySaveFailed = false
    @State private var validating = false

    private var cloudProvider: CloudProvider {
        CloudProvider(rawValue: cloudProviderRaw) ?? .anthropic
    }

    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }

    private var language: Language {
        Language(rawValue: languageRaw) ?? .en
    }

    private var keyDirty: Bool {
        apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines) != savedKey
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(Strings.get("settings.general", lang: language))

                HStack {
                    Text(Strings.get("settings.model", lang: language))
                        .font(.system(size: 13))
                    Spacer()
                    Picker("", selection: $defaultModel) {
                        ForEach(store.models) { model in
                            Text(model.shortName + "  ·  " + model.sizeLabel).tag(model.name)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }

                HStack {
                    Text(Strings.get("settings.language", lang: language))
                        .font(.system(size: 13))
                    Spacer()
                    Picker("", selection: $languageRaw) {
                        ForEach(Language.allCases, id: \.id) { lang in
                            Text(lang.rawValue).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }

                HStack {
                    Text(Strings.get("settings.appearance", lang: language))
                        .font(.system(size: 13))
                    Spacer()
                    Picker("", selection: $appearanceRaw) {
                        ForEach(Appearance.allCases, id: \.id) { app in
                            Text(app.displayName).tag(app.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(Strings.get("settings.customAI", lang: language))

                Text(Strings.get("settings.customAI.subtitle", lang: language))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                TextField(
                    Strings.get("settings.systemPrompt.placeholder", lang: language),
                    text: $systemPrompt,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...7)
                .font(.system(size: 12))

                HStack(spacing: 6) {
                    presetButton("settings.customAI.preset.concise",
                        "You are a helpful AI assistant. Keep answers brief and to the point unless the user asks for more detail.")
                    presetButton("settings.customAI.preset.detailed",
                        "You are a thorough, thoughtful AI assistant. Explain your reasoning and cover edge cases.")
                    presetButton("settings.customAI.preset.creative",
                        "You are a creative, playful AI assistant. Feel free to use analogies, humor, and unconventional ideas.")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(Strings.get("settings.behavior", lang: language))

                Toggle(isOn: $launchAtLogin) {
                    HStack(spacing: 8) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.6, green: 0.3, blue: 0.95))
                            .frame(width: 18)
                        Text(Strings.get("settings.launchAtLogin", lang: language))
                            .font(.system(size: 13))
                    }
                }
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(Strings.get("settings.cloud", lang: language))

                Toggle(isOn: $useCloudAPI) {
                    HStack(spacing: 8) {
                        Image(systemName: "cloud")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 0.6, green: 0.3, blue: 0.95))
                            .frame(width: 18)
                        Text(Strings.get("settings.cloud.toggle", lang: language))
                            .font(.system(size: 13))
                    }
                }
                .onChange(of: useCloudAPI) { _, _ in store.cloudSettingsDidChange() }

                if useCloudAPI {
                    Picker("", selection: $cloudProviderRaw) {
                        ForEach(CloudProvider.allCases, id: \.id) { provider in
                            Text(provider.displayName).tag(provider.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .onChange(of: cloudProviderRaw) { _, _ in
                        savedKey = Keychain.load(provider: cloudProvider) ?? ""
                        apiKeyInput = savedKey
                        keySaveFailed = false
                        store.cloudKeyValid = nil
                        store.cloudSettingsDidChange()
                    }

                    SecureField(
                        cloudProvider.keyPlaceholder,
                        text: $apiKeyInput
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onChange(of: apiKeyInput) { _, _ in
                        store.cloudKeyValid = nil
                        keySaveFailed = false
                    }

                    HStack(spacing: 8) {
                        Button(Strings.get("settings.cloud.save", lang: language)) {
                            let candidate = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            if Keychain.save(candidate, provider: cloudProvider) {
                                savedKey = candidate
                                keySaveFailed = false
                                store.cloudKeyValid = nil
                                store.cloudSettingsDidChange()
                            } else {
                                keySaveFailed = true
                            }
                        }
                        .disabled(!keyDirty)
                        if keySaveFailed {
                            Text(Strings.get("settings.cloud.saveFailed", lang: language))
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                    }

                    HStack(spacing: 6) {
                        Button {
                            validating = true
                            Task {
                                await store.validateCloudKey()
                                validating = false
                            }
                        } label: {
                            if validating {
                                ProgressView().controlSize(.small)
                            } else {
                                Text(Strings.get("settings.cloud.test", lang: language))
                                    .font(.system(size: 12))
                            }
                        }
                        .disabled(savedKey.isEmpty || keyDirty || validating)

                        if let valid = store.cloudKeyValid {
                            HStack(spacing: 4) {
                                Image(systemName: valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(valid ? .green : .red)
                                Text(Strings.get(valid ? "settings.cloud.valid" : "settings.cloud.invalid", lang: language))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Text(Strings.get("settings.cloud.note", lang: language))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel(Strings.get("settings.danger", lang: language))
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text(Strings.get("settings.deleteAll", lang: language))
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    Strings.get("settings.deleteAll.confirmTitle", lang: language),
                    isPresented: $confirmingDelete
                ) {
                    Button(
                        Strings.get("settings.deleteAll.confirm", lang: language),
                        role: .destructive
                    ) {
                        store.deleteAllChats()
                    }
                    Button(Strings.get("settings.cancel", lang: language), role: .cancel) {}
                } message: {
                    Text(Strings.get("settings.deleteAll.confirmBody", lang: language))
                }
            }

            Spacer()

            Text(Strings.get("settings.version", lang: language))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(20)
        .frame(width: 380, height: 560, alignment: .topLeading)
        .onAppear {
            if defaultModel.isEmpty { defaultModel = store.defaultModel }
            savedKey = Keychain.load(provider: cloudProvider) ?? ""
            apiKeyInput = savedKey
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
    }

    private func presetButton(_ labelKey: String, _ prompt: String) -> some View {
        Button {
            systemPrompt = prompt
        } label: {
            Text(Strings.get(labelKey, lang: language))
                .font(.system(size: 11))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
