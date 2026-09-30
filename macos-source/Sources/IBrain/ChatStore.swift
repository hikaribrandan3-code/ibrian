// Central state: chat list, active streaming, Ollama server status, and
// JSON persistence under ~/Library/Application Support/iBrain/.
import AppKit
import Foundation
import SwiftUI

@MainActor
final class ChatStore: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var selectedChatID: UUID?
    @Published var models: [OllamaModel] = []
    @Published var serverStatus: ServerStatus = .checking
    @Published var isStreaming = false
    @Published var searchText = ""
    @Published var cloudKeyValid: Bool?
    @Published var downloadProgress: Double?
    @Published var downloadFailed = false

    private var streamTask: Task<Void, Never>?
    private var saveDebounce: Task<Void, Never>?

    static let storageDir = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("iBrain", isDirectory: true)
    static let storageFile = storageDir.appendingPathComponent("chats.json")

    var selectedChat: Chat? {
        guard let id = selectedChatID else { return nil }
        return chats.first { $0.id == id }
    }

    var defaultModel: String {
        let stored = UserDefaults.standard.string(forKey: Prefs.defaultModel) ?? ""
        if models.contains(where: { $0.name == stored }) { return stored }
        return models.first?.name ?? stored
    }

    var filteredChats: [Chat] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return chats }
        return chats.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.messages.contains { $0.content.localizedCaseInsensitiveContains(query) }
        }
    }

    // MARK: - Lifecycle

    init() {
        // The suite trigger watcher must be alive even if the window never
        // appears (background launch) — a voice question boots the store.
        startSuiteTriggerWatcher()
    }

    private var booted = false

    func boot() {
        guard !booted else { return }
        booted = true
        load()
        Task {
            await refreshServer(autoStart: true)
            // Auto-download model on first launch if none exist
            if !useCloudAPI && models.isEmpty {
                _ = await OllamaClient.downloadModel("llama3.2")
                await refreshModels()
            }
        }
    }

    // MARK: - Suite voice trigger (iVoz "ask Claude …")
    //
    // iVoz writes a question to <App Support>/com.hikari.ibrain/trigger;
    // we poll once a second (suite convention), open the window, and send
    // the question to the active model.

    private var suiteTriggerTimer: Timer?

    private static let suiteTriggerURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.hikari.ibrain", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("trigger")
    }()

    private func startSuiteTriggerWatcher() {
        guard suiteTriggerTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkSuiteTrigger() }
        }
        RunLoop.main.add(timer, forMode: .common)
        suiteTriggerTimer = timer
    }

    private func checkSuiteTrigger() {
        let url = Self.suiteTriggerURL
        guard FileManager.default.fileExists(atPath: url.path),
              let question = try? String(contentsOf: url, encoding: .utf8) else { return }
        try? FileManager.default.removeItem(at: url)
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        boot()
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.identifier?.rawValue == "main" {
            window.makeKeyAndOrderFront(nil)
        }

        let languageRaw = UserDefaults.standard.string(forKey: Prefs.language) ?? "en"
        let language = Language(rawValue: languageRaw) ?? .en

        // Ollama may still be starting (boot autostarts it) — wait for the
        // server before sending so the question isn't silently dropped.
        Task { @MainActor in
            for _ in 0..<20 {
                if useCloudAPI || serverStatus == .running { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            self.newChat()
            self.send(trimmed, language: language)
        }
    }

    func refreshServer(autoStart: Bool = false) async {
        serverStatus = .checking
        if await OllamaClient.ping() {
            serverStatus = .running
            await refreshModels()
            return
        }
        guard OllamaClient.binaryInstalled else {
            serverStatus = .notInstalled
            return
        }
        if autoStart {
            OllamaClient.startServerIfNeeded()
            // Give the server a moment to come up, then poll a few times
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if await OllamaClient.ping() {
                    serverStatus = .running
                    await refreshModels()
                    return
                }
            }
        }
        serverStatus = .stopped
    }

    func refreshModels() async {
        models = (try? await OllamaClient.listModels()) ?? []
    }

    func downloadRecommendedModel() async {
        downloadFailed = false
        downloadProgress = 0
        do {
            try await OllamaClient.pullModel(name: OllamaClient.recommendedModel) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }
            downloadProgress = nil
            await refreshModels()
        } catch {
            downloadProgress = nil
            downloadFailed = true
        }
    }

    var selectedProvider: CloudProvider {
        CloudProvider(rawValue: UserDefaults.standard.string(forKey: Prefs.cloudProvider) ?? "") ?? .anthropic
    }

    var useCloudAPI: Bool {
        UserDefaults.standard.bool(forKey: Prefs.useCloudAPI)
            && (Keychain.load(provider: selectedProvider)?.isEmpty == false)
    }

    func validateCloudKey() async {
        let provider = selectedProvider
        guard let key = Keychain.load(provider: provider), !key.isEmpty else {
            cloudKeyValid = nil
            return
        }
        switch provider {
        case .anthropic:
            cloudKeyValid = await AnthropicClient.validateKey(key)
        case .openai:
            cloudKeyValid = await OpenAIClient.validateKey(key)
        }
    }

    // MARK: - Chat management

    func newChat() {
        selectedChatID = nil
    }

    func deleteChat(_ id: UUID) {
        chats.removeAll { $0.id == id }
        if selectedChatID == id { selectedChatID = nil }
        save()
    }

    func deleteAllChats() {
        stopStreaming()
        chats = []
        selectedChatID = nil
        save()
    }

    func setModel(_ model: String, for chatID: UUID) {
        guard let idx = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[idx].model = model
        save()
    }

    // MARK: - Sending

    func send(_ text: String, language: Language) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let usingCloud = useCloudAPI
        guard !trimmed.isEmpty, !isStreaming, usingCloud || serverStatus == .running else { return }

        let chatID: UUID
        if let existing = selectedChatID, chats.contains(where: { $0.id == existing }) {
            chatID = existing
        } else {
            var title = trimmed.replacingOccurrences(of: "\n", with: " ")
            if title.count > 42 { title = String(title.prefix(42)) + "…" }
            let chat = Chat(title: title, model: defaultModel)
            chats.insert(chat, at: 0)
            selectedChatID = chat.id
            chatID = chat.id
        }

        guard let idx = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[idx].messages.append(ChatMessage(role: .user, content: trimmed))
        chats[idx].updatedAt = Date()

        let model = chats[idx].model
        let history = chats[idx].messages
        let systemPrompt = UserDefaults.standard.string(forKey: Prefs.systemPrompt) ?? ""
        let started = Date()

        // Placeholder assistant message that fills in as tokens stream
        let assistant = ChatMessage(role: .assistant, content: "", modelName: model)
        let assistantID = assistant.id
        chats[idx].messages.append(assistant)
        isStreaming = true

        let provider = selectedProvider
        let cloudKey = usingCloud ? Keychain.load(provider: provider) : nil

        streamTask = Task { [weak self] in
            do {
                if let cloudKey {
                    switch provider {
                    case .anthropic:
                        try await AnthropicClient.chat(
                            apiKey: cloudKey,
                            messages: history,
                            systemPrompt: systemPrompt
                        ) { token in
                            Task { @MainActor [weak self] in
                                self?.appendToken(token, chatID: chatID, messageID: assistantID)
                            }
                        }
                    case .openai:
                        try await OpenAIClient.chat(
                            apiKey: cloudKey,
                            messages: history,
                            systemPrompt: systemPrompt
                        ) { token in
                            Task { @MainActor [weak self] in
                                self?.appendToken(token, chatID: chatID, messageID: assistantID)
                            }
                        }
                    }
                } else {
                    try await OllamaClient.chat(
                        model: model,
                        messages: history,
                        systemPrompt: systemPrompt
                    ) { token in
                        Task { @MainActor [weak self] in
                            self?.appendToken(token, chatID: chatID, messageID: assistantID)
                        }
                    }
                }
                await MainActor.run { [weak self] in
                    self?.finishStreaming(chatID: chatID, messageID: assistantID, started: started)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if let cIdx = self.chats.firstIndex(where: { $0.id == chatID }),
                       let mIdx = self.chats[cIdx].messages.firstIndex(where: { $0.id == assistantID }) {
                        if self.chats[cIdx].messages[mIdx].content.isEmpty && !Task.isCancelled {
                            self.chats[cIdx].messages[mIdx].content =
                                Strings.get("chat.error", lang: language)
                        }
                    }
                    self.finishStreaming(chatID: chatID, messageID: assistantID, started: started)
                    if cloudKey == nil {
                        Task { await self.refreshServer() }
                    }
                }
            }
        }
    }

    private func appendToken(_ token: String, chatID: UUID, messageID: UUID) {
        guard let cIdx = chats.firstIndex(where: { $0.id == chatID }),
              let mIdx = chats[cIdx].messages.firstIndex(where: { $0.id == messageID })
        else { return }
        chats[cIdx].messages[mIdx].content += token
    }

    private func finishStreaming(chatID: UUID, messageID: UUID, started: Date) {
        if let cIdx = chats.firstIndex(where: { $0.id == chatID }),
           let mIdx = chats[cIdx].messages.firstIndex(where: { $0.id == messageID }) {
            chats[cIdx].messages[mIdx].durationSeconds = Date().timeIntervalSince(started)
            // Drop the bubble entirely if nothing ever arrived
            if chats[cIdx].messages[mIdx].content.isEmpty {
                chats[cIdx].messages.remove(at: mIdx)
            }
            chats[cIdx].updatedAt = Date()
        }
        isStreaming = false
        streamTask = nil
        save()
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: Self.storageFile),
              let decoded = try? JSONDecoder().decode([Chat].self, from: data)
        else { return }
        chats = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    func save() {
        saveDebounce?.cancel()
        let snapshot = chats
        saveDebounce = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            try? FileManager.default.createDirectory(
                at: Self.storageDir, withIntermediateDirectories: true)
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: Self.storageFile, options: .atomic)
            }
        }
    }
}
