import Foundation
import Combine
import SwiftUI

// MARK: - Types

enum SadhanaAct: Equatable {
    case darshan
    case bhavana
    case seva
}

enum BhavanaType: Equatable {
    case oneWord
    case yesNo
    case textInput
}

enum SevaType: Equatable {
    case chant
    case askKrishna
    case share
}

// MARK: - Manager

@MainActor
final class SadhanaManager: ObservableObject {
    static let shared = SadhanaManager()

    private enum Keys {
        static let darshanDate = "sadhana_darshan_date"
        static let bhavanaDate = "sadhana_bhavana_date"
        static let sevaDate = "sadhana_seva_date"
        static let streak = "sadhana_streak"
        static let lastCompletion = "sadhana_last_completion_date"
        static let totalActs = "sadhana_total_acts"
        static let notificationVerseHash = "sadhana_notification_verse_hash"
        static let bhavanaInput = "sadhana_bhavana_input"
        static let bhavanaKrishna = "sadhana_bhavana_krishna"
        static let darshanVerseId = "sadhana_darshan_verse_id"
        static let darshanInput = "sadhana_darshan_input"
    }

    @Published private(set) var isDarshanComplete: Bool = false
    @Published private(set) var isBhavanaComplete: Bool = false
    @Published private(set) var isSevaComplete: Bool = false
    @Published private(set) var streakDays: Int = 0
    @Published private(set) var totalActsCompleted: Int = 0

    @Published var bhavanaInput: String = ""
    @Published var bhavanaKrishnaResponse: String = ""
    @Published var darshanVerseId: String = ""
    @Published var darshanInput: String = ""

    private let defaults = UserDefaults.standard

    private init() {
        loadFromDefaults()
        checkAndResetIfNewDay()
        loadPersistedDailyContent()
    }

    private func loadFromDefaults() {
        streakDays = defaults.integer(forKey: Keys.streak)
        totalActsCompleted = defaults.integer(forKey: Keys.totalActs)
        syncCompletionBoolsFromDates()
    }

    /// Loads verse/text snapshots only when the corresponding act is completed today.
    private func loadPersistedDailyContent() {
        if isToday(defaults.object(forKey: Keys.darshanDate) as? Date) {
            darshanVerseId = defaults.string(forKey: Keys.darshanVerseId) ?? ""
            darshanInput = defaults.string(forKey: Keys.darshanInput) ?? ""
        } else {
            darshanVerseId = ""
            darshanInput = ""
        }
        if isToday(defaults.object(forKey: Keys.bhavanaDate) as? Date) {
            bhavanaInput = defaults.string(forKey: Keys.bhavanaInput) ?? ""
            bhavanaKrishnaResponse = defaults.string(forKey: Keys.bhavanaKrishna) ?? ""
        } else {
            bhavanaInput = ""
            bhavanaKrishnaResponse = ""
        }
    }

    func saveBhavanaResponse(input: String, krishnaResponse: String) {
        defaults.set(input, forKey: Keys.bhavanaInput)
        defaults.set(krishnaResponse, forKey: Keys.bhavanaKrishna)
        bhavanaInput = input
        bhavanaKrishnaResponse = krishnaResponse
    }

    func saveDarshanVerseId(_ id: String) {
        defaults.set(id, forKey: Keys.darshanVerseId)
        darshanVerseId = id
    }

    func saveDarshanInput(_ text: String) {
        defaults.set(text, forKey: Keys.darshanInput)
        darshanInput = text
    }

    private func clearBhavanaStrings() {
        defaults.removeObject(forKey: Keys.bhavanaInput)
        defaults.removeObject(forKey: Keys.bhavanaKrishna)
        bhavanaInput = ""
        bhavanaKrishnaResponse = ""
    }

    private func clearDarshanStrings() {
        defaults.removeObject(forKey: Keys.darshanVerseId)
        defaults.removeObject(forKey: Keys.darshanInput)
        darshanVerseId = ""
        darshanInput = ""
    }

    private func syncCompletionBoolsFromDates() {
        isDarshanComplete = isToday(defaults.object(forKey: Keys.darshanDate) as? Date)
        isBhavanaComplete = isToday(defaults.object(forKey: Keys.bhavanaDate) as? Date)
        isSevaComplete = isToday(defaults.object(forKey: Keys.sevaDate) as? Date)
    }

