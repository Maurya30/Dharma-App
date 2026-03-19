import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.dharmaSurface)
        appearance.shadowColor = UIColor(Color.dharmaTabBorder)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(0)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)

            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.horizon.fill")
                }
                .tag(2)
        }
        .tint(.dharmaGold)
    }
}

#Preview {
    ContentView()
}
