import SwiftUI

struct OnboardingVerse: Identifiable {
    let id: String
    let source: String
    let sanskrit: String
    let translation: String

    init(source: String, sanskrit: String, translation: String) {
        self.id = source
        self.source = source
        self.sanskrit = sanskrit
        self.translation = translation
    }
}

private let onboardingVerses: [OnboardingVerse] = [
    OnboardingVerse(
        source: "Bhagavad Gita 2.47",
        sanskrit: "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन",
        translation: "You have a right to perform your duties, but you are not entitled to the fruits of your actions."
    ),
    OnboardingVerse(
        source: "Bhagavad Gita 6.5",
        sanskrit: "उद्धरेदात्मनात्मानं नात्मानमवसादयेत्",
        translation: "Elevate yourself through the power of your own mind, and do not degrade yourself."
    ),
    OnboardingVerse(
        source: "Chandogya Upanishad",
        sanskrit: "तत् त्वम् असि",
        translation: "That thou art — you are one with the ultimate reality."
    ),
    OnboardingVerse(
        source: "Bhagavad Gita 2.20",
        sanskrit: "न जायते म्रियते वा कदाचित्",
        translation: "The soul is never born, nor does it die. It is eternal, ancient, and unslain when the body is slain."
    ),
    OnboardingVerse(
        source: "Rig Veda 1.89.1",
        sanskrit: "आ नो भद्राः क्रतवो यन्तु विश्वतः",
        translation: "Let noble thoughts come to us from every direction."
    ),
    OnboardingVerse(
        source: "Bhagavad Gita 9.22",
        sanskrit: "अनन्याश्चिन्तयन्तो मां ये जनाः पर्युपासते",
        translation: "For those who worship me with devotion, I carry what they lack and preserve what they have."
    ),
    OnboardingVerse(
        source: "Mundaka Upanishad 3.1.6",
        sanskrit: "सत्यमेव जयते",
        translation: "Truth alone triumphs — not falsehood."
    ),
    OnboardingVerse(
        source: "Bhagavad Gita 18.66",
        sanskrit: "सर्वधर्मान्परित्यज्य मामेकं शरणं व्रज",
        translation: "Abandon all varieties of dharma and simply surrender unto me. I shall deliver you from all sinful reactions."
    ),
    OnboardingVerse(
        source: "Kena Upanishad 1.3",
        sanskrit: "यन्मनसा न मनुते",
        translation: "That which is not thought by the mind, but by which the mind thinks — know that alone as Brahman."
    ),
    OnboardingVerse(
        source: "Bhagavad Gita 2.14",
        sanskrit: "मात्रास्पर्शास्तु कौन्तेय शीतोष्णसुखदुःखदाः",
        translation: "The contacts of the senses with objects bring cold and heat, pleasure and pain. They come and go and are impermanent — endure them."
    ),
]

struct VerseSwipeOnboardingView: View {
    var onFinished: () -> Void
    var activeStepIndex: Int = 4
    var totalSteps: Int = 6

    @State private var stack: [OnboardingVerse] = onboardingVerses
    @State private var findingPath = false
    @State private var skipPressed = false
    @State private var hasCompleted = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                VStack(spacing: DharmaSpacing.sm) {
                    Text("What speaks to you?")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(.dharmaTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Swipe right on verses that resonate")
                        .font(DharmaFont.body(16))
                        .foregroundColor(.dharmaTextSecondary)
                        .multilineTextAlignment(.center)

                    OnboardingProgressDots(activeIndex: activeStepIndex, total: totalSteps)
                        .padding(.top, DharmaSpacing.xs)
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .padding(.top, DharmaSpacing.lg)

                Spacer(minLength: DharmaSpacing.md)

                if findingPath {
                    Text("Finding your path...")
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.dharmaTextMuted)
                        .transition(.opacity)
                } else {
                    SwipeCardStack(
                        items: $stack,
                        showBadges: false,
                        threshold: 80,
                        maxRotation: 7,
                        stackScales: (1.0, 0.95, 0.90),
                        stackVerticalOffset: 8,
                        onSwipeLeft: { _ in },
                        onSwipeRight: { verse in
                            var profile = OnboardingProfile.load()
                            profile.appendResonantSource(verse.source)
                            profile.save()
                        },
                        cardContent: { verse in
                            verseSwipeCard(verse)
                        }
                    )
                    .frame(height: 460)
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: DharmaSpacing.lg)
            }

            if !findingPath {
                Button {
                    guard !hasCompleted else { return }
                    HapticManager.light()
                    skipPressed = true
                    hasCompleted = true
                    onFinished()
                } label: {
                    Text("Skip")
                        .font(DharmaFont.body(14))
                        .foregroundColor(Color.dharmaGold.opacity(0.7))
                }
                .padding(.top, DharmaSpacing.md)
                .padding(.trailing, DharmaSpacing.lg)
            }
        }
        .dharmaBackground()
        .onChange(of: stack.count) { oldCount, newCount in
            if newCount == 0 && oldCount > 0 && !skipPressed && !hasCompleted {
                hasCompleted = true
                findingPath = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onFinished()
                }
            }
        }
    }

    private func verseSwipeCard(_ verse: OnboardingVerse) -> some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.dharmaGold)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: DharmaSpacing.md) {
                    Text(verse.source.uppercased())
                        .font(DharmaFont.caption(11))
                        .foregroundColor(Color.dharmaGold)
                        .tracking(0.8)

                    Rectangle()
                        .fill(Color.dharmaDivider)
                        .frame(height: 1)

                    Text(verse.sanskrit)
                        .font(DharmaFont.sanskrit(15))
                        .italic()
                        .foregroundColor(Color.dharmaTextPrimary.opacity(0.65))
                        .lineLimit(2)

                    Text(verse.translation)
                        .font(DharmaFont.title(17))
                        .foregroundColor(.dharmaTextBody)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, DharmaSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("ॐ")
                .font(.system(size: 80, weight: .ultraLight, design: .serif))
                .foregroundColor(Color.dharmaGold)
                .opacity(0.05)
                .padding(.trailing, 8)
                .padding(.bottom, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

}
