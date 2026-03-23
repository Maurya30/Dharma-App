import SwiftUI
import Combine

// MARK: - Scripture Store
class ScriptureStore: ObservableObject {
    @Published var items: [ScriptureItem] = []
    @Published var chapterInfos: [GitaChapterInfo] = []
    @Published var readVerseIDs: Set<String> = []
    /// Category raw value → item `source` string for “Continue reading”
    @Published var lastReadByCategory: [String: String] = [:]
    @Published var streak: Int = 0

    private let favouritesKey = "dharma_favourites"
    private let readVersesKey = "dharma_read_verses"
    private let lastReadKey = "dharma_last_read"
    private let lastReadByCategoryKey = "dharma_last_read_by_category"
    private let lastPracticeDateKey = "dharma_last_practice_date"
    private let streakKey = "dharma_streak"

    init() {
        loadChapterInfos()
        loadItems()
        loadFavourites()
        loadReadingProgress()
        loadStreak()
        syncToWidget()
    }

    /// Reload scripture JSON from the bundle and re-apply favourites (for pull-to-refresh).
    func refreshLibraryContent() async {
        await MainActor.run {
            loadChapterInfos()
            loadItems()
            loadFavourites()
            syncToWidget()
        }
    }

    // MARK: - Loading
    private func loadItems() {
        let gitaItems = loadGita()
        let upanishadItems = loadUpanishads()
        let rigVedaItems = loadRigVeda()
        let otherItems = mantras + bhajans
        items = gitaItems + upanishadItems + rigVedaItems + otherItems
    }

    private func loadChapterInfos() {
        guard let url = Bundle.main.url(forResource: "chapters", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let infos = try? JSONDecoder().decode([GitaChapterInfo].self, from: data)
        else { return }
        chapterInfos = infos
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

                let stableID = UUID(uuidString: uuidFrom(string: "gita-\(verse.reference)")) ?? UUID()

                let item = ScriptureItem(
                    id: stableID,
                    category: .gita,
                    title: "\(verse.speaker) — \(verse.reference)",
                    subtitle: "Chapter \(chapter.chapter) · \(chapter.title)",
                    textEnglish: cleanText,
                    textTransliteration: verse.transliteration?.trimmingCharacters(in: .whitespacesAndNewlines),
                    textSanskrit: verse.sanskrit?.trimmingCharacters(in: .whitespacesAndNewlines),
                    source: "Bhagavad Gita \(verse.reference)"
                )
                result.append(item)
            }
        }

