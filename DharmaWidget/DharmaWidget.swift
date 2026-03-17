//
//  DharmaWidget.swift
//  DharmaWidget
//
//  Created by Maurya Panchal on 2026-03-16.
//

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
            verse: getVerse(for: configuration.contentType),
            contentType: configuration.contentType
        )
    }

    func timeline(for configuration: DharmaWidgetConfiguration, in context: Context) async -> Timeline<DharmaEntry> {
        let verse = getVerse(for: configuration.contentType)
        let entry = DharmaEntry(date: Date(), verse: verse, contentType: configuration.contentType)

        // Refresh at midnight each day
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(midnight))
    }

    private func getVerse(for type: WidgetContentType) -> WidgetVerse {
        let shared = SharedDataManager.shared
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        switch type {
        case .favourites:
            let favs = shared.loadFavourites()
            if !favs.isEmpty {
                return favs[dayOfYear % favs.count]
            }
            fallthrough
        default:
            return shared.loadWidgetVerse() ?? WidgetVerse(
                title: "Verse of the Day",
                text: "You have the right to work only, and not to the fruits of work.",
                source: "Bhagavad Gita 2.47",
                speaker: "Krishna",
                category: "Bhagavad Gita"
            )
        }
    }
}

// MARK: - Widget Views
struct DharmaWidgetEntryView: View {
    var entry: DharmaEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: DharmaEntry

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.16)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: categoryIcon(entry.verse.category))
                        .font(.system(size: 10))
                        .foregroundColor(categoryColor(entry.verse.category))
                    Text(entry.verse.category)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(categoryColor(entry.verse.category))
                    Spacer()
                }

                Spacer()

                Text(entry.verse.text)
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .lineSpacing(2)

                Spacer()

                Text(entry.verse.source)
                    .font(.system(size: 9))
                    .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                    .italic()
                    .lineLimit(1)
            }
            .padding(12)
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: DharmaEntry

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.16)

            HStack(spacing: 12) {
                // Left accent bar
                Rectangle()
                    .fill(categoryColor(entry.verse.category))
                    .frame(width: 3)
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                        Text("VERSE OF THE DAY")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                            .kerning(0.5)
                        Spacer()
                        Text(entry.verse.category)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Text(entry.verse.text)
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .lineSpacing(3)

                    Spacer()

                    Text(entry.verse.source)
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                        .italic()
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: DharmaEntry

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.16)

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                    Text("VERSE OF THE DAY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                        .kerning(0.8)
                    Spacer()
                    Text(Date().formatted(.dateTime.month().day()))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Speaker badge
                if !entry.verse.speaker.isEmpty {
                    Text(entry.verse.speaker)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(categoryColor(entry.verse.category))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(categoryColor(entry.verse.category).opacity(0.15))
                        .clipShape(Capsule())
                }

                // Full verse text
                Text(entry.verse.text)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(.white)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Source
                HStack {
                    Rectangle()
                        .fill(Color(red: 0.9, green: 0.6, blue: 0.2))
                        .frame(width: 2, height: 14)
                        .clipShape(Capsule())
                    Text(entry.verse.source)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.2))
                        .italic()
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Helpers
func categoryIcon(_ category: String) -> String {
    switch category {
    case "Bhagavad Gita": return "book.fill"
    case "Upanishads": return "scroll.fill"
    case "Mantras": return "waveform"
    case "Bhajans": return "music.note"
    default: return "sparkles"
    }
}

func categoryColor(_ category: String) -> Color {
    switch category {
    case "Bhagavad Gita": return Color(red: 0.9, green: 0.6, blue: 0.2)
    case "Upanishads": return Color(red: 0.4, green: 0.7, blue: 0.9)
    case "Mantras": return Color(red: 0.6, green: 0.8, blue: 0.5)
    case "Bhajans": return Color(red: 0.9, green: 0.5, blue: 0.7)
    default: return Color(red: 0.9, green: 0.6, blue: 0.2)
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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Dharma")
        .description("Daily scripture from the Bhagavad Gita and more")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
