import SwiftUI
import UIKit

struct ScriptureDetailView: View {
    let item: ScriptureItem
    @ObservedObject var store: ScriptureStore
    @StateObject private var audioManager = VerseAudioManager.shared
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @Environment(\.colorScheme) private var colorScheme

    private var verseChapter: Int? {
        let parts = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "").split(separator: ".")
        guard parts.count == 2, let ch = Int(parts[0]) else { return nil }
        return ch
    }

    private var verseNumber: Int? {
        let parts = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "").split(separator: ".")
        guard parts.count == 2, let v = Int(parts[1]) else { return nil }
        return v
    }

    private var isThisVerse: Bool {
        guard let ch = verseChapter, let v = verseNumber else { return false }
        return audioManager.currentReference == "\(ch).\(v)"
    }

    private var speakerContext: String? {
        guard item.category == .gita else { return nil }
        let speaker = item.title.split(separator: "—").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
        switch speaker {
        case "Krishna":        return "Krishna speaks to Arjuna"
        case "Arjuna":         return "Arjuna speaks to Krishna"
        case "Sanjaya":        return "Sanjaya speaks to Dhritarashtra"
        case "Dhritarashtra":  return "Dhritarashtra speaks to Sanjaya"
        default:               return nil
        }
    }

    private var categoryItems: [ScriptureItem] {
        store.items(for: item.category)
    }

    private var previousItem: ScriptureItem? {
        guard let idx = categoryItems.firstIndex(where: { $0.id == item.id }), idx > 0 else { return nil }
        return categoryItems[idx - 1]
    }

    private var nextItem: ScriptureItem? {
        guard let idx = categoryItems.firstIndex(where: { $0.id == item.id }), idx < categoryItems.count - 1 else { return nil }
        return categoryItems[idx + 1]
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .topTrailing) {
                OmWatermark(size: 180, opacity: 0.12)
                    .padding(.trailing, -20)
                    .padding(.top, 20)

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

                    // Subtitle
                    Text(item.subtitle)
                        .font(DharmaFont.caption(13))
                        .foregroundColor(.dharmaTextMuted)
                        .padding(.top, -DharmaSpacing.sm)

                    // Speaker context badge
                    if let context = speakerContext {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.dharmaGold)
                                .frame(width: 6, height: 6)
                            Text(context)
                                .font(DharmaFont.caption(11))
                                .foregroundColor(.dharmaSpeakerText)
                                .italic()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.dharmaSpeakerBg)
                        .clipShape(Capsule())
                    }

                    Divider().background(Color.dharmaDivider)

                    // Sanskrit Devanagari
                    if let sanskrit = item.textSanskrit, !sanskrit.isEmpty {
                        Text(sanskrit)
                            .font(.system(size: 13))
                            .foregroundColor(.dharmaTextPrimary)
                            .lineSpacing(13 * 0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Romanized transliteration
                    if let translit = item.textTransliteration, !translit.isEmpty {
                        Text(translit)
                            .font(.system(size: 11).italic())
                            .foregroundColor(.dharmaTextMuted)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Audio card (Gita only)
                    if item.category == .gita, let ch = verseChapter, let v = verseNumber {
                        VerseAudioCard(chapter: ch, verse: v, audioManager: audioManager, isThisVerse: isThisVerse)
                    }

                    Divider().background(Color.dharmaDivider)

                    // English translation with saffron accent bar
                    HStack(alignment: .top, spacing: DharmaSpacing.sm) {
                        Rectangle()
                            .fill(Color.dharmaGold)
                            .frame(width: 3)
                            .clipShape(Capsule())

                        Text(item.textEnglish)
                            .font(DharmaFont.georgia(14))
                            .foregroundColor(.dharmaTextBody)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Source attribution
                    Text(item.source)
                        .font(.system(size: 10).italic())
                        .foregroundColor(.dharmaGold)

                    // Local audio player (Mantras/Bhajans)
                    if item.audioFileName != nil {
                        AudioPlayerView(fileName: item.audioFileName!)
                    }

                    // Previous / Next navigation
                    if previousItem != nil || nextItem != nil {
                        VerseNavigationRow(
                            previousItem: previousItem,
                            nextItem: nextItem,
                            store: store
                        )
                    }

                    Spacer(minLength: DharmaSpacing.md)
                }
                .padding(DharmaSpacing.lg)
            }
        }
        .background(Color.dharmaBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    store.toggleFavourite(item)
                } label: {
                    Image(systemName: item.isFavourite ? "heart.fill" : "heart")
                        .foregroundColor(item.isFavourite ? .dharmaGold : .dharmaTextSecondary)
                }

                Button {
                    let renderedImages = ShareCardRenderer.renderSquareAndTall(item, colorScheme: colorScheme)
                    if renderedImages.isEmpty {
                        shareItems = [shareText]
                    } else {
                        // Share both square + tall so downstream apps can pick what they support.
                        shareItems = renderedImages
                    }
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.dharmaTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .onAppear {
            store.markAsRead(item)
        }
        .onDisappear {
            audioManager.stop()
        }
    }

    private var shareText: String {
        "\"\(item.textEnglish)\"\n\n— \(item.source)\n\nShared via Dharma"
    }
}

