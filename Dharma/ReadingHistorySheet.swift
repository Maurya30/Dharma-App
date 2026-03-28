import SwiftUI

// MARK: - Reading History Sheet

struct ReadingHistorySheet: View {
    @ObservedObject var store: ScriptureStore
    @ObservedObject private var streakManager = StreakManager.shared

    private let categories: [ScriptureCategory] = [.gita, .upanishads, .rigVeda]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DharmaSpacing.lg) {

                    // Drag indicator
                    Capsule()
                        .fill(Color.dharmaTextMuted.opacity(0.35))
                        .frame(width: 36, height: 4)
                        .padding(.top, DharmaSpacing.sm)

                    // Hero count
                    VStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.dharmaGold)
                        Text("\(streakManager.totalVersesRead)")
                            .font(.custom("Georgia-Bold", size: 64))
                            .foregroundColor(.dharmaGold)
                            .lineLimit(1)
                        Text("Verses Read")
                            .font(DharmaFont.body(17))
                            .foregroundColor(.dharmaTextPrimary)
                    }
                    .padding(.top, DharmaSpacing.sm)

                    // Per-scripture progress bars
                    VStack(spacing: 12) {
                        ForEach(categories, id: \.rawValue) { category in
                            NavigationLink(destination: InSheetVerseListView(category: category, store: store)) {
                                progressRow(for: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DharmaSpacing.md)

                    // Continue reading
                    if let item = continueReadingItem {
                        NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                            continueReadingCard(item: item)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DharmaSpacing.md)
                    }

                    Spacer(minLength: DharmaSpacing.xxl)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Reading Progress")
            .navigationBarTitleDisplayMode(.inline)
            .transparentNavigationBar()
            .dharmaBackground()
        }
    }

    // MARK: - Progress Row

    private func progressRow(for category: ScriptureCategory) -> some View {
        let total = store.items(for: category).count
        let read = store.readCount(for: category)
        let progress = total > 0 ? Double(read) / Double(total) : 0.0

        return VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 13))
                    .foregroundColor(category.color)
                Text(category.rawValue)
                    .font(DharmaFont.heading(15))
                    .foregroundColor(.dharmaTextPrimary)
                Spacer()
                Text("\(read) of \(total)")
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.dharmaTextMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.dharmaGold.opacity(0.12))
                    Capsule()
                        .fill(Color.dharmaGold)
                        .frame(width: max(geo.size.width * CGFloat(progress), 0))
                }
            }
            .frame(height: 6)
        }
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    // MARK: - Continue Reading Card

    private func continueReadingCard(item: ScriptureItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Continue reading")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .textCase(.uppercase)
                    .kerning(0.8)
                Text(item.title)
                    .font(DharmaFont.heading(15))
                    .foregroundColor(.dharmaTextPrimary)
                    .lineLimit(1)
                Text(item.source)
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.dharmaGold)
        }
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                .strokeBorder(Color.dharmaGold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    /// The last-read item from whichever scripture has the most read verses.
    private var continueReadingItem: ScriptureItem? {
        let withProgress = categories.filter { store.lastReadItem(for: $0) != nil }
        if let best = withProgress.max(by: { store.readCount(for: $0) < store.readCount(for: $1) }) {
            return store.lastReadItem(for: best)
        }
        return store.items(for: .gita).first
    }
}

// MARK: - In-Sheet Verse List

struct InSheetVerseListView: View {
    let category: ScriptureCategory
    @ObservedObject var store: ScriptureStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.items(for: category)) { item in
                    NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                        ScriptureCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .transparentNavigationBar()
        .dharmaBackground()
    }
}
