import SwiftUI
import UIKit

@main
struct DharmaApp: App {
    @StateObject private var store = ScriptureStore()
    @StateObject private var onboarding = OnboardingManager()
    @StateObject private var goalsManager = GoalsManager.shared
    @StateObject private var journalStore = JournalStore.shared

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.dharmaTextPrimaryUI]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.dharmaTextPrimaryUI]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 1)

        // Let `dharmaBackground` show through SwiftUI ScrollView / List / grid backing stores.
        UIScrollView.appearance().backgroundColor = .clear
        UIView.appearance(whenContainedInInstancesOf: [UIScrollView.self]).backgroundColor = .clear
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear

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
