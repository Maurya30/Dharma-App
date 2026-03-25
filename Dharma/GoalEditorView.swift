import SwiftUI

struct GoalEditorView: View {
    @EnvironmentObject var goalsManager: GoalsManager
    @State private var selectedGoals: Set<String> = []
    @State private var shakeOffset: CGFloat = 0
    @State private var showLimitMessage = false
    @Environment(\.dismiss) private var dismiss

    private let sections: [(title: String, goals: [GoalDefinition])] = {
        let grouped = Dictionary(grouping: GoalsManager.allGoals, by: \.section)
        return ["Spiritual", "Practice", "Personal Growth"].compactMap { section in
            guard let goals = grouped[section] else { return nil }
            return (title: section, goals: goals)
        }
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DharmaSpacing.lg) {
                        // Header
                        VStack(spacing: DharmaSpacing.md) {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.dharmaGold)
                                .padding(.top, DharmaSpacing.xl)

                            Text("Edit Goals")
                                .font(.custom("Georgia-Bold", size: 28))
                                .foregroundColor(.dharmaTextPrimary)
                                .multilineTextAlignment(.center)

                            Text("Select up to 10 goals")
                                .font(DharmaFont.body(16))
                                .foregroundColor(.dharmaTextSecondary)
                        }
                        .padding(.horizontal, DharmaSpacing.lg)

                        // Limit message
                        if showLimitMessage {
                            Text("Maximum 10 goals")
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
                .scrollContentBackground(.hidden)

                // Save button
                VStack(spacing: 0) {
                    Button {
                        goalsManager.saveGoals(Array(selectedGoals))
                        dismiss()
                    } label: {
                        Text("Save goals")
                            .font(DharmaFont.heading(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: DharmaRadius.md)
                                    .fill(selectedGoals.isEmpty
                                          ? Color.dharmaGold.opacity(0.3)
                                          : Color.dharmaGold)
                            )
                    }
                    .disabled(selectedGoals.isEmpty)
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .padding(.vertical, DharmaSpacing.md)
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .tint(Color(hex: "C9821E"))
                }
            }
            .onAppear {
                selectedGoals = Set(goalsManager.selectedGoals)
            }
            .transparentNavigationBar()
            .dharmaBackground()
        }
    }

    private func goalPill(_ name: String) -> some View {
        let isSelected = selectedGoals.contains(name)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedGoals.remove(name)
                    showLimitMessage = false
                    DharmaHaptics.selection()
                } else if selectedGoals.count < 10 {
                    selectedGoals.insert(name)
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
