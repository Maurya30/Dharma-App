import SwiftUI
import Combine

// MARK: - Onboarding Data
enum DharmaIntention: String, CaseIterable, Identifiable {
    case peace    = "Seeking peace"
    case practice = "Daily practice"
    case study    = "Study the Gita"
    case explore  = "Explore Hindu culture"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .peace:    return "leaf.fill"
        case .practice: return "sun.max.fill"
        case .study:    return "book.fill"
        case .explore:  return "sparkles"
        }
    }
}

enum DharmaPace: String, CaseIterable, Identifiable {
    case fiveMin    = "5 minutes"
    case fifteenMin = "15 minutes"
    case thirtyMin  = "30 minutes"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .fiveMin:    return "One verse a day"
        case .fifteenMin: return "A few verses + reflection"
        case .thirtyMin:  return "Deep study of a chapter"
        }
    }
}

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "dharma_onboarding_done") }
    }
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "dharma_user_name") }
    }
    @Published var intention: String {
        didSet { UserDefaults.standard.set(intention, forKey: "dharma_intention") }
    }
    @Published var pace: String {
        didSet { UserDefaults.standard.set(pace, forKey: "dharma_pace") }
    }

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "dharma_onboarding_done")
        self.userName = UserDefaults.standard.string(forKey: "dharma_user_name") ?? ""
        self.intention = UserDefaults.standard.string(forKey: "dharma_intention") ?? ""
        self.pace = UserDefaults.standard.string(forKey: "dharma_pace") ?? ""
    }

    func complete(name: String, intention: DharmaIntention, pace: DharmaPace) {
        self.userName = name
        self.intention = intention.rawValue
        self.pace = pace.rawValue
        self.hasCompletedOnboarding = true
    }

    /// Finishes the new multi-step onboarding (welcome → appearance → name → goals → verse swipe → sign in).
    func completeFirstRun() {
        if intention.isEmpty { intention = DharmaIntention.explore.rawValue }
        if pace.isEmpty { pace = DharmaPace.fiveMin.rawValue }
        hasCompletedOnboarding = true
    }
}
