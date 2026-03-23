import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: ScriptureStore
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedType: FestivalType? = nil
    @StateObject private var searchService = SearchService()
    @State private var searchResult: ScriptureItem? = nil

    private var filteredFestivals: [HinduFestival] {
        allFestivals
            .filter { $0.year == selectedYear }
            .filter { selectedType == nil || $0.type == selectedType }
            .sorted { $0.date < $1.date }
    }

    private var todayFestivals: [HinduFestival] {
        filteredFestivals.filter { $0.isToday }
    }

    private var upcomingFestivals: [HinduFestival] {
        filteredFestivals.filter { !$0.isPast && !$0.isToday }
    }

    private var pastFestivals: [HinduFestival] {
        filteredFestivals.filter { $0.isPast }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {

                    // Year picker
                    yearPicker
                        .padding(.horizontal, DharmaSpacing.md)

                    // Type filter pills
                    typeFilterPills

                    // Today section
                    if !todayFestivals.isEmpty {
                        SectionHeader(title: "Today")
                            .padding(.horizontal, DharmaSpacing.md)

                        ForEach(todayFestivals) { festival in
                            NavigationLink(destination: FestivalDetailView(festival: festival)) {
                                NextFestivalBanner(festival: festival)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DharmaSpacing.md)
                        }
                    }

                    // Next up banner (if no today festivals)
                    if todayFestivals.isEmpty, let next = upcomingFestivals.first {
                        NextFestivalBanner(festival: next)
                            .padding(.horizontal, DharmaSpacing.md)
                    }

                    // Upcoming
                    if !upcomingFestivals.isEmpty {
                        SectionHeader(title: "Upcoming")
                            .padding(.horizontal, DharmaSpacing.md)

                        ForEach(upcomingFestivals) { festival in
                            NavigationLink(destination: FestivalDetailView(festival: festival)) {
                                FestivalRowView(
                                    festival: festival,
                                    store: store,
                                    searchService: searchService,
                                    onVerseFound: { item in searchResult = item }
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DharmaSpacing.md)
                        }
                    }

                    // Past
                    if !pastFestivals.isEmpty {
                        SectionHeader(title: "Earlier")
                            .padding(.horizontal, DharmaSpacing.md)

                        ForEach(pastFestivals) { festival in
                            NavigationLink(destination: FestivalDetailView(festival: festival)) {
                                FestivalRowView(
                                    festival: festival,
                                    muted: true,
                                    store: store,
                                    searchService: searchService,
                                    onVerseFound: { item in searchResult = item }
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DharmaSpacing.md)
                        }
                    }

                    // Disclaimer
                    Text("Festival dates are approximate and may vary by one day depending on your location and local panchang.")
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaTextMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DharmaSpacing.lg)
                        .padding(.top, DharmaSpacing.md)

                    Spacer(minLength: DharmaSpacing.xxl)
                }
                .padding(.top, DharmaSpacing.md)
            }
            .refreshable {
                try? await Task.sleep(for: .milliseconds(350))
                DharmaHaptics.light()
            }
            .background(Color.dharmaBackground)
            .navigationTitle("Sacred Calendar")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $searchResult) { item in
                ScriptureDetailView(item: item, store: store)
            }
        }
    }

    // MARK: - Year Picker

    private var yearPicker: some View {
        Picker("Year", selection: $selectedYear) {
            Text("2026").tag(2026)
            Text("2027").tag(2027)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedYear) { _, _ in
            DharmaHaptics.selection()
        }
    }

    // MARK: - Type Filter Pills

    private var typeFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "All", type: nil)
                ForEach(FestivalType.allCases, id: \.self) { type in
                    filterPill(label: type.rawValue, type: type)
                }
            }
            .padding(.horizontal, DharmaSpacing.md)
        }
    }

    private func filterPill(label: String, type: FestivalType?) -> some View {
        let isActive = selectedType == type
        return Button {
            DharmaHaptics.selection()
            withAnimation(.easeInOut(duration: 0.2)) { selectedType = type }
        } label: {
            Text(label)
                .font(DharmaFont.caption(12))
                .foregroundColor(isActive ? .white : .dharmaGold)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isActive ? Color.dharmaGold : Color.dharmaGold.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.dharmaGold.opacity(isActive ? 0 : 0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Binding navigation helper
extension ScriptureItem: Hashable {
    static func == (lhs: ScriptureItem, rhs: ScriptureItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Next Festival Banner
struct NextFestivalBanner: View {
    let festival: HinduFestival

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let countdown = festival.countdownText {
                    Text(countdown.uppercased())
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaGold)
                        .kerning(0.5)
                }
                Spacer()
                Text(festival.date.formatted(date: .abbreviated, time: .omitted))
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
            }

            Text(festival.name)
                .font(DharmaFont.title(24))
                .foregroundColor(.dharmaTextPrimary)

            Text(festival.type.rawValue)
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.dharmaGold.opacity(0.12))
                .clipShape(Capsule())

            Text(festival.description)
                .font(DharmaFont.body(14))
                .foregroundColor(.dharmaTextSecondary)
                .lineSpacing(4)
                .lineLimit(3)

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
    var store: ScriptureStore
    var searchService: SearchService
    var onVerseFound: ((ScriptureItem) -> Void)?

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

            // Left border
            Rectangle()
                .fill(muted ? Color.dharmaTextMuted.opacity(0.3) : Color.dharmaGold.opacity(festival.isHighlight ? 0.9 : 0.4))
                .frame(width: festival.isHighlight ? 3 : 2)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(festival.name)
                        .font(DharmaFont.heading(festival.isHighlight ? 16 : 15))
                        .foregroundColor(muted ? .dharmaTextSecondary : .dharmaTextPrimary)

                    if let countdown = festival.countdownText, !muted {
                        Text(countdown)
                            .font(DharmaFont.caption(9))
                            .foregroundColor(.dharmaGold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dharmaGold.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text(festival.type.rawValue)
                        .font(DharmaFont.caption(10))
                        .foregroundColor(.dharmaGold.opacity(muted ? 0.6 : 1))

                    Circle().fill(Color.dharmaTextMuted.opacity(0.3)).frame(width: 3, height: 3)

                    Text(festival.deity.components(separatedBy: " · ").first ?? festival.deity)
                        .font(DharmaFont.caption(10))
                        .foregroundColor(.dharmaTextMuted)
                }

                Text(festival.shortDescription)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaTextMuted)
                    .lineLimit(1)
                    .opacity(muted ? 0.55 : 1.0)

                if festival.isHighlight && !muted {
                    Button {
                        findRelatedVerse()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 9))
                            Text("Find related verse")
                                .font(DharmaFont.caption(10))
                        }
                        .foregroundColor(.dharmaGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.dharmaGold.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
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

    private func findRelatedVerse() {
        let deityName = festival.deity.components(separatedBy: " · ").first ?? festival.deity
        let query = "\(festival.name) \(deityName)"

        Task {
            searchService.search(query: query)
            try? await Task.sleep(for: .seconds(1.5))
            if let first = searchService.results.first,
               let item = store.items.first(where: {
                   $0.textEnglish.hasPrefix(String(first.english.prefix(40)))
               }) {
                onVerseFound?(item)
            }
        }
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
        .environmentObject(ScriptureStore())
}
