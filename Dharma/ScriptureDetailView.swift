import SwiftUI
import UIKit

struct ScriptureDetailView: View {
    let item: ScriptureItem
    @ObservedObject var store: ScriptureStore
    @StateObject private var audioManager = VerseAudioManager.shared
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showKrishna = false
    @State private var showingJournal = false
    @State private var relatedVerses: [RelatedVerse] = []
    @State private var loadingRelated = false
    @ObservedObject private var journalStore = JournalStore.shared
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

    /// Large background ॐ — does not affect layout (ZStack layer behind scroll).
    private var omOpacityWatermark: Double {
        colorScheme == .dark ? 0.12 : 0.08
    }

    /// Map ScriptureItem to the backend Supabase ID used by /related.
    private var backendVerseId: String? {
        switch item.category {
        case .gita:
            let ref = item.source.replacingOccurrences(of: "Bhagavad Gita ", with: "")
            return ref.isEmpty ? nil : "bg-\(ref)"
        case .upanishads:
            let slug = item.title
                .lowercased()
                .replacingOccurrences(of: " upanishad", with: "")
                .trimmingCharacters(in: .whitespaces)
            let ch = item.subtitle
                .replacingOccurrences(of: "Ch. ", with: "")
                .components(separatedBy: " · Verse ")
            guard ch.count == 2 else { return nil }
            return "\(slug)-\(ch[0])-\(ch[1])"
        case .rigVeda:
            let parts = item.subtitle
                .replacingOccurrences(of: "Rig Veda ", with: "")
                .split(separator: ".")
            guard parts.count >= 3 else { return nil }
            return "rv-\(parts.joined(separator: "-"))"
        default:
            return nil
        }
    }

    private var hasOriginalText: Bool {
        if let s = item.textSanskrit, !s.isEmpty { return true }
        if let t = item.textTransliteration, !t.isEmpty { return true }
        return false
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Behind all scroll content — no layout impact
            OmWatermark(size: 190, opacity: omOpacityWatermark, rotationDegrees: -8)
                .fixedSize(horizontal: true, vertical: true)
                .allowsHitTesting(false)
                .padding(.top, -28)
                .padding(.trailing, -52)
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                // Category badge
                Label(item.category.rawValue, systemImage: item.category.icon)
                    .font(DharmaFont.caption(13))
                    .foregroundColor(item.category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(item.category.color.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.bottom, 12)

                // Title
                Text(item.title)
                    .font(DharmaFont.title(28))
                    .foregroundColor(.dharmaTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Subtitle + quill if reflected
                HStack(spacing: 6) {
                    Text(item.subtitle)
                        .font(DharmaFont.body(16))
                        .foregroundColor(.dharmaTextSecondary)

                    if journalStore.entry(for: item.id.uuidString) != nil {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.dharmaGold)
                    }
                }
                .padding(.top, 6)

                // Speaker context badge
                if let context = speakerContext {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.dharmaGold)
                            .frame(width: 6, height: 6)
                        Text(context)
                            .font(DharmaFont.caption(12))
                            .foregroundColor(.dharmaSpeakerText)
                            .italic()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.dharmaSpeakerBg)
                    .clipShape(Capsule())
                    .padding(.top, 12)
                }

                // Sanskrit + transliteration: one calm card, clear labels, generous spacing
                if hasOriginalText {
                    VStack(alignment: .leading, spacing: 0) {
                        if let sanskrit = item.textSanskrit, !sanskrit.isEmpty {
                            VerseSectionLabel("Sanskrit")
                            Text(sanskrit)
                                .font(.system(size: 22, weight: .regular, design: .serif))
                                .foregroundColor(.dharmaTextPrimary)
                                .lineSpacing(11)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                        }

                        if let translit = item.textTransliteration, !translit.isEmpty {
                            VerseSectionLabel("Transliteration")
                                .padding(.top, item.textSanskrit == nil || item.textSanskrit?.isEmpty == true ? 0 : 26)

                            Text(translit)
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .italic()
                                .foregroundColor(.dharmaTextSecondary)
                                .lineSpacing(8)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                        }
                    }
                    .padding(DharmaSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.dharmaSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                            .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
                    )
                }

                // Audio card (Gita only)
                if item.category == .gita, let ch = verseChapter, let v = verseNumber {
                    VerseAudioCard(chapter: ch, verse: v, audioManager: audioManager, isThisVerse: isThisVerse)
                        .padding(.top, hasOriginalText ? 20 : 16)
                }

                Divider()
                    .background(Color.dharmaDivider)
                    .padding(.top, hasOriginalText || (item.category == .gita && verseChapter != nil && verseNumber != nil) ? 22 : 20)
                    .padding(.bottom, 22)

