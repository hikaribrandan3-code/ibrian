// Optional cloud path for power users — calls Claude directly with the
// user's own API key (stored in Keychain). Mirrors OllamaClient's shape
// so ChatStore can treat both engines the same way.
import Foundation

struct AnthropicClient {
    static let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    static let defaultModel = "claude-sonnet-5"
    static let apiVersion = "2023-06-01"

    private struct StreamEvent: Decodable {
        struct Delta: Decodable {
            var type: String?
            var text: String?
        }
        var type: String
        var delta: Delta?
    }

    static func chat(
        apiKey: String,
        messages: [ChatMessage],
        systemPrompt: String,
        onToken: @escaping @Sendable (String) -> Void
    ) async throws {
        var payloadMessages: [[String: String]] = []
        for m in messages where m.role != .system {
            payloadMessages.append(["role": m.role.rawValue, "content": m.content])
        }

        var body: [String: Any] = [
            "model": defaultModel,
            "max_tokens": 4096,
            "messages": payloadMessages,
            "stream": true,
        ]
        let trimmedSystem = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSystem.isEmpty {
            body["system"] = trimmedSystem
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 300
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw AnthropicError.invalidKey }
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let json = line.dropFirst(6)
            guard let data = json.data(using: .utf8),
                  let event = try? decoder.decode(StreamEvent.self, from: data) else { continue }
            if event.type == "content_block_delta", let text = event.delta?.text, !text.isEmpty {
                onToken(text)
            }
        }
    }

    // Lightweight validation — a 401 means the key is bad, anything else we treat as reachable.
    static func validateKey(_ apiKey: String) async -> Bool {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 8
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": defaultModel,
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]],
        ])
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode != 401
    }

    enum AnthropicError: Error {
        case invalidKey
    }
}
