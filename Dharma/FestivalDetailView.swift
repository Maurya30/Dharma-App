import SwiftUI

struct FestivalDetailView: View {
    let festival: HinduFestival

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DharmaSpacing.lg) {

                // Date & deity
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(festival.date.formatted(date: .complete, time: .omitted))
                            .font(DharmaFont.caption(13))
                            .foregroundColor(.dharmaGold)
                        Text("Deity: \(festival.deity)")
                            .font(DharmaFont.caption(13))
                            .foregroundColor(.dharmaTextMuted)
                            .italic()
                    }
                    Spacer()
                    if festival.isToday {
                        Text("Today")
                            .font(DharmaFont.caption(12))
                            .foregroundColor(.dharmaGold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dharmaGold.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Divider().background(Color.dharmaTextMuted.opacity(0.3))

                // Story
                InfoSection(title: "The Story", content: festival.fullStory)

                // Significance
                InfoSection(title: "Why It Matters", content: festival.significance)

                // How to observe
                InfoSection(title: "How to Observe", content: festival.howToObserve)

                Spacer(minLength: DharmaSpacing.xxl)
            }
            .padding(DharmaSpacing.lg)
        }
        .background(Color.dharmaBackground)
        .navigationTitle(festival.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct InfoSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaGold)
                .textCase(.uppercase)
                .kerning(0.8)

            Text(content)
                .font(DharmaFont.body())
                .foregroundColor(.dharmaTextPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
    }
}

#Preview {
    NavigationStack {
        FestivalDetailView(festival: HinduFestival.sampleData[0])
    }
}
