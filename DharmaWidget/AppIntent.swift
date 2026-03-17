import WidgetKit
import AppIntents

enum WidgetContentType: String, AppEnum {
    case daily = "Daily Verse"
    case gita = "Daily Gita Verse"
    case upanishad = "Daily Upanishad"
    case mantra = "Daily Mantra"
    case favourites = "From Favourites"
    case pinned = "Pinned Verse"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Content Type"
    static var caseDisplayRepresentations: [WidgetContentType: DisplayRepresentation] = [
        .daily: "Daily Verse",
        .gita: "Daily Gita Verse",
        .upanishad: "Daily Upanishad",
        .mantra: "Daily Mantra",
        .favourites: "From Favourites",
        .pinned: "Pinned Verse"
    ]
}

struct FavouriteVerseEntity: AppEntity {
    let id: String
    let title: String
    let source: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Verse"
    static var defaultQuery = FavouriteVerseQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(source)")
    }
}

struct FavouriteVerseQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FavouriteVerseEntity] {
        let favs = SharedDataManager.shared.loadFavourites()
        return favs
            .filter { identifiers.contains($0.source) }
            .map { FavouriteVerseEntity(id: $0.source, title: $0.title, source: $0.source) }
    }

    func suggestedEntities() async throws -> [FavouriteVerseEntity] {
        let favs = SharedDataManager.shared.loadFavourites()
        return favs.map { FavouriteVerseEntity(id: $0.source, title: $0.title, source: $0.source) }
    }
}

struct DharmaWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Dharma Widget"
    static var description = IntentDescription("Choose what scripture to display")

    @Parameter(title: "Content Type", default: .daily)
    var contentType: WidgetContentType

    @Parameter(title: "Pinned Verse")
    var pinnedVerse: FavouriteVerseEntity?
}
