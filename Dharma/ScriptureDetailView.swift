import SwiftUI
import UIKit
import AVFoundation
import Combine

struct ScriptureDetailView: View {
    let item: ScriptureItem
    var openJournalOnAppear: Bool = false
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
                    .glassCard(cornerRadius: DharmaRadius.lg)
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

                if item.category == .mantras {
                    VStack(alignment: .leading, spacing: 0) {
                        VerseSectionLabel("Translation")
                        Text(item.textEnglish)
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(.dharmaTextSecondary)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)
                    }
                    .padding(DharmaSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: DharmaRadius.lg)
                    .padding(.bottom, 8)
                } else {
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
                }

                // Source attribution
                Text(item.source)
                    .font(.system(size: 13, weight: .regular, design: .default).italic())
                    .foregroundColor(.dharmaGold)
                    .padding(.top, 12)

                // Goal connection card
                GoalConnectionCard(item: item)

                // Mantra Sanskrit + transliteration cards
                if item.category == .mantras {
                    if let sanskrit = item.mantraSanskrit, !sanskrit.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            VerseSectionLabel("Sanskrit")
                            Text(sanskrit)
                                .font(.system(size: 22, weight: .regular, design: .serif))
                                .foregroundColor(.dharmaTextPrimary)
                                .lineSpacing(11)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 8)
                        }
                        .padding(DharmaSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard(cornerRadius: DharmaRadius.lg)
                        .padding(.top, 16)
                    }

                    if let translit = item.mantraTransliteration, !translit.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            VerseSectionLabel("Transliteration")
                            HStack(alignment: .top, spacing: 14) {
                                Rectangle()
                                    .fill(Color.dharmaGold)
                                    .frame(width: 4)
                                    .clipShape(Capsule())

                                Text(translit)
                                    .font(DharmaFont.georgia(19))
                                    .foregroundColor(.dharmaTextBody)
                                    .lineSpacing(10)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 8)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.top, 16)
                    }
                }

                // Local audio player (Mantras)
                if item.audioFileName != nil {
                    AudioPlayerView(
                        fileName: item.audioFileName!,
                        spokenText: item.mantraTransliteration ?? item.textEnglish
                    )
                    .padding(.top, 16)
                }

                // Mantra info sections
                if item.category == .mantras {
                    mantraInfoSections
                        .padding(.top, DharmaSpacing.md)
                }

                // Reflect on this verse
                Button {
                    showingJournal = true
                } label: {
                    HStack(spacing: DharmaSpacing.sm) {
                        Image(systemName: journalStore.entry(for: item.id.uuidString) != nil
                              ? "pencil.circle.fill"
                              : "square.and.pencil")
                            .font(.system(size: 15))
                            .foregroundColor(.dharmaGold)
                        Text(journalStore.entry(for: item.id.uuidString) != nil
                             ? "View / Edit Reflection"
                             : "Reflect on this verse")
                            .font(DharmaFont.georgia(16))
                            .foregroundColor(.dharmaGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DharmaSpacing.md)
                    .glassCard(cornerRadius: DharmaRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                            .strokeBorder(Color.dharmaGold.opacity(0.35), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, DharmaSpacing.md)
                .fullScreenCover(isPresented: $showingJournal) {
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
                    .glassCard(cornerRadius: DharmaRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                            .strokeBorder(Color.dharmaGold.opacity(0.35), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, DharmaSpacing.sm)
                .fullScreenCover(isPresented: $showKrishna) {
                    KrishnaView(verse: KrishnaVerse(
                        id: item.id.uuidString,
                        source: item.source,
                        english: item.textEnglish
                    ))
                    .environmentObject(store)
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
        .task {
            guard let vid = backendVerseId else { return }
            loadingRelated = true
            relatedVerses = await RelatedVersesService.shared.fetchRelated(verseId: vid)
            loadingRelated = false
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if previousItem != nil || nextItem != nil {
                VerseNavigationRow(
                    previousItem: previousItem,
                    nextItem: nextItem,
                    store: store
                )
                .padding(.horizontal, DharmaSpacing.md)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    store.toggleFavourite(item)
                    DharmaHaptics.light()
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
            StreakManager.shared.recordVerseRead()
            if openJournalOnAppear {
                showingJournal = true
            }
        }
        .onDisappear {
            audioManager.stop()
        }
        .transparentNavigationBar()
        .dharmaBackground()
    }

    // MARK: - Mantra Info Sections

    @ViewBuilder
    private var mantraInfoSections: some View {
        VStack(alignment: .leading, spacing: DharmaSpacing.md) {

            if let meaning = item.mantraMeaning {
                VStack(alignment: .leading, spacing: 0) {
                    VerseSectionLabel("WHAT THIS MEANS")
                    Text(meaning)
                        .font(DharmaFont.georgia(15))
                        .foregroundColor(.dharmaTextBody)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
                .padding(DharmaSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: DharmaRadius.lg)
            }

            if let howTo = item.mantraHowToChant {
                VStack(alignment: .leading, spacing: 0) {
                    VerseSectionLabel("HOW TO CHANT")
                    Text(howTo)
                        .font(DharmaFont.georgia(15))
                        .foregroundColor(.dharmaTextBody)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
                .padding(DharmaSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: DharmaRadius.lg)
            }

            if let benefits = item.mantraBenefits, !benefits.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    VerseSectionLabel("BENEFITS")
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(Color.dharmaGold)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                Text(benefit)
                                    .font(DharmaFont.georgia(14))
                                    .foregroundColor(.dharmaTextBody)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(DharmaSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: DharmaRadius.lg)
            }

            if let reps = item.mantraRepetitions {
                Text(repetitionsLabel(reps))
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextMuted)
                    .padding(.horizontal, DharmaSpacing.xs)
            }

            HStack(spacing: 8) {
                if let deity = item.mantraDeity {
                    Text(deity)
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dharmaGold.opacity(0.12))
                        .clipShape(Capsule())
                }
                if item.mantraIsBeej == true {
                    Text("Beej mantra")
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.dharmaGold.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Text(item.source)
                .font(DharmaFont.caption(11))
                .foregroundColor(.dharmaTextMuted)
                .padding(.horizontal, DharmaSpacing.xs)
        }
    }

    private func repetitionsLabel(_ reps: Int) -> String {
        switch reps {
        case 108: return "Chant 108 times · one full mala"
        case 3:   return "Chant 3 times"
        case 0:   return "Synchronize with the breath — no counting needed"
        default:  return "Chant \(reps) times"
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
                    Label("Previous", systemImage: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "C9821E"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.60), lineWidth: 0.5))
                .shadow(color: Color(hex: "8B5A0A").opacity(0.10), radius: 8, x: 0, y: 4)
            }

            Spacer()

            if let next = nextItem {
                NavigationLink(destination: ScriptureDetailView(item: next, store: store)) {
                    Label("Next", systemImage: "chevron.right")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "C9821E"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.60), lineWidth: 0.5))
                .shadow(color: Color(hex: "8B5A0A").opacity(0.10), radius: 8, x: 0, y: 4)
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
        .glassCard(cornerRadius: DharmaRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                .strokeBorder(
                    localState == .playing ? Color.dharmaGold.opacity(0.4) : Color.clear,
                    lineWidth: 0.5
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

// MARK: - Audio Player View (Mantras)

@MainActor
private final class MantraSpeechState: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    let synthesizer = AVSpeechSynthesizer()
    @Published var isPlaying = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
    }
}

struct AudioPlayerView: View {
    let fileName: String
    let spokenText: String
    @StateObject private var speech = MantraSpeechState()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio")
                .font(DharmaFont.caption(12))
                .foregroundColor(.dharmaTextMuted)
                .textCase(.uppercase)
                .kerning(0.8)

            HStack(spacing: DharmaSpacing.md) {
                Button {
                    if speech.isPlaying {
                        speech.synthesizer.stopSpeaking(at: .immediate)
                        HapticManager.light()
                    } else {
                        HapticManager.medium()
                        let utterance = AVSpeechUtterance(string: spokenText)
                        utterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
                        utterance.rate = 0.35
                        utterance.pitchMultiplier = 0.85
                        speech.synthesizer.speak(utterance)
                        speech.isPlaying = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.dharmaGold)
                            .frame(width: 48, height: 48)
                        Image(systemName: speech.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

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
            .glassCard(cornerRadius: DharmaRadius.md)
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
            .glassCard(cornerRadius: DharmaRadius.md)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            RelatedVerseSkeletonCard()
                        }
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
        .glassCard(cornerRadius: DharmaRadius.md)
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
