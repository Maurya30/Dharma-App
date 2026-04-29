import SwiftUI

struct DailyVerseSheetView: View {
    let goalId: String
    let levelIndex: Int
    let dayIndex: Int
    let level: PathLevel
    let day: PathDay

    @ObservedObject private var pathManager = GoalPathManager.shared
    @ObservedObject private var journalStore = JournalStore.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var editorFocused: Bool

    @State private var reflection = ""
    @State private var showMarkSuccess = false
    @State private var krishnaReflectionResponse = ""
    @State private var showKrishnaReflection = false
    @State private var isLoadingKrishnaReflection = false
    var onLevelComplete: (() -> Void)?

    private var reflectionNonEmpty: Bool {
        !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var liveLevel: PathLevel {
        pathManager.pathForGoal(goalId)?.levels[levelIndex] ?? level
    }

    /// Prefer verse data from the live path so content appears if the manager updates after open.
    private var displayDay: PathDay {
        guard let p = pathManager.pathForGoal(goalId),
              p.levels.indices.contains(levelIndex),
              p.levels[levelIndex].days.indices.contains(dayIndex) else {
            return day
        }
        return p.levels[levelIndex].days[dayIndex]
    }

    private var dayAlreadyDone: Bool {
        liveLevel.completedDayIndices.contains(dayIndex)
    }

    private var isLoadingVerses: Bool {
        liveLevel.days.isEmpty
    }

    private var sanskritTrimmed: String {
        displayDay.sanskrit.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoadingVerses {
                    versesLoadingPlaceholder
                } else {
                    verseSheetScrollContent
                }

                if !isLoadingVerses {
                    bottomBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.dharmaGold)
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        editorFocused = false
                    }
                    .foregroundColor(.dharmaGold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .transparentNavigationBar()
            .dharmaBackground()
        }
        .interactiveDismissDisabled(true)
    }

    private var versesLoadingPlaceholder: some View {
        VStack(spacing: DharmaSpacing.lg) {
            ProgressView()
                .tint(Color.dharmaGold)
            Text("Loading verse…")
                .font(DharmaFont.body(15))
                .foregroundColor(.dharmaTextMuted)
            Text("Your path is still syncing.")
                .font(DharmaFont.caption(12))
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DharmaSpacing.xl)
    }

    private var verseSheetScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                Text(displayDay.verseReference.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.dharmaGold)
                    .tracking(1.4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "C9821E"))
                    Text("Level \(liveLevel.levelNumber) — \(liveLevel.levelName)")
                        .font(DharmaFont.caption().weight(.semibold))
                        .foregroundColor(.dharmaGold)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.dharmaGold.opacity(0.12))
                .clipShape(Capsule())

                verseCard

                krishnaBlock

                reflectionSection
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if isLoadingKrishnaReflection {
                ProgressView()
                    .tint(Color.dharmaGold)
            }

            if showKrishnaReflection && !krishnaReflectionResponse.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Text("✦")
                        .font(.system(size: 16))
                        .foregroundColor(.dharmaGold)
                    Text(krishnaReflectionResponse)
                        .font(.system(size: 17, design: .serif))
                        .italic()
                        .foregroundColor(.dharmaTextPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if dayAlreadyDone {
                Text("Come back tomorrow")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.dharmaTextMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.dharmaSurface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
            } else {
                Button {
                    guard !showMarkSuccess, reflectionNonEmpty else { return }
                    let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
                    let leveled = pathManager.markDayComplete(goalId: goalId, levelIndex: levelIndex, dayIndex: dayIndex)
                    if !trimmedReflection.isEmpty {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d"
                        let dateStr = formatter.string(from: Date())
                        let journalEntry = JournalEntry(
                            verseId: displayDay.id,
                            verseReference: displayDay.verseReference,
                            verseSource: displayDay.verseReference,
                            verseEnglish: displayDay.verseText,
                            noteText: trimmedReflection,
                            goalContext: goalId,
                            source: "goalPath",
                            sourceLabel: "\(goalId) · \(dateStr)"
                        )
                        JournalStore.shared.save(entry: journalEntry)
                    }
                    HapticManager.success()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showMarkSuccess = true
                    }
                    Task {
                        await loadKrishnaReflectionReply()
                    }
                    if leveled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onLevelComplete?()
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: DharmaRadius.md)
                            .fill(Color.dharmaGold)
                            .opacity(showMarkSuccess ? 0.4 : (reflectionNonEmpty ? 1 : 0.4))
                        if showMarkSuccess {
                            Text("Completed ✓")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .transition(.opacity)
                        } else {
                            Text("Mark complete")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .disabled(showMarkSuccess || !reflectionNonEmpty)
            }
        }
        .padding(DharmaSpacing.lg)
        .background(.ultraThinMaterial)
    }

    private func loadKrishnaReflectionReply() async {
        await MainActor.run { isLoadingKrishnaReflection = true }
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        let verseId = displayDay.id
        let msg = "The seeker on the path of \(goalId) reflects: '\(trimmed)'. Respond in exactly one sentence as Krishna. Warm, brief, no questions."
        do {
            let text = try await KrishnaService.shared.fetchOneShotResponse(message: msg)
            await MainActor.run {
                isLoadingKrishnaReflection = false
                krishnaReflectionResponse = text
                withAnimation(.easeInOut(duration: 0.5)) {
                    showKrishnaReflection = true
                }
                if var existing = journalStore.entry(for: verseId) {
                    existing.krishnaResponse = text
                    journalStore.save(entry: existing)
                }
            }
        } catch {
            await MainActor.run {
                isLoadingKrishnaReflection = false
            }
        }
    }

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            Text(displayDay.verseReference.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.dharmaGold)
                .tracking(1.4)
            Rectangle()
                .fill(Color.dharmaDivider)
                .frame(height: 1)
            VerseBody(
                sanskrit: sanskritTrimmed.isEmpty ? nil : sanskritTrimmed,
                translation: displayDay.verseText,
                source: nil
            )
        }
        .saffronLeftBar()
        .padding(DharmaSpacing.lg)
        .glassCard(cornerRadius: DharmaRadius.md)
        .overlay(alignment: .bottomTrailing) {
            Text("ॐ")
                .font(.system(size: 60))
                .opacity(0.05)
                .foregroundColor(Color.dharmaGold)
                .padding(.trailing, 4)
                .padding(.bottom, 2)
        }
    }

    private var krishnaBlock: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            Text("✦ KRISHNA'S THOUGHT")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.dharmaGold)
                .tracking(1.4)
            Text(displayDay.krishnaContext)
                .font(DharmaFont.georgia(17))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DharmaSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dharmaGold.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaGold.opacity(0.2), lineWidth: 1)
        )
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            Text("TODAY'S QUESTION")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.dharmaGold)
                .tracking(1.4)
            Text(displayDay.reflectionPrompt)
                .font(DharmaFont.georgia())
                .italic()
                .foregroundColor(.dharmaTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .topLeading) {
                if reflection.isEmpty && !editorFocused {
                    Text("Write a few lines in your own words…")
                        .font(DharmaFont.body(17))
                        .foregroundColor(.dharmaTextMuted)
                        .padding(.leading, 4)
                        .padding(.top, 12)
                }
                TextEditor(text: $reflection)
                    .font(DharmaFont.body(17))
                    .foregroundColor(.dharmaTextPrimary)
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($editorFocused)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.dharmaGold.opacity(0.5), lineWidth: 0.5)
            )
        }
    }
}
