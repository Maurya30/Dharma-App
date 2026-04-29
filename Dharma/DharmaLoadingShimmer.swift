import SwiftUI

struct DharmaLoadingShimmerModifier: ViewModifier {
    @State private var shimmer = false

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.dharmaGold.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmer ? 300 : -300)
                .animation(
                    .linear(duration: 1.4)
                        .repeatForever(autoreverses: false),
                    value: shimmer
                )
            }
            .clipped()
            .onAppear { shimmer = true }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(DharmaLoadingShimmerModifier())
    }
}

struct DharmaSkeletonCard: View {
    var height: CGFloat = 80

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.dharmaGold.opacity(0.08))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .shimmer()
    }
}
