import SwiftUI

struct HowDharmaWorksView: View {
    var onContinue: () -> Void
    var activeStepIndex: Int = 1
    var totalSteps: Int = 7

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressDots(activeIndex: activeStepIndex, total: totalSteps)
                .padding(.top, DharmaSpacing.xl)

            ScrollView {
                VStack(spacing: DharmaSpacing.xl) {
                    Text("Your practice, guided by Krishna")
                        .font(DharmaFont.title())
                        .foregroundColor(.dharmaTextPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, DharmaSpacing.md)

                    VStack(spacing: DharmaSpacing.md) {
                        PillarCard(
                            icon: "book.pages",
                            title: "Scripture",
                            text: "A verse chosen for your goals each morning, drawn from the Gita, Upanishads, and Rig Veda."
                        )
                        PillarCard(
                            icon: "circle.hexagongrid",
                            title: "Practice",
                            text: "Three small acts every day — see, feel, offer. A short ritual that shapes your journey."
                        )
                        PillarCard(
                            icon: "sparkles",
                            title: "Krishna",
                            text: "Ask anything. Krishna answers from scripture and remembers where you are on your path."
                        )
                    }

                    Spacer(minLength: DharmaSpacing.lg)
                }
                .padding(.vertical, DharmaSpacing.lg)
            }

            Button {
                HapticManager.light()
                onContinue()
            } label: {
                Text("Continue")
                    .font(DharmaFont.heading(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: DharmaRadius.md)
                            .fill(Color.dharmaGold)
                    )
            }
            .padding(.bottom, DharmaSpacing.xl)
        }
        .padding(.horizontal, 24)
        .dharmaBackground()
    }
}

private struct PillarCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: DharmaSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.dharmaGold)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: DharmaSpacing.xs) {
                Text(title)
                    .font(DharmaFont.heading())
                    .foregroundColor(.dharmaTextPrimary)
                Text(text)
                    .font(DharmaFont.body())
                    .foregroundColor(.dharmaTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(DharmaSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: DharmaRadius.lg)
    }
}

#Preview {
    HowDharmaWorksView(onContinue: {})
}
