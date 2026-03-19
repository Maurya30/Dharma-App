import SwiftUI

struct OmWatermark: View {
    var size: CGFloat = 60
    var opacity: Double = 0.1

    var body: some View {
        Text("ॐ")
            .font(.system(size: size, weight: .regular, design: .serif))
            .foregroundColor(Color.dharmaGold)
            .opacity(opacity)
    }
}
