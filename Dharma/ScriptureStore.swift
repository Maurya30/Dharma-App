import SwiftUI
import Combine

// MARK: - Scripture Store
class ScriptureStore: ObservableObject {
    @Published var items: [ScriptureItem] = []
    @Published var chapterInfos: [GitaChapterInfo] = []
    @Published var readVerseIDs: Set<String> = []
    @Published var lastReadSource: String? = nil
    @Published var streak: Int = 0

    private let favouritesKey = "dharma_favourites"
    private let readVersesKey = "dharma_read_verses"
    private let lastReadKey = "dharma_last_read"
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

    // MARK: - Loading
    private func loadItems() {
        let gitaItems = loadGita()
        let otherItems = upanishadPassages + mantras + bhajans
        items = gitaItems + otherItems
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
        guard item.category == .gita else { return }
        let ref = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "")
        readVerseIDs.insert(ref)
        lastReadSource = item.source
        saveReadingProgress()
        updateStreak()
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
        guard let source = lastReadSource else { return nil }
        return items.first { $0.source == source }
    }

    var lastReadChapterNumber: Int? {
        guard let src = lastReadSource else { return nil }
        let ref = src.replacingOccurrences(of: "Bhagavad Gita ", with: "")
        return Int(ref.split(separator: ".").first ?? "")
    }

    var lastReadChapterInfo: GitaChapterInfo? {
        guard let ch = lastReadChapterNumber else { return nil }
        return chapterInfos.first { $0.chapterNumber == ch }
    }

    private func saveReadingProgress() {
        UserDefaults.standard.set(Array(readVerseIDs), forKey: readVersesKey)
        UserDefaults.standard.set(lastReadSource, forKey: lastReadKey)
    }

    private func loadReadingProgress() {
        let saved = UserDefaults.standard.stringArray(forKey: readVersesKey) ?? []
        readVerseIDs = Set(saved)
        lastReadSource = UserDefaults.standard.string(forKey: lastReadKey)
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
