import SwiftUI

@main
struct DharmaApp: App {
    @StateObject private var store = ScriptureStore()
    @StateObject private var onboarding = OnboardingManager()
    @StateObject private var goalsManager = GoalsManager.shared
    @StateObject private var journalStore = JournalStore.shared

    init() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .dharmaBackgroundUI
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.dharmaTextPrimaryUI]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.dharmaTextPrimaryUI]

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor.dharmaTextPrimaryUI]
        scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.dharmaTextPrimaryUI]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 1)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .dharmaSurfaceUI
        tabAppearance.shadowColor = .dharmaTabBorderUI
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some Scene {
        WindowGroup {
            if onboarding.hasCompletedOnboarding {
                ContentView()
                    .environmentObject(store)
                    .environmentObject(goalsManager)
                    .environmentObject(journalStore)
                    .fullScreenCover(isPresented: .init(
                        get: { !goalsManager.hasCompletedGoalSelection },
                        set: { _ in }
                    )) {
                        GoalsOnboardingView()
                            .environmentObject(goalsManager)
                    }
            } else {
                OnboardingView(manager: onboarding)
            }
        }
    }
}
