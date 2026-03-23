import SwiftUI
import UIKit

struct KrishnaView: View {
    let verse: KrishnaVerse?

    @EnvironmentObject private var store: ScriptureStore
    @StateObject private var service = KrishnaService()
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @State private var linkedVerse: ScriptureItem? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var omOpacity: Double { colorScheme == .dark ? 0.12 : 0.08 }

    var body: some View {
        NavigationStack {
            Group {
                if linkedVerse == nil {
                    mainChat
                        .navigationBarHidden(true)
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
    }

    // MARK: - Main chat (root of stack)

    private var mainChat: some View {
        ZStack(alignment: .topTrailing) {
            Color.dharmaBackground.ignoresSafeArea()

            OmWatermark(size: 190, opacity: omOpacity, rotationDegrees: -8)
                .fixedSize(horizontal: true, vertical: true)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .padding(.top, -28)
                .padding(.trailing, -52)

            VStack(spacing: 0) {
                navBar

                if let v = verse {
                    verseContextCard(v)
                        .padding(.horizontal, DharmaSpacing.md)
                        .padding(.top, DharmaSpacing.sm)
                        .padding(.bottom, DharmaSpacing.xs)
                }

                Divider()
                    .background(Color.dharmaDivider)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DharmaSpacing.md) {
                            if service.conversationHistory.isEmpty && !service.isStreaming {
                                KrishnaBubble(
                                    text: verse != nil
                                        ? "Namaste. I see you are reflecting on \(verse!.source). What arises in you from these words?"
                                        : "Namaste. I am here. What weighs on your heart today?",
                                    isStreaming: false,
                                    items: store.items
                                )
                                .id("greeting")
                            }

                            ForEach(service.conversationHistory) { message in
                                if message.role == "assistant" {
                                    KrishnaBubble(text: message.content, isStreaming: false, items: store.items)
                                        .id(message.id)
                                } else {
                                    UserBubble(text: message.content)
                                        .id(message.id)
                                }
                            }

                            if service.isStreaming {
                                KrishnaBubble(text: service.streamingResponse, isStreaming: true, items: store.items)
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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            inputBar
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                service.cancel()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.dharmaTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.dharmaSurface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.dharmaCardBorder, lineWidth: 1))
            }

            Spacer()

            Text("Krishna")
                .font(DharmaFont.georgia(20))
                .foregroundColor(.dharmaTextPrimary)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, DharmaSpacing.md)
        .padding(.vertical, DharmaSpacing.sm)
        .background(Color.dharmaBackground)
    }

    // MARK: - Verse Context Card

    private func verseContextCard(_ v: KrishnaVerse) -> some View {
        HStack(spacing: DharmaSpacing.sm) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 12))
                .foregroundColor(.dharmaGold)

            VStack(alignment: .leading, spacing: 2) {
                Text(v.source)
                    .font(DharmaFont.caption(11))
                    .foregroundColor(.dharmaGold)
                    .fontWeight(.medium)

                Text(v.english)
                    .font(DharmaFont.caption(12))
                    .foregroundColor(.dharmaTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()
        }
        .padding(.horizontal, DharmaSpacing.md)
        .padding(.vertical, DharmaSpacing.sm)
        .background(Color.dharmaSurface)
        .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.dharmaDivider)

            HStack(alignment: .bottom, spacing: DharmaSpacing.sm) {
                TextField("Ask Krishna...", text: $inputText, axis: .vertical)
                    .font(DharmaFont.georgia(16))
                    .foregroundColor(.dharmaTextPrimary)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .padding(.horizontal, DharmaSpacing.md)
                    .padding(.vertical, 10)
                    .background(Color.dharmaSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                            .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
                    )

                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(canSend ? Color.dharmaGold : Color.dharmaGold.opacity(0.35))
                        .clipShape(Circle())
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, DharmaSpacing.md)
            .padding(.vertical, DharmaSpacing.sm)
            .background(Color.dharmaBackground)
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !service.isStreaming
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        DharmaHaptics.medium()
        inputText = ""
        service.sendMessage(text, verse: verse)
    }
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
                    .font(DharmaFont.georgia(16))
                    .foregroundColor(.dharmaTextBody)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(VerseReferenceLinker.attributedString(from: plain, items: items))
                    .font(DharmaFont.georgia(16))
                    .foregroundColor(.dharmaTextBody)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .tint(.dharmaGold)
            }
        }
    }
}

// MARK: - Krishna Bubble

private struct KrishnaBubble: View {
    let text: String
    let isStreaming: Bool
    let items: [ScriptureItem]
    @State private var pulse = false

    var body: some View {
        HStack(alignment: .top, spacing: DharmaSpacing.sm) {
            Image(systemName: "seal.fill")
                .font(.system(size: 20))
                .foregroundColor(.dharmaGold)
                .opacity(0.85)
                .frame(width: 28, height: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(Color.dharmaGold)
                        .frame(width: 3)
                        .clipShape(Capsule())
                        .opacity(0.7)

                    VStack(alignment: .leading, spacing: 0) {
                        if !text.isEmpty {
                            VerseLinkedText(plain: text, isStreaming: isStreaming, items: items)
                        }

                        if isStreaming {
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .fill(Color.dharmaGold.opacity(pulse ? 0.9 : 0.3))
                                        .frame(width: 5, height: 5)
                                        .animation(
                                            .easeInOut(duration: 0.5)
                                                .repeatForever()
                                                .delay(Double(i) * 0.15),
                                            value: pulse
                                        )
                                }
                            }
                            .padding(.top, text.isEmpty ? 4 : 8)
                            .onAppear { pulse = true }
                        }
                    }
                }
                .padding(DharmaSpacing.md)
            }
            .background(Color.dharmaSurface)
            .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous)
                    .strokeBorder(Color.dharmaCardBorder, lineWidth: 1)
            )
            .contextMenu {
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }

            Spacer(minLength: 40)
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
                .font(DharmaFont.georgia(16))
                .foregroundColor(.dharmaTextBody)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(DharmaSpacing.md)
                .background(Color.dharmaGold.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DharmaRadius.lg, style: .continuous))
        }
    }
}

#Preview {
    KrishnaView(verse: nil)
        .environmentObject(ScriptureStore())
}