// MARK: - Verse Navigation
struct VerseNavigationRow: View {
    let previousItem: ScriptureItem?
    let nextItem: ScriptureItem?
    let store: ScriptureStore

    var body: some View {
        HStack {
            if let prev = previousItem {
                NavigationLink(destination: ScriptureDetailView(item: prev, store: store)) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Previous")
                            .font(DharmaFont.caption(12))
                    }
                    .foregroundColor(.dharmaGold)
                }
            }

            Spacer()

            if let next = nextItem {
                NavigationLink(destination: ScriptureDetailView(item: next, store: store)) {
                    HStack(spacing: 4) {
                        Text("Next")
                            .font(DharmaFont.caption(12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.dharmaGold)
                }
            }
        }
        .padding(.vertical, DharmaSpacing.sm)
    }
}

// MARK: - Inline Audio Card
struct VerseAudioCard: View {
    let chapter: Int
    let verse: Int
    @ObservedObject var audioManager: VerseAudioManager
    let isThisVerse: Bool

    private var localState: VersePlaybackState {
        isThisVerse ? audioManager.state : .idle
    }

    var body: some View {
        HStack(spacing: DharmaSpacing.md) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                audioManager.togglePlayPause(chapter: chapter, verse: verse)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dharmaGold)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.dharmaGold.opacity(localState == .playing ? 0.4 : 0), radius: 8)

                    if localState == .buffering {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: localState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: localState)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                AnimatedWaveform(isAnimating: localState == .playing)

                Text(statusLabel)
                    .font(DharmaFont.caption(11))
                    .foregroundColor(localState == .playing ? .dharmaGold : .dharmaTextMuted)
                    .animation(.easeInOut(duration: 0.2), value: localState)
            }
        }
        .padding(DharmaSpacing.md)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md)
                .strokeBorder(
                    localState == .playing ? Color.dharmaGold.opacity(0.35) : Color.dharmaCardBorder,
                    lineWidth: 1
                )
                .animation(.easeInOut(duration: 0.3), value: localState)
        )
    }

    private var statusLabel: String {
        switch localState {
        case .idle: return "Listen in Sanskrit"
        case .buffering: return "Loading..."
        case .playing: return "Now playing"
        case .paused: return "Paused"
        case .failed: return "Couldn't load audio"
        }
    }
}

// MARK: - Animated Waveform
struct AnimatedWaveform: View {
    let isAnimating: Bool
    private let barCount = 24

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isAnimating)) { timeline in
            let t = isAnimating ? timeline.date.timeIntervalSinceReferenceDate : 0

            HStack(spacing: 2.5) {
                ForEach(0..<barCount, id: \.self) { i in
                    let phase = t * 3.5 + Double(i) * 0.4
                    let height: CGFloat = isAnimating
                        ? 5 + CGFloat(abs(sin(phase))) * 19
                        : 5

                    Capsule()
                        .fill(Color.dharmaGold.opacity(isAnimating ? 0.85 : 0.22))
                        .frame(width: 3, height: height)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isAnimating)
        }
        .frame(height: 26)
    }
}

// MARK: - Audio Player View (Mantras/Bhajans)
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
                Button {
                    isPlaying.toggle()
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
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.dharmaGold.opacity(0.3))
                        .frame(height: 28)
                        .overlay(
                            HStack(spacing: 2) {
                                ForEach(0..<30, id: \.self) { _ in
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
