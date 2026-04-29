import SwiftUI
import UIKit

// MARK: - Krishna action chips (parsed from completed assistant text)

struct KrishnaAction: Identifiable {
    let id = UUID()
    let type: String // "verse","sadhana","mantra"
    let label: String
    let payload: String
}

// MARK: - Krishna root

struct KrishnaView: View {
    let verse: KrishnaVerse?

    @EnvironmentObject private var store: ScriptureStore
    @StateObject private var service = KrishnaService()
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var network = NetworkMonitor.shared
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @State private var linkedVerse: ScriptureItem? = nil
    @State private var krishnaError: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if linkedVerse == nil {
                    mainChat
                }
            }
            .navigationTitle("Krishna")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        service.cancel()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .tint(Color(hex: "C9821E"))
                }
            }
            .navigationDestination(item: $linkedVerse) { item in
                ScriptureDetailView(item: item, store: store)
            }
            .environment(\.openURL, OpenURLAction { url in
                guard let id = VerseReferenceLinker.verseId(from: url),
                      let item = store.items.first(where: { $0.id == id }) else {
                    return .systemAction
                }
                linkedVerse = item
                return .handled
            })
        }
        .transparentNavigationBar()
        .dharmaErrorBanner(
            message: krishnaError,
            onDismiss: {
                krishnaError = nil
                service.clearChatBannerError()
            }
        )
        .onChange(of: service.chatBannerError) { _, newValue in
            krishnaError = newValue
        }
        .onAppear {
            krishnaError = service.chatBannerError
        }
        .onDisappear {
            Task { await summarizeOfferingIfNeeded() }
        }
    }

    // MARK: - Main chat (root of stack)

    private var mainChat: some View {
        VStack(spacing: 0) {
            if let v = verse {
                verseContextCard(v)
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.top, DharmaSpacing.sm)
                    .padding(.bottom, DharmaSpacing.xs)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DharmaSpacing.md) {
                        if service.conversationHistory.isEmpty && !service.isStreaming {
                            KrishnaBubble(
                                text: greetingText,
                                isStreaming: false,
                                items: store.items,
                                showActionChips: false,
                                onChipAction: { _ in },
                                onCitationBlockTap: nil
                            )
                            .id("greeting")
                        }

                        ForEach(service.conversationHistory) { message in
                            if message.role == "assistant" {
                                KrishnaBubble(
                                    text: message.content,
                                    isStreaming: false,
                                    items: store.items,
                                    showActionChips: true,
                                    onChipAction: handleKrishnaAction,
                                    onCitationBlockTap: { item in
                                        linkedVerse = item
                                    }
                                )
                                .id(message.id)
                            } else {
                                UserBubble(text: message.content)
                                    .id(message.id)
                            }
                        }

                        if service.showEmptyAssistantInline && !service.isStreaming {
                            Text("Something went wrong. Try asking again.")
                                .font(.system(size: 17, design: .serif))
                                .italic()
                                .foregroundColor(.dharmaTextSecondary)
                                .padding(DharmaSpacing.md)
                                .id("emptyAssistantInline")
                        }

                        if service.isStreaming {
                            KrishnaBubble(
                                text: service.streamingResponse,
                                isStreaming: true,
                                items: store.items,
                                showActionChips: false,
                                onChipAction: { _ in },
                                onCitationBlockTap: nil
                            )
                            .id("streaming")
                        }

                        Color.clear.frame(height: 4).id("bottom")
                    }
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.top, DharmaSpacing.md)
                    .padding(.bottom, DharmaSpacing.sm)
                }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: service.streamingResponse) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: service.conversationHistory.count) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if network.isConnected {
                inputBar
            } else {
                krishnaOfflineBar
            }
        }
        .dharmaBackground()
    }

    private var greetingText: String {
        if let v = verse {
            return "Namaste. I see you are reflecting on \(v.source). What arises in you from these words?"
        }
        let summary = authManager.lastOfferingSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty {
            let sentence = firstSentence(from: summary, maxChars: 120)
            return "\(sentence) — what would you like to explore?"
        }
        let name = UserDefaults.standard.string(forKey: "dharma_user_name")?.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = (name == nil || name?.isEmpty == true) ? "friend" : name!
        return "Namaste, \(display). What weighs on your heart today?"
    }

    private func handleKrishnaAction(_ action: KrishnaAction) {
        switch action.type {
        case "sadhana":
            NotificationNavigationState.shared.selectedTab = 2
        case "verse", "mantra":
            NotificationNavigationState.shared.selectedTab = 1
        default:
            break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }

    private func summarizeOfferingIfNeeded() async {
        let history = await MainActor.run { service.conversationHistory }
        guard history.count >= 2 else { return }
        let firstUser = history.first(where: { $0.role == "user" })?.content
        let lastAssistant = history.last(where: { $0.role == "assistant" })?.content
        guard let offeringText = firstUser, let krishnaResponse = lastAssistant,
              !offeringText.isEmpty, !krishnaResponse.isEmpty else { return }

        let url = BackendConfig.baseURL.appendingPathComponent("krishna/summarize-offering")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "offeringText": offeringText,
            "krishnaResponse": krishnaResponse
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = data

        do {
            let (respData, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return }
            let decoded = try JSONDecoder().decode(SummarizeOfferingResponse.self, from: respData)
            let summary = decoded.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !summary.isEmpty else { return }
            await MainActor.run {
                AuthManager.shared.saveOfferingSummary(summary)
            }
        } catch {
            _ = error
        }
    }

    // MARK: - Verse Context Card

    private func verseContextCard(_ v: KrishnaVerse) -> some View {
        HStack(spacing: DharmaSpacing.md) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 16))
                .foregroundColor(.dharmaGold)

            VStack(alignment: .leading, spacing: 4) {
                Text(v.source)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundColor(.dharmaGold)
                    .kerning(1.0)

                Text(v.english)
                    .font(DharmaFont.verseTranslation(17))
                    .foregroundColor(.dharmaTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()
        }
        .padding(.horizontal, DharmaSpacing.md)
        .padding(.vertical, DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    // MARK: - Offline bar

    private var krishnaOfflineBar: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 24))
                .foregroundColor(Color.dharmaGold.opacity(0.4))
            Text("Krishna will be here when you return")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundColor(.dharmaTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DharmaSpacing.md)
        .padding(.vertical, DharmaSpacing.md)
        .background(.ultraThinMaterial)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: DharmaSpacing.sm) {
            ZStack(alignment: .leading) {
                if inputText.isEmpty {
                    Text("Ask Krishna...")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.dharmaTextMuted)
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.vertical, 14)
                }
                TextField("", text: $inputText, axis: .vertical)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(.dharmaTextPrimary)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.vertical, 14)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "2A1A00"))
                    .frame(width: 52, height: 52)
                    .background(canSend ? Color(hex: "C9821E") : Color.dharmaGold.opacity(0.35))
                    .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, DharmaSpacing.md)
        .padding(.vertical, DharmaSpacing.sm)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !service.isStreaming
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        HapticManager.light()
        inputText = ""
        service.sendMessage(text, verse: verse)
    }
}

