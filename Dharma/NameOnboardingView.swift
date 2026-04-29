import SwiftUI

struct NameOnboardingView: View {
    @ObservedObject var manager: OnboardingManager
    var onContinue: () -> Void
    var activeStepIndex: Int = 3
    var totalSteps: Int = 7

    @State private var name: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool {
        trimmedName.count >= 1
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: DharmaSpacing.md) {
                Text("What should Krishna call you?")
                    .font(.system(size: 24, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Krishna will address you by name in every conversation.")
                    .font(.system(size: 11))
                    .foregroundColor(.dharmaTextMuted)
                    .multilineTextAlignment(.center)

                OnboardingProgressDots(activeIndex: activeStepIndex, total: totalSteps)
                    .padding(.top, DharmaSpacing.sm)
            }
            .padding(.horizontal, DharmaSpacing.xl)
            .padding(.top, DharmaSpacing.xl)

            Spacer(minLength: DharmaSpacing.lg)

            TextField("Your name", text: $name)
                .font(.system(size: 18, design: .serif))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                        .stroke(Color.dharmaGold.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
                .padding(.horizontal, DharmaSpacing.lg)

            Spacer(minLength: DharmaSpacing.lg)

            Button {
                HapticManager.light()
                manager.userName = trimmedName
                onContinue()
            } label: {
                Text("Continue")
                    .font(DharmaFont.heading(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: DharmaRadius.md)
                            .fill(Color(hex: "C9821E"))
                    )
            }
            .disabled(!canContinue)
            .opacity(canContinue ? 1 : 0.4)
            .padding(.horizontal, DharmaSpacing.lg)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .dharmaBackground()
        .onAppear {
            let existing = UserDefaults.standard.string(forKey: "dharma_user_name") ?? ""
            if name.isEmpty, !existing.isEmpty {
                name = existing
            }
        }
    }
}
