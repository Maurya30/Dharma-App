import Foundation

struct RelatedVerse: Codable, Identifiable {
    let id: String
    let source: String
    let category: String
    let chapter: FlexibleValue
    let verse: String
    let sanskrit: String?
    let transliteration: String?
    let english: String
    let speaker: String?
    let similarity: Double?

    /// chapter arrives as Int or String depending on category.
    enum FlexibleValue: Codable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) { self = .int(i); return }
            if let s = try? c.decode(String.self) { self = .string(s); return }
            throw DecodingError.typeMismatch(FlexibleValue.self,
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

    var categoryBadge: String {
        switch category.lowercased() {
        case "bhagavad gita", "gita": return "Bhagavad Gita"
        case "upanishad", "upanishads":  return "Upanishad"
        case "rig veda", "rigveda":      return "Rig Veda"
        default:                          return category
        }
    }

    var truncatedEnglish: String {
        if english.count <= 80 { return english }
        let idx = english.index(english.startIndex, offsetBy: 80)
        return String(english[..<idx]) + "…"
    }
}

private struct RelatedResponse: Codable {
    let related: [RelatedVerse]
}

final class RelatedVersesService {
    static let shared = RelatedVersesService()
    private init() {}

    func fetchRelated(verseId: String) async -> [RelatedVerse] {
        let url = BackendConfig.baseURL.appendingPathComponent("related")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["verseId": verseId])
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(RelatedResponse.self, from: data)
            return Array(decoded.related.prefix(5))
        } catch {
            return []
        }
    }
}
