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

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = UserDefaults.standard.string(forKey: "dharma_user_name") ?? ""
        let suffix = name.isEmpty ? "" : ", \(name)"
        switch hour {
        case 5..<12:  return "Good morning\(suffix)"
        case 12..<17: return "Good afternoon\(suffix)"
        case 17..<21: return "Good evening\(suffix)"
        default:      return "Good night\(suffix)"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DharmaSpacing.lg) {

                    // Greeting + Streak
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greeting)
                                .font(DharmaFont.body(15))
                                .foregroundColor(.dharmaTextSecondary)
                            Text(Date().formatted(date: .complete, time: .omitted))
                                .font(DharmaFont.caption(12))
                                .foregroundColor(.dharmaTextMuted)
                        }

                        Spacer()

                        if store.streak > 0 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 14))
                                Text("\(store.streak)")
                                    .font(DharmaFont.heading(15))
                                    .foregroundColor(.dharmaGold)
                                Text(store.streak == 1 ? "day" : "days")
                                    .font(DharmaFont.caption(11))
                                    .foregroundColor(.dharmaTextMuted)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.dharmaGold.opacity(0.10))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.top, DharmaSpacing.sm)

                    // Verse of the Day
                    if let verse = dailyVerse {
                        DailyVerseCard(item: verse)
                            .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Your Journey
                    JourneyCard()
                        .padding(.horizontal, DharmaSpacing.md)

                    // Coming Up
                    if let festival = nextFestival {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Coming Up")
                                .font(DharmaFont.caption(11))
                                .foregroundColor(.dharmaTextMuted)
                                .textCase(.uppercase)
                                .kerning(0.8)
                                .padding(.horizontal, DharmaSpacing.md)

                            NavigationLink(destination: FestivalDetailView(festival: festival)) {
                                FestivalTeaserCard(festival: festival)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DharmaSpacing.md)
                        }
                    }

                    // Browse
                    QuickAccessGrid()
                        .padding(.horizontal, DharmaSpacing.md)

                    Spacer(minLength: DharmaSpacing.xxl)
                }
            }
            .background(Color.dharmaBackground)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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
        NavigationLink(destination: ScriptureDetailView(item: liveItem, store: store)) {
            VStack(alignment: .leading, spacing: DharmaSpacing.md) {
                Label("Verse of the Day", systemImage: "sun.max.fill")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(0.5)

                Text(liveItem.textEnglish)
                    .font(DharmaFont.georgia(15))
                    .foregroundColor(.dharmaTextBody)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)

                HStack {
                    Rectangle()
                        .fill(Color.dharmaGold)
                        .frame(width: 2, height: 14)
                        .clipShape(Capsule())

                    let speaker = liveItem.title.split(separator: "—").first.map {
                        String($0).trimmingCharacters(in: .whitespaces)
                    } ?? ""
                    Text("\(liveItem.source) · \(speaker)")
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaGold)
                        .italic()

                    Spacer()

                    Button {
                        store.toggleFavourite(liveItem)
                    } label: {
                        Image(systemName: liveItem.isFavourite ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(liveItem.isFavourite ? .dharmaGold : .dharmaTextMuted)
                    }
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
        .buttonStyle(.plain)
    }
}

// MARK: - Journey Card
struct JourneyCard: View {
    @EnvironmentObject var store: ScriptureStore

    private var progress: Double {
        store.totalGitaVerses > 0 ? Double(store.readCount) / Double(store.totalGitaVerses) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Journey")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaTextMuted)
                    .textCase(.uppercase)
                    .kerning(0.8)

                Spacer()

                NavigationLink(destination: ChapterListView()) {
                    Text("See all →")
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaGold)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Bhagavad Gita")
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.dharmaTextPrimary)

                    Spacer()

                    Text("\(store.readCount) / \(store.totalGitaVerses) verses")
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaTextMuted)
                }

                ProgressView(value: progress)
                    .tint(.dharmaGold)

                if let chapterInfo = store.lastReadChapterInfo {
                    Text("Chapter \(chapterInfo.chapterNumber) · \(chapterInfo.nameTranslation)")
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaTextSecondary)
                }

                if let lastItem = store.lastReadItem {
                    NavigationLink(destination: ScriptureDetailView(item: lastItem, store: store)) {
                        HStack {
                            Text("Continue reading")
                                .font(DharmaFont.body(14))
                                .foregroundColor(.dharmaGold)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(.dharmaGold)
                        }
                        .padding(.top, 4)
                    }
                } else {
                    NavigationLink(destination: ChapterListView()) {
                        HStack {
                            Text("Start reading")
                                .font(DharmaFont.body(14))
                                .foregroundColor(.dharmaGold)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(.dharmaGold)
                        }
                        .padding(.top, 4)
                    }
                }
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

            Rectangle()
                .fill(Color.dharmaGold.opacity(0.3))
                .frame(width: 1)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                Text(festival.name)
                    .font(DharmaFont.heading(14))
                    .foregroundColor(.dharmaTextPrimary)
                Text(festival.shortDescription)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaTextMuted)
                    .lineLimit(1)
            }

            Spacer()

            if !festival.isToday {
                Text("\(festival.daysUntil)\ndays")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dharmaGold.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
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
                    if cat == .gita {
                        NavigationLink(destination: ChapterListView()) {
                            QuickAccessTile(category: cat)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(destination: CategoryDetailView(category: cat)) {
                            QuickAccessTile(category: cat)
                        }
                        .buttonStyle(.plain)
                    }
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
