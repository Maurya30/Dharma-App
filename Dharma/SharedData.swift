//
//  SharedData.swift
//  Dharma
//
//  Created by Maurya Panchal on 2026-03-16.
//

import Foundation

// Shared container between app and widget
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
    private let defaults = UserDefaults(suiteName: appGroupID)

    // Save a verse for the widget to display
    func saveWidgetVerse(_ verse: WidgetVerse) {
        if let encoded = try? JSONEncoder().encode(verse) {
            defaults?.set(encoded, forKey: "widget_verse")
        }
    }

    // Load the verse in the widget
    func loadWidgetVerse() -> WidgetVerse? {
        guard let data = defaults?.data(forKey: "widget_verse"),
              let verse = try? JSONDecoder().decode(WidgetVerse.self, from: data)
        else { return nil }
        return verse
    }

    // Save favourites for widget access
    func saveFavourites(_ verses: [WidgetVerse]) {
        if let encoded = try? JSONEncoder().encode(verses) {
            defaults?.set(encoded, forKey: "widget_favourites")
        }
    }

    func loadFavourites() -> [WidgetVerse] {
        guard let data = defaults?.data(forKey: "widget_favourites"),
              let verses = try? JSONDecoder().decode([WidgetVerse].self, from: data)
        else { return [] }
        return verses
    }
    
    // Save widget content type preference
    func saveWidgetContentType(_ type: String) {
        defaults?.set(type, forKey: "widget_content_type")
    }
    
    func loadWidgetContentType() -> String {
        defaults?.string(forKey: "widget_content_type") ?? "daily"
    }
}
