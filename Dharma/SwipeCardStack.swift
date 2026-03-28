import SwiftUI

/// Tinder-style stacked cards with drag-to-swipe.
struct SwipeCardStack<Item: Identifiable, Content: View>: View {
    @Binding var items: [Item]
    var showBadges: Bool = true
    var threshold: CGFloat = 80
    var maxRotation: CGFloat = 7
    var stackScales: (CGFloat, CGFloat, CGFloat) = (1.0, 0.95, 0.90)
    var stackVerticalOffset: CGFloat = 8
    var onSwipeLeft: (Item) -> Void
    var onSwipeRight: (Item) -> Void
    @ViewBuilder var cardContent: (Item) -> Content

    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let visible = Array(items.prefix(3))
            ZStack {
                ForEach(0..<visible.count, id: \.self) { index in
                    let item = visible[index]
                    let isTop = index == 0
                    let scale: CGFloat = {
                        switch index {
                        case 0: return stackScales.0
                        case 1: return stackScales.1
                        default: return stackScales.2
                        }
                    }()

                    stackedCard(
                        item: item,
                        index: index,
                        isTop: isTop,
                        scale: scale,
                        width: width,
                        visibleCount: visible.count
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func stackedCard(
        item: Item,
        index: Int,
        isTop: Bool,
        scale: CGFloat,
        width: CGFloat,
        visibleCount: Int
    ) -> some View {
        let base = cardContent(item)
            .frame(width: width)
            .scaleEffect(isTop ? 1.0 : scale)
            .offset(y: CGFloat(index) * stackVerticalOffset)
            .offset(isTop ? dragOffset : .zero)
            .rotationEffect(.degrees(isTop ? dragRotation : 0))
            .zIndex(Double(visibleCount - index))
            .overlay(alignment: .center) {
                if showBadges && isTop {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.green)
                            .opacity(min(1, max(0, dragOffset.width / threshold)))
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.red)
                            .opacity(min(1, max(0, -dragOffset.width / threshold)))
                    }
                    .padding(32)
                    .allowsHitTesting(false)
                }
            }

        Group {
            if isTop {
                base.gesture(dragGesture(for: item))
            } else {
                base
            }
        }
    }

    private func dragGesture(for item: Item) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                let progress = min(1, abs(value.translation.width) / threshold)
                dragRotation = Double(progress * maxRotation) * (value.translation.width >= 0 ? 1 : -1)
            }
            .onEnded { value in
                let dx = value.translation.width
                if dx > threshold {
                    HapticManager.medium()
                    let exit: CGFloat = 500
                    withAnimation(.easeOut(duration: 0.22)) {
                        dragOffset = CGSize(width: exit, height: value.translation.height * 0.3)
                        dragRotation = Double(maxRotation)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onSwipeRight(item)
                        items.removeAll { $0.id == item.id }
                        dragOffset = .zero
                        dragRotation = 0
                    }
                } else if dx < -threshold {
                    HapticManager.light()
                    let exit: CGFloat = -500
                    withAnimation(.easeOut(duration: 0.22)) {
                        dragOffset = CGSize(width: exit, height: value.translation.height * 0.3)
                        dragRotation = -Double(maxRotation)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onSwipeLeft(item)
                        items.removeAll { $0.id == item.id }
                        dragOffset = .zero
                        dragRotation = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        dragOffset = .zero
                        dragRotation = 0
                    }
                }
            }
    }
}
