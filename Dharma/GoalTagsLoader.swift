import Foundation

final class GoalTagsLoader {
    static let shared = GoalTagsLoader()
    private var tags: [String: [String]] = [:]

    init() {
        if let url = Bundle.main.url(forResource: "goalTags", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            tags = decoded
        }
    }

    func goals(for verseId: String) -> [String] {
        tags[verseId] ?? []
    }

    func matchingUserGoals(for verseId: String, userGoals: [String]) -> [String] {
        let verseTags = tags[verseId] ?? []
        return verseTags.filter { userGoals.contains($0) }
    }

    /// All verse IDs that match any of the given goals.
    func verseIds(matching goals: [String]) -> Set<String> {
        var result = Set<String>()
        for (verseId, verseTags) in tags {
            if verseTags.contains(where: { goals.contains($0) }) {
                result.insert(verseId)
            }
        }
        return result
    }

    /// Match user goals for a ScriptureItem by deriving the backend verse ID from its properties.
    func matchingUserGoals(for item: ScriptureItem, userGoals: [String]) -> [String] {
        guard let bid = Self.backendId(for: item) else { return [] }
        return matchingUserGoals(for: bid, userGoals: userGoals)
    }

    /// Derive the backend Supabase verse ID from a ScriptureItem.
    static func backendId(for item: ScriptureItem) -> String? {
        switch item.category {
        case .gita:
            let ref = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "")
            return ref.isEmpty ? nil : "bg-\(ref)"
        case .upanishads:
            let slug = item.title
                .lowercased()
                .replacingOccurrences(of: " upanishad", with: "")
                .trimmingCharacters(in: .whitespaces)
            let parts = item.subtitle
                .replacingOccurrences(of: "Ch. ", with: "")
                .components(separatedBy: " · Verse ")
            guard parts.count == 2 else { return nil }
            return "\(slug)-\(parts[0])-\(parts[1])"
        case .rigVeda:
            let verse = item.subtitle.replacingOccurrences(of: "Rig Veda ", with: "")
            let parts = verse.split(separator: ".")
            guard parts.count >= 3 else { return nil }
            return "rv-\(parts.joined(separator: "-"))"
        default:
            return nil
        }
    }
}