        print("✅ Loaded \(result.count) Gita verses from gita.json")
        return result
    }

    private func loadUpanishads() -> [ScriptureItem] {
        guard let url = Bundle.main.url(forResource: "upanishads", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            print("⚠️ Could not read upanishads.json from bundle — falling back to sample data")
            return upanishadPassages
        }

        let entries: [UpanishadEntry]
        do {
            entries = try JSONDecoder().decode([UpanishadEntry].self, from: data)
        } catch {
            print("⚠️ upanishads.json decode failed: \(error.localizedDescription) — falling back to sample data")
            return upanishadPassages
        }

        let result: [ScriptureItem] = entries.compactMap { entry in
            guard !entry.english.isEmpty else { return nil }
            let stableID = UUID(uuidString: uuidFrom(string: "upanishad-\(entry.id)")) ?? UUID()
            return ScriptureItem(
                id: stableID,
                category: .upanishads,
                title: entry.source,
                subtitle: "Ch. \(entry.chapter) · Verse \(entry.verse)",
                textEnglish: entry.english,
                textTransliteration: entry.transliteration.isEmpty ? nil : entry.transliteration,
                textSanskrit: entry.sanskrit.isEmpty ? nil : entry.sanskrit,
                source: entry.source
            )
        }

        print("✅ Loaded \(result.count) Upanishad verses from upanishads.json")
        return result
    }

    private func loadRigVeda() -> [ScriptureItem] {
        guard let url = Bundle.main.url(forResource: "rigveda", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([RigVedaEntry].self, from: data)
        else {
            print("⚠️ Could not load rigveda.json")
            return []
        }

        let result: [ScriptureItem] = entries.compactMap { entry in
            guard !entry.english.isEmpty else { return nil }
            let stableID = UUID(uuidString: uuidFrom(string: "rigveda-\(entry.id)")) ?? UUID()
            return ScriptureItem(
                id: stableID,
                category: .rigVeda,
                title: "Book \(entry.chapter) · Hymn \(entry.verse)",
                subtitle: "Rig Veda \(entry.verse)",
                textEnglish: entry.english,
                textTransliteration: entry.transliteration.isEmpty ? nil : entry.transliteration,
                textSanskrit: entry.sanskrit.isEmpty ? nil : entry.sanskrit,
                source: "Rig Veda \(entry.verse)"
            )
        }

        print("✅ Loaded \(result.count) Rig Veda verses from rigveda.json")
        return result
    }

    // MARK: - Grouped Data

    /// Distinct Upanishad source names in the order they appear, with verse counts.
    var upanishadSources: [(name: String, count: Int)] {
        var seen: [String] = []
        var counts: [String: Int] = [:]
        for item in items where item.category == .upanishads {
            let src = item.source
            counts[src, default: 0] += 1
            if !seen.contains(src) { seen.append(src) }
        }
        return seen.map { (name: $0, count: counts[$0] ?? 0) }
    }

    func upanishadItems(for source: String) -> [ScriptureItem] {
        items.filter { $0.category == .upanishads && $0.source == source }
    }

    /// Distinct Rig Veda books with verse counts.
    var rigVedaBooks: [(book: Int, count: Int)] {
        var counts: [Int: Int] = [:]
        for item in items where item.category == .rigVeda {
            if let bookStr = item.title.components(separatedBy: "·").first?
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "Book ", with: ""),
               let book = Int(bookStr) {
                counts[book, default: 0] += 1
            }
        }
        return counts.sorted { $0.key < $1.key }.map { (book: $0.key, count: $0.value) }
    }

    func rigVedaItems(for book: Int) -> [ScriptureItem] {
        items.filter { $0.category == .rigVeda && $0.title.hasPrefix("Book \(book) ·") }
    }

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
        syncToWidget()
    }

    var favourites: [ScriptureItem] {
        items.filter { $0.isFavourite }
    }

    func items(for category: ScriptureCategory) -> [ScriptureItem] {
        items.filter { $0.category == category }
    }

    func versesForChapter(_ chapter: Int) -> [ScriptureItem] {
        items.filter { $0.category == .gita && $0.subtitle.hasPrefix("Chapter \(chapter) ·") }
    }

    func randomItem(for category: ScriptureCategory? = nil) -> ScriptureItem? {
        let pool = category == nil ? items : items(for: category!)
        return pool.randomElement()
    }

    // MARK: - Reading Progress
    func markAsRead(_ item: ScriptureItem) {
        lastReadByCategory[item.category.rawValue] = item.source
        saveLastReadByCategory()

        if item.category == .gita {
            let ref = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "")
            readVerseIDs.insert(ref)
            UserDefaults.standard.set(Array(readVerseIDs), forKey: readVersesKey)
        }

        updateStreak()
    }

    func lastReadItem(for category: ScriptureCategory) -> ScriptureItem? {
        guard let source = lastReadByCategory[category.rawValue] else { return nil }
        return items.first { $0.source == source }
    }

    var totalGitaVerses: Int {
        items(for: .gita).count
    }

    var readCount: Int {
        readVerseIDs.count
    }

    func readCountForChapter(_ chapter: Int) -> Int {
        readVerseIDs.filter { $0.hasPrefix("\(chapter).") }.count
    }

    var lastReadItem: ScriptureItem? {
        lastReadItem(for: .gita)
    }

    var lastReadChapterNumber: Int? {
        guard let src = lastReadByCategory[ScriptureCategory.gita.rawValue] else { return nil }
        let ref = src.replacingOccurrences(of: "Bhagavad Gita ", with: "")
        return Int(ref.split(separator: ".").first ?? "")
    }

    var lastReadChapterInfo: GitaChapterInfo? {
        guard let ch = lastReadChapterNumber else { return nil }
        return chapterInfos.first { $0.chapterNumber == ch }
    }

    private func saveLastReadByCategory() {
        UserDefaults.standard.set(lastReadByCategory, forKey: lastReadByCategoryKey)
    }

    private func loadReadingProgress() {
        let saved = UserDefaults.standard.stringArray(forKey: readVersesKey) ?? []
        readVerseIDs = Set(saved)

        if let dict = UserDefaults.standard.dictionary(forKey: lastReadByCategoryKey) as? [String: String] {
            lastReadByCategory = dict
        } else if let legacy = UserDefaults.standard.string(forKey: lastReadKey) {
            lastReadByCategory = [ScriptureCategory.gita.rawValue: legacy]
            saveLastReadByCategory()
        }
    }

    // MARK: - Streak
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDateRaw = UserDefaults.standard.object(forKey: lastPracticeDateKey) as? Date
        let lastDate = lastDateRaw.map { Calendar.current.startOfDay(for: $0) }

        if lastDate == today {
            return
        }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        if lastDate == yesterday {
            streak += 1
        } else {
            streak = 1
        }

        UserDefaults.standard.set(today, forKey: lastPracticeDateKey)
        UserDefaults.standard.set(streak, forKey: streakKey)
    }

    private func loadStreak() {
        streak = UserDefaults.standard.integer(forKey: streakKey)
        let today = Calendar.current.startOfDay(for: Date())
        let lastDateRaw = UserDefaults.standard.object(forKey: lastPracticeDateKey) as? Date
        let lastDate = lastDateRaw.map { Calendar.current.startOfDay(for: $0) }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        if lastDate != today && lastDate != yesterday {
            streak = 0
            UserDefaults.standard.set(0, forKey: streakKey)
        }
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

    // MARK: - Widget Sync
    func syncToWidget() {
        let shared = SharedDataManager.shared
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        let allWidgetVerses = items.map { item in
            WidgetVerse(
                title: item.title,
                text: item.textEnglish,
                source: item.source,
                speaker: String(item.title.split(separator: "—").first ?? "").trimmingCharacters(in: .whitespaces),
                category: item.category.rawValue
            )
        }
        shared.saveAllVerses(allWidgetVerses)

        let gitaItems = items(for: .gita)
        if !gitaItems.isEmpty {
            let verse = gitaItems[dayOfYear % gitaItems.count]
            shared.saveWidgetVerse(WidgetVerse(
                title: verse.title,
                text: verse.textEnglish,
                source: verse.source,
                speaker: String(verse.title.split(separator: "—").first ?? "Krishna").trimmingCharacters(in: .whitespaces),
                category: verse.category.rawValue
            ))
        }

        let widgetFavourites = favourites.map { item in
            WidgetVerse(
                title: item.title,
                text: item.textEnglish,
                source: item.source,
                speaker: String(item.title.split(separator: "—").first ?? "").trimmingCharacters(in: .whitespaces),
                category: item.category.rawValue
            )
        }
        shared.saveFavourites(widgetFavourites)
    }
}
