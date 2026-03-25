import SwiftUI

struct JourneyView: View {
    @EnvironmentObject var store: ScriptureStore
    @EnvironmentObject var goalsManager: GoalsManager
    @ObservedObject private var journalStore = JournalStore.shared
    @State private var exploreFurther: [RelatedVerse] = []
    @State private var showingGoalEditor = false

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
            .refreshable {
                await store.refreshLibraryContent()
                await loadExploreFurther()
                DharmaHaptics.light()
            }
            .navigationTitle("My Journey")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadExploreFurther() }
            .transparentNavigationBar()
            .dharmaBackground()
            .fullScreenCover(isPresented: $showingGoalEditor) {
                GoalEditorView()
                    .environmentObject(goalsManager)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(goalsManager.selectedGoals, id: \.self) { goal in
                            goalCard(goal)
                        }
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

    private func goalCard(_ goal: String) -> some View {
        let section = GoalsManager.allGoals.first { $0.name == goal }?.section ?? ""
        let verseCount = versesForGoal(goal)
        let notesCount = journalStore.entriesForGoal(goal).count

        return VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            Text(GoalsManager.shortName(for: goal))
                .font(.custom("Georgia-Bold", size: 14))
                .foregroundColor(.dharmaTextPrimary)
                .lineLimit(2)

            Text(section)
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaTextMuted)

            Spacer()

            HStack(spacing: DharmaSpacing.md) {
                Label("\(verseCount)", systemImage: "book.closed")
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaTextMuted)
                Label("\(notesCount)", systemImage: "square.and.pencil")
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaTextMuted)
            }
        }
        .padding(DharmaSpacing.md)
        .frame(width: 160, height: 120, alignment: .topLeading)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    private func versesForGoal(_ goal: String) -> Int {
        let ids = GoalTagsLoader.shared.verseIds(matching: [goal])
        return ids.count
    }

    // MARK: - Reflections Section

    private var reflectionsSection: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            Text("Your Reflections")
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaGold)
                .textCase(.uppercase)
                .kerning(0.8)

            if journalStore.entries.isEmpty {
                reflectionsEmptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(journalStore.entries.prefix(4)) { entry in
                        if let item = store.items.first(where: { $0.id.uuidString == entry.verseId }) {
                            NavigationLink(destination: ScriptureDetailView(item: item, openJournalOnAppear: true, store: store)) {
                                reflectionCard(entry)
                            }
                            .buttonStyle(.plain)
                        } else {
                            reflectionCard(entry)
                        }
                    }
                }

                if journalStore.entries.count > 4 {
                    NavigationLink(destination: AllReflectionsView()) {
                        Text("See all reflections →")
                            .font(DharmaFont.caption(13))
                            .foregroundColor(.dharmaGold)
                    }
                    .padding(.top, DharmaSpacing.xs)
                }
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

    private func reflectionCard(_ entry: JournalEntry) -> some View {
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

                Button(action: { journalStore.delete(entry: entry) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaTextSecondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            Text(String(entry.verseEnglish.prefix(80)) + (entry.verseEnglish.count > 80 ? "…" : ""))
                .font(DharmaFont.georgia(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(4)
                .lineLimit(2)

            Divider().background(Color.dharmaDivider)

            Text(String(entry.noteText.prefix(100)) + (entry.noteText.count > 100 ? "…" : ""))
                .font(DharmaFont.body(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(4)
                .lineLimit(3)

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
                        ForEach(exploreFurther) { rv in
                            exploreCard(rv)
                        }
                    }
                }
            }
        }
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

    // MARK: - Load

    private func loadExploreFurther() async {
        guard let latest = journalStore.entries.first else { return }
        let reflected = Set(journalStore.entries.map(\.verseId))

        if let backendId = GoalTagsLoader.backendId(
            for: ScriptureItem(
                category: .gita,
                title: "",
                subtitle: latest.verseReference,
                textEnglish: latest.verseEnglish,
                source: latest.verseSource
            )
        ) {
            let results = await RelatedVersesService.shared.fetchRelated(verseId: backendId)
            exploreFurther = results.filter { !reflected.contains($0.id) }
        } else {
            let bid = latest.verseId
            let results = await RelatedVersesService.shared.fetchRelated(verseId: bid)
            exploreFurther = results.filter { !reflected.contains($0.id) }
        }
    }
}
