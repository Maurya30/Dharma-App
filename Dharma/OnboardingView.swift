import SwiftUI
import Combine

// MARK: - Onboarding Data
enum DharmaIntention: String, CaseIterable, Identifiable {
    case peace    = "Seeking peace"
    case practice = "Daily practice"
    case study    = "Study the Gita"
    case explore  = "Explore Hindu culture"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .peace:    return "leaf.fill"
        case .practice: return "sun.max.fill"
        case .study:    return "book.fill"
        case .explore:  return "sparkles"
        }
    }
}

enum DharmaPace: String, CaseIterable, Identifiable {
    case fiveMin    = "5 minutes"
    case fifteenMin = "15 minutes"
    case thirtyMin  = "30 minutes"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .fiveMin:    return "One verse a day"
        case .fifteenMin: return "A few verses + reflection"
        case .thirtyMin:  return "Deep study of a chapter"
        }
    }
}

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "dharma_onboarding_done") }
    }
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "dharma_user_name") }
    }
    @Published var intention: String {
        didSet { UserDefaults.standard.set(intention, forKey: "dharma_intention") }
    }
    @Published var pace: String {
        didSet { UserDefaults.standard.set(pace, forKey: "dharma_pace") }
    }

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "dharma_onboarding_done")
        self.userName = UserDefaults.standard.string(forKey: "dharma_user_name") ?? ""
        self.intention = UserDefaults.standard.string(forKey: "dharma_intention") ?? ""
        self.pace = UserDefaults.standard.string(forKey: "dharma_pace") ?? ""
    }

    func complete(name: String, intention: DharmaIntention, pace: DharmaPace) {
        self.userName = name
        self.intention = intention.rawValue
        self.pace = pace.rawValue
        self.hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @ObservedObject var manager: OnboardingManager
    @State private var currentPage = 0
    @State private var name = ""
    @State private var selectedIntention: DharmaIntention? = nil
    @State private var selectedPace: DharmaPace? = nil
    @State private var fadeIn = false

    private var canAdvance: Bool {
        switch currentPage {
        case 0: return true
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return selectedIntention != nil
        case 3: return selectedPace != nil
        default: return false
        }
    }

    var body: some View {
        ZStack {
            Color.dharmaBackground.ignoresSafeArea()

            OmWatermark(size: 240, opacity: 0.06)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 40, y: 40)

            VStack(spacing: 0) {
                Spacer()

                Group {
                    switch currentPage {
                    case 0: welcomePage
                    case 1: namePage
                    case 2: intentionPage
                    case 3: pacePage
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentPage)

                Spacer()

                // Bottom controls
                VStack(spacing: DharmaSpacing.md) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<4) { i in
                            Circle()
                                .fill(i == currentPage ? Color.dharmaGold : Color.dharmaGold.opacity(0.2))
                                .frame(width: i == currentPage ? 8 : 6, height: i == currentPage ? 8 : 6)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }

                    Button {
                        advance()
                    } label: {
                        Text(currentPage == 3 ? "Begin your journey" : currentPage == 0 ? "Get started" : "Continue")
                            .font(DharmaFont.heading(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: DharmaRadius.md)
                                    .fill(canAdvance ? Color.dharmaGold : Color.dharmaGold.opacity(0.3))
                            )
                    }
                    .disabled(!canAdvance)
                    .animation(.easeInOut(duration: 0.2), value: canAdvance)
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .padding(.bottom, DharmaSpacing.xl)
            }
        }
        .opacity(fadeIn ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                fadeIn = true
            }
        }
    }

    private func advance() {
        if currentPage == 3 {
            let finalName = name.trimmingCharacters(in: .whitespaces)
            manager.complete(
                name: finalName,
                intention: selectedIntention ?? .explore,
                pace: selectedPace ?? .fiveMin
            )
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentPage += 1
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: DharmaSpacing.lg) {
            Text("ॐ")
                .font(.system(size: 64, design: .serif))
                .foregroundColor(.dharmaGold)

            Text("Welcome to Dharma")
                .font(DharmaFont.title(28))
                .foregroundColor(.dharmaTextPrimary)

            Text("A sacred space for the Bhagavad Gita,\nancient wisdom, and daily practice.")
                .font(DharmaFont.body(15))
                .foregroundColor(.dharmaTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, DharmaSpacing.xl)
    }

    private var namePage: some View {
        VStack(spacing: DharmaSpacing.lg) {
            Text("What should we call you?")
                .font(DharmaFont.title(24))
                .foregroundColor(.dharmaTextPrimary)

            Text("We'll use this to personalize your experience.")
                .font(DharmaFont.body(14))
                .foregroundColor(.dharmaTextSecondary)

            TextField("Your name", text: $name)
                .font(DharmaFont.heading(18))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, DharmaSpacing.lg)
                .background(Color.dharmaSurface)
                .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DharmaRadius.md)
                        .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
                )
                .padding(.horizontal, DharmaSpacing.xl)
        }
        .padding(.horizontal, DharmaSpacing.lg)
    }

    private var intentionPage: some View {
        VStack(spacing: DharmaSpacing.lg) {
            Text("What brings you\nto Dharma?")
                .font(DharmaFont.title(24))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(DharmaIntention.allCases) { intention in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIntention = intention
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: intention.icon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedIntention == intention ? .dharmaGold : .dharmaTextMuted)
                                .frame(width: 24)

                            Text(intention.rawValue)
                                .font(DharmaFont.body(15))
                                .foregroundColor(selectedIntention == intention ? .dharmaTextPrimary : .dharmaTextSecondary)

                            Spacer()

                            if selectedIntention == intention {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.dharmaGold)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: DharmaRadius.md)
                                .fill(selectedIntention == intention ? Color.dharmaGold.opacity(0.08) : Color.dharmaSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DharmaRadius.md)
                                .strokeBorder(
                                    selectedIntention == intention ? Color.dharmaGold.opacity(0.4) : Color.dharmaCardBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DharmaSpacing.md)
        }
        .padding(.horizontal, DharmaSpacing.md)
    }

    private var pacePage: some View {
        VStack(spacing: DharmaSpacing.lg) {
            Text("How much time do you\nhave each day?")
                .font(DharmaFont.title(24))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(DharmaPace.allCases) { pace in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPace = pace
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(pace.rawValue)
                                    .font(DharmaFont.heading(16))
                                    .foregroundColor(selectedPace == pace ? .dharmaTextPrimary : .dharmaTextSecondary)

                                Text(pace.subtitle)
                                    .font(DharmaFont.caption(12))
                                    .foregroundColor(.dharmaTextMuted)
                            }

                            Spacer()

                            if selectedPace == pace {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.dharmaGold)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: DharmaRadius.md)
                                .fill(selectedPace == pace ? Color.dharmaGold.opacity(0.08) : Color.dharmaSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DharmaRadius.md)
                                .strokeBorder(
                                    selectedPace == pace ? Color.dharmaGold.opacity(0.4) : Color.dharmaCardBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DharmaSpacing.md)
        }
        .padding(.horizontal, DharmaSpacing.md)
    }
}
