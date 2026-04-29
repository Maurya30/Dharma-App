import SwiftUI
import UIKit

struct GoalPathMapView: View {
    let goalId: String

    @ObservedObject private var pathManager = GoalPathManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var dailySheetPayload: DailyVerseSheetPayload?
    @State private var showLevelComplete = false
    @State private var levelCompletePayload: (completed: PathLevel, next: PathLevel?)?
    @State private var lockShake: CGFloat = 0
    @State private var scrollTarget: String?
    @State private var completedLevelForDetail: PathLevel?

    private let baseRowHeight: CGFloat = 200
    private let todayCardSpacing: CGFloat = 16
    private let todayCardBlockHeight: CGFloat = 136
    private let nodeSize: CGFloat = 72
    private var nodeCircleCenterOffset: CGFloat { (nodeSize + 28) / 2 }

    private var path: GoalPath? { pathManager.pathForGoal(goalId) }

    var body: some View {
        Group {
            if pathManager.paths.isEmpty {
                ContentUnavailableView(
                    "Set your goals first",
                    systemImage: "map",
                    description: Text("Complete onboarding to begin your goal path.")
                )
                .foregroundStyle(Color.dharmaTextPrimary, Color.dharmaTextSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let path {
                mainMap(path: path)
            } else {
                ContentUnavailableView(
                    "Set your goals first",
                    systemImage: "map",
                    description: Text("Complete onboarding to begin your goal path.")
                )
                .foregroundStyle(Color.dharmaTextPrimary, Color.dharmaTextSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .dharmaBackground()
        .sheet(item: $dailySheetPayload) { payload in
            DailyVerseSheetView(
                goalId: payload.goalId,
                levelIndex: payload.levelIndex,
                dayIndex: payload.dayIndex,
                level: payload.level,
                day: payload.day,
                onLevelComplete: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        guard let p = pathManager.pathForGoal(goalId) else { return }
                        let completed = p.levels[payload.levelIndex]
                        levelCompletePayload = (completed, p.levels[safe: payload.levelIndex + 1])
                        showLevelComplete = true
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showLevelComplete) {
            if let ctx = levelCompletePayload {
                LevelCompleteView(
                    completedLevel: ctx.completed,
                    nextLevel: ctx.next,
                    onBeginNext: {
                        if let n = ctx.next {
                            scrollTarget = "level-\(n.id)"
                        }
                    },
                    onDismiss: {
                        showLevelComplete = false
                        levelCompletePayload = nil
                    }
                )
            }
        }
        .sheet(item: $completedLevelForDetail) { level in
            GoalCompletedLevelSheet(goalId: goalId, level: level)
                .presentationDetents([.medium, .large])
        }
    }

    private func mainMap(path: GoalPath) -> some View {
        let displayLevels = path.levels.sorted { $0.levelNumber > $1.levelNumber }

        return ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    GeometryReader { geo in
                        let w = geo.size.width
                        connectorPath(displayLevels: displayLevels, path: path, width: w)
                    }
                    .frame(height: displayLevels.reduce(CGFloat(0)) { acc, level in
                        let idx = path.levels.firstIndex(where: { $0.id == level.id }) ?? 0
                        return acc + heightForRow(path: path, level: level, levelArrayIndex: idx)
                    })

                    VStack(spacing: 0) {
                        ForEach(Array(displayLevels.enumerated()), id: \.element.id) { _, level in
                            let idx = path.levels.firstIndex(where: { $0.id == level.id }) ?? 0
                            let h = heightForRow(path: path, level: level, levelArrayIndex: idx)
                            levelRow(path: path, level: level, levelArrayIndex: idx)
                                .frame(height: h)
                                .id("level-\(level.id)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) {
                header(path: path)
            }
            .onAppear {
                scrollToActive(proxy: proxy, path: path)
            }
            .onChange(of: scrollTarget) { _, new in
                guard let new else { return }
                withAnimation(.easeInOut(duration: 0.45)) {
                    proxy.scrollTo(new, anchor: .center)
                }
                scrollTarget = nil
            }
        }
    }

    private func heightForRow(path: GoalPath, level: PathLevel, levelArrayIndex: Int) -> CGFloat {
        baseRowHeight + (shouldShowTodayCard(path: path, level: level, levelArrayIndex: levelArrayIndex)
            ? todayCardSpacing + todayCardBlockHeight : 0)
    }

    private func connectorPath(displayLevels: [PathLevel], path: GoalPath, width: CGFloat) -> some View {
        Canvas { context, size in
            guard displayLevels.count > 1 else { return }
            var yCursor: CGFloat = 0
            let points: [CGPoint] = displayLevels.map { level in
                let idx = path.levels.firstIndex(where: { $0.id == level.id }) ?? 0
                let rowH = heightForRow(path: path, level: level, levelArrayIndex: idx)
                let x = CGFloat(level.levelNumber % 2 == 0 ? 0.25 : 0.75) * width
                let centerY = yCursor + rowH / 2
                yCursor += rowH
                return CGPoint(x: x, y: centerY)
            }

            for i in 0..<(points.count - 1) {
                var seg = Path()
                let p0 = points[i]
                let p1 = points[i + 1]
                let midY = (p0.y + p1.y) / 2
                seg.move(to: p0)
                seg.addCurve(to: p1, control1: CGPoint(x: p0.x, y: midY), control2: CGPoint(x: p1.x, y: midY))

                let upper = displayLevels[i]
                let done = upper.isComplete
                if done {
                    context.stroke(seg, with: .color(Color.dharmaGold.opacity(0.6)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                } else {
                    context.stroke(seg, with: .color(Color.dharmaGold.opacity(0.18)), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 5]))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func header(path: GoalPath) -> some View {
        let current = path.levels[safe: path.currentLevelIndex]
        let dayIdx = pathManager.todaysDayIndex(for: path)
        let dayNum = (dayIdx ?? 0) + 1

        return VStack(alignment: .leading, spacing: DharmaSpacing.sm) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("← My Journey")
                        .font(DharmaFont.body(14))
                        .foregroundColor(.dharmaGold)
                }
                Spacer()
            }

            Text(GoalsManager.shortName(for: goalId))
                .font(.custom("Georgia-Bold", size: 24))
                .foregroundColor(.dharmaTextPrimary)

            if let cl = current {
                Text("Level \(cl.levelNumber) of \(path.levels.count) · Day \(dayNum) of \(cl.days.count)")
                    .font(DharmaFont.body(13))
                    .foregroundColor(.dharmaTextMuted)
            }

            if let last = path.earnedTitles.last {
                HStack(spacing: 6) {
                    rewardBadgeIcon(name: last.emoji)
                    Text(last.title)
                        .font(DharmaFont.caption(12))
                        .foregroundColor(.dharmaTextPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.dharmaGold.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.dharmaGold.opacity(0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
        }
        .padding(DharmaSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
    }

    private func scrollToActive(proxy: ScrollViewProxy, path: GoalPath) {
        guard let cur = path.levels[safe: path.currentLevelIndex] else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.45)) {
                proxy.scrollTo("level-\(cur.id)", anchor: .center)
            }
        }
    }

    @ViewBuilder
    private func rewardBadgeIcon(name: String) -> some View {
        if UIImage(systemName: name) != nil {
            Image(systemName: name)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "C9821E"))
        } else {
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "C9821E"))
        }
    }

    private func nodeSubtitle(path: GoalPath, level: PathLevel, isActive: Bool, isDone: Bool, locked: Bool) -> String? {
        if locked { return "Level \(level.levelNumber)" }
        if isDone { return nil }
        guard isActive else { return nil }
        let count = Set(level.completedDayIndices).count
        let todayIdx = pathManager.todaysDayIndex(for: path)
        if count == 0 {
            return "Day 1 of \(level.days.count) · Tap to begin"
        }
        if let t = todayIdx {
            return "Day \(t + 1) of \(level.days.count) · Continue"
        }
        return "Day \(count) complete · Come back tomorrow"
    }

    @ViewBuilder
    private func nodeIcon(level: PathLevel) -> some View {
        if level.isComplete {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#2A1A00"))
        } else if level.isUnlocked {
            let symbolName = (level.levelNumber == 1 && !level.isComplete) ? "flame.fill" : iconName(for: level.levelNumber)
            Image(systemName: symbolName)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(Color(hex: "#2A1A00"))
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(hex: "#C9821E")
                    .opacity(0.45))
        }
    }

    private func iconName(for levelNumber: Int) -> String {
        switch levelNumber {
        case 1: return "flame"
        case 2: return "leaf"
        case 3: return "moon"
        case 4: return "sparkles"
        case 5: return "sun.max"
        default: return "circle"
        }
    }

    private func levelRow(path: GoalPath, level: PathLevel, levelArrayIndex: Int) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let isActive = levelArrayIndex == path.currentLevelIndex && !level.isComplete
            let isDone = level.isComplete
            let locked = !level.isUnlocked

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    if level.levelNumber % 2 == 0 {
                        Spacer().frame(width: w * 0.25 - nodeSize / 2)
                        nodeView(path: path, level: level, levelArrayIndex: levelArrayIndex, isActive: isActive, isDone: isDone, locked: locked, width: w)
                        Spacer(minLength: 0)
                    } else {
                        Spacer(minLength: 0)
                        nodeView(path: path, level: level, levelArrayIndex: levelArrayIndex, isActive: isActive, isDone: isDone, locked: locked, width: w)
                        Spacer().frame(width: w * 0.25 - nodeSize / 2)
                    }
                }

                if isActive, pathManager.todaysDayIndex(for: path) != nil,
                   let dayIdx = pathManager.todaysDayIndex(for: path),
                   let day = level.days[safe: dayIdx] {
                    Spacer().frame(height: todayCardSpacing)
                    todayCard(level: level, day: day, dayIndex: dayIdx, levelIndex: levelArrayIndex)
                }
            }
        }
    }

    private func shouldShowTodayCard(path: GoalPath, level: PathLevel, levelArrayIndex: Int) -> Bool {
        levelArrayIndex == path.currentLevelIndex && !level.isComplete && pathManager.todaysDayIndex(for: path) != nil
    }

    private func todayCard(level: PathLevel, day: PathDay, dayIndex: Int, levelIndex: Int) -> some View {
        Button {
            dailySheetPayload = DailyVerseSheetPayload(
                goalId: goalId,
                level: level,
                day: day,
                dayIndex: dayIndex,
                levelIndex: levelIndex
            )
        } label: {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(Color.dharmaGold)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY · DAY \(dayIndex + 1)")
                        .font(DharmaFont.caption(10))
                        .foregroundColor(.dharmaGold)
                        .tracking(0.8)
                    Text(day.verseText)
                        .font(DharmaFont.georgia(14))
                        .italic()
                        .foregroundColor(.dharmaTextPrimary)
                        .lineLimit(2)
                    Text(day.verseReference)
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.dharmaTextMuted)
                }
                .padding(.leading, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DharmaSpacing.sm)
            .glassCard(cornerRadius: DharmaRadius.md)
        }
        .buttonStyle(.plain)
    }

    private func nodeView(path: GoalPath, level: PathLevel, levelArrayIndex: Int, isActive: Bool, isDone: Bool, locked: Bool, width: CGFloat) -> some View {
        let subtitle = nodeSubtitle(path: path, level: level, isActive: isActive, isDone: isDone, locked: locked)
        let completedCount = Set(level.completedDayIndices).count

        return VStack(spacing: 6) {
            ZStack {
                if isDone {
                    Circle()
                        .fill(Color.dharmaGold)
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(Circle().strokeBorder(Color(hex: "FFDC50").opacity(0.45), lineWidth: 2))
                } else if locked {
                    Circle()
                        .fill(Color.dharmaGold.opacity(0.10))
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(Circle().strokeBorder(Color.dharmaGold.opacity(0.22), lineWidth: 2))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: locked)
                } else if isActive {
                    ZStack {
                        BreathingGlow()
                            .frame(width: 110, height: 110)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FFE870"), Color(hex: "#D4900A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                    }
                }

                nodeIcon(level: level)
                    .offset(x: locked ? lockShake : 0)

                if isActive {
                    Text("\(completedCount)/\(level.days.count)")
                        .font(DharmaFont.caption(11))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.dharmaGold))
                        .offset(x: 26, y: 26)
                        .animation(.spring(response: 0.3), value: completedCount)
                }
            }
            .frame(width: nodeSize + 28, height: nodeSize + 28)

            if isActive {
                dayDots(level: level, path: path)
            }

            Text(level.levelName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(locked ? .dharmaTextMuted.opacity(0.4) : .dharmaTextPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(DharmaFont.caption(11))
                    .foregroundColor(isActive ? .dharmaGold : .dharmaTextMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .onTapGesture {
            if locked {
                HapticManager.softLight()
                withAnimation(.default) { lockShake = 5 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { lockShake = 0 }
                }
            } else if isDone {
                HapticManager.light()
                completedLevelForDetail = level
            } else if isActive, let dayIdx = pathManager.todaysDayIndex(for: path), let day = level.days[safe: dayIdx] {
                HapticManager.light()
                dailySheetPayload = DailyVerseSheetPayload(
                    goalId: goalId,
                    level: level,
                    day: day,
                    dayIndex: dayIdx,
                    levelIndex: levelArrayIndex
                )
            }
        }
    }

    private func dayDots(level: PathLevel, path: GoalPath) -> some View {
        let todayIdx = pathManager.todaysDayIndex(for: path)
        return HStack(spacing: 4) {
            ForEach(0..<level.days.count, id: \.self) { d in
                let done = level.completedDayIndices.contains(d)
                let isToday = d == todayIdx
                Circle()
                    .fill(done ? Color.dharmaGold : Color.dharmaGold.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.dharmaGold.opacity(isToday ? 0.95 : 0), lineWidth: 2)
                    )
                    .animation(.spring(response: 0.3), value: done)
            }
        }
    }
}

