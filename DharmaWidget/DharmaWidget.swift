import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct DharmaEntry: TimelineEntry {
    let date: Date
    let verse: WidgetVerse
    let contentType: WidgetContentType
}

// MARK: - Timeline Provider
struct DharmaWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DharmaEntry {
        DharmaEntry(
            date: Date(),
            verse: WidgetVerse(
                title: "Krishna — 2.47",
                text: "You have the right to work only, and not to the fruits of work.",
                source: "Bhagavad Gita 2.47",
                speaker: "Krishna",
                category: "Bhagavad Gita"
            ),
            contentType: .daily
        )
    }

    func snapshot(for configuration: DharmaWidgetConfiguration, in context: Context) async -> DharmaEntry {
        DharmaEntry(
            date: Date(),
            verse: getVerse(for: configuration),
            contentType: configuration.contentType
        )
    }

    func timeline(for configuration: DharmaWidgetConfiguration, in context: Context) async -> Timeline<DharmaEntry> {
        let verse = getVerse(for: configuration)
        let entry = DharmaEntry(date: Date(), verse: verse, contentType: configuration.contentType)
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        // Pinned verse never needs to refresh
        let policy: TimelineReloadPolicy = configuration.contentType == .pinned ? .never : .after(midnight)
        return Timeline(entries: [entry], policy: policy)
    }

    private func getVerse(for configuration: DharmaWidgetConfiguration) -> WidgetVerse {
        let shared = SharedDataManager.shared
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let favs = shared.loadFavourites()
        let all = shared.loadAllVerses()

        switch configuration.contentType {
        case .daily:
            if !all.isEmpty { return all[dayOfYear % all.count] }
        case .gita:
            let gita = all.filter { $0.category == "Bhagavad Gita" }
            if !gita.isEmpty { return gita[dayOfYear % gita.count] }
        case .upanishad:
            let upanishads = all.filter { $0.category == "Upanishads" }
            if !upanishads.isEmpty { return upanishads[dayOfYear % upanishads.count] }
        case .rigVeda:
            let rigVeda = all.filter { $0.category == "Rig Veda" }
            if !rigVeda.isEmpty { return rigVeda[dayOfYear % rigVeda.count] }
        case .mantra:
            let mantras = all.filter { $0.category == "Mantras" }
            if !mantras.isEmpty { return mantras[dayOfYear % mantras.count] }
        case .favourites:
            if !favs.isEmpty { return favs[dayOfYear % favs.count] }
        case .pinned:
            if let pinned = configuration.pinnedVerse,
               let match = favs.first(where: { $0.source == pinned.id }) {
                return match
            }
            if !favs.isEmpty { return favs[0] }
        }

        return WidgetVerse(
            title: "Verse of the Day",
            text: "You have the right to work only, and not to the fruits of work.",
            source: "Bhagavad Gita 2.47",
            speaker: "Krishna",
            category: "Bhagavad Gita"
        )
    }
}

// MARK: - Widget Entry View
struct DharmaWidgetEntryView: View {
    var entry: DharmaEntry
    @Environment(\.widgetFamily) var family

    var goldColor: Color { Color(red: 0.91, green: 0.48, blue: 0.18) }

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, goldColor: goldColor)
        case .systemMedium:
            MediumWidgetView(entry: entry, goldColor: goldColor)
        case .systemLarge:
            LargeWidgetView(entry: entry, goldColor: goldColor)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry, goldColor: goldColor)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: DharmaEntry
    let goldColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: categoryIcon(entry.verse.category))
                    .font(.system(size: 9))
                    .foregroundColor(goldColor)
                Text(entry.verse.category)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(goldColor)
                Spacer()
            }

            Spacer()

            Text(entry.verse.text)
                .font(.system(size: 11, weight: .regular, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(4)
                .lineSpacing(2)

            Spacer()

            Text(entry.verse.source)
                .font(.system(size: 9))
                .foregroundColor(goldColor)
                .italic()
                .lineLimit(1)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: DharmaEntry
    let goldColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(goldColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 9))
                        .foregroundColor(goldColor)
                    Text("VERSE OF THE DAY")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(goldColor)
                        .kerning(0.5)
                    Spacer()
                    Text(entry.verse.category)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                Text(entry.verse.text)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .lineSpacing(3)

                Spacer()

                Text(entry.verse.source)
                    .font(.system(size: 10))
                    .foregroundColor(goldColor)
                    .italic()
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: DharmaEntry
    let goldColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(goldColor)
                Text("VERSE OF THE DAY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(goldColor)
                    .kerning(0.8)
                Spacer()
                Text(Date().formatted(.dateTime.month().day()))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            if !entry.verse.speaker.isEmpty {
                Text(entry.verse.speaker)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(goldColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(goldColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(entry.verse.text)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack {
                Rectangle()
                    .fill(goldColor)
                    .frame(width: 2, height: 14)
                    .clipShape(Capsule())
                Text(entry.verse.source)
                    .font(.system(size: 11))
                    .foregroundColor(goldColor)
                    .italic()
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Lock Screen Rectangular
struct AccessoryRectangularView: View {
    let entry: DharmaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.verse.source)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(entry.verse.text)
                .font(.system(size: 11, design: .serif))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .lineSpacing(2)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Helpers
func categoryIcon(_ category: String) -> String {
    switch category {
    case "Bhagavad Gita": return "book.fill"
    case "Upanishads": return "scroll.fill"
    case "Rig Veda": return "flame.fill"
    case "Mantras": return "waveform"
    case "Bhajans": return "music.note"
    default: return "sparkles"
    }
}

func categoryColor(_ category: String) -> Color {
    switch category {
    case "Bhagavad Gita": return Color(red: 0.91, green: 0.48, blue: 0.18)
    case "Upanishads": return Color(red: 0.4, green: 0.7, blue: 0.9)
    case "Rig Veda": return Color(red: 0.698, green: 0.298, blue: 0.176)
    case "Mantras": return Color(red: 0.6, green: 0.8, blue: 0.5)
    case "Bhajans": return Color(red: 0.9, green: 0.5, blue: 0.7)
    default: return Color(red: 0.91, green: 0.48, blue: 0.18)
    }
}

// MARK: - Widget Definition
struct DharmaWidget: Widget {
    let kind: String = "DharmaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: DharmaWidgetConfiguration.self,
            provider: DharmaWidgetProvider()
        ) { entry in
            DharmaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dharma")
        .description("Daily scripture from the Bhagavad Gita and more")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

#Preview(as: .systemMedium) {
    DharmaWidget()
} timeline: {
    DharmaEntry(
        date: Date(),
        verse: WidgetVerse(
            title: "Krishna — 2.47",
            text: "You have the right to work only, and not to the fruits of work. Let not the fruit of action be your motive, nor let your attachment be to inaction.",
            source: "Bhagavad Gita 2.47",
            speaker: "Krishna",
            category: "Bhagavad Gita"
        ),
        contentType: .daily
    )
}
