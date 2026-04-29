import SwiftUI

struct TodayView: View {
    enum TimeOfDay {
        case morning   // 5am–11:59am
        case afternoon // 12pm–5:59pm
        case evening   // 6pm–10:59pm
        case night     // 11pm–4:59am
    }

    @EnvironmentObject var store: ScriptureStore
    @ObservedObject var sadhana = SadhanaManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showKrishna = false
    @State private var showSadhana = false
    @State private var showSettings = false
    @State private var showCompletionOverlay = false
    @State private var hasShownCompletionToday = false
    @State private var closingVerse: ScriptureItem? = nil
    @State private var isTodayLoading = true
    
    private var userName: String {
        UserDefaults.standard.string(forKey: "dharma_user_name") ?? ""
    }

    private var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<23: return .evening
        default: return .night
        }
    }

    private var greetingText: String {
        switch timeOfDay {
        case .morning: return "Good morning"
        case .afternoon: return "Good afternoon"
        case .evening: return "Good evening"
        case .night: return "Still up late"
        }
    }

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

    private var formattedDateAndStreak: String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "EEEE, MMMM d"
        let dateStr = df.string(from: Date())
        if sadhana.streakDays > 0 {
            return "\(dateStr) · \(sadhana.streakDays) day streak"
        }
        return dateStr
    }

    private var closingVerseText: String {
        let fallback = "Perform your duty equipoised, abandoning all attachment to success or failure."
        guard let t = closingVerse?.textEnglish, !t.isEmpty else { return fallback }
        if t.count > 120 { return String(t.prefix(120)) + "..." }
        return t
    }

    private var closingVerseSource: String {
        closingVerse?.source ?? "Bhagavad Gita 2.48"
    }

    private var nextFestival: HinduFestival? {
        allFestivals.sorted { $0.date < $1.date }.first { !$0.isPast }
    }

    private var greeting: String {
        let suffix = userName.isEmpty ? "" : ", \(userName)"
        return "\(greetingText)\(suffix)"
    }

    private var morningMessage: String {
        let name = UserDefaults.standard.string(forKey: "dharma_user_name") ?? "friend"
        let summary = AuthManager.shared.lastOfferingSummary

        let firstSentence = summary
            .components(separatedBy: ".")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !firstSentence.isEmpty {
            switch timeOfDay {
            case .morning:
                return "\(firstSentence). Today's verse speaks to this."
            case .afternoon:
                return "This morning you reflected on \(firstSentence.lowercased()). How is your day unfolding?"
            case .evening:
                return "\(firstSentence). As the day ends — what arose for you?"
            case .night:
                return "The day is quieting. \(firstSentence). Rest, Arjuna — the work continues tomorrow."
            }
        }

        switch timeOfDay {
        case .morning:
            return "What is on your heart this morning, \(name)?"
        case .afternoon:
            return "The day is moving, \(name). Krishna is here if something weighs on you."
        case .evening:
            return "The evening is a good time to reflect, \(name). What did today bring?"
        case .night:
            return "Still here, \(name). What's keeping you up?"
        }
    }
    
    private var completionMessage: String {
        let name = UserDefaults.standard.string(forKey: "dharma_user_name") ?? "friend"
        return """
        साधु, \(name).
        You sat with today's practice.
        That is enough. Return when
        something is on your heart.
        """
    }
    
    private var krishnaMessage: String {
        sadhana.isFullyComplete ? completionMessage : morningMessage
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: DharmaSpacing.xl) {

                        // Greeting + Streak
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greeting)
                                    .font(.system(size: 22, weight: .regular, design: .serif))
                                    .foregroundColor(.dharmaTextPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(Date().formatted(date: .complete, time: .omitted))
                                    .font(DharmaFont.body(15))
                                    .foregroundColor(.dharmaTextMuted)
                            }

                            Spacer()

                            if store.streak > 0 {
                                HStack(spacing: 6) {
                                    Text("🔥")
                                        .font(.system(size: 18))
                                    Text("\(store.streak)")
                                        .font(DharmaFont.body(17))
                                        .foregroundColor(.dharmaGold)
                                    Text(store.streak == 1 ? "day" : "days")
                                        .font(DharmaFont.caption(13))
                                        .foregroundColor(.dharmaTextMuted)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.dharmaGold.opacity(0.10))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, DharmaSpacing.lg)
                        .padding(.top, DharmaSpacing.sm)

                        // Krishna hero — leads the screen
                        Group {
                            if isTodayLoading {
                                DharmaSkeletonCard(height: 360)
                                    .padding(.horizontal, DharmaSpacing.lg)
                            } else {
                                KrishnaTodayHeroCard(
                                    dailyVerse: dailyVerse,
                                    userName: userName,
                                    message: krishnaMessage,
                                    isSadhanaComplete: sadhana.isFullyComplete,
                                    onSpeakWithKrishna: {
                                        HapticManager.light()
                                        showKrishna = true
                                    },
                                    onOpenSadhana: {
                                        HapticManager.light()
                                        showSadhana = true
                                    },
                                    onOpenLibrary: {
                                        HapticManager.light()
                                        NotificationNavigationState.shared.selectedTab = 1
                                    }
                                )
                                .padding(.horizontal, DharmaSpacing.lg)
                            }
                        }
                        .fullScreenCover(isPresented: $showKrishna) {
                            KrishnaView(verse: nil)
                            .environmentObject(store)
                        }

                        // Sadhana progress (compact)
                        Group {
                            if isTodayLoading {
                                DharmaSkeletonCard(height: 70)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, DharmaSpacing.lg)
                                    .glassCard(cornerRadius: DharmaRadius.md)
                            } else if sadhana.isFullyComplete {
                                HStack(alignment: .center, spacing: DharmaSpacing.md) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("SADHANA")
                                            .font(.system(size: 13, weight: .semibold, design: .default))
                                            .foregroundColor(.dharmaGold)
                                            .textCase(.uppercase)
                                            .kerning(1.4)

                                        Text(sadhanaTitleText)
                                            .font(.system(size: 17, weight: .regular, design: .serif))
                                            .foregroundColor(sadhanaTitleColor)
                                            .lineLimit(1)

                                        Text("Complete · साधु")
                                            .font(DharmaFont.caption())
                                            .foregroundColor(.dharmaGold)
                                    }

                                    Spacer()

                                    HStack(spacing: 7) {
                                        ForEach(0..<3, id: \.self) { _ in
                                            Circle()
                                                .frame(width: 11, height: 11)
                                                .foregroundColor(Color.dharmaGold)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.dharmaGold.opacity(1.0), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, DharmaSpacing.lg)
                                .glassCard(cornerRadius: DharmaRadius.md)
                            } else {
                                Button {
                                    HapticManager.light()
                                    showSadhana = true
                                } label: {
                                    HStack(alignment: .center, spacing: DharmaSpacing.md) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("SADHANA")
                                                .font(.system(size: 13, weight: .semibold, design: .default))
                                                .foregroundColor(.dharmaGold)
                                                .textCase(.uppercase)
                                                .kerning(1.4)

                                            Text(sadhanaTitleText)
                                                .font(.system(size: 17, weight: .regular, design: .serif))
                                                .foregroundColor(sadhanaTitleColor)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        HStack(spacing: 7) {
                                            ForEach(0..<3, id: \.self) { i in
                                                Circle()
                                                    .frame(width: 11, height: 11)
                                                    .foregroundColor(i < sadhana.completedCount ? Color.dharmaGold : Color.clear)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                Color.dharmaGold.opacity(i < sadhana.completedCount ? 1.0 : 0.35),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, DharmaSpacing.lg)
                                    .glassCard(cornerRadius: DharmaRadius.md)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, DharmaSpacing.lg)
                        .fullScreenCover(isPresented: $showSadhana) {
                            SadhanaView()
                        }

                        // 4) Coming Up (moved here, UI unchanged)
                        if let festival = nextFestival {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Coming Up")
                                    .font(DharmaFont.caption(13))
                                    .foregroundColor(.dharmaTextMuted)
                                    .textCase(.uppercase)
                                    .kerning(1.4)
                                    .padding(.horizontal, DharmaSpacing.lg)

                                if isTodayLoading {
                                    DharmaSkeletonCard(height: 100)
                                        .padding(.horizontal, DharmaSpacing.lg)
                                } else {
                                    NavigationLink(destination: FestivalDetailView(festival: festival)) {
                                        FestivalTeaserCard(festival: festival)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, DharmaSpacing.lg)
                                }
                            }
                        }

                        // Continue reading / journey (restored)
                        JourneyCard()
                            .padding(.horizontal, DharmaSpacing.lg)

                        Spacer(minLength: DharmaSpacing.xxl)
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await store.refreshLibraryContent()
                    HapticManager.light()
                }

                if showCompletionOverlay {
                    ZStack {
                        Color.black.opacity(0.85)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showCompletionOverlay = false
                                }
                            }

                        VStack(spacing: 20) {
                            Text("ॐ")
                                .font(.system(size: 64, design: .serif))
                                .foregroundColor(Color.dharmaGold)

                            Text("Practice complete")
                                .font(.system(size: 28, weight: .regular, design: .serif))
                                .foregroundColor(.dharmaTextPrimary)

                            Text(formattedDateAndStreak)
                                .font(.system(size: 15))
                                .foregroundColor(Color.dharmaGold.opacity(0.7))

                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .frame(width: 11, height: 11)
                                        .foregroundColor(Color.dharmaGold)
                                }
                            }

                            VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                                Text(closingVerseText)
                                    .font(DharmaFont.verseTranslation(17))
                                    .italic()
                                    .foregroundColor(Color.dharmaTextPrimary.opacity(0.85))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(closingVerseSource)
                                    .font(DharmaFont.verseSource())
                                    .foregroundColor(Color.dharmaGold)
                            }
                            .saffronLeftBar()
                            .padding(14)
                            .background(Color.dharmaGold.opacity(0.08))
                            .cornerRadius(10)

                            Text("tap anywhere to continue")
                                .font(.system(size: 13))
                                .italic()
                                .foregroundColor(Color.dharmaGold.opacity(0.55))
                        }
                        .padding(32)
                        .multilineTextAlignment(.center)
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.dharmaGold)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .transparentNavigationBar()
            .dharmaBackground()
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                sadhana.checkAndResetIfNewDay()
                if sadhana.isFullyComplete {
                    hasShownCompletionToday = true
                }
                if !store.items.isEmpty {
                    isTodayLoading = false
                }
            }
            .onChange(of: store.items.count) { _, newCount in
                if newCount > 0 {
                    isTodayLoading = false
                }
            }
            .task {
                if store.items.isEmpty {
                    try? await Task.sleep(for: .milliseconds(400))
                }
                isTodayLoading = false
            }
            .onChange(of: sadhana.isFullyComplete) { _, newValue in
                if newValue && !hasShownCompletionToday {
                    hasShownCompletionToday = true
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showCompletionOverlay = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showCompletionOverlay = false
                        }
                    }
                }
            }
            .onChange(of: showCompletionOverlay) { _, newValue in
                if newValue {
                    let gitaVerses = store.items(for: .gita)
                    if !gitaVerses.isEmpty {
                        closingVerse = gitaVerses[Int.random(in: 0..<gitaVerses.count)]
                    } else {
                        closingVerse = nil
                    }
                }
            }
        }
    }

    private var sadhanaTitleText: String {
        switch sadhana.completedCount {
        case 0: return "Begin today’s practice"
        case 1: return "1 of 3 acts complete"
        case 2: return "2 of 3 acts complete"
        default: return "Practice complete"
        }
    }

    private var sadhanaTitleColor: Color {
        sadhana.completedCount >= 3 ? Color.dharmaGold : .dharmaTextPrimary
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

    private var sourceLine: String {
        if let goal = goalName {
            return "\(liveItem.source) · \(GoalsManager.shortName(for: goal))"
        }
        return liveItem.source
    }

    var body: some View {
        NavigationLink(destination: ScriptureDetailView(item: liveItem, store: store)) {
            VStack(alignment: .leading, spacing: DharmaSpacing.md) {
                HStack(alignment: .top) {
                    Text("VERSE OF THE DAY")
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .kerning(1.4)

                    Spacer()

                    Button {
                        store.toggleFavourite(liveItem)
                        HapticManager.light()
                    } label: {
                        Image(systemName: liveItem.isFavourite ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(liveItem.isFavourite ? .dharmaGold : .dharmaTextMuted)
                    }
                }

                VerseBody(
                    translation: liveItem.textEnglish,
                    source: sourceLine,
                    compact: true
                )
                .saffronLeftBar()
            }
            .padding(DharmaSpacing.lg)
            .glassCard(cornerRadius: DharmaRadius.lg)
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
        [.mantras].filter { store.lastReadItem(for: $0) != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Journey")
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaTextMuted)
                    .textCase(.uppercase)
                    .kerning(1.4)

                Spacer()

                NavigationLink(destination: ChapterListView()) {
                    Text("See all →")
                        .font(DharmaFont.body(15))
                        .foregroundColor(.dharmaGold)
                }
            }

            VStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                gitaJourneyBlock

                Divider().background(Color.dharmaDivider)
                upanishadJourneyBlock

                Divider().background(Color.dharmaDivider)
                rigVedaJourneyBlock

                ForEach(otherJourneyCategories, id: \.self) { category in
                    if let item = store.lastReadItem(for: category) {
                        Divider().background(Color.dharmaDivider)

                        otherCategoryJourneyBlock(category: category, item: item)
                    }
                }
            }
            .padding(DharmaSpacing.lg)
            .glassCard(cornerRadius: DharmaRadius.md)
        }
    }

    private var gitaJourneyBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bhagavad Gita")
                    .font(DharmaFont.heading(20))
                    .foregroundColor(.dharmaTextPrimary)

                Spacer()

                Text("\(store.readCount) / \(store.totalGitaVerses) verses")
                    .font(DharmaFont.caption())
                    .foregroundColor(.dharmaTextMuted)
            }

            ProgressView(value: progress)
                .tint(.dharmaGold)

            if let chapterInfo = store.lastReadChapterInfo {
                Text("Chapter \(chapterInfo.chapterNumber) · \(chapterInfo.nameTranslation)")
                    .font(DharmaFont.body(14))
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

    private var upanishadJourneyBlock: some View {
        let readCnt = store.readCount(for: .upanishads)
        let total = store.items(for: .upanishads).count
        let progress = total > 0 ? Double(readCnt) / Double(total) : 0.0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: ScriptureCategory.upanishads.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.categoryUpanishads)
                    Text("Upanishads")
                        .font(DharmaFont.heading(20))
                        .foregroundColor(.dharmaTextPrimary)
                }
                Spacer()
                Text("\(readCnt) / \(total) verses")
                    .font(DharmaFont.caption())
                    .foregroundColor(.dharmaTextMuted)
            }

            ProgressView(value: progress)
                .tint(.categoryUpanishads)

            if let lastItem = store.lastReadItem(for: .upanishads) {
                NavigationLink(destination: ScriptureDetailView(item: lastItem, store: store)) {
                    journeyActionRowLabel("Continue reading")
                }
                .buttonStyle(.plain)
            } else if let firstItem = store.items(for: .upanishads).first {
                NavigationLink(destination: ScriptureDetailView(item: firstItem, store: store)) {
                    journeyActionRowLabel("Start reading")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rigVedaJourneyBlock: some View {
        let readCnt = store.readCount(for: .rigVeda)
        let total = store.items(for: .rigVeda).count
        let progress = total > 0 ? Double(readCnt) / Double(total) : 0.0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: ScriptureCategory.rigVeda.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.categoryRigVeda)
                    Text("Rig Veda")
                        .font(DharmaFont.heading(20))
                        .foregroundColor(.dharmaTextPrimary)
                }
                Spacer()
                Text("\(readCnt) / \(total) hymns")
                    .font(DharmaFont.caption())
                    .foregroundColor(.dharmaTextMuted)
            }

            ProgressView(value: progress)
                .tint(.categoryRigVeda)

            if let lastItem = store.lastReadItem(for: .rigVeda) {
                NavigationLink(destination: ScriptureDetailView(item: lastItem, store: store)) {
                    journeyActionRowLabel("Continue reading")
                }
                .buttonStyle(.plain)
            } else if let firstItem = store.items(for: .rigVeda).first {
                NavigationLink(destination: ScriptureDetailView(item: firstItem, store: store)) {
                    journeyActionRowLabel("Start reading")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func otherCategoryJourneyBlock(category: ScriptureCategory, item: ScriptureItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(DharmaFont.heading(20))
                    .foregroundColor(.dharmaTextPrimary)
            }

            Text(item.title)
                .font(DharmaFont.body(14))
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
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.dharmaGold)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.dharmaGold)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, DharmaSpacing.md)
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
            VStack(spacing: 4) {
                Text(festival.date.formatted(.dateTime.month(.abbreviated)))
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(1.2)
                Text(festival.date.formatted(.dateTime.day()))
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.dharmaTextPrimary)
            }
            .frame(width: 56)

            Rectangle()
                .fill(Color.dharmaGold.opacity(0.3))
                .frame(width: 1)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 6) {
                Text(festival.name)
                    .font(DharmaFont.heading(17))
                    .foregroundColor(.dharmaTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(festival.shortDescription)
                    .font(DharmaFont.body(15))
                    .foregroundColor(.dharmaTextMuted)
                    .lineLimit(1)
            }

            Spacer()

            if !festival.isToday {
                Text("\(festival.daysUntil)\ndays")
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaGold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.dharmaGold.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(DharmaSpacing.lg)
        .glassCard(cornerRadius: DharmaRadius.md)
    }
}

