import Foundation

let appGroupID = "group.com.maurya.Dharma"

struct WidgetVerse: Codable {
    let title: String
    let text: String
    let source: String
    let speaker: String
    let category: String
}

class SharedDataManager {
    static let shared = SharedDataManager()
    private let defaults = UserDefaults.standard

    func saveWidgetVerse(_ verse: WidgetVerse) {
        if let encoded = try? JSONEncoder().encode(verse) {
            defaults.set(encoded, forKey: "widget_verse")
        }
    }

    func loadWidgetVerse() -> WidgetVerse? {
        guard let data = defaults.data(forKey: "widget_verse"),
              let verse = try? JSONDecoder().decode(WidgetVerse.self, from: data)
        else { return nil }
        return verse
    }

    func saveFavourites(_ verses: [WidgetVerse]) {
        if let encoded = try? JSONEncoder().encode(verses) {
            defaults.set(encoded, forKey: "widget_favourites")
        }
    }

    func loadFavourites() -> [WidgetVerse] {
        guard let data = defaults.data(forKey: "widget_favourites"),
              let verses = try? JSONDecoder().decode([WidgetVerse].self, from: data)
        else { return [] }
        return verses
    }

    func saveWidgetContentType(_ type: String) {
        defaults.set(type, forKey: "widget_content_type")
    }

    func loadWidgetContentType() -> String {
        defaults.string(forKey: "widget_content_type") ?? "daily"
    }
}
