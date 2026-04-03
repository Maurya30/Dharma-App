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
                            .font(.system(size: 22))
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
                .font(.system(size: 11))
                .foregroundColor(.dharmaGold)

            Text("Day \(dayIndex + 1)")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(.dharmaTextPrimary)

            Text(day.verseText)
                .font(DharmaFont.georgia(15))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(5)

            Text(day.verseReference)
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaGold)
                .italic()

            Divider()
                .background(Color.dharmaGold.opacity(0.3))

            if let entry = journalEntry {
                Text("Your reflection")
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(entry.noteText)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .lineSpacing(4)

                if !entry.krishnaResponse.isEmpty {
                    Divider()
                        .background(Color.dharmaGold.opacity(0.3))
                    HStack(alignment: .top, spacing: 6) {
                        Text("✦")
                            .font(.system(size: 12))
                            .foregroundColor(.dharmaGold)
                        Text(entry.krishnaResponse)
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundColor(.dharmaTextPrimary)
                            .lineSpacing(4)
                    }
                }
            } else {
                Text("No reflection recorded for this day")
                    .font(DharmaFont.body(14))
                    .foregroundColor(.dharmaTextMuted)
            }
        }
        .padding(DharmaSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: DharmaRadius.md)
    }
}
