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
    /// "manual" | "sadhana" | "goalPath"
    var source: String
    var sourceLabel: String
    /// Krishna one-sentence inline reply (Sadhana Bhavana, goal path).
    var krishnaResponse: String

    init(
        verseId: String,
        verseReference: String,
        verseSource: String,
        verseEnglish: String,
        noteText: String,
        goalContext: String? = nil,
        source: String = "manual",
        sourceLabel: String = "",
        krishnaResponse: String = ""
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
        self.source = source
        self.sourceLabel = sourceLabel
        self.krishnaResponse = krishnaResponse
    }

    /// Restore from cloud when `verseEnglish` / `verseReference` were not stored server-side.
    init(
        id: UUID,
        verseId: String,
        verseReference: String,
        verseSource: String,
        verseEnglish: String,
        noteText: String,
        date: Date,
        spokenWithKrishna: Bool,
        goalContext: String?,
        source: String = "manual",
        sourceLabel: String = "",
        krishnaResponse: String = ""
    ) {
        self.id = id
        self.verseId = verseId
        self.verseReference = verseReference
        self.verseSource = verseSource
        self.verseEnglish = verseEnglish
        self.noteText = noteText
        self.date = date
        self.spokenWithKrishna = spokenWithKrishna
        self.goalContext = goalContext
        self.source = source
        self.sourceLabel = sourceLabel
        self.krishnaResponse = krishnaResponse
    }

    enum CodingKeys: String, CodingKey {
        case id, verseId, verseReference, verseSource, verseEnglish, noteText, date, spokenWithKrishna, goalContext, source, sourceLabel, krishnaResponse
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        verseId = try c.decode(String.self, forKey: .verseId)
        verseReference = try c.decode(String.self, forKey: .verseReference)
        verseSource = try c.decode(String.self, forKey: .verseSource)
        verseEnglish = try c.decode(String.self, forKey: .verseEnglish)
        noteText = try c.decode(String.self, forKey: .noteText)
        date = try c.decode(Date.self, forKey: .date)
        spokenWithKrishna = try c.decodeIfPresent(Bool.self, forKey: .spokenWithKrishna) ?? false
        goalContext = try c.decodeIfPresent(String.self, forKey: .goalContext)
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "manual"
        sourceLabel = try c.decodeIfPresent(String.self, forKey: .sourceLabel) ?? ""
        krishnaResponse = try c.decodeIfPresent(String.self, forKey: .krishnaResponse) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(verseId, forKey: .verseId)
        try c.encode(verseReference, forKey: .verseReference)
        try c.encode(verseSource, forKey: .verseSource)
        try c.encode(verseEnglish, forKey: .verseEnglish)
        try c.encode(noteText, forKey: .noteText)
        try c.encode(date, forKey: .date)
        try c.encode(spokenWithKrishna, forKey: .spokenWithKrishna)
        try c.encodeIfPresent(goalContext, forKey: .goalContext)
        try c.encode(source, forKey: .source)
        try c.encode(sourceLabel, forKey: .sourceLabel)
        try c.encode(krishnaResponse, forKey: .krishnaResponse)
    }
}
