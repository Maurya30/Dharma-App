import SwiftUI

struct OmWatermark: View {
    var size: CGFloat = 60
    var opacity: Double = 0.1
    /// SwiftUI: positive = counter-clockwise; use negative for clockwise.
    var rotationDegrees: Double = 0

    var body: some View {
        Text("ॐ")
            .font(.system(size: size, weight: .regular, design: .serif))
            .foregroundColor(Color.dharmaGold)
            .opacity(opacity)
            .rotationEffect(.degrees(rotationDegrees))
    }
}
