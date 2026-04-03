import SwiftUI

struct OnboardingProgressDots: View {
    var activeIndex: Int
    var total: Int = 6

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == activeIndex ? Color(hex: "C9821E") : Color(hex: "C9821E").opacity(0.2))
                    .frame(width: i == activeIndex ? 8 : 6, height: i == activeIndex ? 8 : 6)
                    .animation(.easeInOut(duration: 0.3), value: activeIndex)
            }
        }
    }
}

struct OnboardingFlowView: View {
    @ObservedObject var manager: OnboardingManager
    @EnvironmentObject var goalsManager: GoalsManager

    enum Step: Int {
        case welcome = 0
        case appearance = 1
        case name = 2
        case goals = 3
        case verseSwipe = 4
        case signIn = 5
    }

    @State private var step: Step = .welcome
    @State private var fadeIn = false

    var body: some View {
        ZStack {
            Group {
                switch step {
                case .welcome:
                    welcomeStep
                case .appearance:
                    AppearanceOnboardingView(onContinue: { goTo(.name) }, activeStepIndex: 1, totalSteps: 6)
                case .name:
                    NameOnboardingView(
                        manager: manager,
                        onContinue: { goTo(.goals) },
                        activeStepIndex: 2,
                        totalSteps: 6
                    )
                case .goals:
                    GoalsOnboardingView(
                        onGoalsFinished: { goTo(.verseSwipe) },
                        activeStepIndex: 3,
                        totalSteps: 6
                    )
                case .verseSwipe:
                    VerseSwipeOnboardingView(
                        onFinished: {
                            goalsManager.completeGoalSelection()
                            goTo(.signIn)
                        },
                        activeStepIndex: 4,
                        totalSteps: 6
                    )
                case .signIn:
                    SignInView(onFinished: {
                        manager.completeFirstRun()
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(step.rawValue)
        }
        .opacity(fadeIn ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { fadeIn = true }
        }
        .dharmaBackground()
    }

    private func goTo(_ next: Step) {
        withAnimation(.easeInOut(duration: 0.4)) {
            step = next
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DharmaSpacing.lg) {
                Text("ॐ")
                    .font(.system(size: 64, design: .serif))
                    .foregroundColor(Color(hex: "C9821E"))

                Text("Welcome to Dharma")
                    .font(DharmaFont.title(28))
                    .foregroundColor(.dharmaTextPrimary)

                Text("A sacred space for the Bhagavad Gita,\nancient wisdom, and daily practice.")
                    .font(DharmaFont.body(15))
                    .foregroundColor(.dharmaTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                OnboardingProgressDots(activeIndex: 0, total: 6)
                    .padding(.top, DharmaSpacing.sm)
            }
            .padding(.horizontal, DharmaSpacing.xl)

            Spacer()

            VStack(spacing: DharmaSpacing.md) {
                Button {
                    HapticManager.light()
                    goTo(.appearance)
                } label: {
                    Text("Get started")
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: DharmaRadius.md)
                                .fill(Color(hex: "C9821E"))
                        )
                }
            }
            .padding(.horizontal, DharmaSpacing.lg)
            .padding(.bottom, DharmaSpacing.xl)
        }
    }
}
