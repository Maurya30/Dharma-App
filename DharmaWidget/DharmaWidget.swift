import WidgetKit
import SwiftUI

// MARK: - Appearance (matches main app `userDarkMode` via App Group; falls back to system)

private func widgetAppearanceScheme(_ environment: ColorScheme) -> ColorScheme {
    if let stored = SharedDataManager.shared.loadUserDarkModeForWidget() {
        return stored ? .dark : .light
    }
    return environment
}

// MARK: - Theme-aligned palette (duplicated from Theme.swift — widget target cannot import app)

private enum WidgetTheme {
    /// Saffron accent — #C9821E
    static let saffron = Color(red: 0.788, green: 0.510, blue: 0.118)

    /// Primary body/title text
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.961, green: 0.902, blue: 0.784)
            : Color(red: 0.165, green: 0.102, blue: 0.000)
    }

    /// Secondary labels (matches `dharmaTextSecondary`)
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.541, green: 0.478, blue: 0.353)
            : Color(red: 0.604, green: 0.478, blue: 0.251)
    }

    /// Speaker pill text (matches `dharmaSpeakerText`)
    static func speakerText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.961, green: 0.753, blue: 0.416)
            : Color(red: 0.788, green: 0.510, blue: 0.118)
    }

    /// Speaker pill background (matches `dharmaSpeakerBg`)
    static func speakerBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.788, green: 0.510, blue: 0.118).opacity(0.20)
            : Color(red: 0.788, green: 0.510, blue: 0.118).opacity(0.08)
    }

    /// Divider (matches `dharmaDivider`)
    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 0.788, green: 0.510, blue: 0.118).opacity(0.15)
    }

    /// DharmaBackground gradient — light: #FFF9E8 → #F2DCA8 → #D8BF8A; dark: #2A1F0A → #1A1206
    static func backgroundGradient(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            LinearGradient(
                colors: [
                    Color(red: 42 / 255, green: 31 / 255, blue: 10 / 255),
                    Color(red: 26 / 255, green: 18 / 255, blue: 6 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [
                    Color(red: 255 / 255, green: 249 / 255, blue: 232 / 255),
                    Color(red: 242 / 255, green: 220 / 255, blue: 168 / 255),
                    Color(red: 216 / 255, green: 191 / 255, blue: 138 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// ॐ metrics from DharmaBackground: base size 350, offset (-30, -50), rotation 10°, opacity 0.10 / 0.13 — scaled by widget family vs reference width 390pt.
    static func omMetrics(for family: WidgetFamily) -> (font: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let baseFont: CGFloat = 350
        let baseOffsetX: CGFloat = -30
        let baseOffsetY: CGFloat = -50
        let scale: CGFloat
        switch family {
        case .systemSmall:
            scale = 160 / 390
        case .systemMedium:
            scale = 170 / 390
        case .systemLarge:
            scale = 364 / 390
        case .accessoryRectangular:
            scale = 72 / 390
        default:
            scale = 160 / 390
        }
        return (baseFont * scale, baseOffsetX * scale, baseOffsetY * scale)
    }
}

// MARK: - ॐ watermark (aligned with DharmaBackground)

private struct WidgetOmWatermark: View {
    let family: WidgetFamily
    /// Resolved appearance (app preference or system), not raw widget environment alone.
    var appearance: ColorScheme

    var body: some View {
        let m = WidgetTheme.omMetrics(for: family)
        Text("ॐ")
            .font(.system(size: m.font, weight: .ultraLight, design: .serif))
            .foregroundColor(WidgetTheme.saffron)
            .opacity(appearance == .dark ? 0.13 : 0.10)
            .rotationEffect(.degrees(10))
            .offset(x: m.offsetX, y: m.offsetY)
            .accessibilityHidden(true)
    }
}

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

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, accentColor: WidgetTheme.saffron)
        case .systemMedium:
            MediumWidgetView(entry: entry, accentColor: WidgetTheme.saffron)
        case .systemLarge:
            LargeWidgetView(entry: entry, accentColor: WidgetTheme.saffron)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry, accentColor: WidgetTheme.saffron)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: DharmaEntry
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily

    private var appearanceScheme: ColorScheme {
        widgetAppearanceScheme(colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VERSE OF THE DAY")
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(accentColor)
                .kerning(0.5)

            Spacer(minLength: 0)

            Text(entry.verse.text)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundColor(WidgetTheme.textPrimary(appearanceScheme))
                .lineLimit(4)
                .lineSpacing(3)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)

            Text(entry.verse.source)
                .font(.system(size: 9))
                .foregroundColor(accentColor)
                .italic()
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(alignment: .topLeading) {
            WidgetOmWatermark(family: widgetFamily, appearance: appearanceScheme)
                .allowsHitTesting(false)
        }
        .containerBackground(for: .widget) {
            WidgetTheme.backgroundGradient(appearanceScheme)
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: DharmaEntry
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily

    private var appearanceScheme: ColorScheme {
        widgetAppearanceScheme(colorScheme)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 9))
                        .foregroundColor(accentColor)
                    Text("VERSE OF THE DAY")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(accentColor)
                        .kerning(0.5)
                    Spacer(minLength: 4)
                    Text(entry.verse.category)
                        .font(.system(size: 9))
                        .foregroundColor(WidgetTheme.textSecondary(appearanceScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text(entry.verse.text)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(WidgetTheme.textPrimary(appearanceScheme))
                    .lineLimit(3)
                    .lineSpacing(4)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Text(entry.verse.source)
                    .font(.system(size: 10))
                    .foregroundColor(accentColor)
                    .italic()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(alignment: .topLeading) {
            WidgetOmWatermark(family: widgetFamily, appearance: appearanceScheme)
                .allowsHitTesting(false)
        }
        .containerBackground(for: .widget) {
            WidgetTheme.backgroundGradient(appearanceScheme)
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: DharmaEntry
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily

    private var appearanceScheme: ColorScheme {
        widgetAppearanceScheme(colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(accentColor)
                Text("VERSE OF THE DAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentColor)
                    .kerning(0.8)
                Spacer(minLength: 4)
                Text(Date().formatted(.dateTime.month().day()))
                    .font(.system(size: 10))
                    .foregroundColor(WidgetTheme.textSecondary(appearanceScheme))
            }

            Divider()
                .tint(WidgetTheme.divider(appearanceScheme))

            if !entry.verse.speaker.isEmpty {
                Text(entry.verse.speaker)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(WidgetTheme.speakerText(appearanceScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(WidgetTheme.speakerBackground(appearanceScheme))
                    .clipShape(Capsule())
            }

            Text(entry.verse.text)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(WidgetTheme.textPrimary(appearanceScheme))
                .lineLimit(8)
                .lineSpacing(6)
                .minimumScaleFactor(0.90)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 2, height: 14)
                    .clipShape(Capsule())
                Text(entry.verse.source)
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
                    .italic()
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
            }
        }
        .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(alignment: .topLeading) {
            WidgetOmWatermark(family: widgetFamily, appearance: appearanceScheme)
                .allowsHitTesting(false)
        }
        .containerBackground(for: .widget) {
            WidgetTheme.backgroundGradient(appearanceScheme)
        }
    }
}

// MARK: - Lock Screen Rectangular
struct AccessoryRectangularView: View {
    let entry: DharmaEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var widgetFamily

    private var appearanceScheme: ColorScheme {
        widgetAppearanceScheme(colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.verse.source)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(WidgetTheme.textSecondary(appearanceScheme))
            Text(entry.verse.text)
                .font(.system(size: 11, design: .serif))
                .foregroundColor(WidgetTheme.textPrimary(appearanceScheme))
                .lineLimit(2)
                .lineSpacing(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(alignment: .topLeading) {
            WidgetOmWatermark(family: widgetFamily, appearance: appearanceScheme)
                .allowsHitTesting(false)
        }
        .containerBackground(for: .widget) {
            WidgetTheme.backgroundGradient(appearanceScheme)
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
    case "Bhagavad Gita": return Color(red: 0.729, green: 0.459, blue: 0.090)
    case "Upanishads": return Color(red: 0.325, green: 0.294, blue: 0.718)
    case "Rig Veda": return Color(red: 0.698, green: 0.298, blue: 0.176)
    case "Mantras": return Color(red: 0.059, green: 0.431, blue: 0.337)
    case "Bhajans": return Color(red: 0.9, green: 0.5, blue: 0.7)
    default: return Color(red: 0.788, green: 0.510, blue: 0.118)
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














