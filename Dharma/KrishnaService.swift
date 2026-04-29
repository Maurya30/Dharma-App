import Foundation
import Combine

// MARK: - Models

struct KrishnaRequest: Codable {
    let message: String
    let currentVerse: KrishnaVerse?
    let goals: [String]
    let reflection: String?
    let conversationHistory: [KrishnaMessage]?
    let lastOfferingSummary: String?
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

    // #region agent log
    fileprivate nonisolated static func debugLog(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any] = [:]
    ) {
        #if DEBUG
        guard let url = URL(string: "http://127.0.0.1:7914/ingest/6ac49fb4-6cd8-4bd2-9f4f-411bd80ceae6") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("461672", forHTTPHeaderField: "X-Debug-Session-Id")
        let payload: [String: Any] = [
            "sessionId": "461672",
            "runId": "pre-fix",
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        URLSession.shared.uploadTask(with: req, from: body).resume()
        #endif
    }
    // #endregion

    /// Free-tier cap for settings display; increment when the user sends a message.
    static let dailyMessageLimit = 25

    private static let messagesCalendarDayKey = "krishna_messages_calendar_day"
    private static let messagesCountTodayKey = "krishna_messages_count_today"

    @Published var streamingResponse: String = ""
    @Published var isStreaming: Bool = false
    @Published var conversationHistory: [KrishnaMessage] = []

    /// Shown by Krishna chat UI as a top banner (network / HTTP / stream failure).
    @Published var chatBannerError: String?

    /// After a successful HTTP stream with no assistant text, show inline copy in the chat.
    @Published var showEmptyAssistantInline: Bool = false

    /// User messages sent today (resets per calendar day in the current timezone).
    @Published private(set) var messagesSentToday: Int = 0

    private let endpoint = BackendConfig.baseURL.appendingPathComponent("chat")

    /// Set when `cancel()` runs so the URLSession completion does not apply stream outcome twice.
    private var suppressNextStreamOutcome = false

    static let chatReachabilityBannerMessage =
        "Krishna couldn't be reached. Check your connection and try again."

    func clearChatBannerError() {
        chatBannerError = nil
    }

    func clearEmptyAssistantInline() {
        showEmptyAssistantInline = false
    }

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
        chatBannerError = nil
        showEmptyAssistantInline = false
        suppressNextStreamOutcome = false

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
            conversationHistory: Array(historyForAPI),
            lastOfferingSummary: AuthManager.shared.lastOfferingSummary.isEmpty
                ? nil
                : AuthManager.shared.lastOfferingSummary
        )

        guard let body = try? JSONEncoder().encode(request) else {
            Self.debugLog(
                hypothesisId: "H5",
                location: "Dharma/KrishnaService.swift:sendMessage",
                message: "JSONEncoder.encode failed; request not sent",
                data: ["hasVerse": verse != nil, "goalsCount": goals.count]
            )
            conversationHistory.removeLast()
            chatBannerError = Self.chatReachabilityBannerMessage
            return
        }

        recordOutgoingUserMessage()

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = body

        Self.debugLog(
            hypothesisId: "H5",
            location: "Dharma/KrishnaService.swift:sendMessage",
            message: "Starting chat request",
            data: [
                "url": endpoint.absoluteString,
                "bodyBytes": body.count,
                "historyCount": conversationHistory.count
            ]
        )

        streamingResponse = ""
        isStreaming = true

        let delegate = SSEDelegate { [weak self] chunk in
            Task { @MainActor in
                self?.streamingResponse += chunk
            }
        } onStreamFinished: { [weak self] httpRejected, error in
            Task { @MainActor in
                guard let self else { return }
                if self.suppressNextStreamOutcome {
                    self.suppressNextStreamOutcome = false
                    return
                }
                let full = self.streamingResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                self.streamingResponse = ""
                self.isStreaming = false

                if httpRejected || error != nil {
                    self.chatBannerError = Self.chatReachabilityBannerMessage
                    return
                }
                if full.isEmpty {
                    self.showEmptyAssistantInline = true
                } else {
                    self.conversationHistory.append(
                        KrishnaMessage(role: "assistant", content: full)
                    )
                }
            }
        }

        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: urlRequest)
        activeTask = task
        task.resume()
    }

    func cancel() {
        suppressNextStreamOutcome = true
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

    /// One-shot reply without mutating `conversationHistory` (e.g. Sadhana, daily path sheet).
    func fetchOneShotResponse(message: String) async throws -> String {
        let goalList = GoalsManager.shared.selectedGoals.isEmpty ? Self.fallbackGoals : GoalsManager.shared.selectedGoals
        let lastOfferingSummary: String? = await MainActor.run {
            let s = AuthManager.shared.lastOfferingSummary
            return s.isEmpty ? nil : s
        }
        let request = KrishnaRequest(
            message: message,
            currentVerse: nil,
            goals: goalList,
            reflection: nil,
            conversationHistory: nil,
            lastOfferingSummary: lastOfferingSummary
        )
        var result = ""
        for try await chunk in streamResponse(request: request) {
            result += chunk
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - SSE Delegate

private final class SSEDelegate: NSObject, URLSessionDataDelegate {
    private let onChunk: (String) -> Void
    private let onStreamFinished: (_ httpRejected: Bool, _ error: Error?) -> Void
    private var buffer = ""
    private var totalBytes = 0
    private let maxStreamBytes = 50_000
    private var responseLogged = false
    private var httpRejected = false

    init(
        onChunk: @escaping (String) -> Void,
        onStreamFinished: @escaping (_ httpRejected: Bool, _ error: Error?) -> Void
    ) {
        self.onChunk = onChunk
        self.onStreamFinished = onStreamFinished
    }

    // #region agent log
    private func debugLog(_ hypothesisId: String, _ location: String, _ message: String, _ data: [String: Any] = [:]) {
        KrishnaService.debugLog(hypothesisId: hypothesisId, location: location, message: message, data: data)
    }
    // #endregion

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        if !responseLogged {
            responseLogged = true
            let http = response as? HTTPURLResponse
            debugLog(
                "H6",
                "Dharma/KrishnaService.swift:SSEDelegate.didReceiveResponse",
                "Received response headers",
                [
                    "status": http?.statusCode as Any,
                    "contentType": http?.value(forHTTPHeaderField: "Content-Type") as Any,
                    "url": response.url?.absoluteString as Any
                ]
            )
            if let http, !(200...299).contains(http.statusCode) {
                httpRejected = true
                completionHandler(.cancel)
                return
            }
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalBytes += data.count
        if totalBytes == data.count {
            debugLog(
                "H7",
                "Dharma/KrishnaService.swift:SSEDelegate.didReceiveData",
                "Received first data chunk",
                ["chunkBytes": data.count]
            )
        }
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
            if chunk.count > 0, totalBytes < 4096 {
                debugLog(
                    "H7",
                    "Dharma/KrishnaService.swift:SSEDelegate.parseLine",
                    "Parsed text frame",
                    ["sample": String(chunk.prefix(80))]
                )
            }
            onChunk(chunk)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // flush any leftover line
        if !buffer.isEmpty { parseLine(buffer); buffer = "" }
        if let error {
            debugLog(
                "H8",
                "Dharma/KrishnaService.swift:SSEDelegate.didCompleteWithError",
                "Stream completed with error",
                ["error": String(describing: error), "totalBytes": totalBytes]
            )
        } else {
            debugLog(
                "H8",
                "Dharma/KrishnaService.swift:SSEDelegate.didCompleteWithError",
                "Stream completed (no error)",
                ["totalBytes": totalBytes]
            )
        }
        onStreamFinished(httpRejected, error)
    }
}
