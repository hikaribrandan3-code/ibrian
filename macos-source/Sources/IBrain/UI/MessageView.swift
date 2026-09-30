// Renders one chat message — blue right-aligned bubble for the user,
// purple brain avatar + markdown/code segments for the assistant.
import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    let language: Language
    let isLast: Bool
    let isStreaming: Bool

    var body: some View {
        if message.role == .user {
            userBubble
        } else {
            assistantMessage
        }
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 60)
            Text(message.content)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .textSelection(.enabled)
        }
    }

    private var assistantMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            BrainBadge(size: 28)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 10) {
                if message.content.isEmpty && isStreaming && isLast {
                    ThinkingDots()
                } else {
                    ForEach(MessageSegment.parse(message.content)) { segment in
                        switch segment {
                        case .text(let text):
                            MarkdownText(text: text)
                        case .code(let lang, let code):
                            CodeBlock(language: lang, code: code, uiLanguage: language)
                        }
                    }
                }
                if let duration = message.durationSeconds, let model = message.modelName {
                    Text("\(shortModel(model)) · \(String(format: "%.1f", duration))s")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 40)
        }
    }

    private func shortModel(_ name: String) -> String {
        name.hasSuffix(":latest") ? String(name.dropLast(7)) : name
    }
}

// Inline-markdown text with graceful fallback to plain text.
struct MarkdownText: View {
    let text: String

    var body: some View {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let attributed = try? AttributedString(
            markdown: trimmed,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            Text(attributed)
                .font(.system(size: 14))
                .lineSpacing(4)
                .textSelection(.enabled)
        } else {
            Text(trimmed)
                .font(.system(size: 14))
                .lineSpacing(4)
                .textSelection(.enabled)
        }
    }
}

// Dark code card with language tag + Copy button.
struct CodeBlock: View {
    let language: String
    let code: String
    let uiLanguage: Language
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language.isEmpty ? "code" : language)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(white: 0.62))
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copied = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        copied = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(Strings.get(copied ? "chat.copied" : "chat.copy", lang: uiLanguage))
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Color(white: copied ? 0.85 : 0.62))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(red: 0.16, green: 0.16, blue: 0.18))

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(white: 0.9))
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Three pulsing dots while the model warms up.
struct ThinkingDots: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .padding(.vertical, 8)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000)
                phase = (phase + 1) % 3
            }
        }
    }
}
