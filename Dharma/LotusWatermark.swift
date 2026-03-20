import SwiftUI

private struct LotusPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let tip = CGPoint(x: w / 2, y: 0)
        let baseCenter = CGPoint(x: w / 2, y: h)
        let leftMid = CGPoint(x: w * 0.05, y: h * 0.55)
        let rightMid = CGPoint(x: w * 0.95, y: h * 0.55)

        var p = Path()
        p.move(to: baseCenter)
        p.addQuadCurve(to: leftMid, control: CGPoint(x: w * 0.18, y: h * 0.78))
        p.addQuadCurve(to: tip, control: CGPoint(x: w * 0.18, y: h * 0.22))
        p.addQuadCurve(to: rightMid, control: CGPoint(x: w * 0.82, y: h * 0.22))
        p.addQuadCurve(to: baseCenter, control: CGPoint(x: w * 0.82, y: h * 0.78))
        p.closeSubpath()
        return p
    }
}

struct LotusWatermark: View {
    var size: CGFloat
    var opacity: Double? // If nil: defaults to 0.07 light / 0.10 dark

    @Environment(\.colorScheme) private var colorScheme

    init(size: CGFloat = 240, opacity: Double? = nil) {
        self.size = size
        self.opacity = opacity
    }

    private var effectiveOpacity: Double {
        if let opacity { return opacity }
        return colorScheme == .dark ? 0.10 : 0.07
    }

    private let outerPetal = Color(red: 0xBA / 255, green: 0x70 / 255, blue: 0x18 / 255) // #BA7018
    private let midPetal = Color(red: 0xC9 / 255, green: 0x82 / 255, blue: 0x1E / 255)   // #C9821E
    private let innerPetal = Color(red: 0xD4 / 255, green: 0x92 / 255, blue: 0x2A / 255) // #D4922A
    private let innermostPetal = Color(red: 0xE0 / 255, green: 0x98 / 255, blue: 0x30 / 255) // #E09830
    private let centerColor = Color(red: 0xC9 / 255, green: 0x82 / 255, blue: 0x1E / 255) // #C9821E

    var body: some View {
        let dim = size

        ZStack {
            // Petal rings
            petalRing(count: 12, radius: dim * 0.38, petalWidth: dim * 0.12, petalHeight: dim * 0.30, color: outerPetal, angleOffset: 0)
            petalRing(count: 12, radius: dim * 0.32, petalWidth: dim * 0.11, petalHeight: dim * 0.26, color: midPetal, angleOffset: .pi / 12)
            petalRing(count: 10, radius: dim * 0.25, petalWidth: dim * 0.10, petalHeight: dim * 0.22, color: innerPetal, angleOffset: .pi / 10)
            petalRing(count: 10, radius: dim * 0.20, petalWidth: dim * 0.09, petalHeight: dim * 0.18, color: innermostPetal, angleOffset: .pi / 20)

            // Tiny inner buds
            petalRing(count: 8, radius: dim * 0.14, petalWidth: dim * 0.06, petalHeight: dim * 0.10, color: innermostPetal, angleOffset: .pi / 8)

            // Center rosette
            ZStack {
                Circle().fill(centerColor).frame(width: dim * 0.14, height: dim * 0.14)
                Circle().stroke(centerColor.opacity(0.6), lineWidth: dim * 0.02).frame(width: dim * 0.22, height: dim * 0.22)
                Circle().stroke(centerColor.opacity(0.5), lineWidth: dim * 0.012).frame(width: dim * 0.30, height: dim * 0.30)
                Circle().fill(Color.clear).frame(width: dim * 0.32, height: dim * 0.32)
            }
        }
        .frame(width: dim, height: dim)
        .opacity(effectiveOpacity)
    }

    @ViewBuilder
    private func petalRing(count: Int, radius: CGFloat, petalWidth: CGFloat, petalHeight: CGFloat, color: Color, angleOffset: CGFloat) -> some View {
        ForEach(0..<count, id: \.self) { i in
            let angle = (CGFloat(i) / CGFloat(count)) * 2 * .pi + angleOffset
            LotusPetalShape()
                .fill(color)
                .frame(width: petalWidth, height: petalHeight)
                .offset(x: radius * cos(angle), y: radius * sin(angle))
                .rotationEffect(.radians(angle))
        }
    }
}

