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
                    activeStepIndex: 3
                )
            } else {
                GoalsOnboardingView(
                    onGoalsFinished: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showVerse = true
                        }
                    },
                    activeStepIndex: 2,
                    totalSteps: 4
                )
            }
        }
        .dharmaBackground()
    }
}
