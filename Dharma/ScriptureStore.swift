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
            return gitaVerses // fallback to the 7 hardcoded verses
        }

        var result: [ScriptureItem] = []

        for chapter in gitaData.chapters {
            for verse in chapter.verses {
                // Clean the text — remove trailing "(1.1)" reference
                let cleanText = verse.text
                    .replacingOccurrences(of: #"\s*\(\d+\.\d+[\d\.\-]*\)\s*$"#,
                                         with: "",
                                         options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)

                let item = ScriptureItem(
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
