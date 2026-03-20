import SwiftUI

// MARK: - Scripture Category
enum ScriptureCategory: String, CaseIterable, Codable, Identifiable {
    case gita       = "Bhagavad Gita"
    case upanishads = "Upanishads"
    case rigVeda    = "Rig Veda"
    case mantras    = "Mantras"
    case bhajans    = "Bhajans"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gita:       return "book.fill"
        case .upanishads: return "scroll.fill"
        case .rigVeda:    return "flame.fill"
        case .mantras:    return "waveform"
        case .bhajans:    return "music.note"
        }
    }

    var color: Color {
        switch self {
        case .gita:       return .categoryGita
        case .upanishads: return .categoryUpanishads
        case .rigVeda:    return .categoryRigVeda
        case .mantras:    return .categoryMantras
        case .bhajans:    return .categoryBhajans
        }
    }

    var description: String {
        switch self {
        case .gita:       return "700 verses of divine wisdom"
        case .upanishads: return "Ancient philosophical texts"
        case .rigVeda:    return "Oldest sacred hymns"
        case .mantras:    return "Sacred sounds & chants"
        case .bhajans:    return "Devotional songs"
        }
    }
}

// MARK: - Upanishad JSON entry (from upanishads.json)
struct UpanishadEntry: Codable {
    let id: String
    let source: String
    let sourceShort: String
    let category: String
    let chapter: String
    let verse: String
    let sanskrit: String
    let transliteration: String
    let english: String
    let hindi: String
    let speaker: String
    let wordMeanings: String

    enum CodingKeys: String, CodingKey {
        case id, source, category, chapter, verse, sanskrit, transliteration
        case english, hindi, speaker
        case sourceShort = "source_short"
        case wordMeanings
    }
}

// MARK: - Rig Veda JSON entry (from rigveda.json)
struct RigVedaEntry: Codable {
    let id: String
    let source: String
    let sourceShort: String
    let category: String
    let chapter: String
    let verse: String
    let sanskrit: String
    let transliteration: String
    let english: String
    let hindi: String
    let speaker: String
    let wordMeanings: String

    enum CodingKeys: String, CodingKey {
        case id, source, category, chapter, verse, sanskrit, transliteration
        case english, hindi, speaker
        case sourceShort = "source_short"
        case wordMeanings
    }
}

// MARK: - Scripture Item
struct ScriptureItem: Identifiable, Codable {
    let id: UUID
    let category: ScriptureCategory
    let title: String
    let subtitle: String        // e.g. "Chapter 2, Verse 47" or "Rig Veda"
    let textEnglish: String     // main content in English
    let textTransliteration: String?  // Sanskrit in Latin script
    let textSanskrit: String?   // Devanagari script
    let source: String          // e.g. "Bhagavad Gita 2.47"
    let audioFileName: String?  // optional — for mantras/bhajans
    var isFavourite: Bool

    init(
        id: UUID = UUID(),
        category: ScriptureCategory,
        title: String,
        subtitle: String,
        textEnglish: String,
        textTransliteration: String? = nil,
        textSanskrit: String? = nil,
        source: String,
        audioFileName: String? = nil,
        isFavourite: Bool = false
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.textEnglish = textEnglish
        self.textTransliteration = textTransliteration
        self.textSanskrit = textSanskrit
        self.source = source
        self.audioFileName = audioFileName
        self.isFavourite = isFavourite
    }
}

// MARK: - Hindu Festival (for Sacred Calendar)
struct HinduFestival: Identifiable, Codable {
    let id: UUID
    let name: String
    let date: Date
    let deity: String
    let shortDescription: String
    let fullStory: String
    let significance: String
    let howToObserve: String

    init(
        id: UUID = UUID(),
        name: String,
        date: Date,
        deity: String,
        shortDescription: String,
        fullStory: String,
        significance: String,
        howToObserve: String
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.deity = deity
        self.shortDescription = shortDescription
        self.fullStory = fullStory
        self.significance = significance
        self.howToObserve = howToObserve
    }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    var isToday: Bool { daysUntil == 0 }
    var isPast: Bool  { daysUntil < 0  }
}

// MARK: - Gita Chapter Info (from chapters.json)
struct GitaChapterInfo: Codable, Identifiable {
    let chapterNumber: Int
    let chapterSummary: String
    let name: String
    let nameMeaning: String
    let nameTranslation: String
    let nameTransliterated: String
    let versesCount: Int

    var id: Int { chapterNumber }

    enum CodingKeys: String, CodingKey {
        case chapterNumber = "chapter_number"
        case chapterSummary = "chapter_summary"
        case name
        case nameMeaning = "name_meaning"
        case nameTranslation = "name_translation"
        case nameTransliterated = "name_transliterated"
        case versesCount = "verses_count"
    }
}

// MARK: - Bhagavad Gita (from gita.json)
struct GitaData: Codable {
    let chapters: [GitaChapter]
}

struct GitaChapter: Codable, Identifiable {
    let chapter: Int
    let title: String
    let verses: [GitaVerse]
    
    var id: Int { chapter }
}

struct GitaVerse: Codable, Identifiable {
    let reference: String
    let speaker: String
    let text: String
    let transliteration: String?
    let sanskrit: String?
    
    var id: String { reference }
}

