import Foundation
import Combine
import SwiftUI

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

extension SearchResult {
    init(scriptureItem item: ScriptureItem, similarity: Double?) {
        id = item.id.uuidString
        source = item.source
        category = item.category.rawValue
        chapter = .string(item.subtitle)
        verse = ""
        sanskrit = item.textSanskrit
        transliteration = item.textTransliteration
        english = item.textEnglish
        speaker = nil
        self.similarity = similarity
    }
}

@MainActor
final class SearchService: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var showOfflineKeywordBanner = false
    @Published var searchError: String?

    private var debounceTask: Task<Void, Never>?

    static let searchUnavailableMessage =
        "Search is unavailable right now. Try again or browse below."

    func clearSearchError() {
        searchError = nil
    }

    func localSearch(_ query: String, in items: [ScriptureItem]) -> [ScriptureItem] {
        let terms = query.lowercased()
            .components(separatedBy: .whitespaces)
            .filter { $0.count > 2 }
        return Array(
            items.filter { item in
                let text = (item.textEnglish + " " + item.source + " " + item.title).lowercased()
                return terms.contains { text.contains($0) }
            }
            .prefix(20)
        )
    }

    func search(query: String) {
        debounceTask?.cancel()
        guard !query.isEmpty else {
            results = []
            isSearching = false
            showOfflineKeywordBanner = false
            searchError = nil
            return
        }
        results = []
        isSearching = true
        showOfflineKeywordBanner = false
        searchError = nil

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            if !NetworkMonitor.shared.isConnected {
                let matched = localSearch(query, in: ScriptureStore.shared.items)
                self.results = matched.map { SearchResult(scriptureItem: $0, similarity: nil) }
                self.showOfflineKeywordBanner = !matched.isEmpty
                self.isSearching = false
                return
            }

            self.showOfflineKeywordBanner = false

            let url = BackendConfig.baseURL.appendingPathComponent("search")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(["query": query])
            request.timeoutInterval = 10

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    if !Task.isCancelled {
                        self.results = []
                        self.searchError = Self.searchUnavailableMessage
                    }
                    self.isSearching = false
                    return
                }
                guard !Task.isCancelled else { return }
                let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
                self.results = decoded.results
                self.searchError = nil
            } catch {
                if !Task.isCancelled {
                    self.results = []
                    self.searchError = Self.searchUnavailableMessage
                }
            }
            self.isSearching = false
        }
    }

    func cancel() {
        debounceTask?.cancel()
        results = []
        isSearching = false
        showOfflineKeywordBanner = false
        searchError = nil
    }
}

// MARK: - Offline banner (semantic search)

/// Place above your semantic search results (e.g. in the library search stack) when using `SearchService`.
struct OfflineKeywordSearchBanner: View {
    @ObservedObject var searchService: SearchService
    var isActive: Bool

    var body: some View {
        Group {
            if searchService.showOfflineKeywordBanner && isActive {
                Text("Offline — showing keyword results")
                    .font(.system(size: 8))
                    .foregroundColor(Color.dharmaGold.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.bottom, DharmaSpacing.sm)
            }
        }
    }
}
