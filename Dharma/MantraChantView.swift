import SwiftUI

struct MantraChantView: View {
    let item: ScriptureItem

    @Environment(\.dismiss) private var dismiss

    // Screen A
    @State private var chantStarted = false
    @State private var selectedReps = 27
    @State private var customRepsText = ""
    @State private var showCustomInput = false

    // Screen B
    @State private var currentRep = 1
    @State private var isPaused = false
    @State private var wordIndex = 0
    @State private var words: [String] = []
    @State private var longTimer: Timer?
    @State private var shortProgress: CGFloat = 0
    @State private var shortTimer: Timer?

    // Completion
    @State private var chantComplete = false
    @State private var showCompletion = false
    @State private var sessionStart = Date()

    private var mantraWords: [String] {
        let raw = item.mantraTransliteration ?? item.title
        return raw
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }

    private var isShortMantra: Bool {
        mantraWords.count <= 5
    }

    private var progress: CGFloat {
        let total = max(selectedReps, 1)
        return CGFloat(currentRep - 1) / CGFloat(total)
    }

    private var estimatedMinutes: Int {
        let w = mantraWords
        let secondsPerRep = isShortMantra
            ? 8.0
            : Double(max(w.count, 1)) * 1.2
        let totalSeconds = secondsPerRep * Double(selectedReps)
        return max(1, Int(totalSeconds / 60))
    }

    private var elapsedMinutes: Int {
        let elapsed = Date().timeIntervalSince(sessionStart)
        return max(1, Int(elapsed / 60))
    }

    var body: some View {
        Group {
            if showCompletion {
                completionScreen
            } else if chantStarted {
                chantScreen
            } else {
                repSelectorScreen
            }
        }
        .onAppear {
            assert(item.category == .mantras, "MantraChantView requires a mantra item")
        }
        .onDisappear {
            shortTimer?.invalidate()
            shortTimer = nil
            longTimer?.invalidate()
            longTimer = nil
        }
    }

    // MARK: - Screen A

