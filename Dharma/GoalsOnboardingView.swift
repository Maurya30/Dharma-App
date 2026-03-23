import SwiftUI

struct GoalsOnboardingView: View {
    @EnvironmentObject var goalsManager: GoalsManager
    @State private var selected: Set<String> = []
    @State private var shakeOffset: CGFloat = 0
    @State private var showLimitMessage = false
    @State private var fadeIn = false
    @Environment(\.colorScheme) private var colorScheme

    private var omOpacity: Double { colorScheme == .dark ? 0.12 : 0.08 }

    private let sections: [(title: String, goals: [GoalDefinition])] = {
        let grouped = Dictionary(grouping: GoalsManager.allGoals, by: \.section)
        return ["Spiritual", "Practice", "Personal Growth"].compactMap { section in
            guard let goals = grouped[section] else { return nil }
            return (title: section, goals: goals)
        }
    }()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.dharmaBackground.ignoresSafeArea()

            OmWatermark(size: 190, opacity: omOpacity, rotationDegrees: -8)
                .fixedSize(horizontal: true, vertical: true)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .padding(.top, -28)
                .padding(.trailing, -52)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DharmaSpacing.lg) {
                        // Header
                        VStack(spacing: DharmaSpacing.md) {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.dharmaGold)
                                .padding(.top, DharmaSpacing.xl)

                            Text("What are you here for?")
                                .font(.custom("Georgia-Bold", size: 28))
                                .foregroundColor(.dharmaTextPrimary)
                                .multilineTextAlignment(.center)

                            Text("Choose 3 goals to shape your journey")
                                .font(DharmaFont.body(16))
                                .foregroundColor(.dharmaTextSecondary)
                        }
                        .padding(.horizontal, DharmaSpacing.lg)

                        // Limit message
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

                        // Goal sections
                        ForEach(sections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: DharmaSpacing.md) {
                                Text(section.title)
                                    .font(DharmaFont.caption(11))
                                    .foregroundColor(.dharmaGold)
                                    .textCase(.uppercase)
                                    .kerning(0.8)
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

                // Bottom actions
                VStack(spacing: DharmaSpacing.md) {
                    Button {
                        goalsManager.saveGoals(Array(selected))
                        goalsManager.completeGoalSelection()
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
                        goalsManager.completeGoalSelection()
                    } label: {
                        Text("Skip for now")
                            .font(DharmaFont.caption(14))
                            .foregroundColor(.dharmaTextMuted)
                    }
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .padding(.bottom, DharmaSpacing.xl)
                .background(Color.dharmaBackground)
            }
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
                    DharmaHaptics.selection()
                } else if selected.count < 3 {
                    selected.insert(name)
                    showLimitMessage = false
                    DharmaHaptics.selection()
                } else {
                    triggerShake()
                }
            }
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(GoalsManager.shortName(for: name))
                    .font(DharmaFont.body(14))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.dharmaGold : Color.dharmaSurface)
            .foregroundColor(isSelected ? .white : .dharmaTextBody)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.dharmaCardBorder, lineWidth: 1)
            )
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
