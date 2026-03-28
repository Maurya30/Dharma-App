import SwiftUI

struct AppearanceOnboardingView: View {
    var onContinue: () -> Void
    var activeStepIndex: Int = 1

    @AppStorage("userDarkMode") private var userDarkMode: Bool = false
    @State private var selectionIsDark: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: DharmaSpacing.md) {
                Text("Choose your light")
                    .font(DharmaFont.title(28))
                    .foregroundColor(.dharmaTextPrimary)
                    .multilineTextAlignment(.center)

                Text("You can change this anytime in Settings")
                    .font(DharmaFont.body(15))
                    .foregroundColor(.dharmaTextSecondary)
                    .multilineTextAlignment(.center)

                OnboardingProgressDots(activeIndex: activeStepIndex, total: 4)
                    .padding(.top, DharmaSpacing.sm)
            }
            .padding(.horizontal, DharmaSpacing.xl)
            .padding(.top, DharmaSpacing.xl)

            Spacer(minLength: DharmaSpacing.lg)

            HStack(spacing: DharmaSpacing.md) {
                appearancePickCard(
                    isDark: false,
                    title: "Light",
                    sublabel: "Warm parchment",
                    gradient: [Color(hex: "FBF0DC"), Color(hex: "EDD9A3")]
                )
                appearancePickCard(
                    isDark: true,
                    title: "Dark",
                    sublabel: "Sacred night",
                    gradient: [Color(hex: "2A1F0A"), Color(hex: "1A1206")]
                )
            }
            .padding(.horizontal, DharmaSpacing.lg)

            Spacer(minLength: DharmaSpacing.lg)

            Button {
                HapticManager.light()
                withAnimation(.easeInOut(duration: 0.3)) {
                    userDarkMode = selectionIsDark
                }
                var profile = OnboardingProfile.load()
                profile.darkMode = selectionIsDark
                profile.save()
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
            .padding(.horizontal, DharmaSpacing.lg)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .dharmaBackground()
        .onAppear {
            selectionIsDark = userDarkMode
        }
    }

    private func appearancePickCard(
        isDark: Bool,
        title: String,
        sublabel: String,
        gradient: [Color]
    ) -> some View {
        let selected = selectionIsDark == isDark
        return Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectionIsDark = isDark
                userDarkMode = isDark
            }
            var profile = OnboardingProfile.load()
            profile.darkMode = isDark
            profile.save()
        } label: {
            VStack(spacing: DharmaSpacing.sm) {
                ZStack {
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
                    Text("ॐ")
                        .font(.system(size: 28, weight: .ultraLight, design: .serif))
                        .foregroundColor(Color.dharmaGold)
                        .opacity(0.15)
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                        .strokeBorder(
                            selected ? Color.dharmaGold : Color.dharmaGold.opacity(0.2),
                            lineWidth: selected ? 2 : 1
                        )
                )
                .scaleEffect(selected ? 1.02 : 1.0)

                Text(title)
                    .font(DharmaFont.heading(17))
                    .foregroundColor(.dharmaTextPrimary)

                Text(sublabel)
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
