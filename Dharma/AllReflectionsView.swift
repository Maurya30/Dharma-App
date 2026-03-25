import SwiftUI

struct AllReflectionsView: View {
    @EnvironmentObject var store: ScriptureStore
    @ObservedObject private var journalStore = JournalStore.shared

    var body: some View {
        ScrollView {
            if journalStore.entries.isEmpty {
                WarmEmptyState(
                    icon: "square.and.pencil",
                    title: "Your reflections live here",
                    message: "Each note you write is a thread in your practice — nothing is lost; it all gathers in one place.",
                    hint: "From any verse, tap Reflect on this verse to begin."
                )
                .padding(.top, 56)
                .padding(.horizontal, DharmaSpacing.md)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(journalStore.entries) { entry in
                        if let item = store.items.first(where: { $0.id.uuidString == entry.verseId }) {
                            NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                                reflectionCard(entry)
                            }
                            .buttonStyle(.plain)
                        } else {
                            reflectionCard(entry)
                        }
                    }
                }
                .padding(DharmaSpacing.md)
                .padding(.bottom, DharmaSpacing.xl)
            }
        }
        .refreshable {
            await store.refreshLibraryContent()
            DharmaHaptics.light()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("All Reflections")
        .navigationBarTitleDisplayMode(.large)
        .transparentNavigationBar()
        .dharmaBackground()
    }

    private func reflectionCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            HStack(spacing: 8) {
                Text(entry.verseSource)
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())

                if entry.spokenWithKrishna {
                    Text("Spoke with Krishna")
                        .font(DharmaFont.caption(9))
                        .foregroundColor(.dharmaGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dharmaGold.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(entry.verseReference)
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaTextMuted)

            Text(String(entry.verseEnglish.prefix(80)) + (entry.verseEnglish.count > 80 ? "…" : ""))
                .font(DharmaFont.georgia(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(4)
                .lineLimit(2)

            Divider().background(Color.dharmaDivider)

            Text(String(entry.noteText.prefix(100)) + (entry.noteText.count > 100 ? "…" : ""))
                .font(DharmaFont.body(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(4)
                .lineLimit(3)

            HStack {
                Spacer()
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(DharmaFont.caption(10))
                    .foregroundColor(.dharmaTextMuted)
            }
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}
