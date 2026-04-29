import SwiftUI

struct AllReflectionsView: View {
    @EnvironmentObject var store: ScriptureStore
    @EnvironmentObject private var notificationNav: NotificationNavigationState
    @ObservedObject private var journalStore = JournalStore.shared
    @State private var detailEntry: JournalEntry?

    var body: some View {
        ScrollView {
            if journalStore.entries.isEmpty {
                ContentUnavailableView {
                    Label("No reflections yet", systemImage: "text.book.closed")
                        .foregroundColor(Color.dharmaGold)
                } description: {
                    Text("Your reflections from Sadhana, Goal Path, and Krishna will appear here.")
                        .foregroundColor(Color.dharmaTextSecondary)
                }
                .padding(.top, 56)
                .padding(.horizontal, DharmaSpacing.md)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(journalStore.entries) { entry in
                        Button {
                            detailEntry = entry
                        } label: {
                            reflectionCard(entry)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                journalStore.delete(entry: entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
        .sheet(item: $detailEntry) { entry in
            JournalDetailView(entry: entry) {
                detailEntry = nil
            }
            .environmentObject(notificationNav)
        }
    }

    private func reflectionCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            HStack(spacing: 8) {
                Text(entry.verseSource)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())

                if entry.spokenWithKrishna {
                    Text("Spoke with Krishna")
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dharmaGold.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                Button(action: { journalStore.delete(entry: entry) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.dharmaTextSecondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            Text(entry.verseReference)
                .font(DharmaFont.caption(13))
                .foregroundColor(.dharmaTextMuted)

            Text(String(entry.verseEnglish.prefix(80)) + (entry.verseEnglish.count > 80 ? "…" : ""))
                .font(DharmaFont.georgia(17))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(5)
                .lineLimit(3)

            Divider().background(Color.dharmaDivider)

            Text(String(entry.noteText.prefix(100)) + (entry.noteText.count > 100 ? "…" : ""))
                .font(DharmaFont.body(16))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(5)
                .lineLimit(3)

            if !entry.sourceLabel.isEmpty {
                HStack {
                    Spacer()
                    JournalEntrySourceTag(entry: entry)
                }
            }

            HStack {
                Spacer()
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaTextMuted)
            }
        }
        .padding(DharmaSpacing.lg)
        .glassCard(cornerRadius: DharmaRadius.md)
    }
}
