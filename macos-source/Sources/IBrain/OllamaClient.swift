// Thin client for the local Ollama server (http://localhost:11434).
// Streaming chat via NDJSON lines from /api/chat; model list via /api/tags.
import Foundation

struct OllamaClient {
    static let baseURL = URL(string: "http://localhost:11434")!

    struct ChatChunk: Decodable {
        struct Msg: Decodable {
            var role: String?
            var content: String?
        }
        var message: Msg?
        var done: Bool?
    }

    private struct TagsResponse: Decodable {
        struct Entry: Decodable {
            var name: String
            var size: Int64?
        }
        var models: [Entry]
    }

    static func ping() async -> Bool {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/tags"))
        request.timeoutInterval = 2
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    static func listModels() async throws -> [OllamaModel] {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/tags"))
        request.timeoutInterval = 3
        let (data, _) = try await URLSession.shared.data(for: request)
        let tags = try JSONDecoder().decode(TagsResponse.self, from: data)
        return tags.models.map { OllamaModel(name: $0.name, sizeBytes: $0.size ?? 0) }
    }

    // Streams assistant tokens; calls onToken on each content delta.
    static func chat(
        model: String,
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

        var request = URLRequest(url: baseURL.appendingPathComponent("api/chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "messages": payloadMessages,
            "stream": true,
        ])

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8),
                  let chunk = try? decoder.decode(ChatChunk.self, from: data) else { continue }
            if let token = chunk.message?.content, !token.isEmpty {
                onToken(token)
            }
            if chunk.done == true { break }
        }
    }

    static let recommendedModel = "llama3.2"

    private struct PullChunk: Decodable {
        var status: String?
        var completed: Int64?
        var total: Int64?
        var error: String?
    }

    // Streams download progress (0...1) for `ollama pull <name>`.
    static func pullModel(
        name: String,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/pull"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 1800
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "name": name,
            "stream": true,
        ])

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8),
                  let chunk = try? decoder.decode(PullChunk.self, from: data) else { continue }
            if let error = chunk.error, !error.isEmpty {
                throw PullError.serverError(error)
            }
            if let completed = chunk.completed, let total = chunk.total, total > 0 {
                onProgress(Double(completed) / Double(total))
            }
        }
        onProgress(1.0)
    }

    enum PullError: Error {
        case serverError(String)
    }

    // Finds the ollama binary and starts the server detached if it's not running.
    @discardableResult
    static func startServerIfNeeded() -> Bool {
        // Try bundled Ollama first, then system installs
        let bundled = Bundle.main.bundlePath + "/Contents/Resources/ollama/ollama"
        let candidates = [bundled, "/opt/homebrew/bin/ollama", "/usr/local/bin/ollama"]
        guard let binary = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
        else { return false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = ["serve"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    static var binaryInstalled: Bool {
        let bundled = Bundle.main.bundlePath + "/Contents/Resources/ollama/ollama"
        return [bundled, "/opt/homebrew/bin/ollama", "/usr/local/bin/ollama"]
            .contains { FileManager.default.isExecutableFile(atPath: $0) }
    }

}