    private var repSelectorScreen: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: 44)

                        Text(item.title)
                            .font(.system(size: 40, weight: .regular, design: .serif))
                            .foregroundColor(.dharmaTextPrimary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                            .fixedSize(horizontal: false, vertical: true)

                        mantraSubtitleRow
                            .padding(.bottom, 28)

                        Text("CHOOSE YOUR MALA")
                            .font(.system(size: 13, weight: .semibold))
                            .kerning(1.4)
                            .foregroundColor(Color.dharmaGold.opacity(0.75))
                            .padding(.bottom, 12)

                        HStack(spacing: 12) {
                            ForEach([11, 27, 54, 108], id: \.self) { n in
                                repPill(n)
                            }
                        }
                        .padding(.bottom, 12)

                        customNumberRow
                            .padding(.bottom, 28)

                        selectorStatsRow
                            .padding(.bottom, 28)

                        Text("Chant along as each word lights up. The mantra repeats automatically until your mala is complete.")
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(.dharmaTextSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity)
                            .padding(22)
                            .glassCard(cornerRadius: 20)
                            .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 32)
                }

                Button {
                    sessionStart = Date()
                    words = mantraWords
                    wordIndex = 0
                    currentRep = 1
                    chantStarted = true
                    startChanting()
                } label: {
                    Text("Begin chanting →")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2A1A00"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "C9821E"))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.dharmaGold.opacity(0.9))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.trailing, 20)
        }
        .dharmaBackground()
    }

    @ViewBuilder
    private var mantraSubtitleRow: some View {
        let hasDeity = item.mantraDeity != nil
        let hasBeej = item.mantraIsBeej == true
        if hasDeity || hasBeej {
            HStack(spacing: 6) {
                if let deity = item.mantraDeity {
                    Text(deity)
                }
                if hasDeity && hasBeej {
                    Text("·")
                }
                if hasBeej {
                    Text("Beej mantra")
                }
            }
            .font(DharmaFont.body(15))
            .foregroundColor(.dharmaTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var customNumberRow: some View {
        Group {
            if showCustomInput {
                HStack {
                    TextField("Enter number", text: $customRepsText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 17, design: .serif))
                        .foregroundColor(.dharmaTextPrimary)
                    Button("Set") {
                        if let n = Int(customRepsText), n > 0 {
                            selectedReps = n
                            showCustomInput = false
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.dharmaGold)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 14)
            } else {
                Button {
                    showCustomInput = true
                } label: {
                    HStack {
                        Text("Custom number")
                            .font(.system(size: 17, design: .serif))
                            .foregroundColor(.dharmaTextSecondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.dharmaGold.opacity(0.65))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var selectorStatsRow: some View {
        HStack(spacing: 0) {
            selectorStatCell(value: "\(selectedReps)", label: "REPETITIONS")
            statDivider
            selectorStatCell(value: "~\(estimatedMinutes)", label: "MINUTES")
            statDivider
            selectorStatCell(value: item.mantraDeity ?? "Universal", label: "DEITY")
        }
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.dharmaGold.opacity(0.2))
            .frame(width: 0.5)
            .padding(.vertical, 4)
    }

    private func selectorStatCell(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(.dharmaTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.dharmaTextSecondary)
                .tracking(1.4)
        }
        .frame(maxWidth: .infinity)
    }

    private func repPill(_ n: Int) -> some View {
        let isOn = selectedReps == n && !showCustomInput
        return Button {
            selectedReps = n
            showCustomInput = false
        } label: {
            Text("\(n)")
                .font(DharmaFont.caption().weight(.semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .foregroundColor(isOn ? Color.dharmaGold : .dharmaTextSecondary)
                .overlay(
                    Capsule()
                        .stroke(
                            isOn ? Color.dharmaGold : Color.dharmaGold.opacity(0.25),
                            lineWidth: isOn ? 1.5 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Screen B

    private var chantScreen: some View {
        ZStack {
            Color.clear

            VStack(spacing: 0) {
                Spacer(minLength: 8)

                Text(item.title)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(.dharmaTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 52)

                Spacer(minLength: 24)

                ZStack {
                    Circle()
                        .stroke(Color.dharmaGold.opacity(0.12), lineWidth: 12)
                        .frame(width: 240, height: 240)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.dharmaGold,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: progress)

                    VStack(spacing: 6) {
                        Text("\(currentRep)")
                            .font(.system(size: 64, weight: .regular, design: .serif))
                            .foregroundColor(.dharmaTextPrimary)
                        Text("of \(selectedReps)")
                            .font(.system(size: 16))
                            .foregroundColor(Color.dharmaGold.opacity(0.6))
                    }
                }

                Spacer(minLength: 32)

                Group {
                    if isShortMantra {
                        shortChantCard
                    } else {
                        longChantCard
                    }
                }
                .padding(.horizontal, 20)

                Text(chantStatusLine)
                    .font(.system(size: 13))
                    .foregroundColor(.dharmaTextSecondary)
                    .italic()
                    .padding(.top, 16)

                Spacer(minLength: 28)

                HStack(spacing: 24) {
                    Spacer(minLength: 0)

                    Button {
                        togglePause()
                        HapticManager.medium()
                    } label: {
                        Circle()
                            .fill(Color(hex: "C9821E"))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(Color(hex: "2A1A00"))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        shortTimer?.invalidate()
                        shortTimer = nil
                        longTimer?.invalidate()
                        longTimer = nil
                        dismiss()
                    } label: {
                        Circle()
                            .fill(Color.dharmaGold.opacity(0.1))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Circle()
                                    .stroke(Color.dharmaGold.opacity(0.35), lineWidth: 0.5)
                            )
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.dharmaGold)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        togglePause()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.dharmaGold)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .dharmaBackground()
        .onDisappear {
            shortTimer?.invalidate()
            shortTimer = nil
            longTimer?.invalidate()
            longTimer = nil
        }
    }

    private var chantStatusLine: String {
        if isPaused { return "Paused" }
        return "Chanting along…"
    }

    private var transliterationLine: String {
        item.mantraTransliteration ?? item.title
    }

    @ViewBuilder
    private var shortChantCard: some View {
        let sanskrit = item.mantraSanskrit?.trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(spacing: 0) {
            VStack(spacing: DharmaSpacing.md) {
                if let sanskrit, !sanskrit.isEmpty {
                    Text(sanskrit)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(Color.dharmaGold.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                Text(transliterationLine)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 44)
            .frame(maxWidth: .infinity)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.dharmaGold.opacity(0.12))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color.dharmaGold)
                        .frame(width: geo.size.width * shortProgress, height: 3)
                }
            }
            .frame(height: 3)
            .animation(.linear(duration: 0.05), value: shortProgress)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .glassCard(cornerRadius: 22)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !chantComplete, !isPaused else { return }
            shortTimer?.invalidate()
            shortProgress = 0
            completeRep()
        }
    }

    @ViewBuilder
    private var longChantCard: some View {
        let sanskrit = item.mantraSanskrit?.trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(spacing: DharmaSpacing.md) {
            if let sanskrit, !sanskrit.isEmpty {
                Text(sanskrit)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundColor(Color.dharmaGold.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            karaokeText
                .font(.system(size: 20, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .glassCard(cornerRadius: 22)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !chantComplete, !isPaused else { return }
            advanceLong()
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
        return result
    }

    private func karaokeWord(at i: Int) -> Text {
        let w = words[i]
        if i < wordIndex {
            return Text(w).foregroundColor(Color.dharmaGold.opacity(0.35))
        }
        if i == wordIndex {
            return Text(w).bold().foregroundColor(Color.dharmaGold)
        }
        return Text(w).foregroundColor(Color.dharmaTextPrimary.opacity(0.25))
    }

    // MARK: - Chanting engine

    private func startChanting() {
        guard !chantComplete else { return }
        if isShortMantra {
            startShortRep()
        } else {
            startLongTimer()
        }
    }

    private func startShortRep() {
        guard !isPaused, !chantComplete else { return }
        shortProgress = 0
        shortTimer?.invalidate()
        shortTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            tickShortRep()
        }
        if let t = shortTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func tickShortRep() {
        guard !isPaused, !chantComplete else { return }
        shortProgress += 0.05 / 8.0
        if shortProgress >= 1.0 {
            shortProgress = 0
            completeRep()
        }
    }

    private func startLongTimer() {
        guard !words.isEmpty else { return }
        longTimer?.invalidate()
        longTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            advanceLong()
        }
        if let t = longTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func advanceLong() {
        guard !isPaused, !chantComplete else { return }
        guard !words.isEmpty else { return }

        if wordIndex < words.count - 1 {
            wordIndex += 1
        } else {
            completeRep()
        }
    }

    private func completeRep() {
        if currentRep >= selectedReps {
            finishChantingSession()
            return
        }
        currentRep += 1
        wordIndex = 0
        guard !isPaused else { return }
        if isShortMantra {
            startShortRep()
        } else {
            startLongTimer()
        }
    }

    private func finishChantingSession() {
        shortTimer?.invalidate()
        shortTimer = nil
        longTimer?.invalidate()
        longTimer = nil
        chantComplete = true
        HapticManager.success()
        withAnimation(.easeInOut(duration: 0.5)) {
            showCompletion = true
        }
    }

    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            shortTimer?.invalidate()
            shortTimer = nil
            longTimer?.invalidate()
            longTimer = nil
        } else {
            startChanting()
        }
    }

    // MARK: - Screen C

    private var completionScreen: some View {
        ZStack {
            Color.clear
            VStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 16)

                Text("ॐ")
                    .font(.system(size: 64, design: .serif))
                    .foregroundColor(Color.dharmaGold)
                    .padding(.top, 40)

                Text("Mala complete")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .foregroundColor(.dharmaTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)

                Text("\(item.title) · \(selectedReps) repetitions")
                    .font(DharmaFont.body(15))
                    .foregroundColor(Color.dharmaGold.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 10)

                completionStatsRow
                    .padding(.horizontal, 8)
                    .padding(.bottom, 28)

                if let meaning = item.mantraMeaning {
                    VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
                        Text("MEANING")
                            .font(.system(size: 13, weight: .semibold))
                            .kerning(1.4)
                            .foregroundColor(Color.dharmaGold.opacity(0.75))
                        Text(meaning)
                            .font(DharmaFont.verseTranslation(19))
                            .foregroundColor(.dharmaTextPrimary.opacity(0.9))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .saffronLeftBar()
                    .padding(DharmaSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.dharmaGold.opacity(0.06))
                    .cornerRadius(16)
                    .padding(.horizontal, 4)
                }

                Spacer(minLength: 28)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.dharmaGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.dharmaGold.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity)
        }
        .dharmaBackground()
    }

    private var completionStatsRow: some View {
        HStack(spacing: 0) {
            selectorStatCell(value: "\(selectedReps)", label: "CHANTED")
            statDivider
            selectorStatCell(value: "~\(elapsedMinutes)", label: "MINUTES")
            statDivider
            selectorStatCell(value: "\(mantraWords.count)", label: "WORDS")
        }
    }
}
