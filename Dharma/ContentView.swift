import SwiftUI

private struct PushVerseDetail: Identifiable, Hashable {
    let id: UUID
    let item: ScriptureItem
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PushVerseDetail, rhs: PushVerseDetail) -> Bool { lhs.id == rhs.id }
}

struct ContentView: View {
    @EnvironmentObject private var store: ScriptureStore
    @EnvironmentObject private var notificationNav: NotificationNavigationState
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var sadhana = SadhanaManager.shared
    @AppStorage("sadhana_open_krishna") private var openKrishnaFromSadhana = false
    @State private var krishnaPresented = false

    @State private var pushDetail: PushVerseDetail?

    var body: some View {
        TabView(selection: $notificationNav.selectedTab) {

            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.horizon.fill")
                }
                .tag(0)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(1)

            JourneyView()
                .tabItem {
                    ZStack(alignment: .topTrailing) {
                        Label("Journey", systemImage: "figure.walk")
                        if !sadhana.isFullyComplete && sadhana.completedCount == 0 {
                            Circle()
                                .fill(Color(hex: "C9821E"))
                                .frame(width: 8, height: 8)
                                .offset(x: 10, y: -4)
                        }
                    }
                }
                .tag(2)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(3)
        }
        .tint(.dharmaGold)
        .onChange(of: notificationNav.selectedTab) { _, _ in
            HapticManager.light()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dharma.openGoalFilter"))) { _ in
            notificationNav.selectedTab = 1
        }
        .onChange(of: notificationNav.pendingVerseSource) { _, source in
            guard let source, !source.isEmpty else { return }
            if let item = store.items.first(where: { $0.source == source }) {
                pushDetail = PushVerseDetail(id: item.id, item: item)
                notificationNav.pendingVerseSource = nil
                notificationNav.pendingScriptureItemId = nil
            }
        }
        .onChange(of: notificationNav.pendingScriptureItemId) { _, id in
            guard let id else { return }
            if let item = store.items.first(where: { $0.id == id }) {
                pushDetail = PushVerseDetail(id: item.id, item: item)
                notificationNav.pendingScriptureItemId = nil
                notificationNav.pendingVerseSource = nil
            }
        }
        .sheet(item: $pushDetail) { wrap in
            NavigationStack {
                ScriptureDetailView(item: wrap.item, store: store)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Task {
                    await AuthManager.shared.syncToCloud()
                }
            }
        }
        .onChange(of: openKrishnaFromSadhana) { _, v in
            guard v else { return }
            notificationNav.selectedTab = 0
            krishnaPresented = true
            DispatchQueue.main.async {
                openKrishnaFromSadhana = false
            }
        }
        .fullScreenCover(isPresented: $krishnaPresented) {
            KrishnaView(verse: nil)
                .environmentObject(store)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScriptureStore())
        .environmentObject(NotificationNavigationState.shared)
}
