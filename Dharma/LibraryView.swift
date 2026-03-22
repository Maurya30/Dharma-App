import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: ScriptureStore
    @StateObject private var searchService = SearchService()
    @State private var searchText = ""
    @State private var selectedCategory: ScriptureCategory? = nil
    @State private var showFilterSheet = false
    @State private var showFavouritesPage = false
    @State private var selectedChapter: Int? = nil
    @State private var selectedSpeaker: String? = nil
    @State private var selectedUpanishadSource: String? = nil
    @State private var selectedRigVedaBook: Int? = nil

    private var isSemanticQuery: Bool {
        searchText.split(separator: " ").count >= 3
    }

    private var useSemanticResults: Bool {
        isSemanticQuery && !searchService.results.isEmpty
    }

    /// Map a semantic SearchResult to the best local ScriptureItem match.
    private func matchedItem(for result: SearchResult) -> ScriptureItem? {
        store.items.first {
            $0.textEnglish.hasPrefix(String(result.english.prefix(40)))
        }
    }

    /// Local keyword-filtered items (original behaviour).
    var filteredItems: [ScriptureItem] {
        var items = store.items
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
        }
        if let chapter = selectedChapter {
            items = items.filter { $0.subtitle.contains("Chapter \(chapter) ·") }
        }
        if let speaker = selectedSpeaker {
            items = items.filter { $0.title.hasPrefix(speaker) }
        }
        if let source = selectedUpanishadSource {
            items = items.filter { $0.category == .upanishads && $0.source == source }
        }
        if let book = selectedRigVedaBook {
            items = items.filter { $0.category == .rigVeda && $0.title.hasPrefix("Book \(book) ·") }
        }
        if !searchText.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.textEnglish.localizedCaseInsensitiveContains(searchText) ||
                $0.source.localizedCaseInsensitiveContains(searchText)
            }
        }
        return items
    }

    var hasActiveFilters: Bool {
        selectedChapter != nil || selectedSpeaker != nil || selectedUpanishadSource != nil || selectedRigVedaBook != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    CategoryFilterView(selected: $selectedCategory)
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.top, DharmaSpacing.sm)
                        .padding(.bottom, DharmaSpacing.md)

                    if searchText.isEmpty && !hasActiveFilters {
                        if selectedCategory == .gita {
                            browseByLink(
                                destination: ChapterListView(),
                                icon: "list.number",
                                title: "Browse by Chapter",
                                subtitle: "18 chapters · \(store.readCount) of \(store.totalGitaVerses) verses read",
                                color: .dharmaGold
                            )
                        }

                        if selectedCategory == .upanishads {
                            browseByLink(
                                destination: UpanishadListView(),
                                icon: "scroll.fill",
                                title: "Browse by Upanishad",
                                subtitle: "\(store.upanishadSources.count) texts · \(store.items(for: .upanishads).count) verses",
                                color: .categoryUpanishads
                            )
                        }

                        if selectedCategory == .rigVeda {
                            browseByLink(
                                destination: RigVedaListView(),
                                icon: "flame.fill",
                                title: "Browse by Mandala",
                                subtitle: "\(store.rigVedaBooks.count) books · \(store.items(for: .rigVeda).count) hymns",
                                color: .categoryRigVeda
                            )
                        }
                    }

                    // Semantic search indicator
                    if isSemanticQuery && !searchText.isEmpty {
                        HStack(spacing: 6) {
                            if searchService.isSearching {
                                ProgressView()
                                    .tint(.dharmaGold)
                                    .scaleEffect(0.7)
                            }
                            Text("Semantic search")
                                .font(DharmaFont.caption(11))
                                .foregroundColor(.dharmaGold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.dharmaGold.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.bottom, DharmaSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if useSemanticResults {
                        LazyVStack(spacing: 12) {
                            ForEach(searchService.results) { result in
                                if let item = matchedItem(for: result) {
                                    NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                                        SemanticResultCard(item: item, similarity: result.similarity)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.bottom, DharmaSpacing.xl)
                    } else if filteredItems.isEmpty {
                        EmptyStateView(searchText: searchText)
                            .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                                    ScriptureCardView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.bottom, DharmaSpacing.xl)
                    }
                }
            }
            .background(Color.dharmaBackground)
            .navigationTitle("Dharma Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search verses, mantras…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Filter button
                        Button {
                            showFilterSheet = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundColor(hasActiveFilters ? .dharmaGold : .dharmaTextSecondary)
                                if hasActiveFilters {
                                    Circle()
                                        .fill(Color.dharmaGold)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }

                        // Favourites button
                        Button {
                            showFavouritesPage = true
                        } label: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.dharmaGold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(
                    selectedCategory: selectedCategory,
                    selectedChapter: $selectedChapter,
                    selectedSpeaker: $selectedSpeaker,
                    selectedUpanishadSource: $selectedUpanishadSource,
                    selectedRigVedaBook: $selectedRigVedaBook,
                    upanishadSources: store.upanishadSources.map(\.name),
                    rigVedaBooks: store.rigVedaBooks.map(\.book)
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFavouritesPage) {
                FavouritesView()
                    .environmentObject(store)
            }
            .onChange(of: searchText) {
                if isSemanticQuery {
                    searchService.search(query: searchText)
                } else {
                    searchService.cancel()
                }
            }
            .onChange(of: selectedCategory) { _, newValue in
                switch newValue {
                case .gita:
                    selectedUpanishadSource = nil
                    selectedRigVedaBook = nil
                case .upanishads:
                    selectedChapter = nil
                    selectedSpeaker = nil
                    selectedRigVedaBook = nil
                case .rigVeda:
                    selectedChapter = nil
                    selectedSpeaker = nil
                    selectedUpanishadSource = nil
                default:
                    selectedChapter = nil
                    selectedSpeaker = nil
                    selectedUpanishadSource = nil
                    selectedRigVedaBook = nil
                }
            }
        }
    }
}

extension LibraryView {
    func browseByLink<D: View>(destination: D, icon: String, title: String, subtitle: String, color: Color) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DharmaFont.heading(15))
                        .foregroundColor(.dharmaTextPrimary)
                    Text(subtitle)
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaTextMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.dharmaTextMuted)
            }
            .padding(DharmaSpacing.md)
            .background(Color.dharmaSurface)
            .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DharmaRadius.md)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DharmaSpacing.md)
        .padding(.bottom, DharmaSpacing.sm)
    }
}

