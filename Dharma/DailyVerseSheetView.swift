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
                            .font(.system(size: 22))
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
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .tracking(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "C9821E"))
                    Text("Level \(liveLevel.levelNumber) — \(liveLevel.levelName)")
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaGold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
                HStack(alignment: .top, spacing: 8) {
                    Text("✦")
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaGold)
                    Text(krishnaReflectionResponse)
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundColor(.dharmaTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if dayAlreadyDone {
                Text("Come back tomorrow")
                    .font(DharmaFont.heading(15))
                    .foregroundColor(.dharmaTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
                                .font(DharmaFont.heading(16))
                                .foregroundColor(.white.opacity(0.9))
                                .transition(.opacity)
                        } else {
                            Text("Mark complete")
                                .font(DharmaFont.heading(16))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .disabled(showMarkSuccess || !reflectionNonEmpty)
            }
        }
        .padding(DharmaSpacing.md)
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
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(Color.dharmaGold)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                Text(displayDay.verseReference.uppercased())
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .tracking(0.8)
                Rectangle()
                    .fill(Color.dharmaDivider)
                    .frame(height: 1)
                if !sanskritTrimmed.isEmpty {
                    Text(sanskritTrimmed)
                        .font(DharmaFont.sanskrit(15))
                        .italic()
                        .foregroundColor(.dharmaTextPrimary.opacity(0.65))
                        .lineLimit(5)
                }
                Text(displayDay.verseText)
                    .font(DharmaFont.title(18))
                    .foregroundColor(.dharmaTextPrimary)
                    .lineSpacing(5)
            }
            .padding(.leading, DharmaSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DharmaSpacing.md)
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
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaGold)
                .tracking(0.8)
            Text(displayDay.krishnaContext)
                .font(DharmaFont.georgia(15))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(4)
        }
        .padding(DharmaSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dharmaGold.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaGold.opacity(0.2), lineWidth: 1)
        )
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            Text("TODAY'S QUESTION")
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaGold)
                .tracking(0.8)
            Text(displayDay.reflectionPrompt)
                .font(DharmaFont.georgia(16))
                .italic()
                .foregroundColor(.dharmaTextPrimary)

            ZStack(alignment: .topLeading) {
                if reflection.isEmpty && !editorFocused {
                    Text("Write a few lines in your own words…")
                        .font(DharmaFont.body(16))
                        .foregroundColor(.dharmaTextMuted)
                        .padding(.leading, 4)
                        .padding(.top, 10)
                }
                TextEditor(text: $reflection)
                    .font(DharmaFont.body(16))
                    .foregroundColor(.dharmaTextPrimary)
                    .frame(minHeight: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($editorFocused)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.dharmaGold.opacity(0.5), lineWidth: 0.5)
            )
        }
    }
}
