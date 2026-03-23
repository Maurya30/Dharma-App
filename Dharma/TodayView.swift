import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: ScriptureStore
    @State private var showKrishna = false

    private var dailyVerse: ScriptureItem? {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let userGoals = GoalsManager.shared.selectedGoals
        let allVerses = store.items

        if !userGoals.isEmpty {
            let matchedIds = GoalTagsLoader.shared.verseIds(matching: userGoals)
            let goalVerses = allVerses.filter { item in
                guard let bid = GoalTagsLoader.backendId(for: item) else { return false }
                return matchedIds.contains(bid)
            }
            if !goalVerses.isEmpty {
                return goalVerses[dayOfYear % goalVerses.count]
            }
        }

        let gitaVerses = store.items(for: .gita)
        guard !gitaVerses.isEmpty else { return nil }
        return gitaVerses[dayOfYear % gitaVerses.count]
    }

    /// The first goal that matches the daily verse, for display.
    private var dailyVerseGoal: String? {
        guard let verse = dailyVerse else { return nil }
        let matches = GoalTagsLoader.shared.matchingUserGoals(for: verse, userGoals: GoalsManager.shared.selectedGoals)
        return matches.first
    }

    private var nextFestival: HinduFestival? {
        allFestivals.sorted { $0.date < $1.date }.first { !$0.isPast }
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
                        DailyVerseCard(item: verse, goalName: dailyVerseGoal)
                            .padding(.horizontal, DharmaSpacing.md)
                    } else {
                        WarmEmptyState(
                            icon: "sun.horizon",
                            title: "Verses are gathering",
                            message: "We couldn’t pick a verse of the day yet — pull down to refresh, or open the Library when you’re ready.",
                            hint: "Sacred texts load from your device; a moment of patience often helps."
                        )
                        .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Krishna Card
                    Button {
                        DharmaHaptics.light()
                        showKrishna = true
                    } label: {
                        KrishnaTodayCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DharmaSpacing.md)
                    .sheet(isPresented: $showKrishna) {
                        KrishnaView(verse: nil)
                            .environmentObject(store)
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
            .refreshable {
                await store.refreshLibraryContent()
                DharmaHaptics.light()
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
    var goalName: String? = nil
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
                        DharmaHaptics.light()
                    } label: {
                        Image(systemName: liveItem.isFavourite ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(liveItem.isFavourite ? .dharmaGold : .dharmaTextMuted)
                    }
                }

                if let goal = goalName {
                    Text("For your goal: \(GoalsManager.shortName(for: goal))")
                        .font(DharmaFont.caption(12))
                        .italic()
                        .foregroundColor(.dharmaGold)
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

    private var otherJourneyCategories: [ScriptureCategory] {
        [.upanishads, .rigVeda, .mantras, .bhajans].filter { store.lastReadItem(for: $0) != nil }
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

            VStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                gitaJourneyBlock

                ForEach(otherJourneyCategories, id: \.self) { category in
                    if let item = store.lastReadItem(for: category) {
                        Divider().background(Color.dharmaDivider)

                        otherCategoryJourneyBlock(category: category, item: item)
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

    private var gitaJourneyBlock: some View {
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

            if let lastItem = store.lastReadItem(for: .gita) {
                NavigationLink(destination: ScriptureDetailView(item: lastItem, store: store)) {
                    journeyActionRowLabel("Continue reading")
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink(destination: ChapterListView()) {
                    journeyActionRowLabel("Start reading")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func otherCategoryJourneyBlock(category: ScriptureCategory, item: ScriptureItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(DharmaFont.heading(16))
                    .foregroundColor(.dharmaTextPrimary)
            }

            Text(item.title)
                .font(DharmaFont.caption(12))
                .foregroundColor(.dharmaTextSecondary)
                .lineLimit(2)

            NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                journeyActionRowLabel("Continue reading")
            }
            .buttonStyle(.plain)
        }
    }

    private func journeyActionRowLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(DharmaFont.body(14))
                .foregroundColor(.dharmaGold)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(.dharmaGold)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(Color.dharmaGold.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.sm))
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
                    NavigationLink(destination: browseDestination(for: cat)) {
                        QuickAccessTile(category: cat)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

extension QuickAccessGrid {
    @ViewBuilder
    func browseDestination(for category: ScriptureCategory) -> some View {
        switch category {
        case .gita:       ChapterListView()
        case .upanishads: UpanishadListView()
        case .rigVeda:    RigVedaListView()
        default:          CategoryDetailView(category: category)
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

// MARK: - Krishna Today Card

struct KrishnaTodayCard: View {
    var body: some View {
        HStack(spacing: DharmaSpacing.md) {
            Image(systemName: "seal.fill")
                .font(.system(size: 26))
                .foregroundColor(.dharmaGold)

            VStack(alignment: .leading, spacing: 3) {
                Text("Krishna is here.")
                    .font(DharmaFont.georgia(16))
                    .foregroundColor(.dharmaTextPrimary)
                    .fontWeight(.medium)
                Text("Ask anything.")
                    .font(DharmaFont.georgia(14))
                    .foregroundColor(.dharmaTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.dharmaGold.opacity(0.6))
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaGold.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                .strokeBorder(Color.dharmaGold.opacity(0.45), lineWidth: 1)
        )
    }
}

#Preview {
    TodayView()
        .environmentObject(ScriptureStore())
}
