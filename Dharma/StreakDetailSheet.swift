import SwiftUI

struct StreakDetailSheet: View {
    @ObservedObject private var streakManager = StreakManager.shared

    private let cal = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: DharmaSpacing.lg) {

                // Drag indicator
                Capsule()
                    .fill(Color.dharmaTextMuted.opacity(0.35))
                    .frame(width: 36, height: 4)
                    .padding(.top, DharmaSpacing.sm)

                // Current streak hero
                VStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.dharmaGold)

                    Text("\(streakManager.currentStreak)")
                        .font(.custom("Georgia-Bold", size: 64))
                        .foregroundColor(.dharmaGold)
                        .lineLimit(1)

                    Text("Day Streak")
                        .font(DharmaFont.body(17))
                        .foregroundColor(.dharmaTextPrimary)

                    Text("Longest: \(streakManager.longestStreak) days")
                        .font(DharmaFont.caption(13))
                        .foregroundColor(.dharmaTextMuted)
                        .padding(.top, 2)
                }
                .padding(.top, DharmaSpacing.sm)

                // Monthly calendar
                VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                    Text(monthTitle)
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .kerning(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Weekday headers
                    HStack(spacing: 0) {
                        ForEach(Array(["M","T","W","T","F","S","S"].enumerated()), id: \.offset) { _, d in
                            Text(d)
                                .font(DharmaFont.caption(11))
                                .foregroundColor(.dharmaTextMuted)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Day cells
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                        spacing: 6
                    ) {
                        ForEach(Array(calendarCells.enumerated()), id: \.offset) { _, day in
                            if day == 0 {
                                Color.clear.frame(height: 32)
                            } else {
                                let isActive = streakManager.activeDaysThisMonth.contains(day)
                                ZStack {
                                    Circle()
                                        .fill(isActive ? Color.dharmaGold : Color.dharmaGold.opacity(0.08))
                                        .frame(width: 30, height: 30)
                                    Text("\(day)")
                                        .font(DharmaFont.caption(isActive ? 12 : 11))
                                        .foregroundColor(isActive ? .white : .dharmaTextMuted)
                                }
                                .frame(height: 32)
                            }
                        }
                    }
                }
                .padding(DharmaSpacing.md)
                .glassCard(cornerRadius: DharmaRadius.md)
                .padding(.horizontal, DharmaSpacing.md)

                // Streak Shield
                HStack(alignment: .top, spacing: DharmaSpacing.md) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.dharmaGold)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Streak Shield")
                            .font(DharmaFont.caption(11))
                            .foregroundColor(.dharmaGold)
                            .textCase(.uppercase)
                            .kerning(0.8)

                        Text(shieldMessage)
                            .font(DharmaFont.georgia(14))
                            .foregroundColor(.dharmaTextBody)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(DharmaSpacing.md)
                .glassCard(cornerRadius: DharmaRadius.md)
                .padding(.horizontal, DharmaSpacing.md)

                Spacer(minLength: DharmaSpacing.xxl)
            }
        }
        .scrollContentBackground(.hidden)
        .dharmaBackground()
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    private var calendarCells: [Int] {
        let today = Date()
        let comps = cal.dateComponents([.year, .month], from: today)
        let firstOfMonth = cal.date(from: comps)!
        let weekday = cal.component(.weekday, from: firstOfMonth) // 1=Sun…7=Sat
        let offset = (weekday == 1) ? 6 : weekday - 2            // 0=Mon…6=Sun
        let daysInMonth = cal.range(of: .day, in: .month, for: today)!.count

        var cells = Array(repeating: 0, count: offset)
        cells += Array(1...daysInMonth)
        let remainder = cells.count % 7
        if remainder != 0 {
            cells += Array(repeating: 0, count: 7 - remainder)
        }
        return cells
    }

    private var shieldMessage: String {
        streakManager.shieldAvailable
            ? "Shield ready — one missed day this week is forgiven."
            : "Your shield protected your streak"
    }
}
