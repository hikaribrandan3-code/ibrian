// Main chat pane — header (title, Local dot, model picker), message scroll,
// welcome empty state, and the input bar.
import SwiftUI

struct ChatView: View {
    @ObservedObject var store: ChatStore
    let language: Language
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let chat = store.selectedChat, !chat.messages.isEmpty {
                messageList(chat)
            } else {
                WelcomeView(store: store, language: language) { prompt in
                    draft = prompt
                    inputFocused = true
                }
            }
            Divider()
            inputBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text(store.selectedChat?.title ?? Strings.get("chat.newTitle", lang: language))
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(store.useCloudAPI || store.serverStatus == .running ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
                Text(Strings.get(store.useCloudAPI ? "chat.cloud" : "chat.local", lang: language))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if !store.useCloudAPI {
                modelPicker
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var modelPicker: some View {
        Menu {
            ForEach(store.models) { model in
                Button {
                    if let chatID = store.selectedChatID {
                        store.setModel(model.name, for: chatID)
                    }
                    UserDefaults.standard.set(model.name, forKey: Prefs.defaultModel)
                } label: {
                    if currentModel == model.name {
                        Label(model.shortName, systemImage: "checkmark")
                    } else {
                        Text(model.shortName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(shortName(currentModel))
                    .font(.system(size: 12))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var currentModel: String {
        store.selectedChat?.model ?? store.defaultModel
    }

    private func shortName(_ name: String) -> String {
        name.isEmpty ? "—" : (name.hasSuffix(":latest") ? String(name.dropLast(7)) : name)
    }

    private func messageList(_ chat: Chat) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(chat.messages) { message in
                        MessageView(
                            message: message,
                            language: language,
                            isLast: message.id == chat.messages.last?.id,
                            isStreaming: store.isStreaming
                        )
                        .id(message.id)
                    }
                }
                .padding(18)
            }
            .onChange(of: chat.messages.last?.content) {
                if let lastID = chat.messages.last?.id {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
            .onChange(of: chat.messages.count) {
                if let lastID = chat.messages.last?.id {
                    withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField(
                    Strings.get("chat.placeholder", lang: language),
                    text: $draft,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .lineLimit(1...6)
                .focused($inputFocused)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .onSubmit(sendDraft)

                if store.isStreaming {
                    Button {
                        store.stopStreaming()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .help(Strings.get("chat.stop", lang: language))
                } else {
                    Button(action: sendDraft) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(canSend ? Color.accentColor : Color.gray.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            Text(Strings.get("settings.version", lang: language))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (store.useCloudAPI || store.serverStatus == .running)
    }

    private func sendDraft() {
        guard canSend, !store.isStreaming else { return }
        let text = draft
        draft = ""
        store.send(text, language: language)
    }
}

// Empty-state welcome — brain mark, pitch, quick-start tiles, model status.
struct WelcomeView: View {
    @ObservedObject var store: ChatStore
    let language: Language
    let onPick: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            BrainBadge(size: 56)
                .padding(.bottom, 18)
            Text(Strings.get("welcome.title", lang: language))
                .font(.system(size: 21, weight: .semibold))
                .padding(.bottom, 5)
            Text(Strings.get("welcome.subtitle", lang: language))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.bottom, 24)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                tile("chevron.left.forwardslash.chevron.right", "welcome.tile.code", "welcome.prompt.code")
                tile("lightbulb", "welcome.tile.ideas", "welcome.prompt.ideas")
                tile("pencil", "welcome.tile.edit", "welcome.prompt.edit")
                tile("graduationcap", "welcome.tile.explain", "welcome.prompt.explain")
            }
            .frame(maxWidth: 320)
            .padding(.bottom, 22)

            if !store.models.isEmpty {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("\(shortName(store.defaultModel)) \(Strings.get("welcome.ready", lang: language))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.05))
                .clipShape(Capsule())
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tile(_ symbol: String, _ titleKey: String, _ promptKey: String) -> some View {
        Button {
            onPick(Strings.get(promptKey, lang: language))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.6, green: 0.3, blue: 0.95))
                Text(Strings.get(titleKey, lang: language))
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func shortName(_ name: String) -> String {
        name.hasSuffix(":latest") ? String(name.dropLast(7)) : name
    }
}
