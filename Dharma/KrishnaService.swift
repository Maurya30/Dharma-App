import Foundation
import Combine

// MARK: - Models

struct KrishnaRequest: Codable {
    let message: String
    let currentVerse: KrishnaVerse?
    let goals: [String]
    let reflection: String?
    let conversationHistory: [KrishnaMessage]?
}

struct KrishnaVerse: Codable {
    let id: String
    let source: String
    let english: String
}

struct KrishnaMessage: Codable, Identifiable {
    let id: UUID
    let role: String
    let content: String

    init(id: UUID = UUID(), role: String, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case role, content
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        role = try c.decode(String.self, forKey: .role)
        content = try c.decode(String.self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(role, forKey: .role)
        try c.encode(content, forKey: .content)
    }
}

// MARK: - Service

@MainActor
final class KrishnaService: ObservableObject {
    static let shared = KrishnaService()

    /// Free-tier cap for settings display; increment when the user sends a message.
    static let dailyMessageLimit = 25

    private static let messagesCalendarDayKey = "krishna_messages_calendar_day"
    private static let messagesCountTodayKey = "krishna_messages_count_today"

    @Published var streamingResponse: String = ""
    @Published var isStreaming: Bool = false
    @Published var conversationHistory: [KrishnaMessage] = []

    /// User messages sent today (resets per calendar day in the current timezone).
    @Published private(set) var messagesSentToday: Int = 0

    private let endpoint = BackendConfig.baseURL.appendingPathComponent("chat")

    private static let fallbackGoals = [
        "Develop non-attachment",
        "Build a daily meditation practice",
        "Become less reactive"
    ]

    private var goals: [String] {
        let user = GoalsManager.shared.selectedGoals
        return user.isEmpty ? Self.fallbackGoals : user
    }

    private var activeTask: URLSessionDataTask?

    init() {
        messagesSentToday = Self.readMessagesSentToday()
    }

    /// Syncs published count after calendar day changes (e.g. opening Settings at midnight).
    func refreshMessageUsageFromPersistence() {
        messagesSentToday = Self.readMessagesSentToday()
    }

    /// Messages sent today for quota display (same storage as `messagesSentToday`).
    static func messagesSentTodayCount() -> Int {
        let defaults = UserDefaults.standard
        let day = Self.currentCalendarDayString()
        guard defaults.string(forKey: messagesCalendarDayKey) == day else { return 0 }
        return defaults.integer(forKey: messagesCountTodayKey)
    }

    private static func currentCalendarDayString() -> String {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day], from: Date())
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private static func readMessagesSentToday() -> Int {
        messagesSentTodayCount()
    }

    private func recordOutgoingUserMessage() {
        let defaults = UserDefaults.standard
        let day = Self.currentCalendarDayString()
        if defaults.string(forKey: Self.messagesCalendarDayKey) != day {
            defaults.set(day, forKey: Self.messagesCalendarDayKey)
            defaults.set(1, forKey: Self.messagesCountTodayKey)
        } else {
            let n = defaults.integer(forKey: Self.messagesCountTodayKey)
            defaults.set(n + 1, forKey: Self.messagesCountTodayKey)
        }
        messagesSentToday = Self.readMessagesSentToday()
    }

    func sendMessage(_ text: String, verse: KrishnaVerse?) {
        recordOutgoingUserMessage()
        let userMessage = KrishnaMessage(role: "user", content: text)
        conversationHistory.append(userMessage)

        let historyForAPI = conversationHistory.dropLast().map {
            KrishnaMessage(role: $0.role, content: $0.content)
        }

        let request = KrishnaRequest(
            message: text,
            currentVerse: verse,
            goals: goals,
            reflection: nil,
            conversationHistory: Array(historyForAPI)
        )

        guard let body = try? JSONEncoder().encode(request) else { return }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = body

        streamingResponse = ""
        isStreaming = true

        let delegate = SSEDelegate { [weak self] chunk in
            Task { @MainActor in
                self?.streamingResponse += chunk
            }
        } onComplete: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                let full = self.streamingResponse
                if !full.isEmpty {
                    self.conversationHistory.append(
                        KrishnaMessage(role: "assistant", content: full)
                    )
                }
                self.streamingResponse = ""
                self.isStreaming = false
            }
        }

        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: urlRequest)
        activeTask = task
        task.resume()
    }

    func cancel() {
        activeTask?.cancel()
        activeTask = nil
        if isStreaming {
            if !streamingResponse.isEmpty {
                conversationHistory.append(
                    KrishnaMessage(role: "assistant", content: streamingResponse)
                )
            }
            streamingResponse = ""
            isStreaming = false
        }
    }

    func streamResponse(request: KrishnaRequest) -> AsyncThrowingStream<String, Error> {
        let url = endpoint
        guard let body = try? JSONEncoder().encode(request) else {
            return AsyncThrowingStream { $0.finish() }
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = body

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish()
                        return
                    }
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonStr = String(line.dropFirst(6))
                            if jsonStr == "[DONE]" { break }
                            if let data = jsonStr.data(using: .utf8),
                               let obj = try? JSONDecoder().decode([String: String].self, from: data),
                               let text = obj["text"] {
                                continuation.yield(text)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - SSE Delegate

private final class SSEDelegate: NSObject, URLSessionDataDelegate {
    private let onChunk: (String) -> Void
    private let onComplete: () -> Void
    private var buffer = ""
    private var totalBytes = 0
    private let maxStreamBytes = 50_000

    init(onChunk: @escaping (String) -> Void, onComplete: @escaping () -> Void) {
        self.onChunk = onChunk
        self.onComplete = onComplete
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalBytes += data.count
        if totalBytes > maxStreamBytes {
            dataTask.cancel()
            return
        }
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text

        while let range = buffer.range(of: "\n") {
            let line = String(buffer[buffer.startIndex..<range.lowerBound])
            buffer = String(buffer[range.upperBound...])
            parseLine(line)
        }
    }

    private func parseLine(_ line: String) {
        guard line.hasPrefix("data: ") else { return }
        let payload = String(line.dropFirst(6))
        guard payload != "[DONE]" else { return }

        if let data = payload.data(using: .utf8),
           let json = try? JSONDecoder().decode([String: String].self, from: data),
           let chunk = json["text"] {
            onChunk(chunk)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // flush any leftover line
        if !buffer.isEmpty { parseLine(buffer); buffer = "" }
        onComplete()
    }
}
