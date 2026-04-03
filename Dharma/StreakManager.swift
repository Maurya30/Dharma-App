import Foundation
import Combine

// MARK: - Milestone Definition

struct DharmaMilestoneItem: Equatable {
    let days: Int
    let label: String
    let isLotus: Bool
    let isMonthly: Bool
}

// MARK: - StreakManager

final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalVersesRead: Int = 0
    @Published var activeDaysThisWeek: Set<Int> = []    // 0 = Mon … 6 = Sun
    @Published var activeDaysThisMonth: Set<Int> = []   // 1 = 1st … 31 = 31st
    @Published var acknowledgedMilestones: Set<Int> = []
    @Published var pendingMilestone: DharmaMilestoneItem? = nil
    @Published var weeklyInsight: String = ""
    @Published var weeklyInsightDate: Date? = nil
    @Published var isLoadingInsight: Bool = false
    @Published var shieldAvailable: Bool = true

    private let streakKey           = "sm_streak"
    private let longestKey          = "sm_longest"
    private let totalVersesKey      = "sm_total_verses"
    private let lastPracticeKey     = "sm_last_practice"
    private let activeDaysKey       = "sm_active_days"
    private let weekStartKey        = "sm_week_start"
    private let activeDaysMonthKey  = "sm_active_days_month"
    private let monthStartKey       = "sm_month_start"
    private let acknowledgedKey     = "sm_acknowledged"
    private let insightTextKey      = "sm_insight_text"
    private let insightDateKey      = "sm_insight_date"
    private let shieldKey           = "sm_shield"

    // MARK: - Milestone catalogue

    static let milestones: [DharmaMilestoneItem] = [
        .init(days: 3,    label: "3 Days",                           isLotus: false, isMonthly: false),
        .init(days: 7,    label: "7 Days — A Full Week",             isLotus: false, isMonthly: false),
        .init(days: 14,   label: "14 Days",                          isLotus: false, isMonthly: false),
        .init(days: 21,   label: "21 Days — Three Weeks",            isLotus: false, isMonthly: false),
        .init(days: 30,   label: "One Month",                        isLotus: false, isMonthly: true),
        .init(days: 40,   label: "40 Days",                          isLotus: false, isMonthly: false),
        .init(days: 50,   label: "50 Days",                          isLotus: false, isMonthly: false),
        .init(days: 75,   label: "75 Days",                          isLotus: false, isMonthly: false),
        .init(days: 90,   label: "Three Months",                     isLotus: false, isMonthly: true),
        .init(days: 100,  label: "100 Days",                         isLotus: false, isMonthly: false),
        .init(days: 108,  label: "Sacred 108 — a full mala of days", isLotus: true,  isMonthly: false),
        .init(days: 180,  label: "Six Months",                       isLotus: false, isMonthly: true),
        .init(days: 200,  label: "200 Days",                         isLotus: false, isMonthly: false),
        .init(days: 300,  label: "300 Days",                         isLotus: false, isMonthly: false),
        .init(days: 365,  label: "One Year",                         isLotus: false, isMonthly: true),
        .init(days: 500,  label: "500 Days",                         isLotus: false, isMonthly: false),
        .init(days: 1000, label: "1000 Days",                        isLotus: false, isMonthly: false),
    ]

    init() { load() }

    // MARK: - Record verse read

    func recordVerseRead() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastRaw = UserDefaults.standard.object(forKey: lastPracticeKey) as? Date
        let lastDay = lastRaw.map { cal.startOfDay(for: $0) }

        if lastDay != today {
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            let dayBefore = cal.date(byAdding: .day, value: -2, to: today)!

            if lastDay == yesterday {
                currentStreak += 1
            } else if lastDay == dayBefore && shieldAvailable {
                // Shield absorbs exactly one missed day
                currentStreak += 1
                shieldAvailable = false
                UserDefaults.standard.set(false, forKey: shieldKey)
            } else {
                currentStreak = 1
            }
            longestStreak = max(longestStreak, currentStreak)
            UserDefaults.standard.set(today, forKey: lastPracticeKey)
        }

        totalVersesRead += 1
        refreshActiveDays()
        checkMilestones()
        persist()
        Task {
            await AuthManager.shared.syncToCloud()
        }
    }

    // MARK: - Milestones

    private func checkMilestones() {
        guard let top = StreakManager.milestones
            .filter({ currentStreak >= $0.days && !acknowledgedMilestones.contains($0.days) })
            .last
        else { return }
        if pendingMilestone == nil { pendingMilestone = top }
    }

    func acknowledgeMilestone(_ m: DharmaMilestoneItem) {
        acknowledgedMilestones.insert(m.days)
        pendingMilestone = nil
        UserDefaults.standard.set(Array(acknowledgedMilestones), forKey: acknowledgedKey)
        checkMilestones()
    }

    // MARK: - Weekly active days (Mon–Sun)

    private func refreshActiveDays() {
        let cal     = Calendar.current
        let today   = Date()
        let weekday = cal.component(.weekday, from: today)   // 1 = Sun … 7 = Sat
        let idx     = (weekday == 1) ? 6 : weekday - 2      // 0 = Mon … 6 = Sun

        let weekStart = cal.date(byAdding: .day,
                                 value: -idx,
                                 to: cal.startOfDay(for: today))!
        let storedRaw = UserDefaults.standard.object(forKey: weekStartKey) as? Date
        let storedDay = storedRaw.map { cal.startOfDay(for: $0) }

        if storedDay != weekStart {
            activeDaysThisWeek = []
            shieldAvailable = true                              // new week → shield resets
            UserDefaults.standard.set(weekStart, forKey: weekStartKey)
            UserDefaults.standard.set(true, forKey: shieldKey)
        }

        activeDaysThisWeek.insert(idx)
        UserDefaults.standard.set(Array(activeDaysThisWeek), forKey: activeDaysKey)

        // Monthly active-day tracking
        let monthComps = cal.dateComponents([.year, .month], from: today)
        let monthStart = cal.date(from: monthComps)!
        let mRaw       = UserDefaults.standard.object(forKey: monthStartKey) as? Date
        let mDay       = mRaw.map { cal.startOfDay(for: $0) }

        if mDay != monthStart {
            activeDaysThisMonth = []
            UserDefaults.standard.set(monthStart, forKey: monthStartKey)
        }

        let dayOfMonth = cal.component(.day, from: today)
        activeDaysThisMonth.insert(dayOfMonth)
        UserDefaults.standard.set(Array(activeDaysThisMonth), forKey: activeDaysMonthKey)
    }

    // MARK: - Weekly Krishna insight

    func generateWeeklyInsight(journalEntries: [JournalEntry], goals: [String]) async {
        guard !journalEntries.isEmpty else { return }

        if let d = weeklyInsightDate {
            let age = Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 0
            if age < 7 && !weeklyInsight.isEmpty { return }
        }

        isLoadingInsight = true

        let snippets = journalEntries.prefix(5).map {
            "Verse: \($0.verseSource). Reflection: \($0.noteText.prefix(100))"
        }.joined(separator: "\n")

        let goalLine = goals.prefix(3).joined(separator: ", ")

        let message = """
        I have been studying the sacred texts. My current spiritual goals are: \(goalLine.isEmpty ? "spiritual growth" : goalLine).

        My recent reflections:
        \(snippets)

        Based on my practice, offer a single focused weekly spiritual insight in 3–5 sentences. Speak warmly and directly. Do not ask follow-up questions. Respond in exactly 2 sentences maximum. Be personal and direct. Do not use asterisks or markdown formatting.
        """

        let req = KrishnaRequest(
            message: message,
            currentVerse: nil,
            goals: goals,
            reflection: nil,
            conversationHistory: nil
        )

        do {
            var full = ""
            for try await chunk in KrishnaService.shared.streamResponse(request: req) {
                full += chunk
                weeklyInsight = full
            }
            weeklyInsightDate = Date()
            UserDefaults.standard.set(weeklyInsight, forKey: insightTextKey)
            UserDefaults.standard.set(weeklyInsightDate, forKey: insightDateKey)
        } catch {}

        isLoadingInsight = false
    }

    // MARK: - Persistence

    private func persist() {
        UserDefaults.standard.set(currentStreak,   forKey: streakKey)
        UserDefaults.standard.set(longestStreak,   forKey: longestKey)
        UserDefaults.standard.set(totalVersesRead, forKey: totalVersesKey)
    }

    private func load() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())

        currentStreak   = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak   = UserDefaults.standard.integer(forKey: longestKey)
        totalVersesRead = UserDefaults.standard.integer(forKey: totalVersesKey)

        // Restore weekly active days + load shield (must come before streak reset check)
        let weekday   = cal.component(.weekday, from: Date())
        let idx       = (weekday == 1) ? 6 : weekday - 2
        let weekStart = cal.date(byAdding: .day, value: -idx, to: today)!
        let storedRaw = UserDefaults.standard.object(forKey: weekStartKey) as? Date
        let storedDay = storedRaw.map { cal.startOfDay(for: $0) }
        if storedDay == weekStart {
            let saved = UserDefaults.standard.array(forKey: activeDaysKey) as? [Int] ?? []
            activeDaysThisWeek = Set(saved)
            shieldAvailable = UserDefaults.standard.object(forKey: shieldKey) == nil
                ? true
                : UserDefaults.standard.bool(forKey: shieldKey)
        } else {
            // New week: shield resets
            shieldAvailable = true
            UserDefaults.standard.set(true, forKey: shieldKey)
        }

        // Reset streak if last practice was more than a day ago (shield can prevent this)
        let lastRaw = UserDefaults.standard.object(forKey: lastPracticeKey) as? Date
        if let last = lastRaw {
            let lastDay   = cal.startOfDay(for: last)
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            let dayBefore = cal.date(byAdding: .day, value: -2, to: today)!
            if lastDay != today && lastDay != yesterday {
                if lastDay == dayBefore && shieldAvailable {
                    // Shield silently holds the streak; it gets consumed on next recordVerseRead()
                } else {
                    currentStreak = 0
                    UserDefaults.standard.set(0, forKey: streakKey)
                }
            }
        }

        // Restore monthly active days
        let monthComps = cal.dateComponents([.year, .month], from: Date())
        let monthStart = cal.date(from: monthComps)!
        let mRaw = UserDefaults.standard.object(forKey: monthStartKey) as? Date
        let mDay = mRaw.map { cal.startOfDay(for: $0) }
        if mDay == monthStart {
            let saved = UserDefaults.standard.array(forKey: activeDaysMonthKey) as? [Int] ?? []
            activeDaysThisMonth = Set(saved)
        }

        // Acknowledged milestones
        let ack = UserDefaults.standard.array(forKey: acknowledgedKey) as? [Int] ?? []
        acknowledgedMilestones = Set(ack)

        // Cached weekly insight
        weeklyInsight     = UserDefaults.standard.string(forKey: insightTextKey) ?? ""
        weeklyInsightDate = UserDefaults.standard.object(forKey: insightDateKey) as? Date

        checkMilestones()
    }

    func applyFromCloud(streakDays: Int, totalVersesRead cloudTotal: Int) {
        currentStreak = streakDays
        totalVersesRead = cloudTotal
        longestStreak = max(longestStreak, currentStreak)
        persist()
    }
}
