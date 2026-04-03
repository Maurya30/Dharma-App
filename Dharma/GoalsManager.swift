import Foundation
import Combine

final class GoalsManager: ObservableObject {
    static let shared = GoalsManager()

    @Published var selectedGoals: [String] = []
    @Published var hasCompletedGoalSelection: Bool = false

    private let goalsKey = "selectedGoals"
    private let selectionKey = "hasCompletedGoalSelection"

    init() {
        selectedGoals = UserDefaults.standard.stringArray(forKey: goalsKey) ?? []
        hasCompletedGoalSelection = UserDefaults.standard.bool(forKey: selectionKey)
    }

    func saveGoals(_ goals: [String]) {
        selectedGoals = goals
        UserDefaults.standard.set(goals, forKey: goalsKey)
    }

    func completeGoalSelection() {
        hasCompletedGoalSelection = true
        UserDefaults.standard.set(true, forKey: selectionKey)
    }

    func resetGoals() {
        hasCompletedGoalSelection = false
        selectedGoals = []
        UserDefaults.standard.removeObject(forKey: goalsKey)
        UserDefaults.standard.removeObject(forKey: selectionKey)
    }

    func replaceFromCloud(selectedGoals goals: [String], hasCompletedSelection: Bool) {
        selectedGoals = goals
        hasCompletedGoalSelection = hasCompletedSelection
        UserDefaults.standard.set(goals, forKey: goalsKey)
        UserDefaults.standard.set(hasCompletedSelection, forKey: selectionKey)
    }

    static let allGoals: [GoalDefinition] = [
        // Spiritual
        .init(name: "Understand the nature of the Self (Atman)", section: "Spiritual"),
        .init(name: "Develop non-attachment to results", section: "Spiritual"),
        .init(name: "Understand the concept of Karma", section: "Spiritual"),
        .init(name: "Explore the path to Moksha (liberation)", section: "Spiritual"),
        .init(name: "Understand my Dharma — my purpose", section: "Spiritual"),
        // Practice
        .init(name: "Build a daily scripture reading habit", section: "Practice"),
        .init(name: "Develop a meditation practice", section: "Practice"),
        .init(name: "Chant mantras regularly", section: "Practice"),
        .init(name: "Read the full Bhagavad Gita", section: "Practice"),
        // Personal Growth
        .init(name: "Become less reactive and more patient", section: "Personal Growth"),
        .init(name: "Reduce anxiety about the future", section: "Personal Growth"),
        .init(name: "Develop self-discipline", section: "Personal Growth"),
        .init(name: "Be more present in daily life", section: "Personal Growth"),
        .init(name: "Find meaning and purpose", section: "Personal Growth"),
    ]

    static let shortNames: [String: String] = [
        "Understand the nature of the Self (Atman)": "Atman",
        "Develop non-attachment to results": "Non-attachment",
        "Understand the concept of Karma": "Karma",
        "Explore the path to Moksha (liberation)": "Moksha",
        "Understand my Dharma — my purpose": "Dharma",
        "Build a daily scripture reading habit": "Daily reading",
        "Develop a meditation practice": "Meditation",
        "Chant mantras regularly": "Mantras",
        "Read the full Bhagavad Gita": "Full Gita",
        "Become less reactive and more patient": "Patience",
        "Reduce anxiety about the future": "Less anxiety",
        "Develop self-discipline": "Self-discipline",
        "Be more present in daily life": "Presence",
        "Find meaning and purpose": "Purpose",
    ]

    static let explanations: [String: String] = [
        "Understand the nature of the Self (Atman)": "This verse illuminates the eternal, unchanging nature of the Self beyond body and mind.",
        "Develop non-attachment to results": "This verse teaches acting without clinging to outcomes — the heart of karma yoga.",
        "Understand the concept of Karma": "This verse reveals how action, intention, and consequence are woven together.",
        "Explore the path to Moksha (liberation)": "This verse points toward the freedom that comes from knowing one's true nature.",
        "Understand my Dharma — my purpose": "This verse speaks to the sacred duty each soul carries in this lifetime.",
        "Build a daily scripture reading habit": "This verse on the value of knowledge supports your commitment to daily study.",
        "Develop a meditation practice": "This verse on stilling the mind speaks directly to the practice of meditation.",
        "Chant mantras regularly": "This verse on sacred sound and devotion supports your mantra practice.",
        "Read the full Bhagavad Gita": "This verse is part of Krishna's complete teaching to Arjuna.",
        "Become less reactive and more patient": "This verse teaches equanimity — responding to life from stillness rather than reaction.",
        "Reduce anxiety about the future": "This verse releases the burden of worry by grounding action in the present.",
        "Develop self-discipline": "This verse on mastering the senses and the mind supports your practice of tapas.",
        "Be more present in daily life": "This verse calls attention to the sacred nature of this moment.",
        "Find meaning and purpose": "This verse points toward the deeper purpose that underlies all action.",
    ]

    static func shortName(for goal: String) -> String {
        shortNames[goal] ?? goal
    }
}

struct GoalDefinition: Identifiable {
    let name: String
    let section: String
    var id: String { name }
}
