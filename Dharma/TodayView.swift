import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: ScriptureStore

    private var dailyVerse: ScriptureItem? {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let verses = store.items(for: .gita)
        guard !verses.isEmpty else { return nil }
        return verses[dayOfYear % verses.count]
    }

    private var nextFestival: HinduFestival? {
        HinduFestival.sampleData.sorted { $0.date < $1.date }.first { !$0.isPast }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DharmaSpacing.lg) {

                    // Greeting
                    VStack(spacing: 4) {
                        Text(greeting)
                            .font(DharmaFont.title(20))
                            .foregroundColor(.dharmaTextPrimary)
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(DharmaFont.caption(13))
                            .foregroundColor(.dharmaTextMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DharmaSpacing.md)

                    // Daily verse card
                    if let verse = dailyVerse {
                        DailyVerseCard(item: verse)
                            .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Next festival teaser
                    if let festival = nextFestival {
                        NavigationLink(destination: FestivalDetailView(festival: festival)) {
                            FestivalTeaserCard(festival: festival)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Quick access
                    QuickAccessGrid()
                        .padding(.horizontal, DharmaSpacing.md)

                    Spacer(minLength: DharmaSpacing.xxl)
                }
            }
            .background(Color.dharmaBackground)
            .navigationTitle("Dharma")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "🌅  Good morning"
        case 12..<17: return "☀️  Good afternoon"
        case 17..<21: return "🌇  Good evening"
        default:      return "🌙  Good night"
        }
    }
}

// MARK: - Daily Verse Card
struct DailyVerseCard: View {
    let item: ScriptureItem
    @EnvironmentObject var store: ScriptureStore

    private var liveItem: ScriptureItem {
        store.items.first { $0.id == item.id } ?? item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            HStack {
                Label("Verse of the Day", systemImage: "sun.max.fill")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Spacer()
                Button {
                    store.toggleFavourite(liveItem)
                } label: {
                    Image(systemName: liveItem.isFavourite ? "heart.fill" : "heart")
                        .foregroundColor(liveItem.isFavourite ? .dharmaGold : .dharmaTextMuted)
                        .animation(.easeInOut(duration: 0.2), value: liveItem.isFavourite)
                }
            }

            Text(liveItem.textEnglish)
                .font(DharmaFont.sanskrit(16))
                .foregroundColor(.dharmaTextPrimary)
                .lineSpacing(6)

            HStack {
                Rectangle()
                    .fill(Color.dharmaGold)
                    .frame(width: 2, height: 14)
                    .clipShape(Capsule())
                Text(liveItem.source)
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
                    .italic()
            }
        }
        .padding(DharmaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DharmaRadius.lg)
                .fill(Color.dharmaSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: DharmaRadius.lg)
                        .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Festival Teaser
struct FestivalTeaserCard: View {
    let festival: HinduFestival

    var body: some View {
        HStack(spacing: DharmaSpacing.md) {
            VStack(spacing: 2) {
                Text(festival.date.formatted(.dateTime.month(.abbreviated)))
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                Text(festival.date.formatted(.dateTime.day()))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.dharmaTextPrimary)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(festival.isToday ? "Today — \(festival.name)" : "\(festival.name) in \(festival.daysUntil) days")
                    .font(DharmaFont.heading(14))
                    .foregroundColor(.dharmaTextPrimary)
                Text(festival.shortDescription)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaTextMuted)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.dharmaTextMuted)
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Quick Access Grid
struct QuickAccessGrid: View {
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Browse")
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaTextMuted)
                .textCase(.uppercase)
                .kerning(0.8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ScriptureCategory.allCases) { cat in
                    NavigationLink(destination: CategoryDetailView(category: cat)) {
                        QuickAccessTile(category: cat)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct QuickAccessTile: View {
    let category: ScriptureCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 20))
                .foregroundColor(category.color)

            Text(category.rawValue)
                .font(DharmaFont.heading(14))
                .foregroundColor(.dharmaTextPrimary)
                .lineLimit(1)

            Text(category.description)
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaTextMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Category Detail View
struct CategoryDetailView: View {
    let category: ScriptureCategory
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.items(for: category)) { item in
                    NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                        ScriptureCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .background(Color.dharmaBackground)
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    TodayView()
        .environmentObject(ScriptureStore())
}
