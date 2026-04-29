import Foundation
import Combine

final class JournalStore: ObservableObject {
    static let shared = JournalStore()

    @Published var entries: [JournalEntry] = []

    init() {
        load()
    }

    func save(entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.verseId == entry.verseId }) {
            entries[idx].noteText = entry.noteText
            entries[idx].goalContext = entry.goalContext
            entries[idx].spokenWithKrishna = entry.spokenWithKrishna
            entries[idx].source = entry.source
            entries[idx].sourceLabel = entry.sourceLabel
            entries[idx].krishnaResponse = entry.krishnaResponse
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
        Task {
            await AuthManager.shared.syncToCloud()
        }
    }

    func saveOffering(entry: JournalEntry) {
        entries.insert(entry, at: 0)
        persist()
        Task {
            await AuthManager.shared.syncToCloud()
        }
    }

    func entry(for verseId: String) -> JournalEntry? {
        entries.first { $0.verseId == verseId }
    }

    func markSpokenWithKrishna(verseId: String) {
        guard let idx = entries.firstIndex(where: { $0.verseId == verseId }) else { return }
        entries[idx].spokenWithKrishna = true
        persist()
        Task {
            await AuthManager.shared.syncToCloud()
        }
    }

    func delete(entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
        Task {
            await AuthManager.shared.syncToCloud()
        }
    }

    func entriesForGoal(_ goal: String) -> [JournalEntry] {
        entries.filter { $0.goalContext == goal }
    }

    private func journalFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("journal_entries.json")
    }

    private func load() {
        do {
            let data = try Data(contentsOf: journalFileURL())
            entries = try JSONDecoder().decode([JournalEntry].self, from: data)
                .sorted { $0.date > $1.date }
        } catch {
            entries = []
        }
    }

    private func persist() {
        entries.sort { $0.date > $1.date }
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: journalFileURL(), options: [.atomic, .completeFileProtection])
        } catch {
        }
    }

    func replaceFromCloud(_ newEntries: [JournalEntry]) {
        entries = newEntries.sorted { $0.date > $1.date }
        persist()
    }

    func deleteAllEntries() {
        entries = []
        try? FileManager.default.removeItem(at: journalFileURL())
    }
}
