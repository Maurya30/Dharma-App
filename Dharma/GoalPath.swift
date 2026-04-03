import Foundation
import Combine

// MARK: - Models

struct GoalPath: Identifiable, Codable {
    let goalId: String
    var levels: [PathLevel]
    var currentLevelIndex: Int
    var earnedTitles: [EarnedTitle]
    /// Set when user marks any day complete; used for "come back tomorrow."
    var lastCompletionDate: Date?
    /// Sadhana and other practice-based points on this path.
    var practicePoints: Int

    var id: String { goalId }

    enum CodingKeys: String, CodingKey {
        case goalId, levels, currentLevelIndex, earnedTitles, lastCompletionDate, practicePoints
    }

    init(
        goalId: String,
        levels: [PathLevel],
        currentLevelIndex: Int,
        earnedTitles: [EarnedTitle],
        lastCompletionDate: Date?,
        practicePoints: Int = 0
    ) {
        self.goalId = goalId
        self.levels = levels
        self.currentLevelIndex = currentLevelIndex
        self.earnedTitles = earnedTitles
        self.lastCompletionDate = lastCompletionDate
        self.practicePoints = practicePoints
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        goalId = try c.decode(String.self, forKey: .goalId)
        levels = try c.decode([PathLevel].self, forKey: .levels)
        currentLevelIndex = try c.decode(Int.self, forKey: .currentLevelIndex)
        earnedTitles = try c.decode([EarnedTitle].self, forKey: .earnedTitles)
        lastCompletionDate = try c.decodeIfPresent(Date.self, forKey: .lastCompletionDate)
        practicePoints = try c.decodeIfPresent(Int.self, forKey: .practicePoints) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(goalId, forKey: .goalId)
        try c.encode(levels, forKey: .levels)
        try c.encode(currentLevelIndex, forKey: .currentLevelIndex)
        try c.encode(earnedTitles, forKey: .earnedTitles)
        try c.encodeIfPresent(lastCompletionDate, forKey: .lastCompletionDate)
        try c.encode(practicePoints, forKey: .practicePoints)
    }
}

struct PathLevel: Identifiable, Codable {
    let id: String
    let levelNumber: Int
    let levelName: String
    let levelEmoji: String
    let days: [PathDay]
    var completedDayIndices: [Int]
    var isUnlocked: Bool
    var isComplete: Bool
    let rewardTitle: String
    let rewardMeaning: String
    let rewardEmoji: String
}

struct PathDay: Identifiable, Codable {
    let id: String
    let dayNumber: Int
    let verseReference: String
    let sanskrit: String
    let verseText: String
    let krishnaContext: String
    let reflectionPrompt: String
}

struct EarnedTitle: Identifiable, Codable {
    let id: String
    let title: String
    let meaning: String
    let emoji: String
    let earnedDate: Date
    let goalId: String
}

// MARK: - Manager

final class GoalPathManager: ObservableObject {
    static let shared = GoalPathManager()

    private static let storageKey = "dharma_goal_paths"

    @Published private(set) var paths: [GoalPath] = []

    private init() {
        loadPaths()
    }

    private func loadPaths() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([GoalPath].self, from: data) else {
            paths = []
            return
        }
        paths = decoded
    }

    private func savePaths() {
        if let data = try? JSONEncoder().encode(paths) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    func pathForGoal(_ goalId: String) -> GoalPath? {
        paths.first { $0.goalId == goalId }
    }

    func syncPaths(with selectedGoals: [String]) {
        let set = Set(selectedGoals)
        paths.removeAll { !set.contains($0.goalId) }
        for gid in selectedGoals {
            if pathForGoal(gid) == nil {
                createPath(for: gid)
            }
        }
        savePaths()
        objectWillChange.send()
    }

    func createPath(for goalId: String) {
        guard pathForGoal(goalId) == nil else { return }
        let levels = GoalPathContent.levels(for: goalId)
        let path = GoalPath(
            goalId: goalId,
            levels: levels,
            currentLevelIndex: 0,
            earnedTitles: [],
            lastCompletionDate: nil,
            practicePoints: 0
        )
        paths.append(path)
        savePaths()
        objectWillChange.send()
    }

    /// First incomplete day index in the current level, or `nil` if the user already completed a step today or the path is finished.
    func todaysDayIndex(for path: GoalPath) -> Int? {
        guard path.currentLevelIndex < path.levels.count else { return nil }
        let level = path.levels[path.currentLevelIndex]
        guard level.isUnlocked, !level.isComplete else { return nil }

        if let last = path.lastCompletionDate, Calendar.current.isDateInToday(last) {
            return nil
        }

        let completed = Set(level.completedDayIndices)
        for i in 0..<level.days.count {
            if !completed.contains(i) {
                return i
            }
        }
        return nil
    }

    /// Returns `true` if this completion finished the entire level.
    @discardableResult
    func markDayComplete(goalId: String, levelIndex: Int, dayIndex: Int) -> Bool {
        guard let idx = paths.firstIndex(where: { $0.goalId == goalId }) else { return false }
        var path = paths[idx]

        guard levelIndex == path.currentLevelIndex else { return false }
        guard let expected = todaysDayIndex(for: path), expected == dayIndex else { return false }

        var level = path.levels[levelIndex]
        if level.completedDayIndices.contains(dayIndex) { return false }

        level.completedDayIndices.append(dayIndex)
        level.completedDayIndices.sort()
        path.levels[levelIndex] = level
        path.lastCompletionDate = Date()

        let allDone = level.completedDayIndices.count >= level.days.count
        if allDone {
            applyLevelCompletion(goalId: goalId, levelIndex: levelIndex, pathIndex: idx, path: &path)
            savePaths()
            objectWillChange.send()
            Task {
                await AuthManager.shared.syncToCloud()
            }
            return true
        } else {
            paths[idx] = path
            savePaths()
            objectWillChange.send()
            return false
        }
    }

    private func applyLevelCompletion(goalId: String, levelIndex: Int, pathIndex: Int, path: inout GoalPath) {
        path.levels[levelIndex].isComplete = true

        let level = path.levels[levelIndex]
        let title = EarnedTitle(
            id: UUID().uuidString,
            title: level.rewardTitle,
            meaning: level.rewardMeaning,
            emoji: level.rewardEmoji,
            earnedDate: Date(),
            goalId: goalId
        )
        path.earnedTitles.append(title)

        if levelIndex + 1 < path.levels.count {
            path.levels[levelIndex + 1].isUnlocked = true
            path.currentLevelIndex = levelIndex + 1
        }

        paths[pathIndex] = path
    }

    func replaceFromCloud(_ newPaths: [GoalPath]) {
        paths = newPaths
        savePaths()
        objectWillChange.send()
    }

    /// Awards one practice point on the active path (first selected goal that has a path).
    func awardSadhanaPoint() {
        for goalId in GoalsManager.shared.selectedGoals {
            guard let idx = paths.firstIndex(where: { $0.goalId == goalId }) else { continue }
            paths[idx].practicePoints += 1
            savePaths()
            objectWillChange.send()
            return
        }
    }
}