// MARK: - Breathing glow (active node only)

private struct BreathingGlow: View {
    @State private var breatheOut = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let breathDuration: Double = 1.25

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "C9821E"))
                .opacity(reduceMotion ? 0.2 : (breatheOut ? 0.28 : 0.07))
                .frame(width: 104, height: 104)
                .blur(radius: reduceMotion ? 14 : (breatheOut ? 18 : 6))
                .scaleEffect(reduceMotion ? 1.0 : (breatheOut ? 1.07 : 0.93))

            Circle()
                .fill(Color(hex: "FFE8A0"))
                .opacity(reduceMotion ? 0.22 : (breatheOut ? 0.42 : 0.11))
                .frame(width: 80, height: 80)
                .blur(radius: reduceMotion ? 7 : (breatheOut ? 10 : 3))
                .scaleEffect(reduceMotion ? 1.0 : (breatheOut ? 1.05 : 0.96))
        }
        .allowsHitTesting(false)
        .animation(
            reduceMotion ? .default : .easeInOut(duration: breathDuration).repeatForever(autoreverses: true),
            value: breatheOut
        )
        .onAppear {
            guard !reduceMotion else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                breatheOut = true
            }
        }
    }
}

// MARK: - Daily verse sheet payload (`sheet(item:)` — payload exists before presentation)

private struct DailyVerseSheetPayload: Identifiable {
    let id: String
    let goalId: String
    let levelIndex: Int
    let dayIndex: Int
    let level: PathLevel
    let day: PathDay

    init(goalId: String, level: PathLevel, day: PathDay, dayIndex: Int, levelIndex: Int) {
        self.goalId = goalId
        self.level = level
        self.day = day
        self.dayIndex = dayIndex
        self.levelIndex = levelIndex
        self.id = "\(goalId)-\(level.id)-d\(dayIndex)"
#if DEBUG
        print("[GoalPathMapView] DailyVerseSheet presenting day ref=\"\(day.verseReference)\" verseText=\"\(day.verseText.prefix(200))\" (count=\(day.verseText.count))")
#endif
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