// MARK: - Filter Sheet
struct FilterSheetView: View {
    let selectedCategory: ScriptureCategory?
    @Binding var selectedChapter: Int?
    @Binding var selectedSpeaker: String?
    @Binding var selectedUpanishadSource: String?
    @Binding var selectedRigVedaBook: Int?
    let upanishadSources: [String]
    let rigVedaBooks: [Int]
    @Environment(\.dismiss) var dismiss

    let speakers = ["Krishna", "Arjuna", "Sanjaya", "Dhritarashtra"]
    let chapters = Array(1...18)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {

                    if selectedCategory == .gita || selectedCategory == nil {
                        // Speaker filter
                        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                            Text("Speaker")
                                .font(DharmaFont.heading())
                                .foregroundColor(.dharmaTextPrimary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(speakers, id: \.self) { speaker in
                                        CategoryPill(
                                            label: speaker,
                                            icon: speakerIcon(speaker),
                                            color: speakerColor(speaker),
                                            isSelected: selectedSpeaker == speaker
                                        ) {
                                            selectedSpeaker = selectedSpeaker == speaker ? nil : speaker
                                        }
                                    }
                                }
                            }
                        }

                        // Chapter filter
                        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                            Text("Chapter")
                                .font(DharmaFont.heading())
                                .foregroundColor(.dharmaTextPrimary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                                ForEach(chapters, id: \.self) { chapter in
                                    Button {
                                        selectedChapter = selectedChapter == chapter ? nil : chapter
                                    } label: {
                                        Text("\(chapter)")
                                            .font(DharmaFont.caption(13))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(selectedChapter == chapter ? Color.dharmaGold.opacity(0.18) : Color.dharmaSurface)
                                            .foregroundColor(selectedChapter == chapter ? .dharmaGold : .dharmaTextSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(selectedChapter == chapter ? Color.dharmaGold.opacity(0.5) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    if selectedCategory == .upanishads || selectedCategory == nil {
                        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                            Text("Upanishad")
                                .font(DharmaFont.heading())
                                .foregroundColor(.dharmaTextPrimary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(upanishadSources, id: \.self) { source in
                                    Button {
                                        selectedUpanishadSource = selectedUpanishadSource == source ? nil : source
                                    } label: {
                                        Text(source.replacingOccurrences(of: " Upanishad", with: ""))
                                            .font(DharmaFont.caption(12))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(selectedUpanishadSource == source ? Color.categoryUpanishads.opacity(0.18) : Color.dharmaSurface)
                                            .foregroundColor(selectedUpanishadSource == source ? .categoryUpanishads : .dharmaTextSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(selectedUpanishadSource == source ? Color.categoryUpanishads.opacity(0.5) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    if selectedCategory == .rigVeda || selectedCategory == nil {
                        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                            Text("Mandala")
                                .font(DharmaFont.heading())
                                .foregroundColor(.dharmaTextPrimary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                ForEach(rigVedaBooks, id: \.self) { book in
                                    Button {
                                        selectedRigVedaBook = selectedRigVedaBook == book ? nil : book
                                    } label: {
                                        Text("\(book)")
                                            .font(DharmaFont.caption(13))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(selectedRigVedaBook == book ? Color.categoryRigVeda.opacity(0.18) : Color.dharmaSurface)
                                            .foregroundColor(selectedRigVedaBook == book ? .categoryRigVeda : .dharmaTextSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(selectedRigVedaBook == book ? Color.categoryRigVeda.opacity(0.5) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Clear filters button
                    if selectedChapter != nil || selectedSpeaker != nil || selectedUpanishadSource != nil || selectedRigVedaBook != nil {
                        Button {
                            selectedChapter = nil
                            selectedSpeaker = nil
                            selectedUpanishadSource = nil
                            selectedRigVedaBook = nil
                        } label: {
                            Text("Clear All Filters")
                                .font(DharmaFont.body())
                                .foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
                        }
                    }
                }
                .padding(DharmaSpacing.md)
            }
            .background(Color.dharmaBackground)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dharmaGold)
                }
            }
        }
    }

    func speakerIcon(_ speaker: String) -> String {
        switch speaker {
        case "Krishna": return "star.fill"
        case "Arjuna": return "person.fill"
        case "Sanjaya": return "eye.fill"
        case "Dhritarashtra": return "crown.fill"
        default: return "person.fill"
        }
    }

    func speakerColor(_ speaker: String) -> Color {
        switch speaker {
        case "Krishna": return .dharmaGold
        case "Arjuna": return .categoryGita
        case "Sanjaya": return .categoryUpanishads
        case "Dhritarashtra": return .categoryMantras
        default: return .dharmaGold
        }
    }
}

// MARK: - Favourites Page
struct FavouritesView: View {
    @EnvironmentObject var store: ScriptureStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.favourites.isEmpty {
                    VStack(spacing: DharmaSpacing.md) {
                        Image(systemName: "heart")
                            .font(.system(size: 50))
                            .foregroundColor(.dharmaTextMuted)
                            .padding(.top, 80)
                        Text("No favourites yet")
                            .font(DharmaFont.heading())
                            .foregroundColor(.dharmaTextSecondary)
                        Text("Tap the heart on any verse to save it here")
                            .font(DharmaFont.body())
                            .foregroundColor(.dharmaTextMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DharmaSpacing.xl)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(store.favourites) { item in
                            NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                                ScriptureCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(DharmaSpacing.md)
                    .padding(.bottom, DharmaSpacing.xl)
                }
            }
            .background(Color.dharmaBackground)
            .navigationTitle("Favourites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dharmaGold)
                }
            }
        }
    }
}

// MARK: - Category Filter Pills
struct CategoryFilterView: View {
    @Binding var selected: ScriptureCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    label: "All",
                    icon: "sparkles",
                    color: .dharmaGold,
                    isSelected: selected == nil
                ) {
                    selected = nil
                }

                ForEach(ScriptureCategory.allCases) { cat in
                    CategoryPill(
                        label: cat.rawValue,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: selected == cat
                    ) {
                        selected = (selected == cat) ? nil : cat
                    }
                }
            }
        }
    }
}

struct CategoryPill: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(DharmaFont.caption(13))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected ? color.opacity(0.18) : Color.dharmaSurface
            )
            .foregroundColor(isSelected ? color : .dharmaTextSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? color.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Semantic Result Card

struct SemanticResultCard: View {
    let item: ScriptureItem
    let similarity: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Label(item.category.rawValue, systemImage: item.category.icon)
                    .font(DharmaFont.caption(11))
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.category.color.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                if let sim = similarity {
                    Circle()
                        .fill(Color.dharmaGold.opacity(0.2 + sim * 0.8))
                        .frame(width: 8, height: 8)
                }

                if item.isFavourite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaGold)
                }
            }

            Text(item.title)
                .font(DharmaFont.heading())
                .foregroundColor(.dharmaTextPrimary)
                .lineLimit(1)

            Text(item.textEnglish)
                .font(DharmaFont.body(14))
                .foregroundColor(.dharmaTextSecondary)
                .lineLimit(2)
                .lineSpacing(3)

            Text(item.source)
                .font(DharmaFont.caption())
                .foregroundColor(.dharmaTextMuted)
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Scripture Card
struct ScriptureCardView: View {
    let item: ScriptureItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Label(item.category.rawValue, systemImage: item.category.icon)
                    .font(DharmaFont.caption(11))
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.category.color.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                if item.audioFileName != nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaTextMuted)
                }

                if item.isFavourite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaGold)
                }
            }

            Text(item.title)
                .font(DharmaFont.heading())
                .foregroundColor(.dharmaTextPrimary)
                .lineLimit(1)

            Text(item.textEnglish)
                .font(DharmaFont.body(14))
                .foregroundColor(.dharmaTextSecondary)
                .lineLimit(2)
                .lineSpacing(3)

            Text(item.source)
                .font(DharmaFont.caption())
                .foregroundColor(.dharmaTextMuted)
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: DharmaSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.dharmaTextMuted)
            Text(searchText.isEmpty ? "No items found" : "No results for \"\(searchText)\"")
                .font(DharmaFont.heading())
                .foregroundColor(.dharmaTextSecondary)
            Text("Try a different category or search term")
                .font(DharmaFont.body())
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)
        }
        .padding(DharmaSpacing.xl)
    }
}

#Preview {
    LibraryView()
        .environmentObject(ScriptureStore())
}
