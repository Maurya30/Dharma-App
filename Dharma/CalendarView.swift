import SwiftUI

struct CalendarView: View {
    let festivals = HinduFestival.sampleData.sorted { $0.date < $1.date }

    var upcomingFestivals: [HinduFestival] {
        festivals.filter { !$0.isPast }
    }

    var pastFestivals: [HinduFestival] {
        festivals.filter { $0.isPast }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {

                    // Next festival highlight
                    if let next = upcomingFestivals.first {
                        NextFestivalBanner(festival: next)
                            .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Upcoming
                    if !upcomingFestivals.isEmpty {
                        SectionHeader(title: "Upcoming")
                            .padding(.horizontal, DharmaSpacing.md)

                        ForEach(upcomingFestivals) { festival in
                            NavigationLink(destination: FestivalDetailView(festival: festival)) {
                                FestivalRowView(festival: festival)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DharmaSpacing.md)
                        }
                    }

                    // Past festivals (collapsed)
                    if !pastFestivals.isEmpty {
                        SectionHeader(title: "Earlier this year")
                            .padding(.horizontal, DharmaSpacing.md)

                        ForEach(pastFestivals) { festival in
                            NavigationLink(destination: FestivalDetailView(festival: festival)) {
                                FestivalRowView(festival: festival, muted: true)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DharmaSpacing.md)
                        }
                    }

                    Spacer(minLength: DharmaSpacing.xxl)
                }
                .padding(.top, DharmaSpacing.md)
            }
            .background(Color.dharmaBackground)
            .navigationTitle("Sacred Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Next Festival Banner
struct NextFestivalBanner: View {
    let festival: HinduFestival

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(festival.isToday ? "Today" : "Coming up in \(festival.daysUntil) days")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Spacer()
                Text(festival.date.formatted(date: .abbreviated, time: .omitted))
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
            }

            Text(festival.name)
                .font(DharmaFont.title(24))
                .foregroundColor(.dharmaTextPrimary)

            Text(festival.shortDescription)
                .font(DharmaFont.body(14))
                .foregroundColor(.dharmaTextSecondary)

            Text("Deity: \(festival.deity)")
                .font(DharmaFont.caption(12))
                .foregroundColor(.dharmaTextMuted)
                .italic()
        }
        .padding(DharmaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DharmaRadius.lg)
                .fill(Color.dharmaSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: DharmaRadius.lg)
                        .strokeBorder(Color.dharmaGold.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Festival Row
struct FestivalRowView: View {
    let festival: HinduFestival
    var muted: Bool = false

    var body: some View {
        HStack(spacing: DharmaSpacing.md) {
            // Date block
            VStack(spacing: 2) {
                Text(festival.date.formatted(.dateTime.month(.abbreviated)))
                    .font(DharmaFont.caption(11))
                    .foregroundColor(muted ? .dharmaTextMuted : .dharmaGold)
                    .textCase(.uppercase)
                Text(festival.date.formatted(.dateTime.day()))
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(muted ? .dharmaTextMuted : .dharmaTextPrimary)
            }
            .frame(width: 44)

            // Vertical divider
            Rectangle()
                .fill(muted ? Color.dharmaTextMuted.opacity(0.3) : Color.dharmaGold.opacity(0.4))
                .frame(width: 2)
                .clipShape(Capsule())

            // Festival info
            VStack(alignment: .leading, spacing: 4) {
                Text(festival.name)
                    .font(DharmaFont.heading(15))
                    .foregroundColor(muted ? .dharmaTextSecondary : .dharmaTextPrimary)
                Text(festival.shortDescription)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaTextMuted)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.dharmaTextMuted)
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .opacity(muted ? 0.65 : 1.0)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(DharmaFont.caption(12))
            .foregroundColor(.dharmaTextMuted)
            .textCase(.uppercase)
            .kerning(0.8)
    }
}

#Preview {
    CalendarView()
}
