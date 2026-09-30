// Bring-your-own-key providers. This is not "we host it" — the user pastes
// their own key from their own account with that provider, billed to them.
import Foundation

enum CloudProvider: String, CaseIterable, Identifiable {
    case anthropic
    case openai

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: return "Anthropic (Claude)"
        case .openai: return "OpenAI (GPT)"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .anthropic: return "sk-ant-..."
        case .openai: return "sk-proj-..."
        }
    }

    var keyPrefixHint: String {
        switch self {
        case .anthropic: return "sk-ant-"
        case .openai: return "sk-"
        }
    }
}