    private func isToday(_ date: Date?) -> Bool {
        guard let date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    /// Called on init and on every view appear.
    func checkAndResetIfNewDay() {
        let cal = Calendar.current
        var changed = false

        if let d = defaults.object(forKey: Keys.darshanDate) as? Date, !cal.isDateInToday(d) {
            defaults.removeObject(forKey: Keys.darshanDate)
            clearDarshanStrings()
            isDarshanComplete = false
            changed = true
        }
        if let d = defaults.object(forKey: Keys.bhavanaDate) as? Date, !cal.isDateInToday(d) {
            defaults.removeObject(forKey: Keys.bhavanaDate)
            clearBhavanaStrings()
            isBhavanaComplete = false
            changed = true
        }
        if let d = defaults.object(forKey: Keys.sevaDate) as? Date, !cal.isDateInToday(d) {
            defaults.removeObject(forKey: Keys.sevaDate)
            isSevaComplete = false
            changed = true
        }

        syncCompletionBoolsFromDates()

        if changed {
            loadPersistedDailyContent()
            objectWillChange.send()
        }

        rescheduleNotificationIfNeeded()
    }

    private func rescheduleNotificationIfNeeded() {
        let verseText = todayVerse?.textEnglish ?? "Begin your practice"
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let count = ScriptureStore.shared.items.count
        let hash = "\(day)_\(count)_\(verseText.prefix(40))"
        if defaults.string(forKey: Keys.notificationVerseHash) == hash { return }
        defaults.set(hash, forKey: Keys.notificationVerseHash)
        NotificationManager.shared.scheduleSadhanaNotification(verseText: verseText)
    }

    var completedCount: Int {
        [isDarshanComplete, isBhavanaComplete, isSevaComplete].filter(\.self).count
    }

    var isFullyComplete: Bool {
        completedCount == 3
    }

    var sanskritTitle: String {
        let s = streakDays
        switch s {
        case 0...6: return ""
        case 7...20: return "Abhyasi · अभ्यासी"
        case 21...107: return "Sadhaka · साधक"
        default: return "Siddha · सिद्ध"
        }
    }

    private static let oneWordPeacePrompts: [String] = [
        "How do you feel right now?",
        "What is present in your heart today?",
        "One word for this moment.",
        "What emotion is closest to the surface?"
    ]

    private static let yesNoDisciplinePrompts: [String] = [
        "Did you show up for your practice today?",
        "Were you kind to yourself today?",
        "Did you do the hard thing today?"
    ]

    private static let textInputKnowledgePrompts: [String] = [
        "What line stayed with you?",
        "What did you learn that surprised you?",
        "What verse spoke to you recently?"
    ]

    private static let defaultOneWordPrompts: [String] = [
        "What are you carrying today?",
        "What needs your attention right now?",
        "What is asking to be seen?",
        "Where is your energy today?"
    ]

    var bhavanaPrompt: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let first = GoalsManager.shared.selectedGoals.first?.lowercased() ?? ""

        let prompts: [String]
        switch bhavanaType {
        case .oneWord:
            if first.contains("anxiety") || first.contains("stress") || first.contains("peace") {
                prompts = Self.oneWordPeacePrompts
            } else if first.isEmpty {
                prompts = Self.defaultOneWordPrompts
            } else {
                prompts = Self.defaultOneWordPrompts
            }
        case .yesNo:
            prompts = Self.yesNoDisciplinePrompts
        case .textInput:
            prompts = Self.textInputKnowledgePrompts
        }
        guard !prompts.isEmpty else { return Self.defaultOneWordPrompts[day % Self.defaultOneWordPrompts.count] }
        return prompts[day % prompts.count]
    }

    var bhavanaType: BhavanaType {
        guard let first = GoalsManager.shared.selectedGoals.first?.lowercased() else {
            return .oneWord
        }
        if first.contains("anxiety") || first.contains("stress") || first.contains("peace") {
            return .oneWord
        }
        if first.contains("discipline") || first.contains("habit") || first.contains("consistent") {
            return .yesNo
        }
        if first.contains("read") || first.contains("study") || first.contains("knowledge") || first.contains("learn") {
            return .textInput
        }
        return .oneWord
    }

    var todaySevaType: SevaType {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch weekday {
        case 2, 4, 6: return .chant
        case 3, 5: return .askKrishna
        default: return .share
        }
    }

    var todayVerse: ScriptureItem? {
        let items = ScriptureStore.shared.items
        guard !items.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let idx = (day + 137) % items.count
        return items[idx]
    }

    func completeAct(_ act: SadhanaAct) {
        switch act {
        case .darshan:
            guard !isDarshanComplete else { return }
            defaults.set(Date(), forKey: Keys.darshanDate)
            isDarshanComplete = true
        case .bhavana:
            guard !isBhavanaComplete else { return }
            defaults.set(Date(), forKey: Keys.bhavanaDate)
            isBhavanaComplete = true
        case .seva:
            guard !isSevaComplete else { return }
            defaults.set(Date(), forKey: Keys.sevaDate)
            isSevaComplete = true
        }

        totalActsCompleted += 1
        defaults.set(totalActsCompleted, forKey: Keys.totalActs)

        GoalPathManager.shared.awardSadhanaPoint()

        if isFullyComplete {
            updateStreakAfterFullCompletion()
        }

        HapticManager.medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticManager.success()
        }

        Task {
            await AuthManager.shared.syncToCloud()
        }
    }

    private func updateStreakAfterFullCompletion() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastRaw = defaults.object(forKey: Keys.lastCompletion) as? Date
        let lastDay = lastRaw.map { cal.startOfDay(for: $0) }

        if let last = lastDay, last == today {
            return
        }

        if let last = lastDay {
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            if last == yesterday {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }

        defaults.set(Date(), forKey: Keys.lastCompletion)
        defaults.set(streakDays, forKey: Keys.streak)
        objectWillChange.send()
    }

    func applyFromCloud(streakDays: Int, totalActs: Int) {
        self.streakDays = streakDays
        self.totalActsCompleted = totalActs
        defaults.set(streakDays, forKey: Keys.streak)
        defaults.set(totalActs, forKey: Keys.totalActs)
        objectWillChange.send()
    }
}
