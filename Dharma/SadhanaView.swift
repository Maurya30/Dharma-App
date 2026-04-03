import SwiftUI

struct SadhanaView: View {
    @ObservedObject private var sadhana = SadhanaManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notificationNav: NotificationNavigationState

    @State private var darshanExpanded = false
    @State private var darshanDetailExpanded = false
    @State private var darshanReflection = ""

    @State private var bhavanaOneWord: String = ""
    @State private var bhavanaDetailExpanded = false
    @State private var bhavanaText: String = ""
    @State private var bhavanaKrishnaResponse = ""
    @State private var showBhavanaKrishna = false
    @State private var isLoadingBhavanaKrishna = false

    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    @State private var overlayPayload: (SadhanaAct, String, String)?
    @State private var overlayPresented = false
    @State private var overlayEnglishVisible = false

    @AppStorage("sadhana_open_krishna") private var openKrishnaFromSadhana = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    darshanCard
                    bhavanaCard
                    sevaCard

                    if sadhana.isFullyComplete {
                        completionCard
                    }
                }
                .padding()
            }
        }
        .dharmaBackground()
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .onAppear {
            sadhana.checkAndResetIfNewDay()
            if darshanReflection.isEmpty, !sadhana.darshanInput.isEmpty {
                darshanReflection = sadhana.darshanInput
            }
            if !sadhana.bhavanaInput.isEmpty {
                if bhavanaOneWord.isEmpty { bhavanaOneWord = sadhana.bhavanaInput }
                if bhavanaText.isEmpty { bhavanaText = sadhana.bhavanaInput }
            }
            if !sadhana.bhavanaKrishnaResponse.isEmpty {
                bhavanaKrishnaResponse = sadhana.bhavanaKrishnaResponse
                showBhavanaKrishna = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sadhana")
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundColor(.dharmaTextPrimary)

            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(.system(size: 13))
                .foregroundColor(.dharmaTextMuted)

            if !sadhana.sanskritTitle.isEmpty {
                Text(sadhana.sanskritTitle)
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.dharmaGold.opacity(0.2))
                    .foregroundColor(.dharmaGold)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.dharmaGold.opacity(0.9))
        }
        .padding(.top, 12)
        .padding(.trailing, 16)
    }

    // MARK: - Act 1 Darshan

    private var darshanCard: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("DARSHAN · SEEING")
                        .font(.system(size: 9))
                        .kerning(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(.dharmaGold)
                    Spacer()
                    if sadhana.isDarshanComplete {
                        ZStack {
                            Circle()
                                .fill(Color.dharmaGold)
                                .frame(width: 18, height: 18)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                if let v = sadhana.todayVerse {
                    if sadhana.isDarshanComplete {
                        darshanCompletedContent(verse: v)
                    } else if darshanExpanded {
                        Text("Sit with today's verse")
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .foregroundColor(.dharmaTextPrimary)

                        Text(v.textEnglish)
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.dharmaTextPrimary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(v.source)
                            .font(.system(size: 11, design: .serif))
                            .italic()
                            .foregroundColor(.dharmaGold)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .background(Color.dharmaGold.opacity(0.3))

                        ZStack(alignment: .topLeading) {
                            if darshanReflection.isEmpty {
                                Text("Write your reflection…")
                                    .font(.system(size: 15, design: .serif))
                                    .foregroundColor(.dharmaTextMuted)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $darshanReflection)
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.dharmaTextPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(4)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.dharmaGold.opacity(0.35), lineWidth: 1)
                        )

                        if !darshanReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button {
                                finishDarshan()
                            } label: {
                                Text("Done")
                                    .font(.system(size: 15, weight: .semibold, design: .serif))
                                    .foregroundColor(.dharmaGold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.dharmaGold.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    } else {
                        Button {
                            withAnimation(.spring()) {
                                darshanExpanded = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(v.source)
                                    .font(.system(size: 11, design: .serif))
                                    .italic()
                                    .foregroundColor(.dharmaTextSecondary)

                                Text(firstLine(of: v.textEnglish))
                                    .font(.system(size: 14, design: .serif))
                                    .foregroundColor(.dharmaTextPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Tap to read & reflect")
                                    .font(.system(size: 11))
                                    .foregroundColor(.dharmaTextMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("Verses are loading…")
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.dharmaTextMuted)
                }
            }
            .padding(DharmaSpacing.md)
            .opacity(sadhana.isDarshanComplete ? 0.75 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: sadhana.isDarshanComplete)

            sanskritOverlayLayer(for: .darshan)
        }
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    private func firstLine(of text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let r = trimmed.range(of: "\n") {
            return String(trimmed[..<r.lowerBound])
        }
        return trimmed
    }

    private func finishDarshan() {
        if let v = sadhana.todayVerse {
            sadhana.saveDarshanVerseId(v.id.uuidString)
            let trimmed = darshanReflection.trimmingCharacters(in: .whitespacesAndNewlines)
            sadhana.saveDarshanInput(trimmed)
        }
        sadhana.completeAct(.darshan)
        flashOverlay(for: .darshan)
    }

    private func darshanReflectionDisplay() -> String {
        let t = darshanReflection.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        return sadhana.darshanInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private func darshanCompletedContent(verse: ScriptureItem) -> some View {
        let reflection = darshanReflectionDisplay()
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                darshanDetailExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(verse.source)
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundColor(.dharmaGold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if darshanDetailExpanded {
                    Text(verse.textEnglish)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(.dharmaTextPrimary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                        .background(Color.dharmaGold.opacity(0.3))
                    if !reflection.isEmpty {
                        Text(reflection)
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(.dharmaTextPrimary)
                            .lineSpacing(4)
                    }
                } else {
                    Text(verse.textEnglish)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.dharmaTextMuted)
                        .opacity(0.7)
                        .lineSpacing(4)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Tap to see verse")
                        .font(.system(size: 10))
                        .foregroundColor(.dharmaTextMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Act 2 Bhavana

    private var bhavanaCard: some View {
        actCardShell(
            act: .bhavana,
            label: "BHAVANA · FEELING",
            title: sadhana.bhavanaPrompt,
            isComplete: sadhana.isBhavanaComplete,
            dimWhenComplete: false,
            fadeCompletedPrompt: true
        ) {
            if sadhana.isBhavanaComplete {
                completedBhavanaBlock
            } else {
            switch sadhana.bhavanaType {
            case .oneWord:
                TextField("one word...", text: $bhavanaOneWord)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.dharmaGold.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .disabled(sadhana.isBhavanaComplete)

                if bhavanaOneWord.count >= 1 && !sadhana.isBhavanaComplete {
                    Button("Done") {
                        completeBhavanaWithKrishna(userText: bhavanaOneWord)
                    }
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())
                }

            case .yesNo:
                HStack(spacing: 12) {
                    sevaPillButton("Yes") {
                        completeBhavanaWithKrishna(userText: "Yes")
                    }
                    .disabled(sadhana.isBhavanaComplete)
                    sevaPillButton("No") {
                        completeBhavanaWithKrishna(userText: "No")
                    }
                    .disabled(sadhana.isBhavanaComplete)
                }

            case .textInput:
                TextEditor(text: $bhavanaText)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.dharmaGold.opacity(0.35), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .disabled(sadhana.isBhavanaComplete)

                if bhavanaText.count >= 3 && !sadhana.isBhavanaComplete {
                    Button("Done") {
                        completeBhavanaWithKrishna(userText: bhavanaText)
                    }
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(.dharmaGold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.dharmaGold.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            if isLoadingBhavanaKrishna {
                ProgressView()
                    .tint(Color.dharmaGold)
                    .padding(.top, 4)
            }

            if showBhavanaKrishna && !bhavanaKrishnaResponse.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("✦")
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaGold)
                    Text(bhavanaKrishnaResponse)
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundColor(.dharmaTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            }
        }
    }

    private var completedBhavanaBlock: some View {
        let input = sadhana.bhavanaInput
        let kr = sadhana.bhavanaKrishnaResponse
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    bhavanaDetailExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(input.isEmpty ? "—" : String(input.prefix(120)))
                        .lineLimit(1)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(.dharmaTextMuted)
                    if !kr.isEmpty {
                        Text(String(kr.prefix(60)) + (kr.count > 60 ? "…" : ""))
                            .font(.system(size: 11, design: .serif))
                            .italic()
                            .foregroundColor(.dharmaTextMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if bhavanaDetailExpanded {
                Text(input)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                    .background(Color.dharmaGold.opacity(0.3))
                HStack(alignment: .top, spacing: 6) {
                    Text("✦")
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaGold)
                    Text(kr)
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundColor(.dharmaGold)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func completeBhavanaWithKrishna(userText: String) {
        sadhana.completeAct(.bhavana)
        let trimmedBhavana = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        sadhana.saveBhavanaResponse(input: trimmedBhavana, krishnaResponse: "")
        flashOverlay(for: .bhavana)
        let msg = "The seeker reflects: '\(userText)'. Respond in exactly one sentence as Krishna. Warm, direct, no questions."
        isLoadingBhavanaKrishna = true
        Task {
            do {
                let text = try await KrishnaService.shared.fetchOneShotResponse(message: msg)
                await MainActor.run {
                    isLoadingBhavanaKrishna = false
                    bhavanaKrishnaResponse = text
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showBhavanaKrishna = true
                    }
                    sadhana.saveBhavanaResponse(input: trimmedBhavana, krishnaResponse: text)
                    if !trimmedBhavana.isEmpty, let v = sadhana.todayVerse {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d"
                        let dateStr = formatter.string(from: Date())
                        let entry = JournalEntry(
                            verseId: v.id.uuidString,
                            verseReference: v.subtitle,
                            verseSource: v.source,
                            verseEnglish: v.textEnglish,
                            noteText: trimmedBhavana,
                            goalContext: nil,
                            source: "sadhana",
                            sourceLabel: "Sadhana · \(dateStr)",
                            krishnaResponse: text
                        )
                        JournalStore.shared.save(entry: entry)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingBhavanaKrishna = false
                    if !trimmedBhavana.isEmpty, let v = sadhana.todayVerse {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMM d"
                        let dateStr = formatter.string(from: Date())
                        let entry = JournalEntry(
                            verseId: v.id.uuidString,
                            verseReference: v.subtitle,
                            verseSource: v.source,
                            verseEnglish: v.textEnglish,
                            noteText: trimmedBhavana,
                            goalContext: nil,
                            source: "sadhana",
                            sourceLabel: "Sadhana · \(dateStr)",
                            krishnaResponse: ""
                        )
                        JournalStore.shared.save(entry: entry)
                    }
                }
            }
        }
    }

    // MARK: - Act 3 Seva

    private var sevaCard: some View {
        actCardShell(
            act: .seva,
            label: "SEVA · OFFERING",
            title: sevaTitle,
            subtitle: sevaSubtitle,
            isComplete: sadhana.isSevaComplete
        ) {
            Group {
                switch sadhana.todaySevaType {
                case .chant:
                    if sadhana.isSevaComplete {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Self.todayChantMantraTitle())
                                .font(.system(size: 11))
                                .foregroundColor(.dharmaTextMuted)
                            Text("Chanted 3 times")
                                .font(.system(size: 10))
                                .foregroundColor(.dharmaTextMuted)
                        }
                    } else {
                        ChantSevaBlock(
                            isComplete: false,
                            onComplete: {
                                sadhana.completeAct(.seva)
                                flashOverlay(for: .seva)
                            }
                        )
                    }
                case .askKrishna:
                    if sadhana.isSevaComplete {
                        Text("Opened Krishna AI")
                            .font(.system(size: 11))
                            .foregroundColor(.dharmaTextMuted)
                    } else {
                        askKrishnaSevaContent
                    }
                case .share:
                    if sadhana.isSevaComplete {
                        Text("Shared today's verse")
                            .font(.system(size: 11))
                            .foregroundColor(.dharmaTextMuted)
                    } else {
                        shareSevaContent
                    }
                }
            }
        }
    }

    private static func todayChantMantraTitle() -> String {
        guard !mantras.isEmpty else { return "Mantra" }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return mantras[day % mantras.count].title
    }

    private var sevaTitle: String {
        switch sadhana.todaySevaType {
        case .chant: return "Chant today's mantra"
        case .askKrishna: return "Ask Krishna one question"
        case .share: return "Share today's verse"
        }
    }

    private var sevaSubtitle: String? {
        switch sadhana.todaySevaType {
        case .askKrishna: return "He is listening"
        case .share: return "Offer it to someone"
        default: return nil
        }
    }

    private var askKrishnaSevaContent: some View {
        Button("Open Krishna AI") {
            sadhana.completeAct(.seva)
            openKrishnaFromSadhana = true
            dismiss()
        }
        .font(.system(size: 15, weight: .semibold, design: .serif))
        .foregroundColor(.dharmaGold)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(Color.dharmaGold.opacity(0.14))
        .clipShape(Capsule())
    }

    private var shareSevaContent: some View {
        Group {
            if let v = sadhana.todayVerse {
                Button("Share") {
                    let text = "\(v.textEnglish)\n\n— \(v.source)\n\nfrom Dharma"
                    shareItems = [text]
                    showShareSheet = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        sadhana.completeAct(.seva)
                        flashOverlay(for: .seva)
                    }
                }
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundColor(.dharmaGold)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.dharmaGold.opacity(0.14))
                .clipShape(Capsule())
            }
        }
    }

    private func sevaPillButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(.dharmaGold)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .overlay(
                    Capsule().stroke(Color.dharmaGold.opacity(0.85), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private var completionCard: some View {
        let progress = levelProgressForFirstGoal()

        return Button {
            if let g = GoalsManager.shared.selectedGoals.first {
                notificationNav.selectedTab = 2
                notificationNav.pendingGoalIdForPathMap = g
            }
            dismiss()
        } label: {
            ZStack {
                VStack(spacing: 12) {
                    Text("ॐ")
                        .font(.system(size: 32, design: .serif))
                        .foregroundColor(.dharmaGold)
                    Text("Sadhana complete")
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(.dharmaTextPrimary)

                    if let goalName = GoalsManager.shared.selectedGoals.first {
                        Text(goalName.uppercased())
                            .font(.system(size: 11))
                            .tracking(1.2)
                            .foregroundColor(.dharmaGold)
                            .multilineTextAlignment(.center)

                        if let p = progress {
                            HStack(spacing: 5) {
                                ForEach(0..<p.total, id: \.self) { i in
                                    Circle()
                                        .frame(width: 8, height: 8)
                                        .foregroundColor(i < p.done ? Color.dharmaGold : Color.clear)
                                        .overlay(Circle().stroke(Color.dharmaGold, lineWidth: 1))
                                }
                            }
                            Text("\(max(0, p.total - p.done)) more days to complete this level")
                                .font(.system(size: 11))
                                .foregroundColor(.dharmaTextMuted)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Text(Date(), style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.dharmaTextMuted)
                }
                .padding(20)
                .frame(maxWidth: .infinity)

                RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                    .stroke(Color.dharmaGold, lineWidth: 1.5)
            }
            .glassCard(cornerRadius: DharmaRadius.md)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: sadhana.isFullyComplete)
    }

    private func levelProgressForFirstGoal() -> (total: Int, done: Int)? {
        guard let g = GoalsManager.shared.selectedGoals.first,
              let path = GoalPathManager.shared.pathForGoal(g),
              path.currentLevelIndex < path.levels.count else { return nil }
        let level = path.levels[path.currentLevelIndex]
        return (level.days.count, level.completedDayIndices.count)
    }

    // MARK: - Card shell

    private func actCardShell(
        act: SadhanaAct,
        label: String,
        title: String,
        subtitle: String? = nil,
        isComplete: Bool,
        dimWhenComplete: Bool = true,
        fadeCompletedPrompt: Bool = false,
        @ViewBuilder content: () -> some View
    ) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text(label)
                        .font(.system(size: 9))
                        .kerning(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(.dharmaGold)
                    Spacer()
                    if isComplete {
                        ZStack {
                            Circle()
                                .fill(Color.dharmaGold)
                                .frame(width: 18, height: 18)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .opacity(fadeCompletedPrompt && isComplete ? 0.75 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.dharmaTextSecondary)
                }

                content()
            }
            .padding(DharmaSpacing.md)
            .opacity(isComplete && dimWhenComplete ? 0.75 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isComplete)

            sanskritOverlayLayer(for: act)
        }
        .glassCard(cornerRadius: DharmaRadius.md)
    }

    @ViewBuilder
    private func sanskritOverlayLayer(for act: SadhanaAct) -> some View {
        if let pl = overlayPayload, pl.0 == act, overlayPresented {
            ZStack {
                RoundedRectangle(cornerRadius: DharmaRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(1)

                VStack(spacing: 10) {
                    Text(pl.1)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundColor(.dharmaGold)
                        .multilineTextAlignment(.center)
                    Text(pl.2)
                        .font(.system(size: 13))
                        .foregroundColor(.dharmaTextMuted)
                        .multilineTextAlignment(.center)
                        .opacity(overlayEnglishVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 0.4), value: overlayEnglishVisible)
                }
                .padding(DharmaSpacing.md)
            }
            .transition(.opacity)
        }
    }

    private func sanskritEnglish(for act: SadhanaAct) -> (String, String) {
        switch act {
        case .darshan: return ("साधु", "Well done")
        case .bhavana: return ("शुभम्", "Auspicious")
        case .seva: return ("ॐ", "So it is offered")
        }
    }

    private func flashOverlay(for act: SadhanaAct) {
        let pair = sanskritEnglish(for: act)
        overlayPayload = (act, pair.0, pair.1)
        overlayEnglishVisible = false
        withAnimation(.easeInOut(duration: 0.4)) {
            overlayPresented = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.4)) {
                overlayEnglishVisible = true
            }
        }
        let hold: TimeInterval = 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + hold) {
            withAnimation(.easeInOut(duration: 0.4)) {
                overlayPresented = false
                overlayEnglishVisible = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + hold + 0.4) {
            overlayPayload = nil
        }
    }
}

// MARK: - Chant (Seva)

private struct ChantSevaBlock: View {
    let isComplete: Bool
    let onComplete: () -> Void

    @State private var lastTapTime: Date = .distantPast
    @State private var repCount = 0
    @State private var pulseSize: CGFloat = 60

    @State private var words: [String] = []
    @State private var longRep = 1
    @State private var wordIndex = 0
    @State private var longTimer: Timer?

    private var mantra: ScriptureItem? {
        guard !mantras.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return mantras[day % mantras.count]
    }

    private var wordList: [String] {
        guard let m = mantra else { return [] }
        let raw = m.mantraTransliteration ?? m.title
        return raw
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }

    private var isShortMode: Bool {
        wordList.count <= 5
    }

    private var longRepCaption: String {
        if words.count == 1 {
            return "Rep \(min(longRep + 1, 3)) of 3"
        }
        return "Rep \(longRep) of 3"
    }

    var body: some View {
        Group {
            if isComplete {
                EmptyView()
            } else if isShortMode {
                shortModeBody
            } else {
                longModeBody
            }
        }
        .onAppear {
            words = wordList
            if isShortMode {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseSize = 80
                }
            } else {
                if words.count == 1 {
                    longRep = 0
                } else {
                    longRep = 1
                    wordIndex = 0
                }
                startLongTimerIfNeeded()
            }
        }
        .onDisappear {
            longTimer?.invalidate()
            longTimer = nil
        }
    }

    private var shortModeBody: some View {
        VStack(spacing: 16) {
            Text(mantra?.title ?? "Om")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundColor(.dharmaGold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(mantra?.mantraTransliteration ?? mantra?.textEnglish ?? "")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text("Tap the circle once per repetition — 3 repetitions to complete.")
                .font(.system(size: 12))
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button {
                guard repCount < 3 else { return }
                guard Date().timeIntervalSince(lastTapTime) >= 1.5 else { return }
                lastTapTime = Date()
                repCount += 1
                if repCount >= 3 {
                    onComplete()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dharmaGold.opacity(0.3))
                        .frame(width: pulseSize, height: pulseSize)
                    Circle()
                        .stroke(Color.dharmaGold.opacity(0.6), lineWidth: 2)
                        .frame(width: pulseSize, height: pulseSize)
                }
            }
            .buttonStyle(.plain)

            Text("\(min(repCount + 1, 3)) of 3")
                .font(.system(size: 13))
                .foregroundColor(.dharmaGold)
        }
    }

    private var longModeBody: some View {
        VStack(spacing: 12) {
            Text(mantra?.title ?? "Om")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(.dharmaGold)
                .frame(maxWidth: .infinity)

            Text("Chant along as each word lights up — 3 full repetitions to complete.")
                .font(.system(size: 12))
                .foregroundColor(.dharmaTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            karaokeText
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(longRepCaption)
                .font(.system(size: 13))
                .foregroundColor(.dharmaGold)

            Text("chanting…")
                .font(.system(size: 11))
                .foregroundColor(.dharmaTextMuted)
        }
    }

    private var karaokeText: Text {
        guard !words.isEmpty else { return Text(verbatim: "") }
        var result = karaokeWord(at: 0)
        if words.count > 1 {
            for i in 1..<words.count {
                result = result + Text(verbatim: " ") + karaokeWord(at: i)
            }
        }
        return result.font(.system(size: 14, design: .serif))
    }

    private func karaokeWord(at i: Int) -> Text {
        let w = words[i]
        if i < wordIndex {
            return Text(w).foregroundColor(Color.dharmaGold.opacity(0.4))
        }
        if i == wordIndex {
            return Text(w).bold().foregroundColor(Color.dharmaGold)
        }
        return Text(w).foregroundColor(Color.dharmaTextPrimary.opacity(0.3))
    }

    private func startLongTimerIfNeeded() {
        guard !words.isEmpty else { return }
        longTimer?.invalidate()
        longTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            advanceLong()
        }
        RunLoop.main.add(longTimer!, forMode: .common)
    }

    private func advanceLong() {
        guard !words.isEmpty else { return }
        if words.count == 1 {
            if longRep >= 3 {
                longTimer?.invalidate()
                longTimer = nil
                onComplete()
            } else {
                longRep += 1
            }
            return
        }
        if wordIndex < words.count - 1 {
            wordIndex += 1
        } else {
            if longRep >= 3 {
                longTimer?.invalidate()
                longTimer = nil
                onComplete()
            } else {
                longRep += 1
                wordIndex = 0
            }
        }
    }
}

#Preview {
    SadhanaView()
        .environmentObject(NotificationNavigationState.shared)
}
