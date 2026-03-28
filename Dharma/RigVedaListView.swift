import SwiftUI

struct RigVedaListView: View {
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.rigVedaBooks, id: \.book) { entry in
                    NavigationLink(destination: RigVedaBookView(book: entry.book)) {
                        RigVedaBookRow(book: entry.book, count: entry.count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DharmaSpacing.md)
            .padding(.bottom, DharmaSpacing.xl)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Rig Veda")
        .navigationBarTitleDisplayMode(.large)
        .dharmaBackground()
    }
}

private struct RigVedaBookRow: View {
    let book: Int
    let count: Int

    private var bookDescription: String {
        switch book {
        case 1:  return "Hymns to Agni, Indra, and the Ashvins"
        case 2:  return "Family book of Gritsamada"
        case 3:  return "Vishvamitra's hymns & the Gayatri Mantra"
        case 4:  return "Hymns of Vamadeva"
        case 5:  return "The Atri family hymns"
        case 6:  return "Bharadvaja family hymns"
        case 7:  return "Vasishtha's hymns & Maha Mrityunjaya"
        case 8:  return "Kanva family hymns"
        case 9:  return "Soma Pavamana hymns"
        case 10: return "Purusha Sukta, Nasadiya Sukta & more"
        default: return "Sacred hymns"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("\(book)")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundColor(.categoryRigVeda)
                    .frame(width: 40, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mandala \(book)")
                        .font(DharmaFont.heading(16))
                        .foregroundColor(.dharmaTextPrimary)

                    Text(bookDescription)
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaTextSecondary)
                        .italic()
                }

                Spacer()

                Text("\(count) hymns")
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

struct RigVedaBookView: View {
    let book: Int
    @EnvironmentObject var store: ScriptureStore

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.rigVedaItems(for: book)) { item in
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
        .navigationTitle("Mandala \(book)")
        .navigationBarTitleDisplayMode(.large)
        .dharmaBackground()
    }
}