// MARK: - Quick Access Grid
struct QuickAccessGrid: View {
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Browse")
                .font(DharmaFont.caption(13))
                .foregroundColor(.dharmaTextMuted)
                .textCase(.uppercase)
                .kerning(1.4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 26))
                .foregroundColor(category.color)

            Text(category.rawValue)
                .font(DharmaFont.heading(17))
                .foregroundColor(.dharmaTextPrimary)
                .lineLimit(1)

            Text(category.description)
                .font(DharmaFont.caption(13))
                .foregroundColor(.dharmaTextMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DharmaSpacing.lg)
        .glassCard(cornerRadius: DharmaRadius.md)
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
        .scrollContentBackground(.hidden)
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .dharmaBackground()
    }
}

// MARK: - Krishna Today Hero Card

struct KrishnaTodayHeroCard: View {
    let dailyVerse: ScriptureItem?
    let userName: String
    let message: String
    let isSadhanaComplete: Bool
    var onSpeakWithKrishna: () -> Void
    var onOpenSadhana: () -> Void
    var onOpenLibrary: () -> Void

    @EnvironmentObject private var store: ScriptureStore
    @ObservedObject private var sadhana = SadhanaManager.shared

    private var ctaLabel: String {
        isSadhanaComplete ? "Continue with Krishna →" : "Speak with Krishna →"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.dharmaGold.opacity(0.35), lineWidth: 1)
                        .frame(width: 52, height: 52)
                    Circle()
                        .fill(Color.dharmaGold.opacity(0.10))
                        .frame(width: 40, height: 40)
                    Text("ॐ")
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundColor(.dharmaGold)
                }

                Text("Krishna")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(Color.dharmaGold.opacity(0.85))

                if isSadhanaComplete {
                    Text("· साधु")
                        .font(DharmaFont.caption())
                        .foregroundColor(Color.dharmaGold.opacity(0.45))
                }

                Spacer(minLength: 0)
            }

            Text(message)
                .font(.system(size: 34, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(.dharmaTextPrimary)
                .lineSpacing(12)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if !isSadhanaComplete, let verse = dailyVerse {
                NavigationLink(destination: ScriptureDetailView(item: verse, store: store)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verse.textEnglish)
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(.dharmaTextSecondary)
                            .lineSpacing(5)
                            .lineLimit(2)

                        Text(verse.source)
                            .font(DharmaFont.caption())
                            .foregroundColor(Color.dharmaGold.opacity(0.75))

                        Text("tap to read")
                            .font(.system(size: 12))
                            .italic()
                            .foregroundColor(.dharmaTextMuted)
                    }
                    .saffronLeftBar()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            Button {
                onSpeakWithKrishna()
            } label: {
                Text(ctaLabel)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color(hex: "C9821E"))
                    .foregroundColor(Color(hex: "2A1A00"))
                    .cornerRadius(13)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button {
                    onOpenSadhana()
                } label: {
                    Text("Sadhana")
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.dharmaGold.opacity(0.08))
                        .foregroundColor(Color.dharmaGold)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.dharmaGold.opacity(0.2), lineWidth: 0.5)
                        )
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)

                Button {
                    onOpenLibrary()
                } label: {
                    Text("Library")
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.dharmaGold.opacity(0.08))
                        .foregroundColor(Color.dharmaGold)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color.dharmaGold.opacity(0.2), lineWidth: 0.5)
                        )
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }
            .font(DharmaFont.caption())
        }
        .padding(.vertical, DharmaSpacing.md)
    }
}

#Preview {
    TodayView()
        .environmentObject(ScriptureStore())
}
