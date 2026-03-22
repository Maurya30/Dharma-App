import Foundation
import Combine

final class JournalStore: ObservableObject {
    static let shared = JournalStore()

    @Published var entries: [JournalEntry] = []

    private let storageKey = "journalEntries"

    init() {
        load()
    }

    func save(entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.verseId == entry.verseId }) {
            entries[idx].noteText = entry.noteText
            entries[idx].goalContext = entry.goalContext
            entries[idx].spokenWithKrishna = entry.spokenWithKrishna
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }

    func entry(for verseId: String) -> JournalEntry? {
        entries.first { $0.verseId == verseId }
    }

    func markSpokenWithKrishna(verseId: String) {
        guard let idx = entries.firstIndex(where: { $0.verseId == verseId }) else { return }
        entries[idx].spokenWithKrishna = true
        persist()
    }

    func entriesForGoal(_ goal: String) -> [JournalEntry] {
        entries.filter { $0.goalContext == goal }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data)
        else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }

    private func persist() {
        entries.sort { $0.date > $1.date }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
