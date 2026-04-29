import Combine
import SwiftUI

struct GoalsOnboardingView: View {
    @EnvironmentObject var goalsManager: GoalsManager
    @State private var selected: Set<String> = []
    @State private var shakeOffset: CGFloat = 0
    @State private var showLimitMessage = false
    @State private var fadeIn = false

    /// When set, navigating to verse swipe is handled by the parent instead of completing goal selection immediately.
    var onGoalsFinished: (() -> Void)? = nil
    var activeStepIndex: Int? = nil
    var totalSteps: Int = 7

    private let sections: [(title: String, goals: [GoalDefinition])] = {
        let grouped = Dictionary(grouping: GoalsManager.allGoals, by: \.section)
        return ["Spiritual", "Practice", "Personal Growth"].compactMap { section in
            guard let goals = grouped[section] else { return nil }
            return (title: section, goals: goals)
        }
    }()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DharmaSpacing.lg) {
                    VStack(spacing: DharmaSpacing.md) {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.dharmaGold)
                            .padding(.top, DharmaSpacing.xl)

                        Text("What are you here for?")
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(.dharmaTextPrimary)
                            .multilineTextAlignment(.center)

                        Text("Your goals shape your daily verse, your Sadhana prompts, and what context Krishna has when you speak.")
                            .font(.system(size: 11))
                            .foregroundColor(.dharmaTextMuted)
                            .multilineTextAlignment(.center)

                        Text("Choose 3 goals to shape your journey")
                            .font(DharmaFont.body(16))
                            .foregroundColor(.dharmaTextSecondary)

                        if let idx = activeStepIndex {
                            OnboardingProgressDots(activeIndex: idx, total: totalSteps)
                                .padding(.top, DharmaSpacing.xs)
                        }
                    }
                    .padding(.horizontal, DharmaSpacing.lg)

                    if showLimitMessage {
                        Text("Choose only 3 goals")
                            .font(DharmaFont.caption(13))
                            .foregroundColor(.dharmaGold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.dharmaGold.opacity(0.12))
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    Text("Choose up to 3 that feel true right now.")
                        .font(.system(size: 10))
                        .foregroundColor(Color.dharmaGold.opacity(0.65))
                        .italic()
                        .padding(.horizontal, DharmaSpacing.lg)

                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
                            Text(section.title.uppercased())
                                .font(DharmaFont.caption(11))
                                .foregroundColor(.dharmaGold)
                                .tracking(0.8)
                                .padding(.horizontal, DharmaSpacing.md)

                            FlowLayout(spacing: 10) {
                                ForEach(section.goals) { goal in
                                    goalPill(goal.name)
                                }
                            }
                            .padding(.horizontal, DharmaSpacing.md)
                        }
                    }

                    Spacer(minLength: 120)
                }
            }

            VStack(spacing: DharmaSpacing.md) {
                Button {
                    goalsManager.saveGoals(Array(selected))
                    if let onGoalsFinished {
                        onGoalsFinished()
                    } else {
                        goalsManager.completeGoalSelection()
                    }
                } label: {
                    Text("Begin your journey")
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: DharmaRadius.md)
                                .fill(selected.count == 3 ? Color.dharmaGold : Color.dharmaGold.opacity(0.3))
                        )
                }
                .disabled(selected.count != 3)

                Button {
                    if let onGoalsFinished {
                        onGoalsFinished()
                    } else {
                        goalsManager.completeGoalSelection()
                    }
                } label: {
                    Text("Skip for now")
                        .font(DharmaFont.caption(14))
                        .foregroundColor(.dharmaTextMuted)
                }
            }
            .padding(.horizontal, DharmaSpacing.lg)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .opacity(fadeIn ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { fadeIn = true }
        }
    }

    private func goalPill(_ name: String) -> some View {
        let isSelected = selected.contains(name)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selected.remove(name)
                    showLimitMessage = false
                    HapticManager.medium()
                } else if selected.count < 3 {
                    selected.insert(name)
                    showLimitMessage = false
                    HapticManager.light()
                } else {
                    triggerShake()
                }
            }
        } label: {
            Group {
                if isSelected {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .transition(.scale.combined(with: .opacity))
                        Text(GoalsManager.shortName(for: name))
                            .font(DharmaFont.body(14))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(Capsule().fill(Color.dharmaGold))
                } else {
                    Text(GoalsManager.shortName(for: name))
                        .font(DharmaFont.body(14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundColor(.dharmaTextPrimary)
                        .glassCapsuleCard()
                }
            }
            .offset(x: shakeOffset)
        }
        .buttonStyle(.plain)
    }

    private func triggerShake() {
        DharmaHaptics.warning()
        withAnimation(.easeInOut(duration: 0.05)) { showLimitMessage = true }
        withAnimation(.default) { shakeOffset = 8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = 4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) { shakeOffset = 0 }
        }
    }
}

// MARK: - Flow Layout (wrapping pills)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (offsets, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
