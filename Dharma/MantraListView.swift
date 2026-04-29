import SwiftUI

// MARK: - Mantra List View

struct MantraListView: View {
    @EnvironmentObject var store: ScriptureStore
    @State private var selectedMantraCategory: String? = nil
    @State private var chantItem: ScriptureItem?

    private let filterCategories = ["All", "Universal", "Shiva", "Vishnu", "Krishna", "Ganesha", "Devi", "Rama", "Guru", "Peace"]

    private var filteredMantras: [ScriptureItem] {
        let all = store.items(for: .mantras)
        guard let cat = selectedMantraCategory else { return all }
        return all.filter { $0.mantraCategory == cat }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Category filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filterCategories, id: \.self) { cat in
                            let isSelected = (selectedMantraCategory == nil && cat == "All") ||
                                selectedMantraCategory == cat
                            Button {
                                DharmaHaptics.selection()
                                selectedMantraCategory = (cat == "All") ? nil : cat
                            } label: {
                                if isSelected {
                                    Text(cat)
                                        .font(DharmaFont.caption().weight(.semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .foregroundColor(.white)
                                        .background(Color.dharmaGold)
                                        .clipShape(Capsule())
                                } else {
                                    Text(cat)
                                        .font(DharmaFont.caption())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .foregroundColor(.dharmaTextSecondary)
                                        .glassCapsuleCard()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DharmaSpacing.lg)
                }
                .padding(.vertical, DharmaSpacing.md)

                // Mantra cards
                LazyVStack(spacing: 12) {
                    ForEach(filteredMantras) { item in
                        MantraCardView(item: item) {
                            chantItem = item
                        }
                    }
                }
                .padding(.horizontal, DharmaSpacing.md)
                .padding(.bottom, DharmaSpacing.xl)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Mantras & Chants")
        .navigationBarTitleDisplayMode(.large)
        .transparentNavigationBar()
        .dharmaBackground()
        .fullScreenCover(item: $chantItem) { item in
            MantraChantView(item: item)
                .environmentObject(store)
        }
    }
}

// MARK: - Mantra Card

struct MantraCardView: View {
    let item: ScriptureItem
    var onChant: () -> Void

    @EnvironmentObject private var store: ScriptureStore
    @ObservedObject private var journalStore = JournalStore.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                cardMainContent
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Spacer(minLength: 0)

                Button {
                    onChant()
                    HapticManager.light()
                } label: {
                    Text("Chant")
                        .font(DharmaFont.caption().weight(.semibold))
                        .foregroundColor(Color.dharmaGold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(Color.dharmaGold.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(DharmaSpacing.lg)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    private var cardMainContent: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            HStack(alignment: .center, spacing: 8) {
                Label(item.category.rawValue, systemImage: item.category.icon)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(item.category.color.opacity(0.12))
                    .clipShape(Capsule())

                if item.mantraIsBeej == true {
                    Text("Beej")
                        .font(DharmaFont.caption(13))
                        .foregroundColor(.dharmaGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dharmaGold.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()

                if item.audioFileName != nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 15))
                        .foregroundColor(.dharmaTextMuted)
                }

                if journalStore.entry(for: item.id.uuidString) != nil {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 17))
                        .foregroundColor(Color.dharmaGold.opacity(0.7))
                }

                if item.isFavourite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.dharmaGold)
                }
            }

            Text(item.title)
                .font(DharmaFont.heading())
                .foregroundColor(.dharmaTextPrimary)
                .lineLimit(1)

            Text(item.textEnglish)
                .font(DharmaFont.body(17))
                .foregroundColor(.dharmaTextSecondary)
                .lineLimit(3)
                .lineSpacing(5)

            if let deity = item.mantraDeity {
                Text(deity)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(item.source)
                .font(DharmaFont.caption(13))
                .foregroundColor(.dharmaTextMuted)
        }
    }
}
