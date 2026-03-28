import Foundation

/// Persisted onboarding preferences beyond core flags on `OnboardingManager` / `GoalsManager`.
struct OnboardingProfile: Codable {
    var resonantVerses: [String]
    /// Mirrors `AppStorage("userDarkMode")` — `true` means dark mode.
    var darkMode: Bool

    static let storageKey = "dharma_onboarding_profile"

    static func load() -> OnboardingProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(OnboardingProfile.self, from: data) else {
            return OnboardingProfile(resonantVerses: [], darkMode: false)
        }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    mutating func appendResonantSource(_ source: String) {
        if !resonantVerses.contains(source) {
            resonantVerses.append(source)
        }
    }
}
