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
    private let defaults = UserDefaults(suiteName: appGroupID)!

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

    func saveAllVerses(_ verses: [WidgetVerse]) {
        if let encoded = try? JSONEncoder().encode(verses) {
            defaults.set(encoded, forKey: "widget_all_verses")
        }
    }

    func loadAllVerses() -> [WidgetVerse] {
        guard let data = defaults.data(forKey: "widget_all_verses"),
              let verses = try? JSONDecoder().decode([WidgetVerse].self, from: data)
        else { return [] }
        return verses
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

    // MARK: - Appearance (mirrors main app `AppStorage("userDarkMode")` for widgets)

    private let userDarkModeWidgetKey = "userDarkMode"

    /// Writes the in-app appearance toggle so the widget extension can match the app (widgets don’t see `preferredColorScheme`).
    func saveUserDarkModeForWidget(_ isDark: Bool) {
        defaults.set(isDark, forKey: userDarkModeWidgetKey)
    }

    /// `nil` if the value was never synced (e.g. user hasn’t launched the app since this shipped); widget should fall back to system `colorScheme`.
    func loadUserDarkModeForWidget() -> Bool? {
        guard defaults.object(forKey: userDarkModeWidgetKey) != nil else { return nil }
        return defaults.bool(forKey: userDarkModeWidgetKey)
    }
}
