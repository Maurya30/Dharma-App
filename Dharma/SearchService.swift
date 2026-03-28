import Foundation
import Combine

struct SearchResult: Codable, Identifiable {
    let id: String
    let source: String
    let category: String
    let chapter: FlexibleChapter
    let verse: String
    let sanskrit: String?
    let transliteration: String?
    let english: String
    let speaker: String?
    let similarity: Double?

    enum FlexibleChapter: Codable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) { self = .int(i); return }
            if let s = try? c.decode(String.self) { self = .string(s); return }
            throw DecodingError.typeMismatch(FlexibleChapter.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .int(let v): try c.encode(v)
            case .string(let v): try c.encode(v)
            }
        }

        var stringValue: String {
            switch self {
            case .int(let v): return String(v)
            case .string(let v): return v
            }
        }
    }
}

private struct SearchResponse: Codable {
    let results: [SearchResult]
}

@MainActor
final class SearchService: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isSearching = false

    private var debounceTask: Task<Void, Never>?

    func search(query: String) {
        debounceTask?.cancel()
        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }
        results = []
        isSearching = true

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            let url = BackendConfig.baseURL.appendingPathComponent("search")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(["query": query])
            request.timeoutInterval = 10

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else { return }
                guard !Task.isCancelled else { return }
                let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
                self.results = decoded.results
            } catch {
                if !Task.isCancelled { self.results = [] }
            }
            self.isSearching = false
        }
    }

    func cancel() {
        debounceTask?.cancel()
        results = []
        isSearching = false
    }
}
