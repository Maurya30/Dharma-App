import SwiftUI

enum ShareCardSize {
    case square
    case tall

    var width: CGFloat { 1080 }
    var height: CGFloat { self == .square ? 1080 : 1920 }
}

private extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let a = alpha
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

struct ShareCardView: View {
    let item: ScriptureItem
    let size: ShareCardSize

    @Environment(\.colorScheme) private var colorScheme

    private var scale: CGFloat { size.height / 1080 }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1A1206") : Color(hex: "FAF6ED")
    }

    private var verseTextColor: Color {
        colorScheme == .dark ? Color(hex: "F5E6C8") : Color(hex: "2A1A00")
    }

    private var speakerMutedColor: Color {
        colorScheme == .dark ? Color.dharmaTextSecondary.opacity(0.95) : Color.dharmaTextSecondary.opacity(1.0)
    }

    private var referenceLine: String {
        switch item.category {
        case .gita:
            let ref = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "").trimmingCharacters(in: .whitespaces)
            return "BG \(ref)"
        case .upanishads:
            return item.source
        case .rigVeda:
            let ref = item.source.replacingOccurrences(of: "Rig Veda ", with: "").trimmingCharacters(in: .whitespaces)
            return "RV \(ref)"
        case .mantras:
            return item.source
        }
    }

    private var speakerContextLine: String {
        guard let speaker = item.title.split(separator: "—").first.map({ String($0).trimmingCharacters(in: .whitespaces) }) else {
            return ""
        }
        switch speaker {
        case "Krishna": return "Krishna speaks to Arjuna"
        case "Arjuna": return "Arjuna speaks to Krishna"
        case "Sanjaya": return "Sanjaya speaks to Dhritarashtra"
        case "Dhritarashtra": return "Dhritarashtra speaks to Sanjaya"
        default: return speaker
        }
    }

    private var lotusSize: CGFloat { size.height * 0.40 }

    var body: some View {
        let cornerRadius = 64 * scale

        ZStack(alignment: .topLeading) {
            // Card background + border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(cardBackground)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.dharmaGold.opacity(0.35), lineWidth: 6 * scale)

            VStack(alignment: .leading, spacing: 0) {
                // Top left badge
                Text(item.category.rawValue)
                    .font(DharmaFont.heading(54 * scale))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 34 * scale)
                    .padding(.vertical, 18 * scale)
                    .background(Color.dharmaGold.opacity(0.10))
                    .clipShape(Capsule())
                    .padding(.top, 54 * scale)
                    .padding(.leading, 54 * scale)

                VStack(alignment: .leading, spacing: 22 * scale) {
                    // Reference line
                    Text(referenceLine)
                        .font(DharmaFont.caption(44 * scale))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    // Verse text
                    Text(item.textEnglish)
                        .font(DharmaFont.georgia(78 * scale))
                        .foregroundColor(verseTextColor)
                        .lineSpacing(14 * scale)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 6 * scale)
                }
                .padding(.top, 44 * scale)
                .padding(.horizontal, 54 * scale)

                // Rule separator
                Rectangle()
                    .fill(Color.dharmaGold)
                    .frame(height: 2 * scale)
                    .padding(.horizontal, 54 * scale)
                    .padding(.top, 40 * scale)

                // Speaker context
                HStack(alignment: .top) {
                    Text(speakerContextLine)
                        .font(DharmaFont.caption(46 * scale))
                        .foregroundColor(speakerMutedColor)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.horizontal, 54 * scale)
                .padding(.top, 26 * scale)

                Spacer(minLength: 0)
            }

            // Wordmark bottom-left
            VStack {
                Spacer()
                HStack {
                    Text("DHARMA")
                        .font(DharmaFont.heading(44 * scale))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .tracking(2)
                    Spacer()
                }
                .padding(.leading, 54 * scale)
                .padding(.bottom, 62 * scale)
            }

            // Lotus watermark bottom-right (clipped by card bounds)
            LotusWatermark(size: lotusSize, opacity: 0.07)
                .frame(width: lotusSize, height: lotusSize)
                .position(x: size.width - lotusSize * 0.05, y: size.height - lotusSize * 0.05)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

