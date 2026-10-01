// Bring-your-own-key path for OpenAI — mirrors AnthropicClient's shape so
// ChatStore can treat every cloud provider the same way.
import Foundation

struct OpenAIClient {
    static let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    static let defaultModel = "gpt-4o"

    private struct StreamChunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable {
                var content: String?
            }
            var delta: Delta?
        }
        var choices: [Choice]
    }

    static func chat(
        apiKey: String,
        messages: [ChatMessage],
        systemPrompt: String,
        onToken: @escaping @Sendable (String) -> Void
    ) async throws {
        var payloadMessages: [[String: String]] = []
        let trimmedSystem = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSystem.isEmpty {
            payloadMessages.append(["role": "system", "content": trimmedSystem])
        }
        for m in messages {
            payloadMessages.append(["role": m.role.rawValue, "content": m.content])
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 300
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": defaultModel,
            "messages": payloadMessages,
            "stream": true,
        ])

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw OpenAIError.invalidKey }
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let json = line.dropFirst(6)
            if json == "[DONE]" { break }
            guard let data = json.data(using: .utf8),
                  let chunk = try? decoder.decode(StreamChunk.self, from: data) else { continue }
            if let token = chunk.choices.first?.delta?.content, !token.isEmpty {
                onToken(token)
            }
        }
    }

    static func validateKey(_ apiKey: String) async -> Bool {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    enum OpenAIError: Error {
        case invalidKey
    }
}