                VStack(alignment: .leading, spacing: 0) {
                    VerseSectionLabel("Translation")
                    HStack(alignment: .top, spacing: 14) {
                        Rectangle()
                            .fill(Color.dharmaGold)
                            .frame(width: 4)
                            .clipShape(Capsule())

                        Text(item.textEnglish)
                            .font(DharmaFont.georgia(19))
                            .foregroundColor(.dharmaTextBody)
                            .lineSpacing(10)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 8)

                // Source attribution
                Text(item.source)
                    .font(.system(size: 13, weight: .regular, design: .default).italic())
                    .foregroundColor(.dharmaGold)
                    .padding(.top, 12)

                // Goal connection card
                GoalConnectionCard(item: item)

                // Local audio player (Mantras/Bhajans)
                if item.audioFileName != nil {
                    AudioPlayerView(fileName: item.audioFileName!)
                        .padding(.top, 16)
                }

                // Reflect on this verse
                Button {
                    showingJournal = true
                } label: {
                    HStack(spacing: DharmaSpacing.sm) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15))
                            .foregroundColor(.dharmaGold)
                        Text("Reflect on this verse")
                            .font(DharmaFont.georgia(16))
                            .foregroundColor(.dharmaGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DharmaSpacing.md)
                    .background(Color.dharmaSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                            .strokeBorder(Color.dharmaGold.opacity(0.45), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, DharmaSpacing.md)
                .sheet(isPresented: $showingJournal) {
                    JournalSheetView(item: item) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showKrishna = true
                        }
                    }
                }

                // Speak with Krishna
                Button {
                    showKrishna = true
                } label: {
                    HStack(spacing: DharmaSpacing.sm) {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.dharmaGold)
                        Text("Speak with Krishna about this verse")
                            .font(DharmaFont.georgia(16))
                            .foregroundColor(.dharmaGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DharmaSpacing.md)
                    .background(Color.dharmaGold.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                            .strokeBorder(Color.dharmaGold.opacity(0.45), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, DharmaSpacing.sm)
                .sheet(isPresented: $showKrishna) {
                    KrishnaView(verse: KrishnaVerse(
                        id: item.id.uuidString,
                        source: item.source,
                        english: item.textEnglish
                    ))
                }

                // Related Verses
                if backendVerseId != nil {
                    RelatedVersesSection(
                        relatedVerses: relatedVerses,
                        isLoading: loadingRelated,
                        store: store
                    )
                    .padding(.top, DharmaSpacing.lg)
                }

                // Bottom breathing room — nav is pinned via safeAreaInset
                Color.clear.frame(height: 12)
                }
                .padding(.horizontal, DharmaSpacing.md)
                .padding(.top, DharmaSpacing.sm)
                .padding(.bottom, DharmaSpacing.md)
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color.dharmaBackground)
        .task {
            guard let vid = backendVerseId else { return }
            loadingRelated = true
            relatedVerses = await RelatedVersesService.shared.fetchRelated(verseId: vid)
            loadingRelated = false
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if previousItem != nil || nextItem != nil {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.dharmaDivider)
                    VerseNavigationRow(
                        previousItem: previousItem,
                        nextItem: nextItem,
                        store: store
                    )
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.dharmaSurface)
                }
            }
        }
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

// MARK: - Section label (Sanskrit / Transliteration / Translation)
private struct VerseSectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(DharmaFont.caption(11))
            .tracking(1.4)
            .foregroundColor(.dharmaTextMuted)
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
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Previous")
                            .font(DharmaFont.body(16))
                    }
                    .foregroundColor(.dharmaGold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
            }

            Spacer()

            if let next = nextItem {
                NavigationLink(destination: ScriptureDetailView(item: next, store: store)) {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(DharmaFont.body(16))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.dharmaGold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.vertical, 8)
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

// MARK: - Goal Connection Card

private struct GoalConnectionCard: View {
    let item: ScriptureItem

    private var matchingGoals: [String] {
        GoalTagsLoader.shared.matchingUserGoals(for: item, userGoals: GoalsManager.shared.selectedGoals)
    }

    var body: some View {
        if let firstGoal = matchingGoals.first {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.dharmaGold)
                    .frame(width: 2)
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 6) {
                    Text("Connects to your goal")
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaGold)
                        .textCase(.uppercase)
                        .kerning(0.5)

                    Text(GoalsManager.shortName(for: firstGoal))
                        .font(DharmaFont.georgia(15))
                        .foregroundColor(.dharmaTextBody)

                    if let explanation = GoalsManager.explanations[firstGoal] {
                        Text(explanation)
                            .font(DharmaFont.body(13))
                            .foregroundColor(.dharmaTextSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, DharmaSpacing.md)
            }
            .padding(DharmaSpacing.md)
            .background(Color.dharmaSurface)
            .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                    .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
            )
            .padding(.top, DharmaSpacing.md)
        }
    }
}

// MARK: - Related Verses Section

private struct RelatedVersesSection: View {
    let relatedVerses: [RelatedVerse]
    let isLoading: Bool
    let store: ScriptureStore

    var body: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {
            // Decorative divider
            HStack(spacing: DharmaSpacing.sm) {
                VStack { Divider().background(Color.dharmaGold.opacity(0.3)) }
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.dharmaGold.opacity(0.45))
                    .rotationEffect(.degrees(-30))
                VStack { Divider().background(Color.dharmaGold.opacity(0.3)) }
            }

            Text("Related across all texts")
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaGold)
                .textCase(.uppercase)
                .kerning(0.8)

            if isLoading {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.dharmaGold.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, DharmaSpacing.sm)
            } else if !relatedVerses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(relatedVerses) { rv in
                            relatedCard(rv)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func relatedCard(_ rv: RelatedVerse) -> some View {
        let matched = store.items.first {
            $0.textEnglish.hasPrefix(String(rv.english.prefix(40)))
        }

        Group {
            if let item = matched {
                NavigationLink(destination: ScriptureDetailView(item: item, store: store)) {
                    cardContent(rv)
                }
                .buttonStyle(.plain)
            } else {
                cardContent(rv)
            }
        }
    }

    private func cardContent(_ rv: RelatedVerse) -> some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            Text(rv.categoryBadge)
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.dharmaGold.opacity(0.12))
                .clipShape(Capsule())

            Text(rv.truncatedEnglish)
                .font(DharmaFont.georgia(13))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(5)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(rv.id)
                .font(DharmaFont.caption(10))
                .foregroundColor(.dharmaTextMuted)
        }
        .padding(DharmaSpacing.md)
        .frame(width: 200, alignment: .topLeading)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ScriptureDetailView(
            item: ScriptureItem.sampleData[0],
            store: ScriptureStore()
        )
    }
}
