// Core data types — chats, messages, and Ollama model metadata.
import Foundation

enum Role: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: Role
    var content: String
    var date = Date()
    var modelName: String? = nil
    var durationSeconds: Double? = nil
}

struct Chat: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var messages: [ChatMessage] = []
    var model: String
    var createdAt = Date()
    var updatedAt = Date()
}

struct OllamaModel: Identifiable, Equatable {
    var name: String
    var sizeBytes: Int64

    var id: String { name }

    var sizeLabel: String {
        let gb = Double(sizeBytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    var shortName: String {
        name.hasSuffix(":latest") ? String(name.dropLast(7)) : name
    }
}

enum ServerStatus: Equatable {
    case checking
    case running
    case stopped
    case notInstalled
}

// Splits raw model output into text / fenced-code segments for rendering.
enum MessageSegment: Identifiable, Equatable {
    case text(String)
    case code(language: String, code: String)

    var id: String {
        switch self {
        case .text(let s): return "t:\(s.hashValue)"
        case .code(let lang, let code): return "c:\(lang.hashValue):\(code.hashValue)"
        }
    }

    static func parse(_ content: String) -> [MessageSegment] {
        var segments: [MessageSegment] = []
        var remaining = Substring(content)

        while let fenceStart = remaining.range(of: "```") {
            let before = remaining[remaining.startIndex..<fenceStart.lowerBound]
            if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(.text(String(before)))
            }
            let afterFence = remaining[fenceStart.upperBound...]
            // Language tag runs to end of the fence line
            let langEnd = afterFence.firstIndex(of: "\n") ?? afterFence.endIndex
            let language = String(afterFence[afterFence.startIndex..<langEnd])
                .trimmingCharacters(in: .whitespaces)
            let codeStart = langEnd < afterFence.endIndex
                ? afterFence.index(after: langEnd) : afterFence.endIndex
            let codeBody = afterFence[codeStart...]

            if let fenceEnd = codeBody.range(of: "```") {
                let code = String(codeBody[codeBody.startIndex..<fenceEnd.lowerBound])
                    .trimmingCharacters(in: .newlines)
                segments.append(.code(language: language, code: code))
                remaining = codeBody[fenceEnd.upperBound...]
            } else {
                // Unclosed fence (mid-stream) — render what we have as code
                let code = String(codeBody).trimmingCharacters(in: .newlines)
                segments.append(.code(language: language, code: code))
                remaining = Substring("")
            }
        }
        if !remaining.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            segments.append(.text(String(remaining)))
        }
        return segments
    }
}