// MARK: - Summarize API

private struct SummarizeOfferingResponse: Decodable {
    let summary: String
}

// MARK: - Verse-linked assistant text

private struct VerseLinkedText: View {
    let plain: String
    let isStreaming: Bool
    let items: [ScriptureItem]

    var body: some View {
        Group {
            if isStreaming || plain.isEmpty {
                Text(plain)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(.dharmaTextBody)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(styleVerseCitationTypography(plain, items: items))
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .tint(.dharmaGold)
            }
        }
    }
}

/// Body 17pt serif; linked verse citations 15pt serif italic.
private func styleVerseCitationTypography(_ plain: String, items: [ScriptureItem]) -> AttributedString {
    var attr = VerseReferenceLinker.attributedString(from: plain, items: items)
    let baseFont = Font.system(size: 17, weight: .regular, design: .serif)
    let citationFont = Font.system(size: 15, weight: .regular, design: .serif).italic()
    let runSnapshots = Array(attr.runs)
    for run in runSnapshots {
        if run.link != nil {
            attr[run.range].font = citationFont
            attr[run.range].foregroundColor = Color.dharmaGold
        } else {
            attr[run.range].font = baseFont
            attr[run.range].foregroundColor = Color.dharmaTextBody
        }
    }
    return attr
}

// MARK: - Krishna Bubble

private struct KrishnaBubble: View {
    let text: String
    let isStreaming: Bool
    let items: [ScriptureItem]
    let showActionChips: Bool
    let onChipAction: (KrishnaAction) -> Void
    let onCitationBlockTap: ((ScriptureItem) -> Void)?

    @State private var pulse = false

    private var parsedActions: [KrishnaAction] {
        guard !isStreaming, showActionChips, !text.isEmpty else { return [] }
        return parseKrishnaActions(from: text)
    }

