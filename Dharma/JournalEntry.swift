import Foundation

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let verseId: String
    let verseReference: String
    let verseSource: String
    let verseEnglish: String
    var noteText: String
    let date: Date
    var spokenWithKrishna: Bool
    var goalContext: String?

    init(
        verseId: String,
        verseReference: String,
        verseSource: String,
        verseEnglish: String,
        noteText: String,
        goalContext: String? = nil
    ) {
        self.id = UUID()
        self.verseId = verseId
        self.verseReference = verseReference
        self.verseSource = verseSource
        self.verseEnglish = verseEnglish
        self.noteText = noteText
        self.date = Date()
        self.spokenWithKrishna = false
        self.goalContext = goalContext
    }
}
