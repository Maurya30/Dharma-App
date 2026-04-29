import SwiftUI

/// Read-only sheet listing each completed day in a finished level (verse + optional journal).
struct GoalCompletedLevelSheet: View {
    let goalId: String
    let level: PathLevel

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var journalStore = JournalStore.shared

    private var sortedCompletedIndices: [Int] {
        level.completedDayIndices.sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                    ForEach(sortedCompletedIndices, id: \.self) { dayIdx in
                        if dayIdx < level.days.count {
                            GoalDayDetailSection(
                                goalId: goalId,
                                level: level,
                                day: level.days[dayIdx],
                                dayIndex: dayIdx,
                                journalStore: journalStore
                            )
                        }
                    }
                }
                .padding(DharmaSpacing.md)
                .padding(.bottom, DharmaSpacing.xl)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Level \(level.levelNumber)")
            .navigationBarTitleDisplayMode(.inline)
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
                }
            }
            .transparentNavigationBar()
            .dharmaBackground()
        }
    }
}

private struct GoalDayDetailSection: View {
    let goalId: String
    let level: PathLevel
    let day: PathDay
    let dayIndex: Int
    @ObservedObject var journalStore: JournalStore

    private var journalEntry: JournalEntry? {
        journalStore.entries.first { $0.goalContext == goalId && $0.verseId == day.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            Text("\(GoalsManager.shortName(for: goalId)) · \(level.levelName)")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.4)
                .foregroundColor(.dharmaGold)

            Text("Day \(dayIndex + 1)")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(.dharmaTextPrimary)

            VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                Text(day.verseText)
                    .font(DharmaFont.verseTranslation(19))
                    .foregroundColor(.dharmaTextBody)
                    .lineSpacing(6)

                Text(day.verseReference)
                    .font(DharmaFont.verseSource(14))
                    .foregroundColor(.dharmaGold)
                    .italic()
            }
            .saffronLeftBar()

            Divider()
                .background(Color.dharmaGold.opacity(0.3))

            if let entry = journalEntry {
                Text("Your reflection")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.4)
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)

                Text(entry.noteText)
                    .font(.system(size: 17, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .lineSpacing(5)

                if !entry.krishnaResponse.isEmpty {
                    Divider()
                        .background(Color.dharmaGold.opacity(0.3))
                    HStack(alignment: .top, spacing: 8) {
                        Text("✦")
                            .font(.system(size: 16))
                            .foregroundColor(.dharmaGold)
                        Text(entry.krishnaResponse)
                            .font(.system(size: 16, design: .serif))
                            .italic()
                            .foregroundColor(.dharmaTextPrimary)
                            .lineSpacing(5)
                    }
                }
            } else {
                Text("No reflection recorded for this day")
                    .font(DharmaFont.body(16))
                    .foregroundColor(.dharmaTextMuted)
            }
        }
        .padding(DharmaSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: DharmaRadius.md)
    }
}
