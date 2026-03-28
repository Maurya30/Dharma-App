import SwiftUI

struct LevelCompleteView: View {
    let completedLevel: PathLevel
    let nextLevel: PathLevel?
    var onBeginNext: () -> Void
    var onDismiss: () -> Void

    @State private var stage = 0
    @State private var petalScales: [CGFloat] = Array(repeating: 0, count: 8)
    @State private var particleOffsets: [CGSize] = (0..<12).map { _ in .zero }
    @State private var particleOpacities: [Double] = Array(repeating: 0, count: 12)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.clear
                .dharmaBackground()

            if stage == 0 {
                bloomStage
            } else if stage == 1 {
                titleStage
            } else {
                nextStage
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if stage == 1 {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    stage = 2
                }
            }
        }
        .onAppear {
            HapticManager.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                HapticManager.success()
            }
            if !reduceMotion {
                startBloom()
            } else {
                stage = 1
            }
        }
    }

    private var bloomStage: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                PetalShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F5C832"), Color.dharmaGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: 120)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .scaleEffect(petalScales[i])
                    .opacity(petalScales[i] > 0 ? 1 : 0)
            }

            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Color.dharmaGold.opacity(0.45))
                    .frame(width: CGFloat(4 + (i % 3)), height: CGFloat(4 + (i % 3)))
                    .offset(particleOffsets[i])
                    .opacity(particleOpacities[i])
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            for i in 0..<8 {
                let delay = Double(i) * 0.05
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                        petalScales[i] = 1
                    }
                }
            }
            for i in 0..<12 {
                let angle = Double(i) / 12.0 * .pi * 2
                let dist: CGFloat = 80 + CGFloat(i % 4) * 15
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 1.5)) {
                        particleOffsets[i] = CGSize(
                            width: cos(angle) * 40 + CGFloat.random(in: -20...20),
                            height: -dist
                        )
                        particleOpacities[i] = 0
                    }
                }
                particleOpacities[i] = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    stage = 1
                }
            }
        }
    }

    private var titleStage: some View {
        VStack(spacing: DharmaSpacing.md) {
            Image(systemName: rewardSymbolName(for: completedLevel.rewardTitle))
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#FFE070"),
                                 Color(hex: "#C9821E")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(32)
                .background(
                    Circle()
                        .fill(Color(hex: "#C9821E").opacity(0.08))
                )
                .scaleEffect(stage == 1 ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0), value: stage)

            Text(completedLevel.rewardTitle)
                .font(.custom("Georgia-Bold", size: 36))
                .foregroundColor(.dharmaTextPrimary)

            Text(completedLevel.rewardMeaning)
                .font(DharmaFont.body(16))
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Rectangle()
                .fill(Color.dharmaGold.opacity(0.35))
                .frame(height: 1)
                .frame(maxWidth: 120)

            Text("Level \(completedLevel.levelNumber) complete")
                .font(DharmaFont.body(14))
                .foregroundColor(.dharmaTextMuted)

            Text("Tap to continue")
                .font(DharmaFont.caption(12))
                .foregroundColor(.dharmaTextMuted.opacity(0.8))
                .padding(.top, 24)
        }
        .padding(DharmaSpacing.xl)
    }

    private var nextStage: some View {
        VStack(spacing: DharmaSpacing.lg) {
            if let next = nextLevel {
                Text("Next: Level \(next.levelNumber)")
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaGold)

                Text(next.levelName)
                    .font(.custom("Georgia-Bold", size: 28))
                    .foregroundColor(.dharmaTextPrimary)

                Image(systemName: "sun.max")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFE070"), Color(hex: "#C9821E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Seven days of guided verses — \(next.levelName.lowercased())")
                    .font(DharmaFont.body(14))
                    .foregroundColor(.dharmaTextSecondary)
                    .multilineTextAlignment(.center)

                Image(systemName: "lock.open.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.dharmaGold)
                    .padding(.top, 8)

                Button {
                    onBeginNext()
                    onDismiss()
                } label: {
                    Text("Begin Level \(next.levelNumber) →")
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: DharmaRadius.md).fill(Color.dharmaGold))
                }
                .padding(.horizontal, DharmaSpacing.lg)
                .padding(.top, DharmaSpacing.md)
            } else {
                Text("Path complete")
                    .font(DharmaFont.title(24))
                    .foregroundColor(.dharmaTextPrimary)
                Button("Done") {
                    onDismiss()
                }
                .font(DharmaFont.heading(16))
                .foregroundColor(.dharmaGold)
            }
        }
        .padding(DharmaSpacing.xl)
    }

    private func startBloom() {
        petalScales = Array(repeating: 0, count: 8)
    }

    private func rewardSymbolName(for title: String) -> String {
        switch title {
        case "Shishya": return "flame"
        case "Sadhaka": return "sparkles"
        case "Gyani":   return "leaf"
        case "Vairagi": return "bolt"
        case "Yogi":    return "sun.horizon"
        default:        return "seal"
        }
    }
}

private struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w, y: h * 0.5))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: 0, y: h * 0.5))
        return p
    }
}