    private var citationTapItem: ScriptureItem? {
        guard !isStreaming, let onCitationBlockTap else { return nil }
        return firstResolvableScriptureItem(in: text, items: items)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: DharmaSpacing.md) {
                Image(systemName: "seal.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.dharmaGold)
                    .opacity(0.85)
                    .frame(width: 36, height: 36)
                    .padding(.top, 2)

                if let item = citationTapItem {
                    Button {
                        onCitationBlockTap?(item)
                    } label: {
                        bubbleCardContent
                    }
                    .buttonStyle(.plain)
                } else {
                    bubbleCardContent
                }

                Spacer(minLength: 24)
            }

            if !parsedActions.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150), spacing: 10, alignment: .leading)],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(parsedActions) { action in
                        Button {
                            HapticManager.light()
                            onChipAction(action)
                        } label: {
                            Text(action.label)
                                .font(DharmaFont.caption(13).weight(.semibold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(Color.dharmaGold.opacity(0.12))
                                .foregroundColor(Color.dharmaGold)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.dharmaGold.opacity(0.45), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 52)
            }
        }
    }

    private var bubbleCardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: DharmaSpacing.md) {
                Rectangle()
                    .fill(Color.dharmaGold)
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                VStack(alignment: .leading, spacing: 0) {
                    if !text.isEmpty {
                        VerseLinkedText(plain: text, isStreaming: isStreaming, items: items)
                    }

                    if isStreaming {
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(Color.dharmaGold.opacity(pulse ? 0.9 : 0.3))
                                    .frame(width: 7, height: 7)
                                    .animation(
                                        .easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(i) * 0.15),
                                        value: pulse
                                    )
                            }
                        }
                        .padding(.top, text.isEmpty ? 4 : 10)
                        .onAppear { pulse = true }
                    }
                }
            }
            .padding(DharmaSpacing.lg)
        }
        .glassCard(cornerRadius: DharmaRadius.lg)
        .contextMenu {
            Button {
                UIPasteboard.general.string = text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - User Bubble

private struct UserBubble: View {
    let text: String

    var body: some View {
        HStack {
            Spacer(minLength: 40)

            Text(text)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(DharmaSpacing.lg)
                .glassCard(cornerRadius: DharmaRadius.lg, tint: .userMessage)
        }
    }
}

// MARK: - Parse actions

private let mantraKeywords: [(needle: String, labelName: String)] = [
    ("Om Namah Shivaya", "Om Namah Shivaya"),
    ("Mahamrityunjaya", "Mahamrityunjaya"),
    ("Gayatri", "Gayatri"),
    ("So'Ham", "So'Ham"),
    ("Soham", "So'Ham"),
    ("Om", "Om")
]

private func parseKrishnaActions(from text: String) -> [KrishnaAction] {
    var actions: [KrishnaAction] = []
    var seen = Set<String>()

    func appendUnique(_ key: String, type: String, label: String, payload: String) {
        guard !seen.contains(key) else { return }
        seen.insert(key)
        actions.append(KrishnaAction(type: type, label: label, payload: payload))
    }

    let ns = text as NSString
    let fullRange = NSRange(location: 0, length: ns.length)

    let gitaPattern = #"(?i)Bhagavad\s+Gita\s+(\d+)\.(\d+)"#
    if let regex = try? NSRegularExpression(pattern: gitaPattern, options: []) {
        regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match, match.numberOfRanges >= 3 else { return }
            let ch = ns.substring(with: match.range(at: 1))
            let v = ns.substring(with: match.range(at: 2))
            let source = "Bhagavad Gita \(ch).\(v)"
            appendUnique("verse:\(source)", type: "verse", label: "Read \(source) →", payload: source)
        }
    }

    let rigPattern = #"(?i)\bRig\s+Veda\s+(\d+(?:\.\d+)*)\b"#
    if let regex = try? NSRegularExpression(pattern: rigPattern, options: []) {
        regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match, match.numberOfRanges >= 2 else { return }
            let ref = ns.substring(with: match.range(at: 1))
            let source = "Rig Veda \(ref)"
            appendUnique("verse:\(source)", type: "verse", label: "Read \(source) →", payload: source)
        }
    }

    let upPattern = #"(?i)\b([A-Za-z][A-Za-z\s]+Upanishad)\s*[,\.:;]?\s*(\d+(?:\.\d+)*)\b"#
    if let regex = try? NSRegularExpression(pattern: upPattern, options: []) {
        regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match, match.numberOfRanges >= 3 else { return }
            let name = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            let nums = ns.substring(with: match.range(at: 2))
            let source = "\(name) \(nums)"
            appendUnique("verse:\(source)", type: "verse", label: "Read \(source) →", payload: source)
        }
    }

    if text.range(of: #"(?i)\bUpanishads?\b"#, options: .regularExpression) != nil {
        appendUnique("verse:upanishads", type: "verse", label: "Read Upanishads →", payload: "Upanishads")
    }

    if text.range(of: #"(?i)\bSadhana\b"#, options: .regularExpression) != nil
        || text.range(of: #"(?i)\bpractice\b"#, options: .regularExpression) != nil {
        appendUnique("sadhana", type: "sadhana", label: "Begin Sadhana →", payload: "sadhana")
    }

    let lowered = text.lowercased()
    for m in mantraKeywords {
        if lowered.contains(m.needle.lowercased()) {
            appendUnique("mantra:\(m.labelName)", type: "mantra", label: "Chant \(m.labelName) →", payload: m.labelName)
        }
    }

    return actions
}

