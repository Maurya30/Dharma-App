import SwiftUI

struct JourneyView: View {
    @EnvironmentObject var store: ScriptureStore
    @EnvironmentObject var goalsManager: GoalsManager
    @EnvironmentObject var streakManager: StreakManager
    @ObservedObject private var journalStore = JournalStore.shared
    @State private var exploreFurther: [RelatedVerse] = []
    @State private var showingGoalEditor = false
    @State private var showingStreakDetail = false
    @State private var showingReadingHistory = false
    @State private var stackExpanded = false
    @State private var showingEntryDetail = false
    @State private var selectedEntry: JournalEntry? = nil
    @State private var showingAllReflectionsSheet = false
    @State private var exploreFallbackItems: [ScriptureItem] = []
    @ObservedObject private var goalPathManager = GoalPathManager.shared
    @State private var presentedGoalPathMapGoalId: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your spiritual practice")
                            .font(DharmaFont.body(14))
                            .foregroundColor(.dharmaTextMuted)
                    }
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.top, DharmaSpacing.sm)

                    // Stats Row
                    statsRow
                        .padding(.horizontal, DharmaSpacing.md)

                    // Milestone Banner
                    if let milestone = streakManager.pendingMilestone {
                        milestoneBanner(milestone)
                            .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Weekly Insight Card
                    if !streakManager.weeklyInsight.isEmpty || streakManager.isLoadingInsight {
                        weeklyInsightCard
                            .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Section 1 — Goals
                    goalsSection
                        .padding(.horizontal, DharmaSpacing.md)

                    // Section 2 — Reflections
                    reflectionsSection
                        .padding(.horizontal, DharmaSpacing.md)

                    // Section 3 — Explore Further
                    if !journalStore.entries.isEmpty {
                        exploreFurtherSection
                            .padding(.horizontal, DharmaSpacing.md)
                    }

                    Spacer(minLength: DharmaSpacing.xxl)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationDestination(isPresented: $showingEntryDetail) {
                if let entry = selectedEntry,
                   let item = store.items.first(where: { $0.id.uuidString == entry.verseId }) {
                    ScriptureDetailView(item: item, openJournalOnAppear: true, store: store)
                }
            }
            .refreshable {
                await store.refreshLibraryContent()
                await loadExploreFurther()
                DharmaHaptics.light()
            }
            .navigationTitle("My Journey")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadExploreFurther() }
            .task { await streakManager.generateWeeklyInsight(journalEntries: journalStore.entries, goals: goalsManager.selectedGoals) }
            .onChange(of: journalStore.entries.count) { _, _ in
                Task { await loadExploreFurther() }
            }
            .transparentNavigationBar()
            .dharmaBackground()
            .sheet(isPresented: $showingStreakDetail) {
                StreakDetailSheet()
            }
            .sheet(isPresented: $showingReadingHistory) {
                ReadingHistorySheet(store: store)
            }
            .fullScreenCover(isPresented: $showingGoalEditor) {
                GoalEditorView()
                    .environmentObject(goalsManager)
            }
            .sheet(isPresented: $showingAllReflectionsSheet) {
                NavigationStack {
                    AllReflectionsView()
                        .environmentObject(store)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { presentedGoalPathMapGoalId != nil },
                set: { if !$0 { presentedGoalPathMapGoalId = nil } }
            )) {
                if let gid = presentedGoalPathMapGoalId {
                    GoalPathMapView(goalId: gid)
                }
            }
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            HStack {
                Text("Your Goals")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(0.8)
                Spacer()
                Button(action: { showingGoalEditor = true }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color(hex: "C9821E"))
                        .font(.system(size: 18))
                }
            }

            if goalsManager.selectedGoals.isEmpty {
                goalsEmptyState
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(goalsManager.selectedGoals, id: \.self) { goal in
                        Button {
                            goalPathManager.syncPaths(with: goalsManager.selectedGoals)
                            guard goalPathManager.pathForGoal(goal) != nil else { return }
                            HapticManager.medium()
                            presentedGoalPathMapGoalId = goal
                        } label: {
                            goalRingCard(goal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var goalsEmptyState: some View {
        VStack(spacing: DharmaSpacing.md) {
            WarmEmptyState(
                icon: "hands.sparkles",
                title: "Shape your path",
                message: "Choose a few intentions that echo what you’re seeking right now — we’ll highlight verses and moments that resonate.",
                hint: "You can change these anytime from onboarding."
            )
            Button {
                DharmaHaptics.medium()
                goalsManager.resetGoals()
            } label: {
                Text("Choose goals")
                    .font(DharmaFont.heading(14))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.lg)
    }

    private func goalRingCard(_ goal: String) -> some View {
        let verseCount = versesForGoal(goal)
        let readCount = readVersesForGoal(goal)
        let progress = verseCount > 0 ? CGFloat(readCount) / CGFloat(verseCount) : 0.0
        let path = goalPathManager.pathForGoal(goal)
        let levelCaption: String? = {
            guard let p = path, p.currentLevelIndex < p.levels.count, p.currentLevelIndex >= 0 else { return nil }
            return p.levels[p.currentLevelIndex].levelName
        }()
        let dimForTodayDone = shouldDimGoalRing(path: path)

        return VStack(spacing: DharmaSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "C9821E").opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "C9821E"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
            }
            .frame(width: 54, height: 54)

            Text(GoalsManager.shortName(for: goal))
                .font(.custom("Georgia-Bold", size: 17))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let levelCaption {
                Text(levelCaption)
                    .font(DharmaFont.georgia(13))
                    .foregroundColor(.dharmaTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Text("\(readCount) of \(verseCount)")
                .font(DharmaFont.georgia(13))
                .foregroundColor(.dharmaTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .opacity(dimForTodayDone ? 0.5 : 1.0)
    }

    private func shouldDimGoalRing(path: GoalPath?) -> Bool {
        guard let path else { return false }
        if path.levels.allSatisfy(\.isComplete) { return false }
        return goalPathManager.todaysDayIndex(for: path) == nil
    }

    private func versesForGoal(_ goal: String) -> Int {
        let ids = GoalTagsLoader.shared.verseIds(matching: [goal])
        return ids.count
    }

    private func readVersesForGoal(_ goal: String) -> Int {
        let goalVerseIds = GoalTagsLoader.shared.verseIds(matching: [goal])
        return store.items.filter { item in
            guard let bid = GoalTagsLoader.backendId(for: item) else { return false }
            guard goalVerseIds.contains(bid) else { return false }
            if item.category == .gita {
                let ref = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "")
                return store.readVerseIDs.contains(ref)
            } else {
                return store.readVerseIDs.contains(item.id.uuidString)
            }
        }.count
    }

    // MARK: - Reflections Section

    private var reflectionsSection: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            HStack {
                Text("Your Reflections")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(0.8)

                Spacer()

                if stackExpanded && !journalStore.entries.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            stackExpanded = false
                        }
                    }) {
                        Text("Collapse")
                            .font(DharmaFont.caption(11))
                            .foregroundColor(.dharmaTextMuted)
                    }
                }
            }

            if journalStore.entries.isEmpty {
                reflectionsEmptyState
            } else {
                reflectionStack
            }
        }
    }

    private var topReflections: [JournalEntry] {
        Array(journalStore.entries.prefix(3))
    }

    private var reflectionStack: some View {
        Group {
            if stackExpanded {
                expandedReflectionsBlock
            } else {
                collapsedReflectionStack
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: stackExpanded)
    }

    private var collapsedReflectionStack: some View {
        let entries = topReflections
        let stackDepth = entries.count

        return ZStack(alignment: .topLeading) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                reflectionCard(entry, isCollapsedStack: true, showDelete: false)
                    .offset(x: CGFloat(index) * 5, y: CGFloat(index) * 11)
                    .scaleEffect(1.0 - CGFloat(index) * 0.045)
                    .rotationEffect(.degrees(Double(index) * -1.2))
                    .shadow(color: index == 0 ? Color.black.opacity(0.12) : .clear, radius: index == 0 ? 10 : 0, y: index == 0 ? 4 : 0)
                    .zIndex(Double(stackDepth - index))
            }

            if journalStore.entries.count > 3 {
                VStack {
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        Text("+\(journalStore.entries.count - 3) more")
                            .font(DharmaFont.caption(11))
                            .fontWeight(.semibold)
                            .foregroundColor(.dharmaTextPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dharmaSurface.opacity(0.95))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: CGFloat(118 + min(stackDepth - 1, 2) * 11))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                stackExpanded = true
            }
        }
    }

    private var expandedReflectionsBlock: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            ForEach(topReflections) { entry in
                ZStack(alignment: .topTrailing) {
                    reflectionCard(entry, isCollapsedStack: false, showDelete: false)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DharmaHaptics.selection()
                            selectedEntry = entry
                            showingEntryDetail = true
                        }

                    Button(action: { journalStore.delete(entry: entry) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.dharmaTextSecondary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
            }

            if journalStore.entries.count > 3 {
                Button {
                    DharmaHaptics.light()
                    showingAllReflectionsSheet = true
                } label: {
                    HStack {
                        Text("View all \(journalStore.entries.count) reflections")
                            .font(DharmaFont.heading(14))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.dharmaGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DharmaSpacing.sm)
                    .background(Color.dharmaGold.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var reflectionsEmptyState: some View {
        WarmEmptyState(
            icon: "flame",
            title: "A gentle beginning",
            message: "When a verse stays with you, pause and reflect — your words become part of your journey here.",
            hint: "Open any verse and tap Reflect on this verse."
        )
        .frame(maxWidth: .infinity)
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.lg)
    }

    private func reflectionCard(_ entry: JournalEntry, isCollapsedStack: Bool, showDelete: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            HStack(spacing: 8) {
                Text(entry.verseSource)
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())

                if entry.spokenWithKrishna {
                    Text("Spoke with Krishna")
                        .font(DharmaFont.caption(9))
                        .foregroundColor(.dharmaGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dharmaGold.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                if !isCollapsedStack && showDelete {
                    Button(action: { journalStore.delete(entry: entry) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.dharmaTextSecondary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(String(entry.verseEnglish.prefix(isCollapsedStack ? 56 : entry.verseEnglish.count)) + (isCollapsedStack && entry.verseEnglish.count > 56 ? "…" : ""))
                .font(DharmaFont.georgia(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(4)
                .lineLimit(isCollapsedStack ? 1 : nil)
                .fixedSize(horizontal: false, vertical: !isCollapsedStack)

            Divider().background(Color.dharmaDivider)

            Text(String(entry.noteText.prefix(isCollapsedStack ? 48 : entry.noteText.count)) + (isCollapsedStack && entry.noteText.count > 48 ? "…" : ""))
                .font(DharmaFont.body(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(4)
                .lineLimit(isCollapsedStack ? 1 : nil)
                .fixedSize(horizontal: false, vertical: !isCollapsedStack)

            HStack {
                Spacer()
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaTextMuted)
            }
        }
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    // MARK: - Explore Further Section

    private var exploreFurtherSection: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Explore Further")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(0.8)

                Text("Based on your reflections")
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
            }

            if !exploreFurther.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(exploreFurther.prefix(3))) { rv in
                            exploreCard(rv)
                        }
                    }
                }
            } else if !exploreFallbackItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(exploreFallbackItems.prefix(3))) { item in
                            exploreLibraryStyleCard(item)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(store.items.prefix(3))) { item in
                            exploreLibraryStyleCard(item)
                        }
                    }
                }
            }
        }
    }

    private func exploreLibraryStyleCard(_ item: ScriptureItem) -> some View {
        NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
            ScriptureCardView(item: item)
                .frame(width: 260, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func exploreCard(_ rv: RelatedVerse) -> some View {
        let matched = store.items.first {
            $0.textEnglish.hasPrefix(String(rv.english.prefix(40)))
        }

        return Group {
            if let item = matched {
                NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                    exploreCardContent(rv)
                }
                .buttonStyle(.plain)
            } else {
                exploreCardContent(rv)
            }
        }
    }

    private func exploreCardContent(_ rv: RelatedVerse) -> some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            Text(rv.categoryBadge)
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.dharmaGold.opacity(0.12))
                .clipShape(Capsule())

            Text(rv.truncatedEnglish)
                .font(DharmaFont.georgia(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(5)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(rv.id)
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaTextMuted)
        }
        .padding(DharmaSpacing.md)
        .frame(width: 200, alignment: .topLeading)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: DharmaSpacing.sm) {
            Button {
                DharmaHaptics.selection()
                showingStreakDetail = true
            } label: {
                statCard(value: "\(streakManager.currentStreak)", label: "Day Streak", icon: "flame.fill", color: .dharmaGold)
            }
            .buttonStyle(.plain)

            Button {
                DharmaHaptics.selection()
                showingReadingHistory = true
            } label: {
                statCard(value: "\(streakManager.totalVersesRead)", label: "Verses Read", icon: "book.closed.fill", color: .dharmaGold)
            }
            .buttonStyle(.plain)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.custom("Georgia-Bold", size: 20))
                .foregroundColor(.dharmaTextPrimary)
            Text(label)
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    // MARK: - Milestone Banner

    @ViewBuilder
    private func milestoneBanner(_ milestone: DharmaMilestoneItem) -> some View {
        VStack(spacing: DharmaSpacing.sm) {
            Image(systemName: milestone.isLotus ? "seal.fill" : "flame.fill")
                .font(.system(size: milestone.isLotus ? 32 : 24))
                .foregroundColor(.dharmaGold)

            Text(milestone.label)
                .font(.custom("Georgia-Bold", size: milestone.isLotus ? 20 : 17))
                .foregroundColor(.dharmaTextPrimary)

            Text("A sacred milestone on your path")
                .font(DharmaFont.georgia(13))
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)

            Button(action: { streakManager.acknowledgeMilestone(milestone) }) {
                Text("Continue the journey")
                    .font(DharmaFont.heading(14))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DharmaSpacing.lg)
        .glassCard(cornerRadius: DharmaRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                .strokeBorder(Color.dharmaGold.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Weekly Insight Card

    private var weeklyInsightCard: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(Color.dharmaGold)
                .frame(width: 2)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(.dharmaGold)
                    Text("Weekly Insight")
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .kerning(0.8)
                }

                if streakManager.isLoadingInsight {
                    ProgressView()
                        .tint(.dharmaGold)
                        .padding(.vertical, DharmaSpacing.sm)
                } else {
                    Text(streakManager.weeklyInsight)
                        .font(DharmaFont.georgia(14))
                        .foregroundColor(.dharmaTextBody)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, DharmaSpacing.md)
        }
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    // MARK: - Load

    private func loadExploreFurther() async {
        guard let latest = journalStore.entries.first else {
            exploreFurther = []
            exploreFallbackItems = []
            return
        }
        let reflected = Set(journalStore.entries.map(\.verseId))

        let results: [RelatedVerse]
        if let backendId = GoalTagsLoader.backendId(
            for: ScriptureItem(
                category: .gita,
                title: "",
                subtitle: latest.verseReference,
                textEnglish: latest.verseEnglish,
                source: latest.verseSource
            )
        ) {
            results = await RelatedVersesService.shared.fetchRelated(verseId: backendId)
        } else {
            let bid = latest.verseId
            results = await RelatedVersesService.shared.fetchRelated(verseId: bid)
        }

        let filtered = results.filter { !reflected.contains($0.id) }
        exploreFurther = Array(filtered.prefix(3))

        if exploreFurther.isEmpty {
            let candidates = store.items.filter { !reflected.contains($0.id.uuidString) }
            exploreFallbackItems = Array(candidates.prefix(3))
        } else {
            exploreFallbackItems = []
        }
    }
}
