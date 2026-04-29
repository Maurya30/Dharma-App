import SwiftUI
import UIKit
import WidgetKit

@main
struct DharmaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ScriptureStore.shared
    @StateObject private var onboarding = OnboardingManager()
    @StateObject private var goalsManager = GoalsManager.shared
    @StateObject private var journalStore = JournalStore.shared
    @StateObject private var streakManager = StreakManager.shared

    @AppStorage("userDarkMode") private var userDarkMode: Bool = false
    @State private var showDeferredGoalsFlow = false

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
            Group {
                if onboarding.hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(store)
                        .environmentObject(onboarding)
                        .environmentObject(goalsManager)
                        .environmentObject(journalStore)
                        .environmentObject(streakManager)
                        .environmentObject(NotificationNavigationState.shared)
                        .fullScreenCover(isPresented: $showDeferredGoalsFlow) {
                            DeferredGoalsToVerseFlow()
                                .environmentObject(goalsManager)
                        }
                        .onAppear {
                            showDeferredGoalsFlow = !goalsManager.hasCompletedGoalSelection
                        }
                        .onChange(of: goalsManager.hasCompletedGoalSelection) { _, done in
                            if done { showDeferredGoalsFlow = false }
                        }
                } else {
                    OnboardingFlowView(manager: onboarding)
                        .environmentObject(goalsManager)
                }
            }
            .preferredColorScheme(userDarkMode ? .dark : .light)
            .onAppear {
                NotificationManager.shared.setup()
                syncWidgetUserDarkMode()
            }
            .onChange(of: userDarkMode) { _, _ in
                syncWidgetUserDarkMode()
            }
            .task {
                await AuthManager.shared.restoreFromCloudOnLaunchIfNeeded()
            }
        }
    }

    private func syncWidgetUserDarkMode() {
        SharedDataManager.shared.saveUserDarkModeForWidget(userDarkMode)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