// MARK: - First scripture item for citation tap

private func firstResolvableScriptureItem(in text: String, items: [ScriptureItem]) -> ScriptureItem? {
    let ns = text as NSString
    let full = NSRange(location: 0, length: ns.length)

    let gitaPattern = #"(?i)Bhagavad\s+Gita\s+(\d+)\.(\d+)"#
    if let regex = try? NSRegularExpression(pattern: gitaPattern, options: []),
       let match = regex.firstMatch(in: text, options: [], range: full),
       match.numberOfRanges >= 3 {
        let ch = ns.substring(with: match.range(at: 1))
        let v = ns.substring(with: match.range(at: 2))
        let source = "Bhagavad Gita \(ch).\(v)"
        if let item = items.first(where: { $0.source == source }) { return item }
    }

    let rigPattern = #"(?i)\bRig\s+Veda\s+(\d+(?:\.\d+)*)\b"#
    if let regex = try? NSRegularExpression(pattern: rigPattern, options: []),
       let match = regex.firstMatch(in: text, options: [], range: full),
       match.numberOfRanges >= 2 {
        let ref = ns.substring(with: match.range(at: 1))
        let source = "Rig Veda \(ref)"
        if let item = items.first(where: { $0.source == source }) { return item }
    }

    let upPattern = #"(?i)\b([A-Za-z][A-Za-z\s]+Upanishad)\s*[,\.:;]?\s*(\d+(?:\.\d+)*)\b"#
    if let regex = try? NSRegularExpression(pattern: upPattern, options: []),
       let match = regex.firstMatch(in: text, options: [], range: full),
       match.numberOfRanges >= 3 {
        let name = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        let nums = ns.substring(with: match.range(at: 2))
        let key = normalizeRefKey("\(name) \(nums)")
        for item in items where item.category == .upanishads {
            guard let subtitle = parseUpanishadSubtitleForLookup(item.subtitle) else { continue }
            let k2 = normalizeRefKey("\(item.source) \(subtitle.verse)")
            let k3 = normalizeRefKey("\(item.source) \(subtitle.chapter).\(subtitle.verse)")
            if key == k2 || key == k3 { return item }
        }
    }

    return nil
}

private func normalizeRefKey(_ s: String) -> String {
    let collapsed = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    return collapsed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

private func parseUpanishadSubtitleForLookup(_ subtitle: String) -> (chapter: String, verse: String)? {
    let pattern = #"Ch\.\s*(.+?)\s*·\s*Verse\s*(.+)$"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
          let r = regex.firstMatch(in: subtitle, options: [], range: NSRange(subtitle.startIndex..., in: subtitle)),
          let chR = Range(r.range(at: 1), in: subtitle),
          let vR = Range(r.range(at: 2), in: subtitle)
    else { return nil }
    let ch = String(subtitle[chR]).trimmingCharacters(in: .whitespacesAndNewlines)
    let v = String(subtitle[vR]).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !ch.isEmpty, !v.isEmpty else { return nil }
    return (ch, v)
}

// MARK: - Greeting helpers

private func firstSentence(from text: String, maxChars: Int) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }
    let pattern = #"^[\s\S]{1,4000}?[.!?](?=\s|$)"#
    let first: String
    if let regex = try? NSRegularExpression(pattern: pattern, options: []),
       let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
       let range = Range(match.range, in: trimmed) {
        first = String(trimmed[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        first = trimmed
    }
    if first.count > maxChars {
        return String(first.prefix(maxChars)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return first
}

#Preview {
    KrishnaView(verse: nil)
        .environmentObject(ScriptureStore())
}
