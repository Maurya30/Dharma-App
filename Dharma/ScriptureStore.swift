import SwiftUI
import Combine

// MARK: - Scripture Store
class ScriptureStore: ObservableObject {
    @Published var items: [ScriptureItem] = []

    private let favouritesKey = "dharma_favourites"

    init() {
        loadItems()
        loadFavourites()
    }

    // MARK: - Loading
    private func loadItems() {
        // Load real Gita verses from gita.json
        let gitaItems = loadGita()

        // Combine with the rest of the sample data (Upanishads, Mantras, Bhajans)
        let otherItems = upanishadPassages + mantras + bhajans

        items = gitaItems + otherItems
    }

    private func loadGita() -> [ScriptureItem] {
        guard let url = Bundle.main.url(forResource: "gita", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let gitaData = try? JSONDecoder().decode(GitaData.self, from: data)
        else {
            print("⚠️ Could not load gita.json — falling back to sample data")
            return gitaVerses
        }

        var result: [ScriptureItem] = []

        for chapter in gitaData.chapters {
            for verse in chapter.verses {
                let cleanText = verse.text
                    .replacingOccurrences(of: #"\s*\(\d+\.\d+[\d\.\-]*\)\s*$"#,
                                         with: "",
                                         options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)

                // Use stable UUID derived from the verse reference
                let stableID = UUID(uuidString: uuidFrom(string: "gita-\(verse.reference)")) ?? UUID()

                let item = ScriptureItem(
                    id: stableID,
                    category: .gita,
                    title: "\(verse.speaker) — \(verse.reference)",
                    subtitle: "Chapter \(chapter.chapter) · \(chapter.title)",
                    textEnglish: cleanText,
                    source: "Bhagavad Gita \(verse.reference)"
                )
                result.append(item)
            }
        }

        print("✅ Loaded \(result.count) Gita verses from gita.json")
        return result
    }

    // Generates a stable UUID from a string
    private func uuidFrom(string: String) -> String {
        let hash = string.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
        let hex = String(format: "%032x", abs(hash))
        let padded = hex.padding(toLength: 32, withPad: "0", startingAt: 0)
        return "\(padded.prefix(8))-\(padded.dropFirst(8).prefix(4))-\(padded.dropFirst(12).prefix(4))-\(padded.dropFirst(16).prefix(4))-\(padded.dropFirst(20))"
    }

    // MARK: - Favourites
    func toggleFavourite(_ item: ScriptureItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isFavourite.toggle()
        saveFavourites()
    }

    var favourites: [ScriptureItem] {
        items.filter { $0.isFavourite }
    }

    func items(for category: ScriptureCategory) -> [ScriptureItem] {
        items.filter { $0.category == category }
    }

    func randomItem(for category: ScriptureCategory? = nil) -> ScriptureItem? {
        let pool = category == nil ? items : items(for: category!)
        return pool.randomElement()
    }

    // MARK: - Persistence
    private func saveFavourites() {
        let ids = items.filter { $0.isFavourite }.map { $0.id.uuidString }
        UserDefaults.standard.set(ids, forKey: favouritesKey)
    }

    private func loadFavourites() {
        let saved = UserDefaults.standard.stringArray(forKey: favouritesKey) ?? []
        let savedSet = Set(saved)
        for index in items.indices {
            items[index].isFavourite = savedSet.contains(items[index].id.uuidString)
        }
    }
}
