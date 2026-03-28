import SwiftUI

struct JournalSheetView: View {
    let item: ScriptureItem
    var onAskKrishna: (() -> Void)?

    @ObservedObject private var journalStore = JournalStore.shared
    @State private var noteText = ""
    @State private var showSaved = false
    @State private var showingKrishnaResponse = false
    @State private var krishnaResponse = ""
    @State private var isKrishnaLoading = false
    @Environment(\.dismiss) private var dismiss

    private var verseId: String { item.id.uuidString }

    private var matchingGoal: String? {
        GoalTagsLoader.shared.matchingUserGoals(for: item, userGoals: GoalsManager.shared.selectedGoals).first
    }

    private var prompts: [String] {
        [
            "What does this verse mean in your life right now?",
            "How does this connect to your goal of \(matchingGoal.map { GoalsManager.shortName(for: $0) } ?? "your practice")?",
            "What would it look like to live this teaching today?",
            "What resistance do you feel reading this?"
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DharmaSpacing.lg) {
                    // Verse context card
                    verseContextCard

                    // Prompts
                    VStack(alignment: .leading, spacing: DharmaSpacing.md) {
                        Text("Prompts")
                            .font(DharmaFont.caption(11))
                            .foregroundColor(.dharmaGold)
                            .textCase(.uppercase)
                            .kerning(0.8)

                        FlowLayout(spacing: 8) {
                            ForEach(prompts, id: \.self) { prompt in
                                Button {
                                    if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        noteText = prompt + "\n\n"
                                    }
                                } label: {
                                    Text(prompt)
                                        .font(DharmaFont.caption(12))
                                        .foregroundColor(.dharmaTextBody)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .glassCard(cornerRadius: DharmaRadius.sm)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Text editor
                    VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                        Text("Your reflection")
                            .font(DharmaFont.caption(11))
                            .foregroundColor(.dharmaGold)
                            .textCase(.uppercase)
                            .kerning(0.8)

                        TextEditor(text: $noteText)
                            .font(DharmaFont.georgia(16))
                            .foregroundColor(.dharmaTextBody)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .padding(DharmaSpacing.md)
                            .background(Color.clear)
                            .overlay(alignment: .topLeading) {
                                if noteText.isEmpty {
                                    Text("Write your reflection…")
                                        .font(DharmaFont.georgia(16))
                                        .foregroundColor(.dharmaTextMuted)
                                        .padding(DharmaSpacing.md)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }
                            .glassCard(cornerRadius: DharmaRadius.md)
                    }

                    // Saved confirmation
                    if showSaved {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.dharmaGold)
                            Text("Saved")
                                .font(DharmaFont.caption(13))
                                .foregroundColor(.dharmaGold)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    // Action buttons
                    VStack(spacing: DharmaSpacing.sm) {
                        Button { saveReflection() } label: {
                            Text("Save reflection")
                                .font(DharmaFont.heading(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: DharmaRadius.md)
                                        .fill(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                              ? Color.dharmaGold.opacity(0.3)
                                              : Color.dharmaGold)
                                )
                        }
                        .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(action: { askKrishnaInline() }) {
                            HStack(spacing: DharmaSpacing.sm) {
                                if isKrishnaLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(Color(hex: "C9821E"))
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "C9821E"))
                                }
                                Text(isKrishnaLoading ? "Krishna is reflecting..." : "Ask Krishna about this")
                                    .font(DharmaFont.heading(16))
                                    .foregroundColor(Color(hex: "C9821E"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassCard(cornerRadius: DharmaRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                                    .strokeBorder(Color(hex: "C9821E").opacity(0.45), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isKrishnaLoading)

                        if showingKrishnaResponse && !krishnaResponse.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(Color(hex: "C9821E"))
                                        .font(.system(size: 12))
                                    Text("Krishna")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(hex: "C9821E"))
                                    Spacer()
                                    Button(action: {
                                        noteText += "\n\n— Krishna: " + krishnaResponse
                                        showingKrishnaResponse = false
                                        krishnaResponse = ""
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 11))
                                            Text("Add to reflection")
                                                .font(.system(size: 11))
                                        }
                                        .foregroundColor(Color(hex: "C9821E"))
                                    }
                                }
                                Text(krishnaResponse)
                                    .font(Font.custom("Georgia", size: 13))
                                    .foregroundColor(Color(hex: "2A1A00"))
                                    .italic()
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .glassCard(cornerRadius: DharmaRadius.md)
                            .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: DharmaSpacing.xl)
                }
                .padding(.horizontal, DharmaSpacing.md)
                .padding(.top, DharmaSpacing.md)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .tint(Color(hex: "C9821E"))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(Color(hex: "C9821E"))
                }
            }
            .onAppear {
                if let existing = journalStore.entry(for: verseId) {
                    noteText = existing.noteText
                }
            }
            .transparentNavigationBar()
            .dharmaBackground()
        }
    }

    // MARK: - Verse Context Card

    private var verseContextCard: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(Color.dharmaGold)
                .frame(width: 2)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(DharmaFont.caption(10))
                        .foregroundColor(item.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(item.category.color.opacity(0.12))
                        .clipShape(Capsule())

                    Text(item.source)
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaTextMuted)
                }

                Text(String(item.textEnglish.prefix(120)) + (item.textEnglish.count > 120 ? "…" : ""))
                    .font(DharmaFont.georgia(13))
                    .foregroundColor(.dharmaTextBody)
                    .lineSpacing(5)
                    .lineLimit(3)
            }
            .padding(.leading, DharmaSpacing.md)
        }
        .padding(DharmaSpacing.md)
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    // MARK: - Actions

    private func saveReflection() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var entry = journalStore.entry(for: verseId) ?? JournalEntry(
            verseId: verseId,
            verseReference: item.subtitle,
            verseSource: item.source,
            verseEnglish: item.textEnglish,
            noteText: trimmed,
            goalContext: matchingGoal
        )
        entry.noteText = trimmed
        journalStore.save(entry: entry)
        DharmaHaptics.success()

        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }

    func askKrishnaInline() {
        isKrishnaLoading = true
        showingKrishnaResponse = false
        krishnaResponse = ""

        let message = noteText.trimmingCharacters(in: .whitespaces).isEmpty
            ? "What does this verse mean and how can I apply it? Give a single focused insight in 3-5 sentences only. Do not ask follow up questions."
            : "I wrote this reflection on the verse: \(noteText)\n\nRespond to my reflection with a single focused insight in 3-5 sentences. Speak directly to what I wrote. Do not ask follow up questions."

        let request = KrishnaRequest(
            message: message,
            currentVerse: KrishnaVerse(
                id: item.id.uuidString,
                source: item.source,
                english: item.textEnglish
            ),
            goals: GoalsManager.shared.selectedGoals,
            reflection: noteText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : noteText,
            conversationHistory: nil
        )

        Task {
            do {
                var fullResponse = ""
                for try await chunk in KrishnaService.shared.streamResponse(request: request) {
                    fullResponse += chunk
                    await MainActor.run {
                        krishnaResponse = fullResponse
                        showingKrishnaResponse = true
                    }
                }
                await MainActor.run {
                    isKrishnaLoading = false
                }
            } catch {
                await MainActor.run {
                    isKrishnaLoading = false
                }
            }
        }
    }
}
