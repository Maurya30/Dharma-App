import SwiftUI
import UIKit

// MARK: - Haptics

enum DharmaHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Shimmer

struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        Group {
            if reduceMotion {
                content.opacity(0.55)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    let cycle: Double = 1.35
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let p = (t.truncatingRemainder(dividingBy: cycle)) / cycle

                    content
                        .overlay {
                            GeometryReader { geo in
                                let w = geo.size.width
                                let band = max(w * 0.55, 80)
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        Color.white.opacity(0.42),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: band)
                                .offset(x: -band + CGFloat(p) * (w + band))
                            }
                        }
                        .mask(content)
                }
            }
        }
    }
}

extension View {
    func dharmaShimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Semantic search skeleton rows

struct SemanticSearchSkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dharmaTextMuted.opacity(0.15))
                    .frame(width: 88, height: 14)
                    .dharmaShimmer()
                Spacer()
            }
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dharmaTextMuted.opacity(0.12))
                .frame(height: 16)
                .dharmaShimmer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dharmaTextMuted.opacity(0.1))
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .dharmaShimmer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dharmaTextMuted.opacity(0.1))
                .frame(width: 120, height: 12)
                .dharmaShimmer()
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Related verse skeleton cards (horizontal)

struct RelatedVerseSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dharmaGold.opacity(0.15))
                .frame(width: 72, height: 12)
                .dharmaShimmer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dharmaTextMuted.opacity(0.12))
                .frame(width: 160, height: 13)
                .dharmaShimmer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dharmaTextMuted.opacity(0.1))
                .frame(width: 150, height: 13)
                .dharmaShimmer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dharmaTextMuted.opacity(0.1))
                .frame(width: 90, height: 10)
                .dharmaShimmer()
        }
        .padding(DharmaSpacing.md)
        .frame(width: 200, alignment: .topLeading)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Warm empty state

struct WarmEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var hint: String? = nil

    var body: some View {
        VStack(spacing: DharmaSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.dharmaGold.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.dharmaGold.opacity(0.9), .dharmaGold.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 8)

            Text(title)
                .font(DharmaFont.georgia(20))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(DharmaFont.body(15))
                .foregroundColor(.dharmaTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if let hint = hint {
                Text(hint)
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(DharmaSpacing.xl)
    }
}
