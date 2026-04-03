import SwiftUI

/// For users who completed onboarding before goal + verse steps existed.
struct DeferredGoalsToVerseFlow: View {
    @EnvironmentObject var goalsManager: GoalsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showVerse = false

    var body: some View {
        Group {
            if showVerse {
                VerseSwipeOnboardingView(
                    onFinished: {
                        goalsManager.completeGoalSelection()
                        dismiss()
                    },
                    activeStepIndex: 4,
                    totalSteps: 6
                )
            } else {
                GoalsOnboardingView(
                    onGoalsFinished: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showVerse = true
                        }
                    },
                    activeStepIndex: 3,
                    totalSteps: 6
                )
            }
        }
        .dharmaBackground()
    }
}
