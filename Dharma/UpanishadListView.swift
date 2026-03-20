import SwiftUI

struct UpanishadListView: View {
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.upanishadSources, id: \.name) { source in
                    NavigationLink(destination: UpanishadVerseListView(sourceName: source.name)) {
                        UpanishadSourceRow(name: source.name, count: source.count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .background(Color.dharmaBackground)
        .navigationTitle("Upanishads")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct UpanishadSourceRow: View {
    let name: String
    let count: Int

    private var shortDescription: String {
        switch name {
        case "Isha Upanishad":          return "On renunciation and the Self"
        case "Kena Upanishad":          return "Who directs the mind?"
        case "Katha Upanishad":         return "Nachiketa's dialogue with Death"
        case "Prashna Upanishad":       return "Six questions on Brahman"
        case "Mundaka Upanishad":       return "Higher and lower knowledge"
        case "Mandukya Upanishad":      return "Om and the four states"
        case "Taittiriya Upanishad":    return "Bliss and the five sheaths"
        case "Chandogya Upanishad":     return "Tat Tvam Asi — That art thou"
        case "Brihadaranyaka Upanishad": return "The great forest teaching"
        default:                        return "Ancient wisdom"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: "scroll.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.categoryUpanishads)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.dharmaTextPrimary)

                    Text(shortDescription)
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaTextSecondary)
                        .italic()
                }

                Spacer()

                Text("\(count) verses")
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaTextMuted)
            }
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

struct UpanishadVerseListView: View {
    let sourceName: String
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.upanishadItems(for: sourceName)) { item in
                    NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                        ScriptureCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .background(Color.dharmaBackground)
        .navigationTitle(sourceName)
        .navigationBarTitleDisplayMode(.large)
    }
}
