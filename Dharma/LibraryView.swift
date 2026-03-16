import SwiftUI

struct LibraryView: View {
    @StateObject private var store = ScriptureStore()
    @State private var searchText = ""
    @State private var selectedCategory: ScriptureCategory? = nil
    @State private var showFavouritesOnly = false

    var filteredItems: [ScriptureItem] {
        var items = store.items
        if showFavouritesOnly {
            items = items.filter { $0.isFavourite }
        }
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    CategoryFilterView(selected: $selectedCategory)
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.top, DharmaSpacing.sm)
                        .padding(.bottom, DharmaSpacing.md)

                    if filteredItems.isEmpty {
                        EmptyStateView(searchText: searchText, showFavouritesOnly: showFavouritesOnly)
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
                    Button {
                        showFavouritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavouritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(.dharmaGold)
                    }
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
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let searchText: String
    var showFavouritesOnly: Bool = false

    var body: some View {
        VStack(spacing: DharmaSpacing.md) {
            Image(systemName: showFavouritesOnly ? "heart" : "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.dharmaTextMuted)
            Text(showFavouritesOnly ? "No favourites yet" : searchText.isEmpty ? "No items found" : "No results for \"\(searchText)\"")
                .font(DharmaFont.heading())
                .foregroundColor(.dharmaTextSecondary)
            Text(showFavouritesOnly ? "Tap the heart on any verse to save it here" : "Try a different category or search term")
                .font(DharmaFont.body())
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)
        }
        .padding(DharmaSpacing.xl)
    }
}

#Preview {
    LibraryView()
}
