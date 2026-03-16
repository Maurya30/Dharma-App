import SwiftUI

struct ScriptureDetailView: View {
    let item: ScriptureItem
    @ObservedObject var store: ScriptureStore
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DharmaSpacing.lg) {

                // Category badge
                Label(item.category.rawValue, systemImage: item.category.icon)
                    .font(DharmaFont.caption(12))
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(item.category.color.opacity(0.12))
                    .clipShape(Capsule())

                // Title
                Text(item.title)
                    .font(DharmaFont.title(26))
                    .foregroundColor(.dharmaTextPrimary)

                // Subtitle / reference
                Text(item.subtitle)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(.dharmaTextMuted)
                    .padding(.top, -DharmaSpacing.sm)

                Divider()
                    .background(Color.dharmaTextMuted.opacity(0.3))

                // Main scripture text
                Text(item.textEnglish)
                    .font(DharmaFont.sanskrit(17))
                    .foregroundColor(.dharmaTextPrimary)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                // Source attribution
                HStack {
                    Rectangle()
                        .fill(item.category.color)
                        .frame(width: 3, height: 20)
                        .clipShape(Capsule())
                    Text(item.source)
                        .font(DharmaFont.caption(13))
                        .foregroundColor(.dharmaTextSecondary)
                        .italic()
                }

                // Audio player (if available)
                if item.audioFileName != nil {
                    AudioPlayerView(fileName: item.audioFileName!)
                }

                Spacer(minLength: DharmaSpacing.xxl)
            }
            .padding(DharmaSpacing.lg)
        }
        .background(Color.dharmaBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Favourite button
                Button {
                    store.toggleFavourite(item)
                } label: {
                    Image(systemName: item.isFavourite ? "heart.fill" : "heart")
                        .foregroundColor(item.isFavourite ? .dharmaGold : .dharmaTextSecondary)
                }

                // Share button
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.dharmaTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    private var shareText: String {
        "\"\(item.textEnglish)\"\n\n— \(item.source)\n\nShared via Dharma"
    }
}

// MARK: - Audio Player View
// Simple placeholder — wire up AVAudioPlayer here
struct AudioPlayerView: View {
    let fileName: String
    @State private var isPlaying = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio")
                .font(DharmaFont.caption(12))
                .foregroundColor(.dharmaTextMuted)
                .textCase(.uppercase)
                .kerning(0.8)

            HStack(spacing: DharmaSpacing.md) {
                // Play/pause button
                Button {
                    isPlaying.toggle()
                    // TODO: wire up AVAudioPlayer
                    // AudioManager.shared.play(fileName: fileName)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.dharmaGold)
                            .frame(width: 48, height: 48)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Waveform placeholder
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.dharmaGold.opacity(0.3))
                        .frame(height: 28)
                        .overlay(
                            HStack(spacing: 2) {
                                ForEach(0..<30, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.dharmaGold.opacity(0.6))
                                        .frame(width: 2, height: CGFloat.random(in: 4...24))
                                }
                            }
                        )
                    Text(fileName.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: ".mp3", with: ""))
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaTextMuted)
                }
            }
            .padding(DharmaSpacing.md)
            .background(Color.dharmaSurface)
            .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ScriptureDetailView(
            item: ScriptureItem.sampleData[0],
            store: ScriptureStore()
        )
    }
}
