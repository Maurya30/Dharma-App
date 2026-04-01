import SwiftUI

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var store: ScriptureStore
    @EnvironmentObject private var notificationNav: NotificationNavigationState
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedType: FestivalType? = nil
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDate: Date? = nil
    @StateObject private var searchService = SearchService()
    @State private var searchResult: ScriptureItem? = nil

    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    // MARK: - Filtered festivals

    private var filteredFestivals: [HinduFestival] {
        allFestivals
            .filter { $0.year == selectedYear }
            .filter { selectedType == nil || $0.type == selectedType }
            .sorted { $0.date < $1.date }
    }

    private var festivalsInMonth: [HinduFestival] {
        filteredFestivals.filter {
            Calendar.current.component(.month, from: $0.date) == selectedMonth &&
            Calendar.current.component(.year, from: $0.date) == selectedYear
        }
    }

    private var festivalsForSelectedDate: [HinduFestival] {
        guard let d = selectedDate else { return [] }
        return filteredFestivals.filter {
            Calendar.current.isDate($0.date, inSameDayAs: d)
        }
    }

    private var todayFestivals: [HinduFestival] {
        festivalsInMonth.filter { $0.isToday }
    }

    private var upcomingFestivals: [HinduFestival] {
        festivalsInMonth.filter { !$0.isPast && !$0.isToday }
    }

    private var pastFestivals: [HinduFestival] {
        festivalsInMonth.filter { $0.isPast }
    }

    // MARK: - Calendar grid helpers

    private var daysInMonth: [Date?] {
        var cal = Calendar.current
        cal.firstWeekday = 1
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = 1
        guard let firstDay = cal.date(from: comps) else { return [] }
        let weekday = cal.component(.weekday, from: firstDay) - 1
        let range = cal.range(of: .day, in: .month, for: firstDay)!
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            comps.day = day
            days.append(cal.date(from: comps))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func festivalsOn(_ date: Date) -> [HinduFestival] {
        filteredFestivals.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let sel = selectedDate else { return false }
        return Calendar.current.isDate(sel, inSameDayAs: date)
    }

    private var monthName: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM"
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = 1
        let date = Calendar.current.date(from: comps) ?? Date()
        return df.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {

                    // Year picker
                    yearPicker
                        .padding(.horizontal, DharmaSpacing.md)

                    // Type filter pills
                    typeFilterPills

                    // Month calendar card
                    monthCalendarCard
                        .padding(.horizontal, DharmaSpacing.md)

                    // Festival list — selected date or full month
                    if selectedDate != nil {
                        selectedDateSection
                    } else {
                        monthFestivalList
                    }

                    // Disclaimer
                    Text("Festival dates are approximate and may vary by one day depending on your location and local panchang.")
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaTextMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DharmaSpacing.lg)
                        .padding(.top, DharmaSpacing.xs)

                    Spacer(minLength: DharmaSpacing.xxl)
                }
                .padding(.top, DharmaSpacing.md)
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                try? await Task.sleep(for: .milliseconds(350))
                DharmaHaptics.light()
            }
            .navigationTitle("Sacred Calendar")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $searchResult) { item in
                ScriptureDetailView(item: item, store: store)
            }
            .transparentNavigationBar()
            .dharmaBackground()
            .onChange(of: notificationNav.pendingFestivalDate) { _, dateStr in
                guard let dateStr, !dateStr.isEmpty else { return }
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                df.locale = Locale(identifier: "en_US_POSIX")
                guard let d = df.date(from: dateStr) else {
                    notificationNav.resetFestivalHighlight()
                    return
                }
                let cal = Calendar.current
                selectedYear = cal.component(.year, from: d)
                selectedMonth = cal.component(.month, from: d)
                selectedDate = d
                notificationNav.resetFestivalHighlight()
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
            selectedDate = nil
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
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedType = type
                selectedDate = nil
            }
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

    // MARK: - Month Calendar Card

    private var monthCalendarCard: some View {
        VStack(spacing: DharmaSpacing.sm) {

            // Month navigation header
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedMonth == 1 {
                            selectedMonth = 12
                            selectedYear = max(2026, selectedYear - 1)
                        } else {
                            selectedMonth -= 1
                        }
                        selectedDate = nil
                    }
                    DharmaHaptics.selection()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dharmaGold)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text("\(monthName) \(String(selectedYear))")
                    .font(DharmaFont.heading(16))
                    .foregroundColor(.dharmaTextPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedMonth == 12 {
                            selectedMonth = 1
                            selectedYear = min(2027, selectedYear + 1)
                        } else {
                            selectedMonth += 1
                        }
                        selectedDate = nil
                    }
                    DharmaHaptics.selection()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dharmaGold)
                        .frame(width: 32, height: 32)
                }
            }

            // Weekday headers
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 0
            ) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                }
            }

            // Day cells
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            festivals: festivalsOn(date),
                            isToday: isToday(date),
                            isSelected: isSelected(date)
                        )
                        .onTapGesture {
                            let festivals = festivalsOn(date)
                            guard !festivals.isEmpty else { return }
                            DharmaHaptics.selection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isSelected(date) {
                                    selectedDate = nil
                                } else {
                                    selectedDate = date
                                }
                            }
                        }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }

            // Footer: count + clear button
            HStack {
                if !festivalsInMonth.isEmpty {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.dharmaGold)
                            .frame(width: 5, height: 5)
                        Text("\(festivalsInMonth.count) festival\(festivalsInMonth.count == 1 ? "" : "s") this month")
                            .font(DharmaFont.caption(11))
                            .foregroundColor(.dharmaTextMuted)
                    }
                }
                Spacer()
                if selectedDate != nil {
                    Button("Clear") {
                        withAnimation { selectedDate = nil }
                    }
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                }
            }
            .padding(.top, DharmaSpacing.xs)
        }
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.lg)
    }

    // MARK: - Selected Date Section

    @ViewBuilder
    private var selectedDateSection: some View {
        if festivalsForSelectedDate.isEmpty {
            Text("No festivals on this day")
                .font(DharmaFont.body())
                .foregroundColor(.dharmaTextMuted)
                .padding(.horizontal, DharmaSpacing.md)
        } else {
            VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                if let d = selectedDate {
                    SectionHeader(title: d.formatted(date: .complete, time: .omitted))
                        .padding(.horizontal, DharmaSpacing.md)
                }

                ForEach(festivalsForSelectedDate) { festival in
                    NavigationLink(destination: FestivalDetailView(festival: festival)) {
                        NextFestivalBanner(festival: festival)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DharmaSpacing.md)
                }
            }
        }
    }

    // MARK: - Full Month Festival List

    @ViewBuilder
    private var monthFestivalList: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {

            // Today
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

            // Next up banner if nothing today
            if todayFestivals.isEmpty, let next = upcomingFestivals.first {
                NavigationLink(destination: FestivalDetailView(festival: next)) {
                    NextFestivalBanner(festival: next)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DharmaSpacing.md)
            }

            // Remaining upcoming
            let remaining = todayFestivals.isEmpty ? Array(upcomingFestivals.dropFirst()) : upcomingFestivals
            if !remaining.isEmpty {
                SectionHeader(title: "Upcoming")
                    .padding(.horizontal, DharmaSpacing.md)
                ForEach(remaining) { festival in
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

            // Empty state
            if festivalsInMonth.isEmpty {
                VStack(spacing: DharmaSpacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 32))
                        .foregroundColor(.dharmaTextMuted)
                    Text("No festivals in \(monthName)")
                        .font(DharmaFont.body())
                        .foregroundColor(.dharmaTextMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DharmaSpacing.xl)
            }
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let festivals: [HinduFestival]
    let isToday: Bool
    let isSelected: Bool

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }

    private var hasHighlight: Bool {
        festivals.contains { $0.isHighlight }
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Today ring
                if isToday && !isSelected {
                    Circle()
                        .strokeBorder(Color.dharmaGold, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }
                // Selected fill
                if isSelected {
                    Circle()
                        .fill(Color.dharmaGold)
                        .frame(width: 32, height: 32)
                }

                Text(dayNumber)
                    .font(.system(
                        size: 14,
                        weight: festivals.isEmpty ? .regular : .semibold
                    ))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday    ? .dharmaGold :
                        !festivals.isEmpty ? .dharmaTextPrimary :
                        .dharmaTextPrimary
                    )
            }
            .frame(width: 32, height: 32)

            // Festival dots
            if !festivals.isEmpty {
                HStack(spacing: 2) {
                    ForEach(0..<min(festivals.count, 3), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.8) :
                                  hasHighlight ? Color.dharmaGold : Color.dharmaGold.opacity(0.5))
                            .frame(width: 4, height: 4)
                    }
                }
            } else {
                Color.clear.frame(height: 4)
            }
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: - Hashable conformance for navigation
extension ScriptureItem: Hashable {
    static func == (lhs: ScriptureItem, rhs: ScriptureItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
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
        .glassCard(cornerRadius: DharmaRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                .strokeBorder(Color.dharmaGold.opacity(0.35), lineWidth: 0.5)
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

            // Left accent border
            Rectangle()
                .fill(muted
                      ? Color.dharmaTextMuted.opacity(0.3)
                      : Color.dharmaGold.opacity(festival.isHighlight ? 0.9 : 0.4))
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
                    Circle()
                        .fill(Color.dharmaTextMuted.opacity(0.3))
                        .frame(width: 3, height: 3)
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
                    Button { findRelatedVerse() } label: {
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
        .glassCard(cornerRadius: DharmaRadius.md)
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
